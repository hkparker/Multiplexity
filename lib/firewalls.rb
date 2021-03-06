require './colors.rb'

class Firewall
	def get_bind_ips
		bind_ips = []
		@route_list.each do |route|
			bind_ips << route[:ip_address]
		end
		bind_ips
	end
end

class IPFirewall < Firewall
	def initialize(routes)
		@route_file = "/etc/iproute2/rt_tables"
		@route_list = routes
	end

	def apply
		system "sudo cp #{@route_file} #{@route_file}.backup"
		@route_list.each_with_index do |route, i|
			table_name = "multiplex#{i}"
			system "sudo sh -c \"echo '#{128+i}\t#{table_name}' >> #{@route_file}\""
			system "sudo ip route add default via #{route[:default_gateway]} dev #{route[:interface]} table #{table_name}"
			system "sudo ip rule add from #{route[:ip_address]} table #{table_name}"
		end
		system "sudo ip route flush cache"
	end
	
	def restore_system
		system "sudo mv #{@route_file}.backup #{@route_file}"
		system "sudo ip route flush cache"
	end
end
