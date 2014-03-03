require 'zlib'
require 'fileutils'
require 'thread'
require './securesocket'
require './smp.rb'
require 'openssl'

#
# This class represents the server side part of a control socket.  Sessions
# are created by MultiplexityServers and respond to commands from a Host.
# They send information back to the Host as well as create IMUXManagers to 
# manage imux sessions with whoever the Host instructs.
#

class Session
	def initialize(client, allow_anonymous=false, auth_mandatory=false, server_secret=nil)
		@allow_anonymous = allow_anonymous
		@auth_mandatory = auth_mandatory
		@server_secret = server_secret
		if @auth_mandatory && @server_secret == nil
			raise "Cannot enforce authentication without shared secret"
		end
		@client = client
		raise "handshake failed" if handshake != true
		@command_processors = {"cd" => change_dir,
							  "ls" => send_file_list,
							  "rm" => delete_item,
							  "pwd" => send_pwd,
							  "mkdir" => create_directory,
							  "updatechunk" => change_chunk_size,
							  "setrecycle" => set_recycling,
							  "createsession" => create_imux_session,
							  "verify" => authenticate_client,
							  "closesession" => close_session
							  }
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
			login = @client.gets.chomp
			if login == "ANONYMOUS"
				if !@allow_anonymous
					@client.puts "Anonymous NO"
					@client.close
					return false
				else
					@client.puts "Anonymous OK"
			else
					login = login.split(":")
					username = login[0]
					password = login[1]
					# either @client.puts "user ok" or "user no"
			end
			@auth_mandatory ? @client.puts("AUTH MANDATORY") : @client.puts("AUTH NOMANDATORY")
			
			return true
		rescue
			@client.close
			return false
		end
	end

	def authenticate_client(secret)
		shared_secret = OpenSSL::Digest::SHA256.hexdigest "#{secret}#{@client.shared_secret}"
		smp = SMP.new shared_secret
		@client.puts(smp.step2(@client.gets))
		@client.puts(smp.step4(@client.gets))
		return smp.match
	end
	
	#def create_imux_session(server_ip, multiplex_port, bind_ips)
		## communicate with the sever about how many are going to open
		#@manager = WorkerManager.new
		#@manager.add_workers (server_ip, multiplex_port,bind_ips)
	#end
	
	#def recieve_imux_session(listen_ip, listen_port, count, sync_string)
		## communicate with the client about what the sync string is
		#@manager = WorkerManager.new
		#recieve_workers(listen_ip, listen_port, count, sync_string)
	#end

	def process_commands
		loop {
			command = @client.gets.chomp.split(" ")
			if @command_processors[command[0]] != nil
				@command_processors[command[0]] command[1]
			else
				@client.puts "REQUEST NOT UNDERSTOOD"
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

	def serve_file(file)	# needs a queue for is tranfer request while busy worker manager.
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

	def get_next_chunk
		if @stale.size > 0
			return stale.shift
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
