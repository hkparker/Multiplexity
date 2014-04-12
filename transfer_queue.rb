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
	attr_accessor :pending			# Access and modify the contents of the queue as an array
	attr_reader :processing			# Check if the queue is paused
	attr_accessor :message_queue	# Access messages and errors

	def initialize(client, server, imux_config)
		@pending = []																		# Create a new array of pending transfers
		@processing = true																	# By default transfers won't start unless the queue is told to begin processing
		@server = server																	# Create instance variables for server and client
		@client = client
		@process_thread = Thread.new{}														# Create a new thread to empty the queue
		@message_queue = Queue.new															# UIs will access to queue to recieve messages and errors
		@session_key = SecureRandom.hex.to_s
		opened = create_imux_session(imux_config)											# Use the configuration information in imux_config to set up inverse multiplexing
		@message_queue << "Created queue between #{@client.peer_ip} and #{@server.peer_ip}" if opened
		@message_queue << "Failed to create queue between #{@client.peer_ip} and #{@server.peer_ip}" if !opened
	end

	#
	# This method is used by the user interface to add a tranfer to a queue.
	# The method ensures both of the hosts are either the server or client.
	# It then adds the tranfer to the @pending array and if the last thread
	# used to empty the queue has finished, and we aren't paused, it starts a new one.
	#
	def add_transfer(source, destination, filename, destination_name=filename)
		if not [@server,@client].include? source
			@message_queue << "Source is not part of this transfer queue, aborting transfer"
			return false
		end
		if not [@server,@client].include? destination
			@message_queue << "Destination is not part of this transfer queue, aborting transfer"
			return false
		end
		@pending << {:filename => filename, :source => source, :destination => destination, :destination_name => destination_name}			# Add the transfer information to the queue
		@process_thread = Thread.new{ process_queue } if @process_thread.status == false && @processing		# start a thread to process whats in the queue if there isn't already one and there is supposed to be one
	end

	#
	# This method is used to the user interface to pause a current transfer or prevent the queue from starting
	#
	def pause
		if @process_thread.status != false
			# tell both server and client to pause their imux managers
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
			# tell both server and client to resume their imux managers
		end
		@processing = true
	end

	##
	##	IMUX settings:
	##

	#
	# Change the chunk size both the server and client are using to create chunks.
	#
	def set_chunk_size(i)
		client_change = Thread.new{
			size_changed = @client.change_chunk_size(@session_key, i)
			@message_queue << "Could not change #{@client.peer_ip}'s chunk size to #{i}" if !size_changed
			@message_queue << "Updated #{@client.peer_ip}'s chunk size to #{i}" if size_changed
		}
		server_change = Thread.new{
			size_changed = @server.change_chunk_size(@session_key, i)
			@message_queue << "Could not change #{@server.peer_ip}'s chunk size to #{i}" if !size_changed
			@message_queue << "Updated #{@server.peer_ip}'s chunk size to #{i}" if size_changed
		}
		client_change.join
		server_change.join
	end
	
	#
	# Set socket recycling for both hosts for this session
	#
	def set_recycling(state)
		client_change = Thread.new{
			recycling_changed = @client.set_recycling(@session_key, state)
			@message_queue << "Could not set recycling to #{state.to_s} on #{@client.peer_ip}" if !recycling_changed
			@message_queue << "Set recycling to #{state.to_s} on #{@client.peer_ip}" if recycling_changed
		}
		server_change = Thread.new{
			recycling_changed = @server.set_recycling(@session_key, state)
			@message_queue << "Could not set recycling to #{state.to_s} on #{@server.peer_ip}" if !recycling_changed
			@message_queue << "Set recycling to #{state.to_s} on #{@server.peer_ip}" if recycling_changed
		}
		client_change.join
		server_change.join
	end
	
	def set_verification(state)
		client_change = Thread.new{
			verification_changed = @client.set_verification(@session_key, state)
			@message_queue << "Could not set verification to #{state.to_s} on #{@client.peer_ip}" if !verification_changed
			@message_queue << "Set verification to #{state.to_s} on #{@client.peer_ip}" if verification_changed
		}
		server_change = Thread.new{
			verification_changed = @server.set_verification(@session_key, state)
			@message_queue << "Could not set verification to #{state.to_s} on #{@server.peer_ip}" if !verification_changed
			@message_queue << "Set verification to #{state.to_s} on #{@server.peer_ip}" if verification_changed
		}
		client_change.join
		server_change.join
	end
	
	#
	# This method changes the number of workers in an imux session.  Change can be 
	# :add or :remove, count is the number of workers, and bind_ip optionally only removes
	# workers bound to that IP.  If no bind IP is specified it will remove evenly across all bind
	# ips, if there are any.
	#
	def change_worker_count(change, count, bind_ip)
		bind_ip = "nil" if bind_ip == nil
		if change == :add
			@server.recieve_more_workers("#{count}:#{@session_key}")
			error = @client.create_more_workers("#{count}:#{bind_ip}:#{@session_key}")
			@message_queue << "Worker count between #{@client.peer_ip} and #{@server.peer_ip} increased by #{count}" if error == "0"
			@message_queue << "Failed to add workers between #{@client.peer_ip} and #{@server.peer_ip}: #{error}" if error != "0"
		elsif change == :remove
			error = @client.remove_workers("#{0-count}:#{bind_ip}:#{@session_key}")
			
			@message_queue << "Worker count between #{@client.peer_ip} and #{@server.peer_ip} decreased by #{count.abs}" if error == "0"
			@message_queue << "Failed to remove #{count.abs} workers between #{@client.peer_ip} and #{@server.peer_ip}" if error != "0"
		end
	end

	private

	#
	# This method creates an inverse multiplexed session between two hosts
	#
	def create_imux_session(imux_config)
		error = @server.recieve_imux_session(imux_config.server_config+":"+@session_key)
		if error != "0"
			@message_queue << "#{@server.peer_ip} could not recieve imux session: #{error}"
			return false
		end
		error = @client.create_imux_session(imux_config.client_config+":"+@server.peer_ip+":"+@session_key)
		if error != "0"
			@message_queue << "#{@client.peer_ip} could not create imux session: #{error}"
			return false
		end
		return true
	end

	#
	# This method will run in it's own thread and preform every transfer in @pending.
	# It assumes @pending could be changed by the user between interations.
	#
	def process_queue
		until @pending.size == 0											# The array will likely change as the thread runs, better to check its size each time then iterate
			begin															# Execeptions will be fed into an error queue for the user interface
				transfer = @pending.shift									# Grab the next transfer
				ready = transfer[:destination].recieve_file(transfer[:destination_name], @session_key)
				@message_queue << ready
				if ready != "0"
					@message_queue << "Destination unable to recieve file: #{ready}"
					raise "Destination unable to recieve file"
				end
				sent = transfer[:source].send_file(transfer[:filename], @session_key)
				@message_queue << sent
			rescue exception
				@message_queue << "Error transferring #{transfer[:filename]} from #{transfer[:source].peer_ip} to #{transfer[:destination].peer_ip}: #{exception.to_s}"
			end
		end
	end
end
