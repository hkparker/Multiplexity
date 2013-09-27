require './colors.rb'
require './buffer.rb'
require './chunk.rb'
require 'socket'
require 'zlib'

class MultiplexityClient
	def initialize(socket)
		@server = socket
	end
	
	def handshake(multiplex_port,chunk_size)
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
	#	@chunk_size = chunk_size	### isn't needed
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
	
	def setup_multiplex(bind_ips, server_ip, multiplex_port)	# multiplex port doesn't need to be passed here, but maybe should be moved here
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
	
	###############################
	###############################
	###############################
	
	#def check_target_type(target)
		#@server.puts "check #{target}"
		#type = @server.gets.chomp
		#@server.gets
		#return type
	#end
	
	def download_file(file)
		@server.puts "bytes #{file}"
		@bytes = @server.gets.to_i
		@downloaded = 0
		@server.puts "download #{file}"
		@buffer = Buffer.new(file)
		@speeds = []
		@multiplex_sockets.each_with_index do |socket, i|
			Thread.new{get_next_chunk(socket, i, false)}	# this is going to change a lot
		end
		Thread.list.each do |thread|
			thread.join if thread != (Thread.current)
		end
	end
	
	#def draw_screen
		#system "clear"
		#puts "Multiplexity".teal
		#puts
		#puts "Currently downloading: ".green + "#{@buffer.filename}"
		#puts
		#puts "Buffer:".green
		#puts "\tChunks:\t" + "#{@buffer.count}".yellow
		#puts "\tSize:\t" + "#{format_bytes(@buffer.size)}".yellow
		#puts
		#puts "Interface speeds:".green
		#total_speed = 0
		#@speeds.each_with_index do |speed, i|
			#speed = 0 if speed == nil
			#puts "\tWorker #{i}: " + "#{format_bytes(speed)}/s".yellow
			#total_speed += speed
		#end
		#puts
		#puts "Pool speed: ".green + "#{format_bytes(total_speed)}/s".yellow
		#puts
		#puts "Progress: ".green + "#{((@downloaded.to_f/@bytes.to_f)*100).round(1)}%".yellow
	#end
	
	def format_bytes(bytes)
		i = 0
		until bytes < 1024
			bytes = (bytes / 1024).round(1)
			i += 1
		end
		suffixes = ["bytes","KB","MB","GB","TB"]
		"#{bytes} #{suffixes[i]}"
	end
	
	def get_next_chunk(socket, verify, reset)
		Thread.current[:close] = false
		Thread.current[:reset] = reset
		# define a variable for the bound IP and port? 	# sock_domain, remote_port, remote_hostname, remote_ip = socket.peeraddr
		closed = false
		loop {
			if Thread.current[:close] == true
				socket.puts "CLOSE"
				socket.close
				break
			end
			if closed
				socket = create_multiplex_socket(bind_ip, server_ip)	# need to have this stuff defined before the for loop
				closed = false
			end
			if verify
				socket.puts "GETNEXTWITHCRC"
			else
				socket.puts "GETNEXT"
			end
			response = socket.gets.chomp
			break if response == "DONE"
			data = response.split(":")
			chunk_id = data[0].to_i
			chunk_size = data[1].to_i
			if verify
				chunk_crc = data[2].to_i
			end
			chunk_data = socket.read(chunk_size)
			if verify
				local_crc = Zlib::crc32(chunk_data)
				if local_crc == chunk_crc
					socket.puts "CRC OK"
				else
					socket.puts "CRC MISMATCH"
				end
			end
			if Thread.current[:reset]
				socket.puts "RESET"
				@multiplex_sockets.delete socket
				socket.close
				closed = true
			end
		}	
		#loop {
			#draw_screen
			#chunk_id = socket.gets.to_i
			#break if chunk_id == 0
			#chunk_size = socket.gets.to_i
			#start = Time.now
			#chunk_data = socket.read(chunk_size)
			#time = Time.now - start
			#@buffer.insert(Chunk.new(chunk_id,chunk_data))
			#@speeds[id] = chunk_size / time
			#@downloaded += chunk_size
		#}
	end
	
	#def verify_file(file)
		#remote_thread = Thread.new{ Thread.current[:remote_crc] = get_remote_crc(file)}
		#local_crc = Zlib::crc32(File.read(file))
		#remote_thread.join
		#remote_thread[:remote_crc] == local_crc
	#end
	
	#def get_remote_crc(file)
		#@server.puts "crc #{file}"
		#return @server.gets.to_i
	#end
	
end
