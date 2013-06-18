require './colors.rb'

class MultiplexityServer
	@@used_ports = []
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
		# choose a random port and send it back to the client. skip for now.
		# this method ensures that all sockets are open correctly and that multiplex transfers are now ready.  hand over to transfer
		# probably going to need an array of sockets.  then a thread for each socket that waits for the socket to ask for the next chunk then gives it
		
		#once multiplexing is setup, now what?
		self.choose_file
	end
	
	def choose_file
		loop{ process_command(@client.gets.chomp)}
		# a method to transfer files.
		# after multiplex is setup have a method that return which file to server
		# this method will loop commands with client until the download command is selected
		# it will return to the client if that file is ok to download, and if so start serving it
	end
	
	def process_command(command)
		command = command.split(" ")
		case command[0]
			when "ls"
				list_files
			when "cd"
				change_dir command[1]
			when "pwd"
				print_dir
			else
				@client.puts "That was not a recognized command".bad
				@client.puts "fin"
		end
	end
	
	def list_files
		@client.puts "Files and directories in current directory:".good
		files = Dir.entries(Dir.getwd)
		files.each do |file|
			file += "/" if Dir.exists?(file)
			@client.puts(file)
		end
		@client.puts "fin"
	end
	
	def change_dir(dir)
		begin
			Dir.chdir(dir)
			@client.puts("Changed directory to #{new_dir}".good)
			@client.puts "fin"
		rescue
			@client.puts("Unable to change directory to #{new_dir}".bad)
			@client.puts "fin"
		end
	end
	
	def print_dir
		@client.puts "The current working directory is:".good
		@client.puts(Dir.pwd)
		@client.puts "fin"
	end
end
