class Queue
	attr_reader :pending

	def initialize(client, server)
		@state = "new"
		@pending = []
	end
	
	def create_imux_session
		server.recieve_imux_session
		client.create_imux_session
	end
	
	def get_next_transfer
		@pending_transfer.shift(1)
	end
end
