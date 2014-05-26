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
	attr_reader :bind_ip
	attr_reader :port
	attr_reader :peer_ip
	
	attr_reader :transfer_speed
	attr_reader :bytes_transfered
	
	attr_accessor :reset
	attr_accessor :pause
	attr_accessor :verify
	
	def initialize(manager)
		@manager = manager
		@state = :new
		@bind_ip = nil
		@port = nil
		@peer_ip = nil
		@closed = true
		@transfer_speed = 0
		@bytes_transfered = 0
		@reset = false
		@pause = false
		@verify = false	
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
	
	def process_download(buffer, verify, reset)
		raise "Socket in use: #{@state}" if @state != :idle
		@state = :downloading
		@verify = verify
		@reset = reset
		@bytes_transfered = 0
		loop{
			sleep 1 until @pause == false
			open_socket if @closed
			request_next_chunk
			response = @socket.gets.chomp
			break if response == "DONE"
			chunk_id, chunk_size, chunk_crc = parse_chunk_header response
			start = Time.now
			chunk_data = recieve_chunk_data(chunk_size)
			if chunk_data == nil
				close_connection
				break 
			end
			chunk_ok = verify_chunk(chunk_data, chunk_crc)
			buffer.insert({:id => chunk_id, :data => chunk_data}) if chunk_ok
			time_elapsed = Time.now - start
			@transfer_speed = chunk_size / time_elapsed
			@bytes_transfered += chunk_size
			reset_socket
		}
		@state = :idle
	end
	
	def serve_download(file_queue)
		raise "Socket in use: #{@state}" if @state != :idle
		@state = :serving
		@bytes_transfered = 0
		loop{
			recieve_connection(@manager.server) if @closed
			request = @socket.gets.chomp
			add_crc = add_crc? request
			chunk = nil
			chunk = file_queue.next_chunk
			if chunk[:data] == nil
				@socket.puts "DONE"
				break
			end
			chunk_header = build_chunk_header(chunk, add_crc)
			success = send_chunk_data(chunk_header, chunk)
			if !success
				puts "Chunk #{chunk[id]} is now stale"
				file_queue.stale_chunks << chunk
			end
			client_confirm_crc(chunk)
			reset_socket_server
		}
		@state = :idle
	end

	def close_connection
		@socket.close if @socket != nil
	end

	private
	
	#
	# Download methods
	#
	
	def request_next_chunk
		if @verify
			@socket.puts "GETNEXTWITHCRC"
		else
			@socket.puts "GETNEXT"
		end
	end

	def parse_chunk_header(header)
		header = header.split(":")
		chunk_id = header[0].to_i
		chunk_size = header[1].to_i
		if header.size == 3
			chunk_crc = header[2].to_i
		else
			chunk_crc = nil
		end
		return chunk_id, chunk_size, chunk_crc
	end
	
	def recieve_chunk_data(chunk_size)
		begin
			chunk_data = @socket.read(chunk_size)
		rescue
			chunk_data = nil
		end
		chunk_data
	end

	def verify_chunk(chunk_data, chunk_crc)
		if @verify && chunk_crc != nil
			local_crc = Zlib::crc32(chunk_data)
			if local_crc == chunk_crc
				@socket.puts "CRCOK"
				return true
			else
				@socket.puts "CRCMISMATCH"
				return false
			end
		else
			@socket.puts "CRCOK"
			return true
		end
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

	def buffer_insert(buffer, semaphore, chunk_id, chunk_data)
		semaphore.synchronize{ buffer.insert({:id => chunk_id, :data => chunk_data}) }
	end
	
	def add_crc?(command)
		case command
			when "GETNEXT"
				return false
			when "GETNEXTWITHCRC"
				return true
		end
	end

	def build_chunk_header(chunk, add_crc)
		chunk_header = "#{chunk[:id]}:#{chunk[:data].size}"
		chunk_header += ":#{Zlib::crc32(chunk[:data])}" if add_crc
		return chunk_header
	end

	def send_chunk_data(chunk_header, chunk)
		@socket.puts chunk_header
		begin
			@socket.write(chunk[:data])
			return true
		rescue
			return false
		end
	end

	def client_confirm_crc(chunk)
		success = @socket.gets.chomp
		if success == "CRCMISMATCH"
			@manager.stale_chunks << chunk
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
