require 'thread'

#
# The FileReadQueue is used by MultiplexitySession objects to read chunks
# of a file from disk.  It is thread safe, so each thread serving chunks
# can use the same FileReadQueue to grab chunks.  It also supports a read
# ahead level as an experimental feature.
#

class FileReadQueue
	attr_reader :filename
	attr_accessor :read_ahead_depth		# Number of chunks to cache in RAM.  Can be adjusted dynamically.  Experimental.
	
	def initialize(filename,read_ahead=false,read_ahead_depth=0)
		@filename = filename
		@read_ahead = read_ahead
		@read_ahead_depth = read_ahead_depth
		@chunk_queue = Queue.new
		@chunk_queue << 0
		@chunk_queue.shift
	end

	def next_chunk
		
		# use real queue
		
		# fork a new thread to do this: if there isn't one running already
		
	end

	def fill_chunk_queue
		(@read_ahead_depth-@chunk_queue.size).times do |i|
			queue_next_chunk
		end
	end

	def queue_next_chunk
		# use instance variable for where we are in the file, and read out chunk size.  
	end

end
