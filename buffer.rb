
class Buffer
	def initialize(file)
		@chunkArray = []
		@fileTop = 0
		@file = File.open(file, 'w')
	end
	def checkNext(newChunk, i)
		if newChunk.return("id") > @chunkArray[i].return("id") && newChunk.return("id") < @chunkArray[i+1].return("id")
			@chunkArray.insert(i+1, newChunk)
			return
		end
		checkNext(newChunk, i+1)
	end
	def insert(newChunk)
		if @chunkArray.size == 0 || newChunk.return("id") > @chunkArray[-1].return("id")
			@chunkArray << newChunk
		elsif newChunk.return("id") < @chunkArray[0].return("id")
			@chunkArray.insert(0, newChunk)
		elsif newChunk.return("id") > @chunkArray[0].return("id")
			checkNext(newChunk, 0)
		end
		self.dump
	end
	def countChunks(i)		
		return i+1 if @chunkArray.size == i+1 || @chunkArray[i].return("id") != @chunkArray[i+1].return("id")-1
		countChunks(i+1)
	end
	def dump
		safeCount = countChunks(0)
		if @chunkArray[0].return("id") == @fileTop+1
			toDump = @chunkArray.shift(safeCount)
			@fileTop = toDump[-1].return("id")
			toDump.each do |out_chunk|
				@file.write(out_chunk.return("data"))
			end
		end
	end
end
