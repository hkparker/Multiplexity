#!/usr/bin/env ruby

require './multiplexity_client.rb'

# Multiplexity options.
tests = 1
verifications = [true, false]
recyclings = [true, false]
chunk_sizes = [262144,524288,1048576,3145728,6291456]
socket_counts = [2,4,6,8,10,20,50,100,150]


# Test settings.
log_filename = "multiplexity_results.txt"
server = "192.210.217.180"
port = 8000
multiplex_port = 8001
bind_ip = "192.168.1.4"
download_file = "500MB_file"
file_size = 524288000

# Used for clean output.
def format_bytes(bytes)
		i = 0
		until bytes < 1024
			bytes = (bytes / 1024).round(1)
			i += 1
		end
		suffixes = ["bytes","KB","MB","GB","TB"]
		"#{bytes} #{suffixes[i]}"
end

puts "This test will download #{format_bytes(file_size*tests*verifications.size*recyclings.size*chunk_sizes.size*socket_counts.size)}"

log_file = File.open(log_filename, "w")
log_file.sync = true

tests.times do |i|
	verifications.each do |verify|
		recyclings.each do |recycle|
			chunk_sizes.each do |chunk_size|
				socket_counts.each do |socket_count|
					## ssh in and start server
					client = MultiplexityClient.new(server, port, multiplex_port, chunk_size)
					client.handshake
					bind_ips = Array.new(socket_count,bind_ip)
					bind_start = Time.now
					client.setup_multiplex(bind_ips)
					bind_time = Time.now - bind_start
					start = Time.now
					client.download_file(download_file, verify, recycle)
					time = Time.now - start
					client.shutdown
					speed = file_size / time
					log_file.write "#{i},#{verify},#{recycle},#{chunk_size},#{socket_count},#{bind_time},#{time},#{speed}\n"
					sleep 5
				end
			end
		end
	end
end

log_file.close
