#!/usr/bin/ruby

require 'socket'
require './lib/session.rb'

server = TCPServer.new("0.0.0.0", 8000)
loop {
	Thread.new{ Session.new(server.acept) }
}
