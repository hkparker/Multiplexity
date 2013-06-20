require './colors.rb'
require './buffer.rb'
require './chunk.rb'
require 'socket'

class MultiplexityClient
	def initialize(socket)
		@server = socket
	end
	
	def handshake
		@socket_count = 0
		@server.puts "HELLO Multiplexity"
		@server.close if @server.gets.chomp != "HELLO Client"
		@server.puts "SOCKETS #{@socket_count}"
		if @server.gets.chomp == "SOCKETS OK"
			true
		else
			false
		end
	end
	
	def setup_multiplex
		# do this later, using another port
		#self.choose_file
	end
	
	def get_command
		command = ""
		until command != ""
			print ">"
			command = gets.chomp
		end
		command
	end
	
	def choose_file
		loop{ process_command(get_command) }
		# this method will return a filename that is able to be downloaded
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
	
	
	def shutdown
		exit 0
		# close network connections and exit
	end
	
end
