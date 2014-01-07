require './buffer.rb'
require 'socket'
require 'zlib'
require './securesocket.rb'
require './smp.rb'
require 'openssl'

class MultiplexityClient
	def initialize(server_ip, server_port)
		@server_ip = server_ip
		@server_port = server_port
		handshake
	end
	
	def handshake
		begin
			@server = SecureSocket.new
			@server.open(@server_ip, @server_port)
			@server.puts "HELLO Multiplexity"
			response = @server.gets.chomp
			if response != "HELLO Client"
				@server.close
				raise "Server did not respond to hello correctly"
			end
			# check if authentication is required and if username:password is required
		rescue
			return false
		end
		return true
	end

	def authenticate_server(secret)
		@server.puts "authenticate"
		shared_secret = OpenSSL::Digest::SHA256.hexdigest "#{secret}#{@server.shared_secret}"
		smp = SMP.new shared_secret
		@server.puts smp.step1
		@server.puts smp.step3 @server.gets
		smp.step5 @server.gets
		return smp.match
	end
	
	def create_imux_session
		# create new worker manager, make connections
	end
	
	
{
	#def create_multiplex_socket(bind_ip)
		#begin
			#lhost = Socket.pack_sockaddr_in(0, bind_ip)
			#rhost = Socket.pack_sockaddr_in(@multiplex_port, @server_ip)
			#socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
			#socket.bind(lhost)
			#socket.connect(rhost)
			#@multiplex_sockets << socket
		#rescue
		#end
		#socket
	#end

	#def setup_multiplex(bind_ips)
		#@multiplex_sockets = []
		#if @server.gets.chomp != "OK"
			#return false
		#end
		#@server.puts bind_ips.size
		#if @server.gets.chomp != "OK"
			#return false
		#end	
		#bind_threads = []
		#bind_ips.each do |bind_ip|
			#bind_threads << Thread.new{create_multiplex_socket(bind_ip)}
		#end
		#bind_threads.each do |thread|
			#thread.join if thread != Thread.current
		#end
		#@server.puts "OK"
		#@server.gets
		#@multiplex_sockets.size
	#end
}
	
	
	
	
	def get_remote_dir
		@server.puts "pwd"
		return @server.gets.chomp
	end
	
	def change_remote_directory(directory)
		@server.puts "cd #{directory}"
		return @server.gets.to_i
	end
	
	def get_remote_files(directory=".")
		files = []
		@server.puts "ls #{directory}"
		file_list = @server.gets
		file_list = file_list.split(";")
		file_list.each do |line|
			line = line.split("#")
			files << {:filename => line[0], :path => line[1], :size => line[2].to_i, :type => line[3], :last_write => line[4], :readable => line[5]}
		end
		files
	end
	
	def delete_remote_item(item)
		@server.puts "rm #{item}"
		return @server.gets.to_i
	end
	
	def change_chunk_size(i)
		@server.puts "updatechunk #{i}"
		success = @server.gets.to_i
		@chunk_size = i if success == 0
		return success
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
	
	def download_file(file, verify, reset)
		#@downloaded = 0
		#@workers = []
		#@semaphore = Mutex.new
		#@verify = verify
		#@server.puts "download #{file}"
		#busy = @server.gets.to_i
		#if busy == 1
			#raise "Server is current processing another transfer"
		#end
		#readable = @server.gets.to_i
		#if readable == 1
			#raise "Remote file is not readable"
		#end
		#@buffer = Buffer.new(file)
		#@server.gets
		#@multiplex_sockets.each_with_index do |socket, i|
			#@workers << Thread.new{get_next_chunk(socket, verify, reset)}
		#end
		#@workers.each do |thread|
			#thread.join
		#end
		#@workers = []
	end
	
{
	#def get_next_chunk(socket, verify, reset)
		#Thread.current[:close] = false
		#Thread.current[:reset] = reset
		#Thread.current[:pause] = false
		#Thread.current[:bind_ip] = socket.local_address.ip_address
		#Thread.current[:verify] = verify
		#closed = false
		#loop {
			#until Thread.current[:pause] == false
				#sleep 1
			#end
			#if closed
				#begin
					#socket = create_multiplex_socket(Thread.current[:bind_ip])
					#closed = false
				#rescue
					#break
				#end
			#end
			#if Thread.current[:close] == true
				#socket.puts "CLOSE"
				#@multiplex_sockets.delete socket
				#@workers.delete Thread.current
				#socket.close
				#break
			#end
			#if Thread.current[:verify]
				#socket.puts "GETNEXTWITHCRC"
				#has_crc = true
			#else
				#socket.puts "GETNEXT"
				#has_crc = false
			#end
			#response = socket.gets.chomp
			#if response == "DONE"
				#break
			#end
			#header = response.split(":")
			#chunk_id = header[0].to_i
			#chunk_size = header[1].to_i
			#if has_crc
				#chunk_crc = header[2].to_i
			#end
			#start = Time.now
			
			#begin
				#chunk_data = socket.read(chunk_size)
			#rescue
				#@multiplex_sockets.delete socket
				#@workers.delete Thread.current
				#socket.close
				#break
			#end
			#if Thread.current[:verify] and has_crc
				#local_crc = Zlib::crc32(chunk_data)
				#if local_crc == chunk_crc
					#socket.puts "CRC OK"
					#@semaphore.synchronize{ @buffer.insert({:id => chunk_id, :data => chunk_data}) }
				#else
					#socket.puts "CRC MISMATCH"
				#end
			#else
				#socket.puts "NO VERIFY"
				#@semaphore.synchronize{ @buffer.insert({:id => chunk_id, :data => chunk_data}) }
			#end
			#time = Time.now - start
			#Thread.current[:speed] = chunk_size / time
			#@downloaded += chunk_size
			#if Thread.current[:reset]
				#socket.puts "RESET"
				#@multiplex_sockets.delete socket
				#socket.close
				#closed = true
			#else
				#socket.puts "NORESET"
			#end
		#}
	#end
}

	def download_progress
		
	end
	
	#def remove_interface(ip)
		#raise "There are no active workers" if (defined? @workers) == nil
		#@workers.each do |worker|
			#if worker[:bind_ip] == ip
				#worker[:close] = true
			#end
		#end
	#end

	
	def change_verification
		#@workers.each do |worker|
			#worker[:verify] = !worker[:verify]
		#end
		#@verify = !@verify
	end
	
	def change_recycling
		
	end
	
	def pause_transfer
		
	end
	
	def resume_transfer
		
	end
end
