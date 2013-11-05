#!/usr/bin/env ruby

require './multiplexity_client.rb'

client = MultiplexityClient.new("192.210.217.180", 8000, 8001, 3145728)
client.handshake
bind_ips = []
bind_ips << Array.new(50,"158.104.244.87")
#bind_ips << Array.new(10,"192.168.1.6")
#bind_ips << Array.new(10,"10.0.4.15")
#bind_ips << Array.new(10,"192.168.1.36")
bind_ips = bind_ips.flatten
client.setup_multiplex(bind_ips)
download = Thread.new{ client.download_file("500MB_file", false, false) }


download.join
client.shutdown
