require './buffer.rb'
require 'socket'
require 'zlib'
require './securesocket.rb'
require './smp.rb'
require 'openssl'
require './workermanager.rb'

class Host
	def initialize(server_ip, server_port, authentication=nil, server_secret=nil)
		@server_ip = server_ip
		@server_port = server_port
		handshake(authentication, server_secret)
		queue = []
	end
	
	def handshake(authentication, server_secret)
		begin
			@server = SecureSocket.new
			@server.open(@server_ip, @server_port)
			@server.puts "HELLO Multiplexity"
			response = @server.gets.chomp
			if response != "HELLO Client"
				@server.close
				raise "Server did not respond to hello correctly"
			end
			authentication = "ANONYMOUS" if authentication == nil
			@server.puts authentication
			response = @server.gets
			if response.split(" ")[1] == "NO"
				@server.close
				raise "Bad username:password"
			end
			auth_mandatory = @server.gets
			if auth_mandatory.split(" ")[1] == "MANDATORY"
				if server_secret == nil
					@server.puts "NOSECRET"
					@server.close
					raise "Auth mandatory but no server secret"
				end
				safe = authenticate_server server_secret
				# if failed?
			end
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
		@server.puts(smp.step3(@server.gets))
		smp.step5 @server.gets
		return smp.match
	end
	
	def create_imux_session(server_ip, multiplex_port, bind_ips)
		# communicate with the sever about how many are going to open
		@manager = WorkerManager.new
		@manager.add_workers (server_ip, multiplex_port,bind_ips)
	end
	
	def recieve_imux_session(listen_ip, listen_port, count, sync_string)
		# communicate with the client about what the sync string is
		@manager = WorkerManager.new
		recieve_workers(listen_ip, listen_port, count, sync_string)
	end
	
	
	
	
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
	
	end
	
	def upload_file
	
	end

	def transfer_progress
		
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



# queue management?
# host.get_queue
# ok, so host-specific things are accessed directly, while transfered are addressed through the manager
# site1.get_files # => array of hashes
