require './chunk.rb'

class Worker
	def initialize(socket)
			@socket = socket
			@ready = false
			@chunk = nil
	end
	
	def start
		loop{
			@ready = true
			puts "Ready"
			loop {
				if @chunk != nil
					puts "chunk is now full, lets no longer be ready"
					@ready = false
					break
				end
			}
			if @chunk == 0
				puts "The chunk was 0, so lets close this thread"
				@socket.puts 0
				break
			end
			@socket.puts @chunk.return("id")
			@socket.puts @size
			puts "sending the actual data"
			@socket.write(@chunk.return("data"))
			@chunk = nil
		}
	end
	
	def ready
		@ready
	end
	
	def get_chunk(chunk, size)
		@chunk = chunk
		@size = size
	end
	
end
