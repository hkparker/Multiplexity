require 'zlib'
require 'fileutils'
require 'thread'
require 'openssl'

#
# This class represents the server side part of a control socket.  Sessions
# are created by MultiplexityServers and respond to commands from a Host.
# They send information back to the Host as well as create IMUXManagers to 
# manage imux sessions with other Sessions per the Host's instructions.
#

class Session
	def initialize(client)
		@client = client
		@imux_connections = {}
		handshake
		process_commands
	end

	private
	
	def handshake
		init = @client.gets.chomp
		raise "Connection not from a multiplexity client" if init != "Hello Multiplexity"
		@client.puts "Hello Client"
	end

	def process_commands
		loop {
			command = @client.gets.chomp.split(" ")
			case command[0]
				when "ls"
					send_file_list command[1]
				when "pwd"
					send_pwd
				when "cd"
					change_dir command[1]
				when "mkdir"
					create_directory command[1]
				when "rm"
					delete_item command[1]
				when "createsession"
					create_imux_session command[1]
				when "recievesession"
					recieve_imux_session command[1]
				when "createworkers"
					create_more_workers command[1]
				when "recieveworkers"
					recieve_workers command[1]
				when "closesession"
					close_imux_session
				when "updatechunk"
					change_chunk_size command[1]
				when "setrecycle"
					set_recycling command[1]
				when "upload"
					upload command[1]
				when "download"
					download command[1]
				when "close"
					close
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
	
	def create_imux_session(settings)
		begin
			settings = settings.split(":")
			bind_ip_config = settings[0]
			port = settings[1]
			recycle = settings[2]
			verify = settings[3]
			session_key = settings[4]
			imux_manager = IMUXManager.new
			@imux_connections.merge!(session_key => imux_manager)
			workers_opened = imux_manager.create_workers(peer_ip, port, Array.new(socket_count, bind_ip))
			@client.puts "#{workers_opened}"
		rescue
			@client.puts "ERROR"
		end
	end
	
	def recieve_imux_session(settings)
		begin
			settings = settings.split(":")
			listen_ip = settings[0]
			port = settings[1]
			socket_count = settings[2]
			imux_manager = IMUXManager.new
			session_key = settings[4]
			@imux_connections.merge!(session_key => imux_manager)
			@imux_manager.chunk_size = settings[3]
			Thread.new{ imux_manager.recieve_workers(listen_ip, port, socket_count) }
			@client.puts "0"
		rescue
			@client.puts "ERROR"
		end
	end
	
	def create_more_workers(settings)
		#
	end
	
	def recieve_more_workers(settings)
		#
	end
	
	def close_imux_session(session_key)
		@imux_connections[session_key].close_session
	end
	
	##
	## Imux settings
	##
	
	def change_chunk_size(settings)
		settings = settings.split(":")
		session_key = settings[0]
		size = settings[1]
		begin
			#@chunk_size = size.to_i # tell the imux manager?
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

	def upload(settings)
		
	end
	
	def download(settings)
		
	end

	##
	## Session operations
	##
	
	def close
		Thread.current.terminate
	end
end
