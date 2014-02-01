#!/usr/bin/ruby

require 'socket'
require './session.rb'

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


class Server

end
