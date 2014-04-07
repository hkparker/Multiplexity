#!/usr/bin/env ruby

require './host.rb'
require './transfer_queue.rb'

class TransferQueueTest
	def initialize
		
	end
	
	def test_can_create_tranfer_queue
	
	end
	
	def test_can_change_chunk_size
	
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
