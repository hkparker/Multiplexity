#!/usr/bin/env ruby

require '../colors.rb'
require '../file_read_queue.rb'

puts "Testing file read queue...".good

puts "Creating queue"
queue = FileReadQueue.new("/home/hayden/Downloads/demo", 0, false, 0)
chunk = queue.next_chunk
puts chunk[:id]
Thread.new{ puts queue.next_chunk[:id] }
Thread.new{ puts queue.next_chunk[:id] }
Thread.new{ puts queue.next_chunk[:id] }

