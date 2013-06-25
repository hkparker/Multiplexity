class IPPair
	def initialize(interface, address, gateway)
		@interface = interface
		@address = address
		@gateway = gateway
	end
	
	def address
		@address
	end
	
	def gateway
		@gateway
	end
	
	def interface
		@interface
	end
	
	def add_table(table)
		@table = table
	end
	
	def table
		@table
	end
end
