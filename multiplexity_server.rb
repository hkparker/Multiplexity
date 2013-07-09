require './colors.rb'

class MultiplexityServer
	@@used_ports = []
	$chunk_size = 1024*1024
	@id = 0
	def initialize(client)
		@id = 0
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
		done = ""
		until done == "done"
			command = @client.gets.chomp
			done = process_command(command)
		end
		process_command(@client.gets.chomp)
		self.serve_file
	end
	
	def serve_file
		@file_remaining = File.size(@download_file)
		@multiplex_sockets.each do |socket|
			Thread.new{serve_chunk(socket)}
		end
		@file = File.open(@download_file, 'rb')
		@client.puts "ready"
		Thread.list.each do |thread|
			thread.join if thread != Thread.current
		end
	end
	
	def serve_chunk(socket)
		loop {
			socket.gets
			size = get_size
			socket.puts size
			break if size == 0
			socket.puts get_id
			socket.write(@file.read(size))
		}
	end
	
	def get_size
		if (@file_remaining - $chunk_size) > 0
			size = $chunk_size
			@file_remaining = @file_remaining - $chunk_size
		else
			size = @file_remaining
			@file_remaining = 0
		end
		size
	end
	
	def get_id
		@id += 1
		@id
	end
	
	def check_file file
		valid = (FileTest.readable?(file) and (Dir.exists?(file) != true))
		@client.puts "#{valid}"
		if valid == true
			@download_file = file
			return "done"
		end
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
			when "check"
				check_file command[1]
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
	
	def format_bytes(bytes)
		i = 0
		until bytes < 1024
			bytes = (bytes / 1024).round(1)
			i += 1
		end
		suffixes = ["bytes","KB","MB","GB","TB"]
		"#{bytes} #{suffixes[i]}"
	end
	
	def show_size(file)
		@client.puts "File size for #{file}:".good
		if file != nil and file != "" and FileTest.readable?(file)
			size = format_bytes(File.size(file))
			@client.puts size
			@client.puts "fin"
		else
			@client.puts "The file could not be read".bad
			@client.puts "fin"
		end
	end
end
