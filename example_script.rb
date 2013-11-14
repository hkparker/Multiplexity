#!/usr/bin/env ruby

require './multiplexity_client.rb'

client = MultiplexityClient.new("149.5.241.33", 8000, 8001, 3145728)
client.handshake
bind_ips = []
bind_ips << Array.new(20,"182.168.1.2")
#bind_ips << Array.new(10,"192.168.1.6")
#bind_ips << Array.new(10,"10.0.4.15")
#bind_ips << Array.new(10,"192.168.1.36")
bind_ips = bind_ips.flatten
client.setup_multiplex(bind_ips)
download = Thread.new{ client.download_file("\"/home/hayden/data/[a-S] Fullmetal Alchemist Brotherhood (01-64) (1080p)/[a-s]_fullmetal_alchemist_brotherhood_-_13_-_beasts_of_dublith__rs2_[1080p_bd-rip][190815DC].mkv\"", false, false) }
download.join
client.shutdown
