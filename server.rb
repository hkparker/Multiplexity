#!/usr/bin/ruby

require 'socket'
require './multiplexity_server.rb'

#env check, have flag for logging


	#def initialize(listen_ip, listen_port)
		#@server = SecureServer.new(listen_ip, listen_port)
	#end

	#def serve_sessions
		##loop
			##server.accept
			##handshake it
			## thread new process_commands thread for client
	#end



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
