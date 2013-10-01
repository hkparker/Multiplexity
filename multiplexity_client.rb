require './buffer.rb'
require 'socket'
require 'zlib'

class MultiplexityClient
	def initialize(socket)
		@server = socket
	end
	
	def handshake(multiplex_port,chunk_size)
		# open the socket here, define everything in initialize
		begin
			@server.puts "HELLO Multiplexity"
			response = @server.gets.chomp
			if response != "HELLO Client"
				@server.close
				return false
			end
			@server.puts "#{multiplex_port}:#{chunk_size}"
			response = @server.gets.chomp
			if response != "OK"
				@server.close
				return false
			end
		rescue
			return false
		end
		@multiplex_port = multiplex_port
		return true
	end
	
	def create_multiplex_socket(bind_ip, server_ip)
		begin
			lhost = Socket.pack_sockaddr_in(0, bind_ip)
			rhost = Socket.pack_sockaddr_in(@multiplex_port, server_ip)
			socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
			socket.bind(lhost)
			socket.connect(rhost)
			@multiplex_sockets << socket
		rescue
		end
		socket
	end
	
	def setup_multiplex(bind_ips, server_ip)
		@multiplex_sockets = []
		if @server.gets.chomp != "OK"
			return false
		end
		@server.puts bind_ips.size
		if @server.gets.chomp != "OK"
			return false
		end	
		bind_ips.each do |bind_ip|
			Thread.new{create_multiplex_socket(bind_ip, server_ip)}
		end
		Thread.list.each do |thread|
			thread.join if thread != Thread.current
		end
		@server.puts "OK"
		@server.gets
		@multiplex_sockets.size
	end
	
	def get_remote_dir
		@server.puts "pwd"
		return @server.gets.chomp
	end
	
	def get_remote_files(directory=".")
		files = []
		@server.puts "ls #{directory}"
		file_list = @server.gets
		file_list = file_list.split(";")
		file_list.each do |line|
			line = line.split("#")
			files << {:filename => line[0], :path => line[1], :size => line[2].to_i, :type => line[3], :last_write => line[4], :readable => line[5]}
		end
		files
	end
	
	def delete_remote_item(item)
		@server.puts "rm #{item}"
		return @server.gets.to_i
	end
	
	def change_remote_directory(directory)
		@server.puts "cd #{directory}"
		return @server.gets.to_i
	end
	
	def shutdown
		@server.puts "halt"
	end
	
	def format_bytes(bytes)
		i = 0
		until bytes < 1024
			bytes = (bytes / 1024).round(1)
			i += 1
		end
		suffixes = ["bytes","KB","MB","GB","TB"]
		"#{bytes} #{suffixes[i]}"
	end
	
	def download_file(file, verify, reset)
		@downloaded = 0
		@workers = []
		@semaphore = Mutex.new
		@server.puts "download #{file}"
		readable = @server.gets.to_i
		if readable == 1
			return 1
		end
		@buffer = Buffer.new(file)
		@server.gets
		@multiplex_sockets.each_with_index do |socket, i|
			@workers << Thread.new{get_next_chunk(socket, verify, reset)}
		end
		@workers.each do |thread|
			thread.join
		end
	end
	
	def get_next_chunk(socket, verify, reset)
		Thread.current[:close] = false
		Thread.current[:reset] = reset
		Thread.current[:pause] = false
		bind_ip = socket.local_address.ip_address
		server_ip = socket.gets.chomp
		closed = false
		loop {
			until Thread.current[:pause] == false
				sleep 1
			end
			if closed
				begin
					socket = create_multiplex_socket(bind_ip, server_ip)
					closed = false
				rescue
					break
				end
			end
			if Thread.current[:close] == true
				socket.puts "CLOSE"
				@multiplex_sockets.delete socket
				socket.close
				break
			end
			if verify
				socket.puts "GETNEXTWITHCRC"
			else
				socket.puts "GETNEXT"
			end
			response = socket.gets.chomp
			break if response == "DONE"
			header = response.split(":")
			chunk_id = header[0].to_i
			chunk_size = header[1].to_i
			if verify
				chunk_crc = header[2].to_i
			end
			start = Time.now
			begin
				chunk_data = socket.read(chunk_size)
			rescue
				@multiplex_sockets.delete socket
				socket.close
				break
			end
			if verify
				local_crc = Zlib::crc32(chunk_data)
				if local_crc == chunk_crc
					socket.puts "CRC OK"
					@semaphore.synchronize{ @buffer.insert({:id => chunk_id, :data => chunk_data}) }
				else
					socket.puts "CRC MISMATCH"
				end
			else
				@semaphore.synchronize{ @buffer.insert({:id => chunk_id, :data => chunk_data}) }
			end
			time = Time.now - start
			Thread.current[:speed] = chunk_size / time
			@downloaded += chunk_size
			if Thread.current[:reset]
				socket.puts "RESET"
				@multiplex_sockets.delete socket
				socket.close
				closed = true
			else
				socket.puts "NORESET"
			end
		}
	end
	
	def get_pool_speed
		pool_speed = 0
		@workers.each do |worker|
			pool_spped += worker[:speed]
		end
		pool_speed
		#0 if downloading != true
		# otherwise workers.each add worker[:speed]
	end
	
	def get_chunk_size
		# local var or ask server?
	end
	
	#check verification and recycling
	
	def get_worker_count
	
	end
	
	def get_download_progress
	
	end
	
	def add_workers
	
	end
	
	def remove_workers
	
	end
	
	def change_chunk_size
	
	end
	
	def change_verification
	
	end
	
	def change_recycling
	
	end
	
	def pause_transfer
	
	end
	
	def resume_transfer
	
	end
end
