require './colors.rb'
require './buffer.rb'
require './chunk.rb'
require 'socket'
require 'zlib'

class MultiplexityClient
	def initialize(socket)
		@server = socket
		@multiplex_sockets = []
		@id = 1
	end
	
	def handshake(port,chunk_size)
		begin
			@server.puts "HELLO Multiplexity"
			response = @server.gets.chomp
			if response == "HELLO Client"
				@server.puts port
				@server.puts chunk_size
				return true
			else
				return false
			end
		rescue
			return false
		end
	end
	
	def create_multiplex_socket(bind_ip, server_ip, multiplex_port)
		begin
			lhost = Socket.pack_sockaddr_in(0, bind_ip)
			rhost = Socket.pack_sockaddr_in(multiplex_port, server_ip)
			socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
			socket.bind(lhost)
			socket.connect(rhost)
			@multiplex_sockets << socket
		rescue
		end
	end
	
	def setup_multiplex(bind_ips, server_ip, multiplex_port)
			# send the number of expected sockets
			# server spins up that many listening threads, then tells me when they are all waiting on .accept
			# once the server is ready, client spins up a thread for each attempt
			# every successful connection gets added to the server and client list
			# just join every thread on the client because it will return either way
			# have the server be waiting for the client to say everything has returned
			# once the client says that, kill all threads that aresn't done, roll with what got added
		
		@server.gets
		@server.puts bind_ips.size
		@server.gets
		bind_ips.each do |bind_ip|
			Thread.new{create_multiplex_socket(bind_ip, server_ip, multiplex_port)}
		end
		Thread.list.each do |thread|
			thread.join if thread != Thread.current
		end
		@server.puts "done"
		@server.gets
		@multiplex_sockets.size
	end
	
	def check_target_type(target)
		@server.puts "check #{target}"
		return @server.gets.chomp
		# this is a bug!  if user types "check" no fin is sent, command line hangs
	end
		
	def process_command(command)
		@server.puts command
		loop {
			line = @server.gets
			break if line.chomp == "fin"
			puts line
		}
	end
	
	def download_directory(dir)
	
	end
	
	def download_file(file)
		@server.puts "bytes #{file}"
		@bytes = @server.gets.to_i
		@downloaded = 0
		@server.puts "download #{file}"
		@buffer = Buffer.new(file)
		@speeds = []
		@multiplex_sockets.each_with_index do |socket, i|
			Thread.new{get_next_chunk(socket, i)}
		end
		Thread.list.each do |thread|
			thread.join if thread != (Thread.current)
		end
	end
	
	def draw_screen
		system "clear"
		puts "Multiplexity".teal
		puts
		puts "Currently downloading: ".green + "#{@buffer.filename}"
		puts
		puts "Buffer:".green
		puts "\tChunks:\t" + "#{@buffer.count}".yellow
		puts "\tSize:\t" + "#{format_bytes(@buffer.size)}".yellow
		puts
		puts "Interface speeds:".green
		total_speed = 0
		@speeds.each_with_index do |speed, i|
			speed = 0 if speed == nil
			puts "\tWorker #{i}: " + "#{format_bytes(speed)}/s".yellow	# pass a hash containing speed and ip address of socket reporting speed
			total_speed += speed
		end
		puts
		puts "Pool speed: ".green + "#{format_bytes(total_speed)}/s".yellow
		puts
		puts "Progress: ".green + "#{((@downloaded.to_f/@bytes.to_f)*100).round(1)}%".yellow
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
	
	def get_next_chunk(socket, id)
		loop {
			draw_screen
			chunk_id = socket.gets.to_i
			break if chunk_id == 0
			chunk_size = socket.gets.to_i
			start = Time.now
			chunk_data = socket.read(chunk_size)
			time = Time.now - start
			@buffer.insert(Chunk.new(chunk_id,chunk_data))
			@speeds[id] = chunk_size / time
			@downloaded += chunk_size
		}
	end
	
	def verify_file(file)
		remote_thread = Thread.new{ Thread.current[:remote_crc] = get_remote_crc(file)}
		local_crc = Zlib::crc32(File.read(file))
		remote_thread.join
		remote_thread[:remote_crc] == local_crc
	end
	
	def get_size_bytes
		
	end
	
	def get_remote_crc(file)
		@server.puts "crc #{file}"
		return @server.gets.to_i
	end
	
	def shutdown
		@multiplex_sockets.each do |socket|
			socket.close
		end
		@server.close
	end
	
end
