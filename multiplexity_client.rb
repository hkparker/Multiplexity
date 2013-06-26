require './colors.rb'
require './buffer.rb'
require './chunk.rb'
require 'socket'

class MultiplexityClient
	def initialize(socket)
		@server = socket
		@multiplex_sockets = []
	end
	
	def handshake
		@server.puts "HELLO Multiplexity"
		@server.close if @server.gets.chomp != "HELLO Client"
	end
	
	def setup_multiplex(bind_ips, server)
		@server.puts "SOCKETS #{bind_ips.size}"
		multiplex_port = @server.gets.to_i
		bind_ips.each do |ip|
			puts "Connecting to #{server} on port #{multiplex_port} from ip address #{ip}"
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
