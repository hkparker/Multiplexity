require './colors.rb'

class MultiplexityServer
	def initialize(client)
		@client = client
		self.handshake
	end
	def handshake
		@client.close if @client.gets.chomp != "HELLO Multiplexity"
		@client.puts "HELLO Client"
		socket_count = @client.gets.chomp
		@client.close if (socket_count.slice! "SOCKETS ") != "SOCKETS "
		socket_count = socket_count.to_i
		@client.puts "SOCKETS OK"
		self.setup_multiplex
	end
	def setup_multiplex
		# this method ensures that all sockets are open correctly and that multiplex transfers are now ready.  hand over to transfer
	end
	def something
		# a method to transfer files.
		# loop {process_command server.gets} ... or something
	end
	
	def process_command(command)
		command = command.split(" ")
		case command[0]
			when "ls"
				list_files command[1]
			when "cd"
				change_dir command[1]
			when "pwd"
				print_dir
			else
				@client.puts "That was not a recognized command".bad
		end
	end
	
	def list_files
		files = Dir.entries(Dir.getwd)
		files.each do |file|
			file += "/" if Dir.exists?(file)
			@client.puts(file)
		end
		@client.puts "fin"
	end
	
	def change_dir
	
	end
	
	def print_dir
	
	end
end
