require 'zlib'
require 'fileutils'
require 'thread'
require './securesocket'
require './smp.rb'
require 'openssl'

class MultiplexityServer
	def initialize(client)
		@client = client
		raise "handshake failed" if handshake != true
		process_commands
	end

	def handshake
		begin
			hello = @client.gets.chomp
			if hello != "HELLO Multiplexity"
				@client.close
				return false
			end
			@client.puts "HELLO Client"
			# check if authentication is required
			return true
		rescue
			@client.close
			return false
		end
	end

	def authenticate_client(secret)
		shared_secret = OpenSSL::Digest::SHA256.hexdigest "#{secret}#{@client.shared_secret}"
		smp = SMP.new shared_secret
		@client.puts smp.step2 @client.gets
		@client.puts smp.step4 @client.gets
		return smp.match
	end



	def recieve_multiplex_socket
		#socket = @multiplex_server.accept
		#@multiplex_sockets << socket
		#socket
	end

	def setup_multiplex
		#@multiplex_sockets = []
		#begin
			#@multiplex_server = TCPServer.new("0.0.0.0", @multiplex_port)
		#rescue
			#@client.puts "FAIL"
			#return false
		#end
		#@client.puts "OK"
		#begin
			#socket_count = @client.gets.to_i
			#socket_count.to_i.times do |i|
				#Thread.new{ recieve_multiplex_socket }
			#end
		#rescue
			#@client.puts "FAIL"
			#return false
		#end
		#@client.puts "OK"
		#@client.gets
		#Thread.list.each do |thread|
			#thread.terminate if thread != Thread.current
		#end
		#@client.puts "OK"
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
					if @downloading
						@client.puts "1"
					else
						@client.puts "0"
						Thread.new{ serve_file command[1] }
					end
				when "upload"
					
				when "updatechunk"
					change_chunk_size command[1]
			#	when "updateworkers"
			#	when "changeverification"
			# perhaps also have a CONNECT TO command where you can tell ther server to make an outgoing connection
				when "halt"
					@multiplex_sockets.each do |socket|
						socket.close
					end
					@client.close
					return 0
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
		begin
			FileUtils.rm_rf item
			@client.puts "0"
		rescue
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
	
	def change_chunk_size(i)
		begin
			i = i.to_i
			@chunk_size = i
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

	def serve_file(file)
		@downloading = true
		@id = 0
		begin
			@current_file = File.open(file, 'rb')
			@client.puts "0"
		rescue
			@client.puts "1"
			@downloading = false
			return
		end
		@semaphore = Mutex.new
		@stale = []
		@file_remaining = File.size(file)
		@workers = []
		@multiplex_sockets.each do |socket|
			@workers << Thread.new{ serve_chunk(socket) }
		end
		@client.puts "OK"
		@workers.each do |thread|
			thread.join
		end
		@current_file.close
		@workers = []
		@downloading = false
	end
{
	#def serve_chunk(socket)
		#closed = false
		#loop {
			#if closed
				#begin
					#socket = recieve_multiplex_socket
					#closed = false
				#rescue
					#break
				#end
			#end
			#command = socket.gets.chomp
			#if command == "CLOSE"
				#@multiplex_sockets.delete socket
				#@workers.delete Thread.current
				#socket.close
				#break
			#elsif command == "GETNEXTWITHCRC"
				#add_crc = true
			#elsif command == "GETNEXT"
				#add_crc = false
			#end
			#next_chunk = nil
			#@semaphore.synchronize{ next_chunk = get_next_chunk }
			#if next_chunk == nil
				#socket.puts "DONE"
				#break
			#end
			#chunk_header = "#{next_chunk[:id]}:#{next_chunk[:data].size}"
			#chunk_header += ":#{Zlib::crc32(next_chunk[:data])}" if add_crc == true
			#socket.puts chunk_header
			#begin
				#socket.write(next_chunk[:data])
			#rescue
				#@stale << next_chunk
				#@multiplex_sockets.delete socket
				#@workers.delete Thread.current
				#socket.close
				#break
			#end
			#error = socket.gets.chomp
			#if error == "CRC MISMATCH"
				#@stale << next_chunk
			#end
			#reset = socket.gets.chomp
			#if reset == "RESET"
				#@multiplex_sockets.delete socket
				#socket.close
				#closed = true
			#end
		#}
	#end
}
	def get_next_chunk
		if @stale.size > 0
			return stale.shift(1)
		end
		chunk_size = get_size
		if chunk_size == 0
			return nil
		else
			@id += 1
			return {:id => @id, :data => @current_file.read(chunk_size)}
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
end
