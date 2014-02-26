require 'thread'
require 'securerandom'

#
# This class is used by the user interface to create an inverse multiplexed
# connection between two hosts, as well as queue transfers through that connection.
# Two host objects need to be created, and the details of their session stored in an
# IMUXConfig object. When these three objects are passed to a new TransferQueue the
# connection is created and the queue is ready to use.
#

class TransferQueue
	attr_accessor :pending		# Access and modify the contents of the queue as an array
	attr_reader :processing		# Check if the queue is paused
	attr_reader :message_queue	# Access messages and errors

	def initialize(client, server,imux_config)
		@pending = []																		# Create a new array of pending transfers
		@processing = false																	# By default transfers won't start unless the queue is told to begin processing
		@server = server																	# Create instance variables for server and client
		@client = client
		@process_thread = Thread.new{}														# Create a new thread to empty the queue
		@message_queue = Queue.new															# UIs will access to queue to recieve messages and errors
		@message_queue << "Created queue between #{@client.peer_ip} and #{@server.peer_ip}"
		@port = imux_config.port															# Used to identify the imux session to the multiplexity session object
		create_imux_session(imux_config)													# Use the configuration information in imux_config to set up inverse multiplexing
		@session_key = SecureRandom.hex.to_s
	end

	#
	# This method is used by the user interface to add a tranfer to a queue.
	# The method ensures both of the hosts are either the server or client.
	# It then adds the tranfer to the @pending array and if the last thread
	# used to empty the queue has finished, and we aren't paused, it starts a new one.
	#
	def add_transfer(source, destination, filename, destination_name=filename)
		if not [@server,@client].include? source															# If the source host is not our server or client
			raise "source host does not belong to tranfer queue"											# raise an exception to indicate we don't know the source
		end
		if not [@server,@client].include? destination														# Do the same thing for the client
			raise "destination host does not belong to tranfer queue"										# This ensures the hosts have a good imux connection, because we set it up
		end
		@pending << {:filename => filename, :source => source, :destination => destination}					# Add the transfer information to the queue
		@process_thread = Thread.new{ process_queue } if @process_thread.status == false && @processing		# start a thread to process whats in the queue if there isn't already one and there is supposed to be one
	end

	#
	# This method is used to the user interface to pause a current transfer or prevent the queue from starting
	#
	def pause
		if @process_thread.status != false
			# tell the running thread to pause its transfer
		end
		@processing = false
	end

	#
	# This method is used by the user interface to resume transfers or start a queue
	#
	def process
		if @process_thread.status == false
			@process_thread = Thread.new{ process_queue } if @pending.size > 0
		else
			# tell the running thread to resume its tranfer.
		end
		@processing = true
	end

	##
	##	IMUX settings:
	##

	#
	# Change the chunk size both the server and client are using to create chunks.
	#
	def change_chunk_size(i)
		size_changed = @client.change_chunk_size(@port, i)
		@message_queue << "Could not change #{@client.peer_ip}'s chunk size to #{}" if !size_changed
		size_changed = @server.change_chunk_size(@port, i)
		@message_queue << "Could not change #{@server.peer_ip}'s chunk size to #{}" if !size_changed
	end
	
	#
	# Set socket recycling for both hosts for this session
	#
	def set_recycling
		recycling_changed = @client.set_recycling(@session_key, state)
		@message_queue << "Could not set recycling to #{state.to_s} on #{@client.peer_ip}" if !recycling_changed
		recycling_changed = @server.set_recycling(@session_key, state)
		@message_queue << "Could not set recycling to #{state.to_s} on #{@server.peer_ip}" if !recycling_changed
	end
	
	#
	# Set socket recycling for both hosts while they download
	#
	def set_recycling(recycle)
		recycling_changed = @client.set_recycling(@port, recycle)
		@message_queue << "Could not change #{@client.peer_ip}'s recycle state to #{recycle.to_s}" if !recycling_changed
		recycling_changed = @server.set_recycling(@port, i)
		@message_queue << "Could not change #{@server.peer_ip}'s recycle state to #{recycle.to_s}" if !recycling_changed
	end
	
	#
	# This method changes the number of workers in an imux session.  Change can be 
	# :add or :remove, count is the number of workers, and bind_ip optionally only removes
	# workers bound to that IP.  If no bind IP is specified it will remove evenly across all bind
	# ips, if there are any.
	#
	def change_worker_count(change, count, bind_ip)
	
	end

	private

	#
	# This method creates an inverse multiplexed session between two hosts
	#
	def create_imux_session(imux_config)
		can_recieve = @server.create_imux_session(imux_config.server_config)			# Send a command telling the server to listen for imux sockets
		raise "server cannot recieve an imux session" if not can_recieve				# Raise an exception the server can't for any reason
		successfully_created = @client.create_imux_session(imux_config.client_config)	# Send a command telling the client to open the imux sockets
		raise "client could not connect to imux server" if not successfully_created		# How will I send back the number of correctly opened sockets?  Just report errors?
	end

	#
	# This method will run in it's own thread and preform every transfer in @pending.
	# It assumes @pending could be changed by the user between interations.
	#
	def process_queue
		until @pending.size == 0											# The array will likely change as the thread runs, better to check its size each time then iterate
			begin															# Execeptions will be fed into an error queue for the user interface
				transfer = @pending.shift									# Grab the next transfer
				file = transfer[:source].stat_file(transfer[:filename])		# Get detailed information about the source file
				raise "file unreadable on source" if not file[:readable]	# Raise an exception if we cannot read the source file
				ready = transfer[:destination].recieve_file()				#what to pass?
				raise "destination cannot recieve file" if not ready		# Raise an exception if the destination could not prepare to recieve a file for any reason
				transfer[:source].send_file()								#what to pass?
			rescue exception
				@message_queue << "Error transferring #{transfer[:filename]} from #{transfer[:source].peer_ip} to #{transfer[:destination].peer_ip}: #{exception.to_s}"
			end
		end
	end
end
