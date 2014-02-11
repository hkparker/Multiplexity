class TransferManager
	attr_reader :localhost

	def initialize
		local_server = Server.new("127.0.0.1", 8000)#, ?)
		Thread.new{ local_server.accept }
		@localhost = Host.new("127.0.0.1", 8000)#, ?)
		# Exception handling
		@queues = []
	end
	
	def process_queue(queue)
		loop {
			transfer = queue.get_next_transfer
			# ensure queue is not nil.  What kind of loop to use?
			
		}
		# while there are pending transfers, do them.  Thread one of these for each queue object.
	end
	
	def transfer_between(source, destination, filename)
		# ** check @queues for s:d/d:s, raise error about needing queue if not in there
		# ensure there is only one queue for two hosts
		file = source.stat_file(filename)
		if file[:readable]
			queue.add(transfer)
		else
			return false
		end
		# => true	(transfer started)
		# => nil	(transfer queued)
		# => false	(transfer cannot start)
	end
	
	def queue(client, server)
		queue = Queue.new()		# Queue object will hold a reference to client and server host objects to call WorkerManager actions.  It will FIFO process its array or transfer objects (or hashes).
		# do multiplexing here
		@queues << queue
		return queue
	end
	
	# method to close a queue?
	
end
