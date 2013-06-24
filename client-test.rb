#!/usr/bin/env ruby

require './multiplexity_client.rb'
require './ippair.rb'
require 'socket'

port = 8000

def env_check
	puts "Preforming environmental check".good
	$route_file = "/etc/iproute2/rt_tables"
	if File.exists?($route_file) == false
		puts "Could not find #{$route_file} on your system".bad
		puts "Please enter another file to use"
	end
	# other environmental checks
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

def get_routes
	puts "How many network interfaces would you like to multiplex across?".question
	route_list = []
	get_int.times do |i|
		puts "Interface #{i+1}".yellow.good
		puts "Please enter the IP address of the interface".good
		address = get_ip
		puts "Please enter the corresponding default gateway for that interface".good
		gateway = get_ip
		route_list << IPPair.new(address, gateway)
	end
	puts "To confirm:".good
	route_list.each do |pair|
		puts "IP Address #{pair.address} uses gateway #{pair.gateway}"
	end
	puts "Is this correct?".question
	correct = get_bool
	if correct == "y"
		return route_list
	elsif correct == "n"
		puts "Thats ok, lets try again".bad
		return nil
	end
end

def setup_routes
	puts "Setting up source based routing".good
	puts "Please join all networks you plan to use now".good
	puts "Press enter once you have an IP address on each network".good
	STDIN.gets
	routes = nil
	until routes != nil
		routes = get_routes
	end
	puts "Now we need to create a routing rule for each interface".good
	puts "Backing up your old routing table configuration".good
	command = "sudo cp #{$route_file} #{$route_file}.backup"
	puts command.executing
	system command
	exit 0
end

puts "Loading Multiplex client ".good

env_check

puts "Before we connect to a server we need to setup routing rules".good
puts "If you have already setup source based routing, you can skip this step".good
puts "Would you like to setup routing rules now?".question
setup_routes if get_bool == "y"

puts "Please enter the IP address of the multiplex server".question
server = get_ip

puts "Opening control socket".good
begin
	socket = TCPSocket.open(server, port)
rescue
	puts "Failed to open control socket, please check your server information and try again".bad
	exit 0
end

client = MultiplexityClient.new(socket)

client.handshake
client.setup_multiplex

loop {
	command = client.get_command
	client.process_command command
}
