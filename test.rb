#!/usr/bin/env ruby

require './multiplexity_client.rb'

# Multiplexity options.  This test will be 54.8GB.
tests = 1
verifications = [true, false]
recyclings = [true, false]
chunk_sizes = [524288,1048576,3145728,6291456]
socket_counts = [2,5,10,20,50,100,150]


# Test settings.
log_filename = "multiplexity_results.txt"
server = "192.210.217.180"
port = 8000
multiplex_port = 8001
bind_ip = "192.168.1.4"
download_file = "500MB_file"

log_file = File.open(log_filename, "w")

tests.times do |i|
	verifications.each do |verify|
		recyclings.each do |recycle|
			chunk_sizes.each do |chunk_size|
				socket_counts.each do |socket_count|
					client = MultiplexityClient.new(server, port, multiplex_port, chunk_size)
					client.handshake
					bind_ips = Array.new(socket_count,bind_ip)
					client.setup_multiplex(bind_ips)
					start = Time.now
					client.download_file(download_file, verify, recycle)
					time = Time.now - start
					client.shutdown
					log_file.write "#{i},#{verify},#{recycle},#{chunk_size},#{socket_count},#{time}}"
				end
			end
		end
	end
end

log_file.close
