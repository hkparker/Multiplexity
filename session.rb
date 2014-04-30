require 'zlib'
require 'fileutils'
require 'thread'
require 'openssl'

require './imux_manager.rb'

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
					create_workers command[1]
				when "recieveworkers"
					recieve_workers command[1]
				when "removeworkers"
					remove_workers command[1]
				when "closesession"
					close_imux_session
				when "updatechunk"
					change_chunk_size command[1]
				when "setrecycle"
					set_recycling command[1]
				when "setverification"
					set_verification command[1]
				when "sendfile"
					send_file command[1]
				when "recievefile"
					recieve_file command[1]
				when "close"
					close
				else
					@client.puts "REQUEST NOT UNDERSTOOD: #{command[0]}"
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
			peer_ip = settings[4]
			session_key = settings[5]
			imux_manager = IMUXManager.new
			@imux_connections.merge!(session_key => imux_manager)
			bind_ip_config = bind_ip_config.split(";")
			bind_ip_array = []
			bind_ip_config.each do |config|
				ip_pair = config.split("-")
				ip_pair[1].to_i.times do |i|
					bind_ip_array << ip_pair[0]
				end
			end
			imux_manager.create_workers(peer_ip, port, bind_ip_array)
			@client.puts "0"
		rescue StandardError => e
			@client.puts e.inspect
		end
	end
	
	def recieve_imux_session(settings)
		begin
			settings = settings.split(":")
			listen_ip = settings[0]
			port = settings[1].to_i
			socket_count = settings[2].to_i
			@imux_manager = IMUXManager.new
			session_key = settings[4]
			@imux_connections.merge!(session_key => @imux_manager)
			@imux_manager.chunk_size = settings[3]
			Thread.new{ @imux_manager.recieve_workers(socket_count, listen_ip, port) }
			@client.puts "0"
		rescue StandardError => e
			@client.puts e.inspect
		end
	end
	
	def create_workers(settings)
		begin
			settings = settings.split(":")
			count = settings[0].to_i
			bind_ip = settings[1]
			session_key = settings[2]
			@imux_connections[session_key].change_worker_count(count,bind_ip)
			@client.puts "0"
		rescue StandardError => e
			@client.puts e.inspect
		end
	end
	
	def recieve_workers(settings)
		begin
			settings = settings.split(":")
			count = settings[0]
			session_key = settings[1]
			Thread.new{ @imux_connections[session_key].recieve_workers(count) }
			@client.puts "0"
		rescue StandardError => e
			@client.puts e.inspect
		end
	end
	
	def remove_workers(settings)
		begin
			settings = settings.split(":")
			change = settings[0].to_i
			bind_ip = settings[1]
			bind_ip = nil if bind_ip == "nil"
			session_key = settings[2]
			@imux_connections[session_key].change_worker_count(change, bind_ip)
			@client.puts "0"
		rescue StandardError => e
			@client.puts e.inspect
		end
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
			@imux_connections[session_key].chunk_size = size
			@client.puts "0"
		rescue
			@client.puts "1"
		end
	end
	
	def set_recycling(settings)
		settings = settings.split(":")
		session_key = settings[0]
		state = settings[1]
		begin
			if state == "true"
				@imux_connections[session_key].enable_reset
			elsif state == "false"
				@imux_connections[session_key].disable_reset
			end
			@client.puts "0"
		rescue
			@client.puts "1"
		end
	end
	
	def set_verification(settings)
		settings = settings.split(":")
		session_key = settings[0]
		state = settings[1]
		begin
			if state == "true"
				@imux_connections[session_key].enable_verification
			elsif state == "false"
				@imux_connections[session_key].disable_verification
			end
			@client.puts "0"
		rescue
			@client.puts "1"
		end
	end
	
	##
	## Transfer operations
	##

	def send_file(settings)
		begin
			settings = settings.split(":")
			session_key = settings[0]
			filename = settings[1]
			if File.readable?(filename)
				Thread.new{ @imux_connections[session_key].serve_file(filename) }
				@client.puts "0"
			else
				@client.puts "File cannot be read"
			end
		rescue StandardError => e
			@client.puts e.inspect
		end
	end
	
	def recieve_file(settings)
		begin
			settings = settings.split(":")
			session_key = settings[0]
			filename = settings[1]
			@imux_connections[session_key].download_file(filename)
			@client.puts "0"
		rescue StandardError => e
			@client.puts e.inspect
		end
	end

	##
	## Session operations
	##
	
	def close
		Thread.current.terminate
	end
end
