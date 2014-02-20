require 'zlib'

#
# This class represents a single socket used to transfer file chunks as part of
# an inverse multiplex session.  It is controlled by an instance of IMUXManager.
# This class controls opening, closing, or recycling the socket, as well as serving
# or recieving chunks of a file.
#

class IMUXSocket
	attr_reader :state
	attr_accessor :reset
	attr_accessor :pause
	attr_accessor :bind_ip
	attr_accessor :verify
	attr_accessor :server_ip
	attr_accessor :multiplex_port
	attr_accessor :finish	
	attr_accessor :transfer_speed
	attr_accessor :bytes_transfered

	def initialize(manager, client_semaphore, server_semaphore)
		@manager = manager
		@client_semaphore = client_semaphore
		@server_semaphore = server_semaphore
		@state = "new"
		@reset = false
		@pause = false
		@bind_ip = nil
		@verify = false
		@server_ip = nil
		@multiplex_port = nil
		@finish = false
		@transfer_speed = 0
		@bytes_transfered = 0
		@closed = true		
	end

	def open_socket(server_ip, multiplex_port, bind_ip=nil)
		@state = "connecting"
		@bind_ip = bind_ip
		@server_ip = server_ip
		@multiplex_port = multiplex_port
		begin
			if @bind_ip != nil
				lhost = Socket.pack_sockaddr_in(0, @bind_ip)
				rhost = Socket.pack_sockaddr_in(@multiplex_port, @server_ip)
				@socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
				@socket.bind(lhost)
				@socket.connect(rhost)
			else
				@socket = TCPSocket.new(@server_ip, @multiplex_port)
			end
			@closed = false
			return true
		rescue
			@closed = true
			return false
		end
		# exchange strings randomly generated by multiplexity client to ensure correct multiplex session
		@state = "idle"
	end
	
	def recieve_connection(server)
		@socket = server.accept
		# exchange strings randomly generated by multiplexity client to ensure correct multiplex session
	end
	
	def process_download(buffer, verify, reset)
		@state = "downloading"
		@verify = verify
		@reset = reset
		@bytes_transfered = 0
		loop{
			sleep 1 until @pause == false
			open_socket if @closed
			close_socket; break if @finish
			request_next_chunk
			response = @socket.gets.chomp
			close_socket; break if response == "DONE"
			chunk_id, chunk_size, chunk_crc = parse_chunk_header response
			start = Time.now
			chunk_data = recieve_chunk_data(chunk_size)
			close_socket; break if chunk_data == nil
			chunk_ok = verify_chunk(chunk_data, chunk_crc)
			@client_semaphore.synchronize{ buffer.insert {:id => chunk_id, :data =>chunk_data} } if chunk_ok
			time_elapsed = Time.now - start
			@transfer_speed = chunk_size / time_elapsed
			@bytes_transfered += chunk_size
			reset_socket
		}
		@state = "idle"
	end
	
	def serve_download
		@state = "serving"
		@bytes_transfered = 0
		loop{
			recieve_connection if closed
			command = @socket.gets.chomp
			break if command == "CLOSE"
			add_crc = add_crc? command
			next_chunk = nil
			@server_semaphore.synchronize{ next_chunk = @manager.get_next_chunk }
			@socket.puts "DONE"; break if next_chunk == nil
			chunk_header = build_chunk_header(next_chunk, add_crc)
			success = send_chunk_data(chunk_header, next_chunk)
			@manager.stale_chunks << next_chunk if not success	# if that/attr_accessor doesn't work try @manager.stale_chunks = @manager.stale_chunks + next_chunk
			client_confirm_crc(next_chunk)
			reset_socket_server
		}
		@state = "idle"
	end

	def close_connections
		case @state
			when "idle"
				@socket.close
			when "downloading"
				@finish = true
			when "connecting"
				sleep 1
				close_connections
		end
	end

	private
	
	def close_socket
		@socket.puts "CLOSE"
		@socket.close
	end
	
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
		@manager.recieve_stale chunk if success == "CRCMISMATCH"
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
	
	def reset_socket_server
		reset = @socket.gets.chomp
		if reset == "RESET"
			@socket.close
			@closed = true
		end
	end
end
