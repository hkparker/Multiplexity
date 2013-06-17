require './colors.rb'

class MultiplexityClient
	def initialize
	
	end
	def handshake
		@socket_count = 0
		@server.puts "HELLO Multiplexity"
		@server.close if @server.gets.chomp != "HELLO Client"
		@server.puts "SOCKETS #{@socket_count}"
		self.setup_multiplex if @server.gets.chomp == "SOCKETS OK"
	end
	def setup_multiplex
		
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
		# this method will return a filename that is able to be downloaded
	end
		
	def process_command(command)		# this should really be a server method
		case command
			when "clear"
				system "clear"
			when "exit"
				shutdown
			else
				@server.puts command
				until @server.gets == "fin"
					puts @server.gets
				end
		end
	end
	

	
	def shutdown
		# close network connections and exit
	end
	
end
