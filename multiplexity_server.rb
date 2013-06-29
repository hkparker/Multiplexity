require './colors.rb'

class MultiplexityServer
	@@used_ports = []
	def initialize(client)
		@client = client
		@multiplex_port = 8001
		@server = TCPServer.new("0.0.0.0", @multiplex_port)
		@multiplex_sockets = []
		self.handshake
	end
	
	def handshake
		@client.close if @client.gets.chomp != "HELLO Multiplexity"
		@client.puts "HELLO Client"
		self.setup_multiplex
	end
	
	def setup_multiplex
		socket_count = @client.gets.to_i
		@client.puts @multiplex_port
		socket_count.to_i.times do |i|
			@multiplex_sockets << @server.accept
		end
		self.choose_file
	end
	
	def choose_file
		loop{
			command = @client.gets.chomp
			process_command(command)
		}
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
			when "size"
				show_size command[1]
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
			@client.puts("Changed directory to #{dir}".good)
			@client.puts "fin"
		rescue
			@client.puts("Unable to change directory to #{dir}".bad)
			@client.puts "fin"
		end
	end
	
	def print_dir
		@client.puts "The current working directory is:".good
		@client.puts(Dir.pwd)
		@client.puts "fin"
	end
	
	def show_size(file)
		@client.puts "File size for #{file}:".good
		if FileTest.readable?(file)	# also need to make sure file isn't null or an empty string
			size = File.size(file)
			@client.puts "#{(size / 1024.0 / 1024.0).round(1)} MB, #{(size / 1024.0 / 1024.0 / 1024.0).round(1)} GB"
			@client.puts "fin"
		else
			@client.puts "The file could not be read".bad
			@client.puts "fin"
		end
	end
end
