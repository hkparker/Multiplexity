class Chunk
	attr_reader :id
	attr_reader :data
	def initialize(id, data)
		@id = id
		@data = data
	end
end
