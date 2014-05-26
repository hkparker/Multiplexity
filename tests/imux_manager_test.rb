#!/usr/bin/env ruby

require './imux_manager.rb'

class IMUXManagerTest
	def initialize
		@socket_count = 5
	end
	
	def test_can_create_unbound_session
		@server = IMUXManager.new
		@client = IMUXManager.new
		recieve = Thread.new{ @server.recieve_workers(@socket_count) }
		@client.create_workers("127.0.0.1", 8001, Array.new(@socket_count, nil))
		recieve.join
		@server.close_session
		return true
	end

	def test_can_create_bound_session
		@server = IMUXManager.new
		@client = IMUXManager.new
		recieve = Thread.new{ @server.recieve_workers(@socket_count) }
		@client.create_workers("127.0.0.1", 8001, Array.new(@socket_count, "127.0.0.1"))
		recieve.join
		@server.close_session
		return true
	end
	
	def test_can_get_stats
		@server = IMUXManager.new
		@client = IMUXManager.new
		recieve = Thread.new{ @server.recieve_workers(@socket_count) }
		@client.create_workers("127.0.0.1", 8001, Array.new(@socket_count, "127.0.0.1"))
		@client.get_stats
		@server.get_stats
		@server.close_session
		recieve.join
		return true
	end
	
	def test_can_transfer_files
		@server = IMUXManager.new
		@client = IMUXManager.new
		recieve = Thread.new{ @server.recieve_workers(@socket_count) }
		@client.create_workers("127.0.0.1", 8001, Array.new(@socket_count, nil))
		recieve.join
		serve = Thread.new{ @server.serve_file("testfile") }
		@client.download_file("testfileout")
		serve.join
		@client.close_session
		@server.close_session
		return true
	end
end

test = IMUXManagerTest.new
#puts "test_can_create_unbound_session\t=>\t#{test.test_can_create_unbound_session}"
#puts "test_can_create_bound_session\t=>\t#{test.test_can_create_bound_session}"
#puts "test_can_get_stats\t\t=>\t#{test.test_can_get_stats}"
puts "test_can_transfer_files\t\t=>\t#{test.test_can_transfer_files}"
