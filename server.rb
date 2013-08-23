#!/usr/bin/ruby

require 'socket'
require './multiplexity_server.rb'

#env check, have flag for logging

server = TCPServer.new("0.0.0.0", 8000)
client = server.accept
multiplex_server = MultiplexityServer.new(client)
multiplex_server.handshake
multiplex_server.setup_multiplex
multiplex_server.choose_file
multiplex_server.serve_file


# need to loop for commands like the client instead
