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
	def initialize(client, shared_secret, session_key)
		@client = client
		@shared_secret = shared_secret	# used to reauthenitcate
		@command_processors = {"ls" => send_file_list,
							  "pwd" => send_pwd,
							  "cd" => change_dir,
							  "mkdir" => create_directory,
							  "rm" => delete_item,
							  "createsession" => new_imux_session,
							  "closesession" => close_imux_session,
							  "updatechunk" => change_chunk_size,
							  "setrecycle" => set_recycling,
							  "upload" => upload,
							  "download" => download,
							  "verify" => authenticate_client
							  "close" => close_session,
							  }
		process_commands
	end

	private

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

	##
	## Filesystem operations
	##

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
	
	def send_pwd
		@client.puts Dir.pwd
	end
	
	def change_dir(dir)
		begin
			Dir.chdir(dir)
			@client.puts "0"
		rescue
			@client.puts "1"
		end
	end
	
	def create_directory(directory)
		begin
			Dir.mkdir("#{Dir.pwd}/#{directory}")
			@client.puts "0"
		rescue
			@client.puts "1"
		end
	end
	
	def delete_item(item)
		begin
			FileUtils.rm_rf item
			@client.puts "0"
		rescue
			@client.puts "1"
		end
	end
	
	##
	## Imux operations
	##
	
	def new_imux_session(settings)
		# based on settings, create or recieve a sessions
	end
	
	def create_imux_session(server_ip, multiplex_port, bind_ips)
		## communicate with the sever about how many are going to open
		@manager = WorkerManager.new
		@manager.add_workers(server_ip, multiplex_port,bind_ips)
	end
	
	def recieve_imux_session(listen_ip, listen_port, count, sync_string)
		## communicate with the client about what the sync string is
		@manager = WorkerManager.new
		recieve_workers(listen_ip, listen_port, count, sync_string)
	end
	
	def close_imux_session
		# close workermanager but leave control socket open
	end
	
	##
	## Imux settings
	##
	
	def change_chunk_size(i)
		begin
			i = i.to_i
			@chunk_size = i
			@client.puts "0"
		rescue
			@client.puts "1"
		end
	end
	
	def set_recycling
		
	end
	
	##
	## Transfer operations
	##

	def upload
		
	end
	
	def download
		
	end
	
	#def serve_file(file)	# needs a queue for is tranfer request while busy worker manager.
		#@downloading = true
		#@id = 0
		#begin
			#@current_file = File.open(file, 'rb')
			#@client.puts "0"
		#rescue
			#@client.puts "1"
			#@downloading = false
			#return
		#end
		#@semaphore = Mutex.new
		#@stale = []
		#@file_remaining = File.size(file)
		#@workers = []
		#@multiplex_sockets.each do |socket|
			#@workers << Thread.new{ serve_chunk(socket) }
		#end
		#@client.puts "OK"
		#@workers.each do |thread|
			#thread.join
		#end
		#@current_file.close
		#@workers = []
		#@downloading = false
	#end

	##
	## Session operations
	##

	def authenticate_client
	
	end
	
	def cloes_session
	
	end
end
