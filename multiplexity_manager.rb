# class to interact directly with user interfaces

class MultiplexityManager
	def initialize
		@local_server = MultiplexityServer.new("127.0.0.1", 8000)
		@local_controller = MultiplexityController.new("127.0.0.1", 8000)
		# create a local server and connect a controller to it.
		@hosts = [@local_controller]
	end
	
	def add_host
		# maybe add the host to the host list and return a refernce for the UI
		# the class can be MultiplexityController and have its own getters
	end
	
	def get_serialized_hosts
		# maybe not serialized, instead return objects that the ui can get info from.  Host.get_files, etc
		# Or perhaps use an accessor: MultiplexityManager.hosts[0]
	end
	
	def transfer_between()
		
	end
	
	def get_files_from(host)
		
	end
	
end

# in the UI:
# manager = MultiplexityManager.new
# local_site = manager.local_site
# site1 = manager.add_host(remote_host)
# site1.get_files
# manager.transfer(filename, site1, local_site)
