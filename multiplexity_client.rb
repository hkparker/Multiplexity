require './colors.rb'
require './buffer.rb'
require './chunk.rb'
require 'socket'

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
			command = gets.chomp
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
		@multiplex_sockets.each do |socket|
			Thread.new{get_next_chunk(socket)}
		end
		Thread.list.each do |thread|
			thread.join if thread != Thread.current
		end
	end
	
	def get_next_chunk(socket)
		socket.puts "NEXT"
		# this method should terminate when there are no new chunks
	end
	
	def verify_file(file)
		# md5 the local file, compare to asking the server
	end
	
	def shutdown
		exit 0
		# close network connections and exit
	end
	
end
