#!/usr/bin/env ruby

require './multiplexity_client.rb'
require 'socket'

def get_ip
	return "127.0.0.1"
end


puts "Loading Multiplex client ".good
puts "Please enter the IP address of the multiplex server".question
server = get_ip

puts "Opening control socket".good
begin
	socket = TCPSocket.open(server, 8000)
rescue
	puts "Failed to open control socket, please check your server information and try again".bad
	exit 0
end






# get info here, pass open socket to initialize
client = MultiplexityClient.new(socket)
# then work from here
client.handshake
client.setup_multiplex
