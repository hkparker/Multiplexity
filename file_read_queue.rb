require 'thread'

#
# The FileReadQueue is used by MultiplexitySession objects to read chunks
# of a file from disk.  It is thread safe, so each thread serving chunks
# can use the same FileReadQueue to grab chunks.  It also supports a read
# ahead level as an experimental feature.
#

class FileReadQueue
	attr_reader :filename				# To check the filename being read
	attr_reader	:read_ahread			# To check if a queue is reading ahead
	attr_accessor :read_ahead_depth		# Number of chunks to cache in RAM.  Can be adjusted dynamically.  Experimental.
	
	def initialize(filename, starting_position=0, read_ahead=false, read_ahead_depth=0)
		@file = File.open(filename, 'rb')
		@read_ahead = read_ahead
		@read_ahead_depth = read_ahead_depth
		if @read_ahead
			@chunk_queue = Queue.new
			@chunk_queue << 0
			@chunk_queue.shift
			@fill_thread = Thread.new{}
		end
		@id = 0
		@next_chunk_semaphore = Mutex.new
	end

	def next_chunk
		@next_chunk_semaphore.synchronize {
			if !@read_ahead
				return {:id => @id, :data => @file.read(chunk_size)}
			else
				return {:id => @id, :data => @chunk_queue.pop}
				@fill_thread = Thread.new{ fill_chunk_queue } if @fill_thread.status == false
			end
			@id += 1
		}
	end

	def fill_chunk_queue
		@read_ahead_depth = 1 if @read_ahead_depth < 1
		(@read_ahead_depth-@chunk_queue.size).times do |i|
			queue_next_chunk
		end
	end

	def queue_next_chunk
		@chunk_queue << @file.read(chunk_size)
	end
end
