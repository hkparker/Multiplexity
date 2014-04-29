#!/usr/bin/env ruby

require 'socket'
require './imux_socket.rb'
require './file_write_buffer.rb'
require './file_read_queue.rb'

class IMUXSocketTest

	def initialize
		@client = IMUXSocket.new(self)
		@server = IMUXSocket.new(self)
		@tcpserver = TCPServer.new("127.0.0.1",8001)
	end
	
	def test_can_open_socket
		Thread.new{ @server.recieve_connection(@tcpserver) }
		return @client.open_socket("127.0.0.1", 8001)
	end

	def test_can_transfer_chunks
		buffer = Buffer.new("testfileout")
		file_queue = FileReadQueue.new("testfile",5242880)
		Thread.new{ @server.serve_download(file_queue) }
		@client.process_download(buffer, false, false)
	end
end

test = IMUXSocketTest.new
puts "test.test_can_open_socket => #{test.test_can_open_socket}"
puts "test.test_can_transfer_chunks => #{test.test_can_transfer_chunks}"
