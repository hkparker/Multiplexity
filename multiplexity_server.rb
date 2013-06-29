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
		done = ""
		until done == "done"
			command = @client.gets.chomp
			done = process_command(command)
		end
		process_command(@client.gets.chomp)
		# do things to setup threaded server.  Fork a new thread for each multiplex socket that listens then gets send it the return value from get_next_chunk
		@client.puts "ready"
	end
	
	def check_file file
		valid = (FileTest.readable?(file) and (Dir.exists?(file) != true))
		@client.puts "#{valid}"
		return "done" if valid == true
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
	
	def show_size(file)
		@client.puts "File size for #{file}:".good
		if file != nil and file != "" and FileTest.readable?(file)
			size = File.size(file)
			i = 0
			loop {
				until size < 1024
					size = (size / 1024).round(1)
					i += 1
				end
				break
			}
			case i
				when 0
					suffix = "bytes"
				when 1
					suffix = "KB"
				when 2
					suffix = "MB"
				when 3
					suffix = "GB"
				when 4
					suffix = "TB"
			end
			@client.puts "#{size} #{suffix}"
			@client.puts "fin"
		else
			@client.puts "The file could not be read".bad
			@client.puts "fin"
		end
	end
end
