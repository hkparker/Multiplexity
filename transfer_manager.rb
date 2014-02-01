class TransferManager
	attr_reader :localhost

	def initialize
		local_server = Server.new("127.0.0.1", 8000)#, ?)
		Thread.new{ local_server.accept }
		@localhost = Host.new("127.0.0.1", 8000)#, ?)
		# Exception handling
		@queues = []
	end
	
	def add_to_queue(Transfer, position) # The UI will now have to create Transfer objects and send them to the TransferManager.  position is top(1) or bottom(0)
		# ** check @queues for s:d/d:s, raise error about needing queue if not in there
		# define queue
		file = destination.stat_file(filename)
		if file[:readable]
			queue.add(transfer)#, position?) or make position (or priority) part of the transfer object)
		else
			return false
		end
		# => true	(transfer started)
		# => nil	(transfer queued)
		# => false	(transfer cannot start)
	end
	
	def create_queue(client, server)
		# do multiplexing here
		queue = Queue.new()		# Queue object will hold a reference to client and server host objects to call WorkerManager actions.  It will FIFO process its array or transfer objects (or hashes).
		@queues << queue
		return queue
	end
	
	# method to close a queue?
	
end
