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
			sleep(0.1) until @chunk != nil
			if @chunk == 0
				@socket.puts 0
				break
			end
			# send the id
			# send the size
			# then send the chunk
			@chunk = nil
		}
	end
	
	def ready
		@ready
	end
	
	def get_chunk(chunk)
		@chunk = chunk
	end
	
end
