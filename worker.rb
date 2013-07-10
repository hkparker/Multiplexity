class Worker
	def initialize(socket)
			@socket = socket
			@ready = false
	end
	
	def start
		
		# get NEXT reequest
		# set ready
		# get next chunk object
		# if instead you got a 0 close the socket
		# otherwise send the id
		# then send the chunk
		# then wait for a next request
	end
	
	def ready
		@ready
	end
	
end
