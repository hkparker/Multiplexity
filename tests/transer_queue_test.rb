#!/usr/bin/env ruby

require './host.rb'
require './session.rb'
require './transfer_queue.rb'
require './imux_config.rb'

class TransferQueueTest
	def initialize
	end
	
	def test_can_create_tranfer_queue
		@client = Localhost.new
		@server = Localhost.new(8081)#Host.new("box.rutlen.net", 8000)
		imux_config = IMUXConfig.new
		@transfer_queue = TransferQueue.new(@client, @server, imux_config)
		collect_messages
		return true
	end
	
	def test_can_change_chunk_size
		@transfer_queue.set_chunk_size(1000000)
		return true
	end
	
	def test_can_change_recycling
		@transfer_queue.set_recycling(true)
		sleep 1
		@transfer_queue.set_recycling(false)
		sleep 1
		return true
	end
	
	def test_can_change_verification
		@transfer_queue.set_verification(true)
		sleep 1
		@transfer_queue.set_verification(false)
		sleep 1
		return true
	end
	
	def test_can_add_workers
		@transfer_queue.change_worker_count(:add, 5, nil)
		sleep 1
		return true
	end
	
	def test_can_remove_workers
		@transfer_queue.change_worker_count(:remove, 5, nil)
		sleep 1
		return true
	end
	
	def test_can_transfer_file
		@transfer_queue.add_transfer(@client, @server, "testfile", "testfileout")
		sleep 100
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
test.test_can_create_tranfer_queue
#test.test_can_change_chunk_size
#test.test_can_change_recycling
#test.test_can_change_verification
#test.test_can_add_workers
#test.test_can_remove_workers
test.test_can_transfer_file
