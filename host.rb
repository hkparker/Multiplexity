require './buffer.rb'
require 'socket'
require 'zlib'
require './securesocket.rb'
require './smp.rb'
require 'openssl'
require './workermanager.rb'

#
# The Host class wraps around multiplexity's control socket.  In scripts or user interfaces
# an instance of Host can be used to list the files on the remote host and preform other
# filesystem operations.  Hosts are also passed into TransferQueues to transfer files.
# When a TransferQueue sets up inverse multiplexing, it uses Host's methods for opening and
# recieving the imux sockets.
#

class Host
	def initialize(server_ip, server_port, authentication=nil, server_secret=nil)
		@server_ip = server_ip
		@server_port = server_port
		handshake(authentication, server_secret)
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

	##
	## Filesystem operations:
	##
	
	#
	# Get the working directory of the remote host
	#
	def get_remote_dir
		@server.puts "pwd"
		return @server.gets.chomp
	end

	#
	# Change the working directory on the remote host
	#
	def change_remote_directory(directory)
		@server.puts "cd #{directory}"
		return @server.gets.to_i
	end

	#
	# Get a list of files in a directory on the remote host
	#
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

	#
	# Remove a file from the remote host
	#
	def delete_remote_item(item)
		@server.puts "rm #{item}"
		return @server.gets.to_i
	end

	##
	## IMUX settings:
	##	These methods are used to interact with the Session's IMUXManager(s)
	##	They are meant to be used by a transfer queue, and require the session keys
	##	transfer queues create with each imux session.
	##

	#
	# Tell the Session to create a new imux session with someone else
	#
	def create_imux_session(session_key, session)
		# load informatin fron session hash
		@server.puts "createsession #{}"
		return @server.gets.to_i
	end

	#
	# Change the chunk size the remote host is creating
	#
	def change_chunk_size(session_key, i)
		@server.puts "updatechunk #{session_key}:#{i}"
		return @server.gets.to_i == 0 ? true : false
	end
	
	#
	# Change if the Session recycles sockets when it downloads
	#
	def set_recycling(session_key, state)
		@server.puts "setrecycle #{session_key}:#{state.to_s}"
		return @server.gets.to_i == 0 ? true : false
	end
end

class Localhost << Host
	def initialize
		# create new multiplexity server on localhost, handshake with it, close it
	end
end
