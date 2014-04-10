require './file_write_buffer.rb'
require 'socket'
require 'zlib'
require 'openssl'
require './imux_manager.rb'

#
# The Host class wraps around multiplexity's control socket.  In scripts or user interfaces
# an instance of Host can be used to list the files on the remote host and preform other
# filesystem operations.  Hosts are also passed into TransferQueues to transfer files.
# When a TransferQueue sets up inverse multiplexing, it uses Host's methods for opening and
# recieving the imux sockets.
#


class Host
	attr_reader :control_socket_ip
	attr_reader :control_socket_port
	alias :peer_ip :control_socket_ip

	def initialize(server_ip, server_port)
		@control_socket_ip = server_ip
		@control_socket_port = server_port
	end
	
	def handshake
		begin
			@control_socket = TCPSocket.new(@control_socket_ip, @control_socket_port)
			@control_socket.puts "Hello Multiplexity"
			return ("Hello Client" == @control_socket.gets.chomp)
		rescue
			return false
		end
	end
	
	def close
		@control_socket.close
	end

	##
	## Filesystem operations:
	##
	
	#
	# Get the working directory of the remote host.
	#
	def get_remote_dir
		@control_socket.puts "pwd"
		return @control_socket.gets.chomp
	end

	#
	# Change the working directory on the remote host.  Returns true if successful.
	#
	def change_remote_directory(directory)
		@control_socket.puts "cd #{directory}"
		return @control_socket.gets.to_i == 0 ? true : false
	end

	#
	# Get a list of files on the remote host as an array of hashes
	#
	def get_remote_files(directory=".")
		files = []
		@control_socket.puts "ls #{directory}"
		file_list = @control_socket.gets
		file_list = file_list.chomp.split(";")
		file_list.each do |line|
			line = line.split("#")
			files << {:filename => line[0], :path => line[1], :size => line[2].to_i, :type => line[3], :last_write => line[4], :readable => line[5]}
		end
		return files
	end

	#
	# Create a new directory on the server.  Returns true if sucessful
	#
	def create_directory(dir)
		@control_socket.puts "mkdir #{dir}"
		return @control_socket.gets.to_i == 0 ? true : false
	end

	#
	# Remove a item from the remote host.  Returns true if sucessful
	#
	def delete_item(item)
		@control_socket.puts "rm #{item}"
		return @control_socket.gets.to_i == 0 ? true : false
	end

	##
	## IMUX settings:
	##	These methods are used to interact with the Session's IMUXManager(s)
	##	They are meant to be used by a transfer queue only.
	##

	#
	# Tell the Session to create a new imux session with someone else
	#
	def create_imux_session(settings)
		@control_socket.puts "createsession #{settings}"
		return @control_socket.gets.chomp
	end
	
	def recieve_imux_session(settings)
		@control_socket.puts "recievesession #{settings}"
		return @control_socket.gets.chomp
	end

	def create_more_workers(settings)
		@control_socket.puts "createworkers #{settings}"
		return @control_socket.gets.chomp
	end
	
	def recieve_more_workers(settings)
		@control_socket.puts "recieveworkers #{settings}"
		return @control_socket.gets.chomp
	end

	def remove_workers(settings)
		@control_socket.puts "removeworkers #{settings}"
		return @control_socket.gets.chomp
	end

	def close_session(settings)
		@control_socket.puts "closesession #{settings}"
		return @control_socket.gets.chomp
	end

	#
	# Change the chunk size the remote host is creating
	#
	def change_chunk_size(session_key, i)
		@control_socket.puts "updatechunk #{session_key}:#{i}"
		return @control_socket.gets.to_i == 0 ? true : false
	end
	
	#
	# Change if the Session recycles sockets when it downloads
	#
	def set_recycling(session_key, state)
		@control_socket.puts "setrecycle #{session_key}:#{state.to_s}"
		return @control_socket.gets.to_i == 0 ? true : false
	end
end

class Localhost < Host
	def initialize(port = 8000)
		@control_socket_ip = "127.0.0.1"
		@control_socket_port = port
		server = TCPServer.new("0.0.0.0", @control_socket_port)
		Thread.new{ Session.new(server.accept) }
		@control_socket = TCPSocket.new("127.0.0.1", @control_socket_port)
		@control_socket.puts "Hello Multiplexity"
		@control_socket.gets
	end
end
