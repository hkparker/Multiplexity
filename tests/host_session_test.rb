#!/usr/bin/env ruby

require 'socket'
require './session.rb'
require './host.rb'

class HostSessionTest
	def initialize
	end
	
	def test_can_connect_host_to_session
		server = TCPServer.new("0.0.0.0", 8000)
		Thread.new{ Session.new(server.accept) }
		@host = Host.new("127.0.0.1", 8000)
		return @host.handshake
	end

	def test_can_get_remote_files
		@host.get_remote_files
		return true
	end

	def test_can_get_pwd
		@host.get_remote_dir
		return true
	end

	def test_can_change_directory
		@host.change_remote_directory ".."
		return true
	end

end

test = HostSessionTest.new
puts "test_can_connect_host_to_session => #{test.test_can_connect_host_to_session}"
puts "test_can_get_remote_files => #{test.test_can_get_remote_files}"
puts "test_can_get_pwd => #{test.test_can_get_pwd}"
puts "test_can_change_directory => #{test.test_can_change_directory}"
