#!/usr/bin/env ruby

require './multiplexity_client.rb'
require './firewalls.rb'
require 'socket'

port = 8000

def write_verbose(string)
	puts string if $verbose == true
end

def parse_args
	settings = {:skip_route_setup => false,
				:bind_ips => nil,
				:server_ip => nil,
				:chunk_size => 1024*1024,
				:username => nil,
				:password => nil,
				:recycle => nil
				}	# choose mode as well
	ARGV.each_with_index do |arg, i|
		case arg
			when "-n"
				settings[:skip_route_setup] = true
			when "-b"
				if ARGV[i+1] != nil
					ip_list = ARGV[i+1].split(",")
					input_ips = ip_list
					ip_size = input_ips.size
					if ip_size <= 1
						puts "Provided IP addresses for binding are not valid or too few".bad
						puts "Bind IPs will be obtained interactivly".good
					else
						bind_ips = []
						input_ips.each do |ip|
							bind_ips << ip if is_ip?(ip)
						end
						if bind_ips.size == ip_size
							settings[:bind_ips] = bind_ips
						else
							puts "Some of the entered bind IP addresses were not valid".bad
							puts "Bind IP addresses will be obtained interactivly"
						end
					end
				else
					puts "No bind IPs provided, will be obtained interactivly".bad
				end
			when "-s"
				server_ip = ARGV[i+1]
				if is_ip?(server_ip) == true
					settings[:server_ip] = server_ip
				else
					puts "Provided server IP address is not valid, will be obtained interactivly".bad
				end
			when "-c"
				begin
					settings[:chunk_size] = ARGV[i+1].to_i
				rescue
					puts "The provided chunk size was not an integer".bad
					puts "Using the default value of #{format_bytes(settings[:chunk_size])}"
				end
			when "-v"
				$verbose = true
			when "-u"
				#settings[:username] = ARGV[i+1]
			when "-p"
				#settings[:password] = ARGV[i+1]
			when "-r"
				settings[:recycle] = ARGV[i+1].to_i	# recycle can either be every chunk (0), never (nil) or every x bytes
			when "-h"
				print_help
				exit(0)
		end
	end
	settings
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
	ip_config = {:detect_command => "ip", :class => IPFirewall}
	firewalls = [ip_config]
	firewalls.each do |firewall|
		write_verbose "Checking for #{firewall[:detect_command]} on this system".good
		if `which #{firewall[:detect_command]}` != ""
			write_verbose "Detected #{firewall[:detect_command]} on this system".good
			return firewall[:class]
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
		puts "Is this correct? (y/n)"
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

def process_local_command(command,client)
	case command.split(" ")[0]
		when "lls"
			puts "Files and directories in current local directory:".good
			files = Dir.entries(Dir.getwd)
			files.each do |file|
				file += "/" if Dir.exists?(file)
				puts file
			end
		when "lpwd"
			puts "The current local working directory is:".good
			puts Dir.pwd
		when "lcd"
			dir = command.split(" ")[1]
			begin
				Dir.chdir(dir)
				puts "Changed local directory to #{dir}".good
			rescue
				puts "Unable to change local directory to #{dir}".bad
			end
		when "lsize"
			file = command.split(" ")[1]
			puts "File size for #{file}:".good
			if file != nil and file != "" and FileTest.readable?(file)
				puts client.format_bytes(File.size(file))
			else
				puts "The file could not be read".bad
			end
		when "clear"
			system "clear"
		when "exit"
			shutdown(client)
	end
end

def process_download_request(client, command)
	target = command.split(" ")[1]
	if target != nil and target != ""
		type = client.check_target_type target
		if type == "file"
			client.download_file target
			puts "Download complete".good
			puts "Would you like to check the file integrity?".question
			if get_bool
				success = client.verify_file target
				if success == true
					puts "CRC match, the file was download successfully".good
				else
					puts "CRC mismatch, the file was corrupt during download".bad
				end
			end
		elsif type == "directory"
			puts "Directory downloads are not yet supported, sorry".bad
		else
			puts "The selected file/directory could not be read".bad
		end
	else
		puts "File cannot be blank".bad
	end
end

def shutdown(client)
	puts "Closing multiplexity".good
	client.shutdown if client != nil
	if (defined? firewall) != nil
		puts "Would you like to remove the multiplexity firewall rules?".question
		if get_bool
			write_verbose "Telling firewall to restore environment".good
			firewall.restore_system
		end
	end
	puts "Multiplexity closed.".good
	exit 0	# also send some sort of halt command to the server?  maybe in the client object's shutdown method
end

puts "Multiplexity".good
settings = parse_args
env_check
if settings[:skip_route_setup] == false
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
				shutdown(nil)
			end
		else
			routes = get_env_config
			firewall = config.new(routes)
			write_verbose "Applying firewall rules".good
			firewall.apply
		end
	end
end
if (defined? firewall) != nil and firewall != nil
	bind_ips = firewall.get_bind_ips
	if settings[:bind_ips] != bind_ips
		write_verbose "Conflicting values for bind IP addresses, using IPs used for route setup".bad
	end
else
	if settings[:bind_ips] == nil
		bind_ips = get_bind_ips
	else
		bind_ips = settings[:bind_ips]
	end
end
if settings[:server_ip] == nil
	puts "Please enter the IP address of the multiplexity server".question
	server = get_ip
else
	server = settings[:server_ip]
end
write_verbose "Opening control socket".good
begin
	socket = TCPSocket.open(server, port)
rescue
	puts "Failed to open control socket, please check your server information and try again".bad
	shutdown(nil)
end
write_verbose "Creating new client object".good
client = MultiplexityClient.new(socket)
write_verbose "Beginning handshake with server".good
if client.handshake == false
	puts "Client handshake failed".bad
	puts "This most likely means the server or client is outdated".bad
	puts "Something other than multiplexity might be listening on port #{port}".bad
	shutdown(client)
	exit 0
end
write_verbose "Opening multiplex sockets with server".good
socket_count = client.setup_multiplex(bind_ips, server)
if socket_count < bind_ips.size
	puts "Not all multiplex sockets opened successfully".bad
	puts "Attempted to open #{bind_ips.size} sockets, #{socket_count} sockets opened successfully".bad
	puts "This could be caused by an incorrect IP address, port filtering on the network(s), or bad firewall rules".bad
#	puts "Continue with successful connections? (y/n)".question
	# The server is still expecting X multiplex connections even if one fails, need to tell the server to forget some or add them one at a time
	# maybe take attempted-success (# of missing sockets) and just open sockets from the default ip and throw them away so the server is ahppy
#	shutdown(client) if get_bool == false
#	(socket_count - bind_ips.size).times do
#		(TCPSocket.open(server, 8001)).close
#	end
	shutdown(client)
	# just close for now
end
write_verbose "Multiplex connections setup".good
puts "Connected to the Multiplexity server".good
loop {
	local_commands = ["lls","lpwd","lcd","lsize","clear","exit"]
	transfer_commands = ["download", "upload"]
	command = get_string
	switch = command.split(" ")[0]
	if local_commands.include? switch
		process_local_command(command,client)
	elsif transfer_commands.include? switch
		case switch
			when "download"
				process_download_request(client,command)
			when "upload"
				puts "File uploads not working yet, sorry".bad
		end
	else
		client.process_command command
	end
}
