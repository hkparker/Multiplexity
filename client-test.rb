#!/usr/bin/env ruby

require './multiplexity_client.rb'
require 'socket'

port = 8000

def get_ip
	return "127.0.0.1"
end

puts "Loading Multiplex client ".good
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
