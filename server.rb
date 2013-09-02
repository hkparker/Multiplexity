#!/usr/bin/ruby

require 'socket'
require './multiplexity_server.rb'

#env check, have flag for logging

settings = {:daemonize => false,
			:pid_file => false,
			:use_auth => true
			}

server = TCPServer.new("0.0.0.0", 8000)
client = server.accept
multiplex_server = MultiplexityServer.new(client)
multiplex_server.handshake
multiplex_server.setup_multiplex
multiplex_server.process_commands


# need to loop for commands like the client instead
