#!/usr/bin/env ruby

require './multiplexity_client.rb'

client = MultiplexityClient.new("192.210.217.180", 8000, 8001, 1048576)#3145728)
client.handshake
bind_ips = []
bind_ips << Array.new(10,"192.168.1.9")
bind_ips << Array.new(10,"192.168.1.6")
bind_ips << Array.new(10,"10.0.4.15")
bind_ips << Array.new(10,"192.168.1.36")
bind_ips = bind_ips.flatten
client.setup_multiplex(bind_ips)
download = Thread.new{ client.download_file("largefile", true, true) }

sleep 3
client.change_recycling
sleep 3
client.change_recycling
sleep 3
client.change_recycling

download.join
client.shutdown
