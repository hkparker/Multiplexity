class Chunk
	def initialize(id, data)
		@id = id
		@data = data
	end
	def return(attribute)
		if attribute == "id"
			@id.to_i
		elsif attribute == "data"
			@data
		end
	end
end
