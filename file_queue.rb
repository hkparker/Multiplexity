class FileQueue
	alias_method :next_chunk :dequeue
	attr_reader :filename
	attr_accessor :read_ahead_depth # allow it to be adjusted dynamically
	def initialize(filename,read_ahead=false,read_ahead_depth=0)
		@filename = filename
		@read_ahead = read_ahead
		@read_ahead_depth = read_ahead_depth
	end

	def dequeue
		
	end

end
