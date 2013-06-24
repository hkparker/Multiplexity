#!/usr/bin/env ruby

require './multiplexity_client.rb'
require 'socket'

port = 8000

def get_ip
	return "127.0.0.1"
end

def get_bool
	choice = ""
	until choice == "y" or choice == "n"
		print ">"
		choice = STDIN.gets.chomp
	end
	choice
end

def setup_routes
	puts "Setting up source based routing".good
end

puts "Loading Multiplex client ".good

puts "Before we connect to a server we need to setup routing rules".good
puts "If you have already setup source based routing, you can skip this step".good
puts "Would you like to setup routing rules now?".question
choice = get_bool
setup_routes if choice == "y"

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

# get information on interfaces, setup routing rules

client.handshake
client.setup_multiplex

loop {
	command = client.get_command
	client.process_command command
}
