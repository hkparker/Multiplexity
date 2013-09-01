require './colors.rb'
require './worker.rb'
require './chunk.rb'
require 'zlib'

class MultiplexityServer
	@@used_ports = []
	def initialize(client)
		@client = client
		@multiplex_port = 8001
		@server = TCPServer.new("0.0.0.0", @multiplex_port)
		@multiplex_sockets = []
		@chunk_size = 1024*1024
		@last_chunk = 0
	end
	
	def handshake
		@client.close if @client.gets.chomp != "HELLO Multiplexity"
		@client.puts "HELLO Client"
	end
	
	def setup_multiplex
		socket_count = @client.gets.to_i
		@client.puts @multiplex_port
		socket_count.to_i.times do |i|
			@multiplex_sockets << @server.accept
		end
	end
	
	def process_commands
		loop {
			transfer_commands = ["download","upload"]
			command = @client.gets.chomp
			switch = command.split(" ")[0]
			if transfer_commands.include? switch
				case switch
					when "download"
						@download_file = command.split(" ")[1]
						serve_file
					when "upload"
						
				end
			else
				process_command(command)
			end
		}
	end
	
	def serve_file
		@workers = []
		@file_remaining = File.size(@download_file)
		@multiplex_sockets.each do |socket|
			worker = Worker.new(socket)
			@workers << worker
			Thread.new{worker.start}
		end
		@file = File.open(@download_file, 'rb')
		Thread.new{serve_chunk}
		Thread.list.each do |thread|
			thread.join if thread != Thread.current
		end
	end
	
	def serve_chunk
		told = 0
		@id = 1
		until told == @workers.size
			@workers.each do |worker|
				if worker.ready == true
					if @file_remaining > 0
						chunk_size = get_size
						worker.chunk = Chunk.new(@id,@file.read(chunk_size))
						@id += 1
						worker.ready = false
					else
						worker.chunk = 0
						worker.ready = false
						told += 1
					end
				end
			end
		end
	end
	
	def get_size
		if (@file_remaining - @chunk_size) > 0
			size = @chunk_size
			@file_remaining = @file_remaining - @chunk_size
		else
			size = @file_remaining
			@file_remaining = 0
		end
		size
	end
	
	def check_file file
		if (FileTest.readable?(file) and (Dir.exists?(file) != true))
			@client.puts "file"
		elsif Dir.exists?(file)
			@client.puts "directory"
		else
			@client.puts "unavailable"
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
			when "crc"
				send_file_crc command[1]
			when "bytes"
				send_bytes command[1]
			when "?"
				print_help
			else
				@client.puts "That was not a recognized command".bad
				@client.puts "Type ? to see all commands".good
				@client.puts "fin"
		end
	end
	
	def list_files
		@client.puts "Files and directories in current remote directory:".good
		files = Dir.entries(Dir.getwd)
		files.each do |file|
			file += "/" if Dir.exists?(file)
			@client.puts(file)
		end
		@client.puts "fin"
	end
	
	def print_help
		@client.puts "Avaliable commands are:".good
		@client.puts "ls\t\t- list remote files"
		@client.puts "lls\t\t- list local files"
		@client.puts "pwd\t\t- print remote working directory"
		@client.puts "lpwd\t\t- print local working directory"
		@client.puts "cd <dir>\t- change remote directory"
		@client.puts "lcd <dir>\t- change local directory"
		@client.puts "size <file>\t- check the size of a remote file/directory"
		@client.puts "lsize <file>\t- check the size of a local file/directory"
		@client.puts "clear\t\t- clear the terminal"
		@client.puts "download <file/directory>\t- download file/directory from server to client"
		@client.puts "upload <file/directory>\t\t- upload file/direcoty from client to server"
		@client.puts "?\t\t- print this message"
		@client.puts "exit\t\t- exits multiplexity"
		@client.puts "fin"
	end
	
	def change_dir(dir)
		begin
			Dir.chdir(dir)
			@client.puts("Changed remote directory to #{dir}".good)
			@client.puts "fin"
		rescue
			@client.puts("Unable to change remote directory to #{dir}".bad)
			@client.puts "fin"
		end
	end
	
	def print_dir
		@client.puts "The current remote working directory is:".good
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
	
	def send_file_crc(file)
		@client.puts Zlib::crc32(File.read(file))
	end
	
	def send_bytes(file)
		begin
			bytes = File.size(file)
		rescue
			bytes = 0
		end
		@client.puts bytes
	end
end
