class Queue
	attr_reader :pending
	

	def initialize(client, server)
		@state = "new"
		@pending = []	# {:filename => "", :source => "", :destination => "" }
	end
	
	def create_imux_session
		server.recieve_imux_session
		client.create_imux_session
	end
	
	def get_next_transfer
		@pending.shift
	end
end
