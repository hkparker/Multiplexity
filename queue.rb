require 'thread'

class TransferQueue
	attr_reader :pending
	attr_accessor :processing

	def initialize(client, server,imux_config)
		@pending = []						# Create a new array of pending transfers
		@processing = false					# By default transfers won't start unless the queue is told to begin processing
		@server = server					# Create instance variables for server and client
		@client = client
		create_imux_session(imux_config)	# Use the configuration information in imux_config to set up inverse multiplexing
	end
	
	def create_imux_session(imux_config)
		@server.recieve_imux_session
		@client.create_imux_session
	end
	
	def add_transfer(source, destination, filename)
		# check to make sure the source and destination are both hosts we own
		@pending << {:filename => filename, :source => source, :destination => destination}		# Add the transfer information to the queue
		
		
		# start process_queue thread (until @pending.size == 0, pending.shift) if there isn't one running and were in processing mode
	end
	
	def pause
	
	end
	
	def resume
	
	end
	
	def process_queue
		#while @processing
			#next_transfer = queue.shift
			## file = next_transfer[:source].stat_file(next_transfer[:filename])
			## check file, make sure its there and we can read it
			## tell next_transfer[:destination] to recieve
			## tell next_transfer[:source] to send next_transfer[:filename]
		#end
	#end
	
	
	
	
	
end
