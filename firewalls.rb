class Firewalls
	def initailize(config) # going to get an array of config hashes
		@interface = config[:interface]
		@ip_address = config[:ip_address]
		@default_gateway = config[:default_gateway]
	end
end

class IP < Firewalls
	def setup_routes
		
	end

	def backup_config
		
	end
	
	def add_table
		"sudo sh -c \"echo '#{table_name}' >> #{route_file}\""
	end
	
	def add_rule
		"sudo ip route add default via #{default_gateway} dev #{interface} table #{table}"
	end
	
	def flush_cache
		
	end
end
