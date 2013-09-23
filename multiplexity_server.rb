require './colors.rb'
require './worker.rb'
require './chunk.rb'
require 'zlib'
require 'fileutils'

class MultiplexityServer
	def initialize(client)
		@client = client
	end

	def handshake
		begin
			hello = @client.gets.chomp
			if hello != "HELLO Multiplexity"
				@client.close
				return false
			end
			@client.puts "HELLO Client"
			values = @client.gets.chomp
			values = values.split(":")
			@multiplex_port = values[0].to_i
			@chunk_size = values[1].to_i
			@client.puts "OK"
		rescue
			@client.close
			return false
		end
	end

	def recieve_multiplex_socket(server)
		@multiplex_sockets << server.accept
	end

	def setup_multiplex
		@multiplex_sockets = []
		begin
			multiplex_server = TCPServer.new("0.0.0.0", @multiplex_port)
		rescue
			@client.puts "FAIL"
			return false
		end
		@client.puts "OK"
		begin
			socket_count = @client.gets.to_i
			socket_count.to_i.times do |i|
				Thread.new{ recieve_multiplex_socket(multiplex_server)}
			end
		rescue
			@client.puts "FAIL"
			return false
		end
		@client.puts "OK"
		@client.gets
		Thread.list.each do |thread|
			thread.terminate if thread != Thread.current
		end
		@client.puts "OK"
	end

	def process_commands
		loop{
			command = @client.gets.chomp.split(" ")
			case command[0]
				when "ls"
					send_file_list command[1]
				when "rm"
					delete_item command[1]
				when "cd"
					change_dir command[1]
				when "pwd"
					send_pwd
				when "mkdir"
					create_directory command[1]
				when "download"
					@download_file = command[1]
					serve_file
				when "upload"
					
				when "halt"
					@multiplex_sockets.each do |socket|
						socket.close
					end
					@client.close
					return 0
				## to be removed:
				when "bytes"
					send_bytes command[1]
				when "check"
					check_file command[1]
				when "crc"
					send_file_crc command[1]
			end
		}
	end

	def send_file_list(directory)
		directory = Dir.getwd if directory == nil
		files = Dir.entries(directory)
		file_list = ""
		files.each do |filename|
			line = filename
			line += "#"
			line += directory
			line += "#"
			line += File.size("#{directory}/#{filename}").to_s
			line += "#"
			line += File.ftype "#{directory}/#{filename}"
			line += "#"
			line += File.mtime("#{directory}/#{filename}").strftime("%m/%e/%Y %l:%M %p")
			line += "#"
			line += File.readable?("#{directory}/#{filename}").to_s
			line += ";"
			file_list << line
		end
		@client.puts file_list
	end

	def delete_item(item)
		if (FileTest.readable?(item) and (Dir.exists?(item) != true))
			begin
				File.delete(item)
				@client.puts "0"
			rescue
				@client.puts "1"
			end
		elsif Dir.exists?(item)
			begin
				FileUtils.rm_rf item
				@client.puts "0"
			rescue
				@client.puts "1"
			end
		else
			@client.puts "1"
		end
	end
	
	def change_dir(dir)
		begin
			Dir.chdir(dir)
			@client.puts "0"
		rescue
			@client.puts "1"
		end
	end
	
	def send_pwd
		@client.puts Dir.pwd
	end
	
	def create_directory(directory)
		begin
			Dir.mkdir("#{Dir.pwd}/#{directory}")
			@client.puts "0"
		rescue
			@client.puts "1"
		end
	end
	
	
	
	###############################
	###############################
	###############################
	
	
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
	
	###############################
	###############################
	###############################
	
	
	def check_file file
		if (FileTest.readable?(file) and (Dir.exists?(file) != true))
			@client.puts "file"
		elsif Dir.exists?(file)
			@client.puts "directory"
		else
			@client.puts "unavailable"
		end
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
