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
			sleep(0.01) until @chunk != nil
			if @chunk == 0
				@socket.puts 0
				break
			end
			@socket.puts @chunk.return("id")
			@socket.puts @size
			@socket.write(@chunk.return("data"))
			@chunk = nil
		}
	end
	
	def ready
		@ready
	end
	
	def not_ready
		@ready = false
	end
	
	def get_chunk(chunk, size)
		@chunk = chunk
		@size = size
	end
	
end
