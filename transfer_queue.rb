require 'thread'

class TransferQueue
	attr_reader :pending
	attr_reader :processing

	def initialize(client, server,imux_config)
		@pending = []						# Create a new array of pending transfers
		@processing = false					# By default transfers won't start unless the queue is told to begin processing
		@server = server					# Create instance variables for server and client
		@client = client
		create_imux_session(imux_config)	# Use the configuration information in imux_config to set up inverse multiplexing
	end
	
	def create_imux_session(imux_config)
		can_recieve = @server.recieve_imux_session(imux_config.server_config)			# Send a command telling the server to listen for imux sockets
		raise "server cannot recieve an imux session" if not can_recieve				# Raise an exception the server can't for any reason
		sockets_created = @client.create_imux_session(imux_config.client_config)		# Send a command telling the client to open the imux sockets
		raise "client could not connect to imux server" if not successfully_created	# How will I send back the number of correctly opened sockets?  Just report errors?
	end
	
	def add_transfer(source, destination, filename)
		if not [@server,@client].include? source													# If the source host is not our server or client
			raise "source host does not belong to tranfer queue"									# raise an exception to indicate we don't know the source
		end
		if not [@server,@client].include? destination												# Do the same thing for the client
			raise "destination host does not belong to tranfer queue"								# This ensures the hosts have a good imux connection, because we set it up
		end
		@pending << {:filename => filename, :source => source, :destination => destination}			# Add the transfer information to the queue
		@process_thread = Thread.new{ process_queue } if not @process_thread.status and @processing	# start a thread to process whats in the queue if there isn't already one and there is supposed to be one
	end
	
	def pause
		@processing = false
		# pause the current transfer if there is one
	end
	
	def process
		@processing = true
		# resumme the current transfer if there is one
		# start the queu processor
		
	end
	
	private
	
	def process_queue																													# This method runs in a thread and empties the transfer queue
		until @pending.size == 0																										# The array will likely change as the thread runs, better to check its size each time then iterate
			begin																														# Execeptions will be fed into an error queue for the user interface
				next_transfer = @pending.shift																							# Grab the next transfer
				file = next_transfer[:source].stat_file(next_transfer[:filename])														# Get detailed information about the source file
				raise "file #{next_transfer[:filename]} on host #{next_transfer[:source].peer_ip} unreadable" if not file[:readable]	# Raise an exception if we cannot read the source file
				ready = next_transfer[:destination].recieve_file()#what to pass?
				raise "destination #{next_transfer[:destination].peer_ip} cannot recieve file" if not ready								# Raise an exception if the destination could not prepare to recieve a file for any reason
				next_transfer[:source].send_file()#what to pass?
			rescue exception
				# use a queue to send a list of failed transfers back up
			end
		end
end
