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
	
	def handshake
		@server.puts "HELLO Multiplexity"
		@server.close if @server.gets.chomp != "HELLO Client"
	end
	
	def setup_multiplex(bind_ips, server)
		@server.puts bind_ips.size
		multiplex_port = @server.gets.to_i
		bind_ips.each do |ip|
			lhost = Socket.pack_sockaddr_in(0, ip)
			rhost = Socket.pack_sockaddr_in(multiplex_port, server)
			socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
			socket.bind(lhost)
			socket.connect(rhost)
			@multiplex_sockets << socket
		end
	end
	
	def get_command
		command = ""
		until command != ""
			print ">"
			command = STDIN.gets.chomp
		end
		command
	end
	
	def check_file(file)
		@server.puts "check #{file}"
		if @server.gets.chomp == "true"
			true
		else
			false
		end
	end
	
	def choose_file
		command = ""
		loop {
			command = get_command
			if command[0..7] != "download"
				process_command command
			else
				file = command.split(" ")[1]
				if file != nil and file != ""
					status = check_file file
					if status == true
						return file
					end
				end
			end
		}
	end
		
	def process_command(command)
		case command
			when "clear"
				system "clear"
			when "exit"
				shutdown
			else
				@server.puts command
				loop {
					line = @server.gets
					break if line.chomp == "fin"
					puts line
				}
		end
	end
	
	def download(file)
		@buffer = Buffer.new(file)
		@speeds = []
		@multiplex_sockets.each_with_index do |socket, i|
			Thread.new{get_next_chunk(socket, i)}
		end
		Thread.list.each do |thread|
			thread.join if thread != (Thread.current or screen)
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
			puts "\tWorker #{i}: " + "#{format_bytes(speed)}/s".yellow
			total_speed += speed
		end
		puts
		puts "Pool speed: ".green + "#{format_bytes(total_speed)}/s".yellow
		puts
		puts "Progress: ".green + "%".yellow
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
		}
	end
	
	def verify_file(file)
		@server.puts "VERIFY"
		remote_crc = @server.gets.to_i
		local_crc = Zlib::crc32(File.read(file))
		remote_crc == local_crc
	end
	
	def shutdown
		exit 0
		@multiplex_sockets.each do |socket|
			socket.close
		end
		@server.close
	end
	
end
