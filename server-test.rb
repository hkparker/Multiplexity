#!/usr/bin/ruby

require 'socket'
require './colors.rb'
require './multiplexity.rb'

server = TCPServer.new("0.0.0.0", 80)
loop {
	Thread.start(server.accept) do |client|
		MultiplexityServer.new(client)
	end
}
