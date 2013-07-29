require '.\colors.rb'

class Firewalls
	def initailize(routes)
		@route_list = routes
	end
	
	def execute(command)
		verbose_out command.executing
		system command
	end
	
	def get_bind_ips
		bind_ips = []
		@route_list.each do |route|
			bind_ips << route[:ip_address]
		end
		bind_ips
	end
end

class IP < Firewalls
	@route_file = "/etc/iproute2/rt_tables"
	def apply
		execute "sudo cp #{@route_file} #{@route_file}.backup"
		@route_list.each_with_index do |route, i|
			table_name = "multiplex#{i}"
			execute "sudo sh -c \"echo '#{128+i}\t#{table_name}' >> #{@route_file}\""
			execute "sudo ip route add default via #{route[:default_gateway]} dev #{route[:interface]} table #{table_name}"
			execute "sudo ip rule add from #{route[:ip_address]} table #{table_name}"
		end
		execute "sudo ip route flush cache"
	end
	
	def restore_system
		execute "sudo cp #{@route_file}.backup #{@route_file}"
		execute "sudo ip route flush cache"
	end
end
