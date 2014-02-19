require 'thread'

class FileReadQueue
	attr_reader :filename
	attr_accessor :read_ahead_depth # allow it to be adjusted dynamically
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
		(@read_ahead_depth-@chunk_queue.size).times do |i|
			queue_next_chunk
		end
	end

	def fill_chunk_queue
		
	end

	def queue_next_chunk
		# use instance variable for where we are in the file, and read out chunk size.  
	end

end
