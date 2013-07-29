#!/usr/bin/ruby

require 'socket'
require './multiplexity_server.rb'

#env check

server = TCPServer.new("0.0.0.0", 8000)
client = server.accept
MultiplexityServer.new(client)
