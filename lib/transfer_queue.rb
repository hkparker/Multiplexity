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
	attr_accessor :pending
	attr_accessor :message_queue
	attr_reader :opened

	def initialize(client, server, imux_config)
		@pending = []
		@server = server
		@client = client
		@process_thread = Thread.new{}
		@message_queue = Queue.new
		@session_key = SecureRandom.hex.to_s
		@message_queue << "Attempting to build queue between #{@client.peer_ip} and #{@server.peer_ip}"
		@opened = create_imux_session(imux_config)
		@message_queue << "Created queue between #{@client.peer_ip} and #{@server.peer_ip}" if @opened
		@message_queue << "Failed to create queue between #{@client.peer_ip} and #{@server.peer_ip}" if !@opened
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
		@pending << {:filename => filename, :source => source, :destination => destination, :destination_name => destination_name}
		@message_queue << "Adding tranfer: #{filename} (#{source.peer_ip}) -> #{destination_name} (#{destination.peer_ip})"
		@process_thread = Thread.new{ process_queue } if @process_thread.status == false	# start a thread to process whats in the queue if there isn't already one
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
	
	def close
		# close the imux managers of each
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
		@message_queue << "#{@server.peer_ip} ready to accept imux session"
		error = @client.create_imux_session(imux_config.client_config+":"+@server.peer_ip+":"+@session_key)
		if error != "0"
			@message_queue << "#{@client.peer_ip} could not create imux session: #{error}"
			return false
		end
		@message_queue << "#{@client.peer_ip} successfully created imux session"
		return true
	end

	#
	# This method will run in it's own thread and preform every transfer in @pending.
	# It assumes @pending could be changed by the user between iterations.
	#
	def process_queue
		until @pending.size == 0
			begin
				transfer = @pending.shift
				@message_queue << "Processing transfer: #{transfer[:filename]} (#{transfer[:source].peer_ip}) -> #{transfer[:destination_name]} (#{transfer[:destination].peer_ip})"
				serving_error = transfer[:source].send_file(transfer[:filename], @session_key)
				raise serving_error if serving_error != "0"
				downloading_error = transfer[:destination].recieve_file(transfer[:destination_name], @session_key)
				raise downloading_error if downloading_error != "0"
				@message_queue << "Transfer complete: #{transfer[:filename]} (#{transfer[:source].peer_ip}) -> #{transfer[:destination_name]} (#{transfer[:destination].peer_ip})"
			rescue StandardError => e
				@message_queue << "Error transferring #{transfer[:filename]} from #{transfer[:source].peer_ip} to #{transfer[:destination].peer_ip}: #{e.inspect}"
			end
			sleep 5
		end
	end
end
