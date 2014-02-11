#!/usr/bin/env ruby

require 'multiplexity'

##
## All methods avaliable to user interfaces
##

# Define a TransferManager to facilitate all tranfers
manager = TransferManager.new
# Get the auto generated localhost Host object
localhost = manager.localhost
# Connect to new hosts by creating new Host objects
host1 = Host.new(remote_host)
# IMUX between hosts by creating queues
queue = manager.queue(localhost, host1)
# Once a queue exists, tell the manager to tranfer between hosts
status = manager.transfer_between(localhost, host1, filename)	# start queue paused?
# See whats in the queue
puts queue.pending
# Pause and resume a transfer
queue.pause
queue.resume
# Get information about a current transfer
manager.stat_transfer(queue)
# Calcel the current tranfer
manager.cancel_current()
# Change things about current multiplex states
queue.add_workers(...)
# ...
# other methods to reorder the queue?  contained within queue? (queue.move(position, new_position))
# Clear a queue
queue.clear
# methods to disconnect and close everything
manager.close_queue(queue) # disconnect all imuxing, destroy queue object, keep host objects
manager.close # close all queues, including localhost.  Full shutdown
host1.close # disconnect control socket, close any queues involving it unless there are current transfers.  Has refernce to TransferManager class and Queues it is a part of to remove itself from.



#	TransferManager
#		new
#		localhost
#		queue
#		transfer_between
#		stat_transfer
#		cancel_current
#		close_queue
#		close

#	Host
#		new

	
#	Queue
#		pending
#		pause
#		resume
#		add_workers
#		clear
#



# Other Idea:



# localhost = Localhost.new

#class Localhost < Host
#	def initialize
		# copy Host's init but fill in params
#	end
#end

#box = Host.new("box.net","hayden","password") # no imux settings, just control socket

#queue = Queue.new(host1, host2, imus settings) # Maybe make imux settings its own object?  Like IMUXConfig.new(socket count, ) # 
