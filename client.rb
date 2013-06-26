#!/usr/bin/env ruby

require './multiplexity_client.rb'
require './ippair.rb'
require 'socket'

port = 8000

def env_check
	puts "Preforming environmental check".good
	puts "Checking for routing table file".good
	$route_file = "/etc/iproute2/rt_tables"
	if File.exists?($route_file) == false
		puts "Could not find #{$route_file} on your system".bad
		puts "Please enter another file to use".question
		file = $route_file
		until File.exists?(file)
			file = get_string
		end
		$route_file = file
	end
	puts "Checking for ip utility".good
	if `which ip` == ""
		puts "ip utility not found".bad
		puts "This application requires a unix-like operating system with the ip utility".bad
		exit 0
	end
	puts "Environmental check complete".good
end

def is_ip?(address)	# from IPAddr standard library
	if /\A(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\Z/ =~ address
		return $~.captures.all? {|i| i.to_i < 256}
	end
	return false
end

def get_ip
	address = ""
	until is_ip?(address)
		print ">"
		address = STDIN.gets.chomp
	end
	address
end

def get_bool
	choice = ""
	until choice == "y" or choice == "n"
		print ">"
		choice = STDIN.gets.chomp
	end
	choice
end

def is_digit?(string)
	begin
		Float(string)
	rescue
		false
	else
		true
	end
end

def get_int
	int = ""
	until is_digit?(int) == true
		print ">"
		int = STDIN.gets.chomp
	end
	int.to_i
end

def get_string
	string = ""
	until string != ""
		print ">"
		string = STDIN.gets.chomp
	end
	string
end

def execute(command)
	puts command.executing
	system command
end

def get_routes
	puts "How many network interfaces would you like to multiplex across?".question
	route_list = []
	table_count = get_int
	table_count.times do |i|
		puts "Interface #{i+1}".yellow.good
		puts "Please enter the name of the interface".question
		interface = get_string
		puts "Please enter the IP address of #{interface}".question
		address = get_ip
		puts "Please enter the default gateway for #{interface}".question
		gateway = get_ip
		route_list << Route.new(interface, address, gateway)
	end
	puts "To confirm:".good
	route_list.each do |pair|
		puts "#{pair.interface} has an IP address of #{pair.address} and uses #{pair.gateway} as its default gateway"
	end
	puts "Is this correct?".question
	correct = get_bool
	if correct == "y"
		return table_count, route_list
	elsif correct == "n"
		puts "Thats ok, lets try again".bad
		return nil, nil
	end
end

def setup_routes
	puts "Setting up source based routing".good
	puts "Please join all networks you plan to use now".good
	puts "Press enter once you have an IP address on each network".good
	STDIN.gets
	routes = nil
	until routes != nil
		table_count, routes = get_routes
	end
	puts "Now we need to create a routing rule for each interface".good
	puts "Backing up your old routing table configuration".good
	execute "sudo cp #{$route_file} #{$route_file}.backup"
	puts "Creating #{table_count} new routing tables".good
	table_count.times do |i|
		execute "sudo sh -c \"echo '#{128+i}\tmultiplex#{i}' >> #{$route_file}\""
	end
	puts "Routing tables created".good
	puts "Now adding routes for these tables".good
	i = 0
	routes.each do |route|
		table = "multiplex#{i}"
		route.add_table(table)
		execute "sudo ip route add default via #{route.gateway} dev #{route.interface} table #{route.table}"
		i += 1
	end
	puts "Routes added to routing tables".good
	puts "Now creating routing rules to force the use of these tables".good
	bind_ips = []
	routes.each do |route|
		execute "sudo ip rule add from #{route.address} table #{route.table}"
		bind_ips << route.address
	end
	puts "Flushing routing cache".good
	execute "sudo ip route flush cache"
	bind_ips
end

puts "Loading Multiplex client ".good
env_check
puts "Before we connect to a server we need to setup routing rules".good
puts "If you have already setup source based routing, you can skip this step".good
puts "Would you like to setup routing rules now? (y/n)".question
table_setup = get_bool
bind_ips = []
if table_setup == "y"
	bind_ips = setup_routes
elsif table_setup == "n"
	puts "How many IP addresses would you like to bind to?".question
	ip_count = get_int
	ip_count.times do |i|
		puts "Please enter an IP to bind to".question
		bind_ips << get_ip
	end
end
puts "Kernel ready to route multiplexed connections".good
puts "Please enter the IP address of the multiplex server".question
server = get_ip
puts "Opening control socket".good
begin
	socket = TCPSocket.open(server, port)
rescue
	puts "Failed to open control socket, please check your server information and try again".bad
	exit 0
end
puts "Creating new client object".good
client = MultiplexityClient.new(socket)
puts "Beginning handshake with server".good
client.handshake
puts "Opening multiplex sockets with server".good
sockets = client.setup_multiplex(bind_ips, server)
puts "Multiplex connections setup".good



#loop {
#	command = client.get_command
#	client.process_command command
#}
