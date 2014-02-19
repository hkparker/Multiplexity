class TransferQueue
	attr_reader :pending
	

	def initialize(client, server)
		#@state = "new"
		@transfering = false
		@pending = []	# {:filename => "", :source => Host, :destination => Host }
	end
	
	def create_imux_session
		server.recieve_imux_session
		client.create_imux_session
	end
	
	def get_next_transfer
		@pending.shift
	end
	
	def add_transfer(source, destination, filename)
		# add it to pending.
		# start a new thread to process pending if there isn't already one
		@transfering = true
	end
	
	def process_queue						# 
		@transferring = true
		until @pending.size == 0 
			transfer = get_next_transfer	
		
		
			
		end
		@transfering = false
	end
end
