#!/usr/bin/ruby

require 'socket'
require './multiplexity_server.rb'

server = TCPServer.new("0.0.0.0", 80)
loop {
	Thread.start(server.accept) do |client|
		MultiplexityServer.new(client)
	end
}
