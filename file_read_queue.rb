require 'thread'

#
# The FileReadQueue is used by MultiplexitySession objects to read chunks
# of a file from disk.  It is thread safe, so each thread serving chunks
# can use the same FileReadQueue to grab chunks.
#

class FileReadQueue
	attr_reader :filename
	attr_accessor :stale_chunks
	attr_accessor :chunk_size
	
	def initialize(filename, chunk_size, starting_position=0)
		@file = File.open(filename, 'rb')
		#discard the beginning if needed
		@chunk_size = chunk_size
		@stale_chunks = []
		@id = 0
		@next_chunk_semaphore = Mutex.new
	end

	def next_chunk
		@next_chunk_semaphore.synchronize {
			return @stale_chunks.shift if @stale_chunks.size > 0
			@id += 1
			return {:id => @id, :data => @file.read(@chunk_size)}
		}
	end
end
