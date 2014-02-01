#!/usr/bin/env ruby

require 'multiplexity'

remote_host = "192.168.1.12"

transfer_manager = TransferManager.new
localhost = transfer_manager.localhost
host1 = Host.new(remote_host)
localhost_host1_queue = transfer_manager.create_queue(localhost, host1)
transfer = {:source => host1, :destination => localhost, :filename => "filename"}
transfer_manager.add_to_queue(transfer, 0)
puts localhost_host1_queue.to_a
puts localhost_host1_queue.top
# other methods to reorder the queue.  contained within queue? (queue.move(position, new_position))
# or, access the queue as an array directly?  Then use native ruby array methods
