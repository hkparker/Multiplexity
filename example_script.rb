#!/usr/bin/env ruby

require './multiplexity_client.rb'

server = TCPSocket.open("192.210.217.180", 8000)
client = MultiplexityClient.new(server)
client.handshake(8001,3145728)
client.setup_multiplex(["192.168.1.9", "192.168.1.9"], "192.210.217.180")
client.download_file("randfile", false, false)
sleep 1
