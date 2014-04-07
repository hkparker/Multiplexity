#!/usr/bin/env ruby

require './host.rb'
require './session.rb'
require './transfer_queue.rb'
require './imux_config.rb'

class TransferQueueTest
	def initialize
	end
	
	def test_can_create_tranfer_queue
		local1 = Localhost.new
		local2 = Localhost.new(8080)
		imux_config = IMUXConfig.new
		@transfer_queue = TransferQueue.new(local1, local2, imux_config)
		collect_messages
		return true
	end
	
	def test_can_change_chunk_size
		@transfer_queue.set_chunk_size(1000000)
		return true
	end
	
	def test_can_change_recycling
	
	end
	
	def test_can_change_verification
	
	end
	
	def test_can_add_workers
	
	end
	
	def test_can_remove_workers
	
	end
	
	def test_can_transfer_file
	
	end
	
	private
	
	def collect_messages
		Thread.new{
			loop {
				puts @transfer_queue.message_queue.pop
			}
		}
	end
end

test = TransferQueueTest.new
puts "test_can_create_tranfer_queue\t=>\t#{test.test_can_create_tranfer_queue}"
#puts "test_can_change_chunk_size\t=>\t#{test.test_can_change_chunk_size}"
