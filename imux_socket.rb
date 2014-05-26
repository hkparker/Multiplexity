require 'socket'
require 'resolv'
require 'zlib'

#
# This class represents a single socket used to transfer file chunks as part of
# an inverse multiplex session.  It is controlled by an instance of IMUXManager.
# This class controls opening, closing, or recycling the socket, as well as serving
# or recieving chunks of a file.
#

class IMUXSocket
	attr_reader :state
	attr_reader :port
	attr_reader :peer_ip
	attr_reader :bind_ip
	attr_reader :transfer_speed
	attr_reader :bytes_transfered
	attr_accessor :reset
	
	def initialize(manager)
		@manager = manager
		@state = :new
		@port = nil
		@peer_ip = nil
		@bind_ip = nil
		@closed = true
		@transfer_speed = 0
		@bytes_transfered = 0
		@reset = false
	end

	def open_socket(peer_ip, port, bind_ip=nil)
		@state = :connecting
		@bind_ip = bind_ip
		@bind_ip = nil if @bind_ip == "nil"
		@port = port
		@peer_ip = Resolv::getaddress(peer_ip)
		begin
			if @bind_ip != nil
				lhost = Socket.pack_sockaddr_in(0, @bind_ip)
				rhost = Socket.pack_sockaddr_in(@port, @peer_ip)
				@socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
				@socket.bind(lhost)
				@socket.connect(rhost)
			else
				@socket = TCPSocket.new(@peer_ip, @port)
			end
			@closed = false
			@state = :idle
			return true
		rescue StandardError => e
			@state = :failed
			return false
		end
	end
	
	def recieve_connection(server)
		@socket = server.accept
		@state = :idle
		@closed = false
	end
	
	def process_download(buffer)
		raise "Socket in use: #{@state}" if @state != :idle
		@state = :downloading
		@bytes_transfered = 0
		@transfer_speed = 0
		loop{
			open_socket(@peer_ip, @port, @bind_ip) if @closed
			@socket.puts "GETNEXT"
			header = @socket.gets.chomp
			break if header == "DONE"
			chunk_id, chunk_size = header.split(":")
			chunk_id = chunk_id.to_i
			chunk_size = chunk_size.to_i
			start = Time.now
			chunk_data = recieve_chunk_data(chunk_size)
			if chunk_data == nil
				close_connection
				break
			end
			buffer.insert({:id => chunk_id, :data => chunk_data})
			time_elapsed = Time.now - start
			@transfer_speed = chunk_size / time_elapsed
			@bytes_transfered += chunk_size
			reset_socket
		}
		@transfer_speed = 0
		@state = :idle
	end
	
	def serve_download(file_queue)
		raise "Socket in use: #{@state}" if @state != :idle
		@state = :serving
		@bytes_transfered = 0
		@transfer_speed = 0
		loop{
			recieve_connection(@manager.server) if @closed
			request = @socket.gets.chomp
			chunk = file_queue.next_chunk
			if chunk[:data] == nil
				@socket.puts "DONE"
				return
			end
			@socket.puts "#{chunk[:id]}:#{chunk[:data].size}"
			success = send_chunk_data(chunk[:data])
			if !success
				file_queue.stale_chunks << chunk
			end
			reset_socket_server
		}
		@transfer_speed = 0
		@state = :idle
	end

	def close_connection
		begin
			@socket.close
		rescue
		end
	end

	private
	
	#
	# Download methods
	#
	
	def recieve_chunk_data(chunk_size)
		begin
			chunk_data = @socket.read(chunk_size)
		rescue
			chunk_data = nil
		end
		chunk_data
	end
	
	def reset_socket
		if @reset
			@socket.puts "RESET"
			@socket.close
			@closed = true
		else
			@socket.puts "NORESET"
		end
	end

	#
	# Upload methods
	#

	def send_chunk_data(data)
		begin
			@socket.write(data)
			return true
		rescue
			return false
		end
	end
	
	def reset_socket_server
		reset = @socket.gets.chomp
		if reset == "RESET"
			@socket.close
			@closed = true
		end
	end
end
