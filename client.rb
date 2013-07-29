#!/usr/bin/env ruby

require './multiplexity_client.rb'
require './route.rb'
require 'socket'
require './firewalls.rb'

port = 8000
$route_file = "/etc/iproute2/rt_tables"

def write_verbose(string)
	puts string if $verbose == true
end

def parse_args
	ARGV.each do |arg|
		$verbose = true if arg == "-v"
	end
end

def env_check
	write_verbose "Preforming environmental check".good
	write_verbose "Checking Ruby version".good
	if RUBY_VERSION.to_f < 1.9
		puts "You appear to be using Ruby #{RUBY_VERSION}".bad
		puts "Multiplexity requires Ruby >= 1.9.1".bad
		exit 0
	end
	write_verbose "Ruby #{RUBY_VERSION} detected".good
	write_verbose "Environmental check complete".good
end

def route_auto_config
	write_verbose "Attempting to auto configure routing information".good
	ip_config = {:detect_command => "ip", :class => Firewalls::IP}
	#ipfw_config = nil
	#pfctl_config = nil
	firewalls = [ip_config]
	firewalls.each do |firewall|
		write_verbose "Checking for #{firewall[:detect_command]} on this system".good
		if `which #{firewall[:detect_command]}` != ""
			write_verbose "Detected #{firewall[:detect_command]} on this system".good
			return firewall[:class].new
		end
	end
end

def is_ip?(address)
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
		choice = STDIN.gets.chomp.downcase
	end
	if choice == "y"
		true
	elsif choice == "n"
		false
	end
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

def get_env_config
	puts "How many network interfaces would you like to multiplex across?".question
	route_list = []
	table_count = get_int
	correct = false
	until correct == true
		table_count.times do |i|
			puts "Interface #{i+1}".yellow.good
			puts "Please enter the name of the interface".question
			interface = get_string
			puts "Please enter the IP address of #{interface}".question
			ip_address = get_ip
			puts "Please enter the default gateway for #{interface}".question
			default_gateway = get_ip
			route_list << {:interface => interface, :ip_address => ip_address, :default_gateway => default_gateway}
		end
		puts "To confirm:".good
		route_list.each do |route|
			puts "#{route[:interface]} has an IP address of #{route[:ip_address]} and uses #{route[:default_gateway]} as its default gateway"
		end
		puts "Is this correct?"
		correct = true if get_bool
	end
	route_list
end

def get_bind_ips
	bind_ips = []
	puts "How many IP addresses would you like to bind to?".question
	ip_count = get_int
	ip_count.times do |i|
		puts "Please enter an IP to bind to".question
		bind_ips << get_ip
	end
	bind_ips
end

puts "Multiplexity".good
parse_args
env_check
puts "Would you like to setup routing rules now? (y/n)".question
if get_bool
	config = route_auto_config
	if config == nil
		puts "Unable to auto configure routing information".bad
		puts "You can still use Multiplexity, but you must do all source based routing.".bad
		puts "This means your operating system must already know to route packets to the correct interface/gateway.".bad
		puts "Continue anyway? (y/n)".question
		if get_bool == false
			puts "Closing Multiplexity".good
			exit 0
		end
		bind_ips = get_bind_ips
	else
		routes = get_env_config
		firewall = config[:class].new(routes)
		firewall.apply
		bind_ips = firewall.get_bind_ips
	end
else
	bind_ips = get_bind_ips
end
# Above here checked, below here unchecked.
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
puts "Now entering file selection dialog".good
puts "Avaliable commands are:".good
puts "\tls - list files"
puts "\tpwd - print working directory"
puts "\tcd <dir> - change directory"
puts "\tsize <file> - check the size of a file"
puts "\tclean - clear the terminal"
puts "\texit - exits multiplexity"
file = client.choose_file
puts "File #{file} has been successfully choosen.".good
client.process_command("size #{file}")
puts "Waiting for server to be ready to serve file".good
socket.gets
puts "Server is ready.  Downloading file".good
client.download file
puts "The file has been downloaded".good
puts "Would you like to check the file integrity?".question
if get_bool
	success = client.verify_file file
	if success == true
		puts "CRC match, the file was download successfully".good
	else
		puts "CRC mismatch, the file was corrupt during download".bad
	end
else
	socket.puts "NO VERIFY"
end
# if defined? firewall != nil, ask to call firewall.restore_system
#puts "Would you like to keep the multiplexity routing tables?".question
#if get_bool == false
#	execute "sudo mv /etc/iproute2/rt_tables.backup /etc/iproute2/rt_tables"
#	execute "sudo ip route flush cache"
#end
puts "Closing multiplexity".good
#client.shutdown
