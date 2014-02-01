class TransferManager
	attr_reader :localhost

	def initialize
		local_server = Server.new("127.0.0.1", 8000)#, ?)
		Thread.new{ local_server.accept }
		@localhost = Host.new("127.0.0.1", 8000)#, ?)
		# Exception handling
	end
	
	def transfer(filename, source, destination) # destination_filename=nil
		file = destination.stat_file(filename)
		if file[:readable]
			# if a transfer is blocking the channel, add to queue, else transfer
		else
			return false
		end
		# => true	(transfer started)
		# => nil	(transfer queued)
		# => false	(transfer cannot start)
	end
	
end
