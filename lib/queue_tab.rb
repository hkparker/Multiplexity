class QueueTab

	def initialize
		@client = nil
		@server = nil
		@transfer_queue = nil
	end

	def update_files(host, host_tree)
		files = host.get_remote_files()
		files.each do |file|
			row = host_tree.append()
			row[0] = file[:filename]
			row[1] = file[:path]
			row[2] = file[:size]
			row[3] = file[:type]
			row[4] = file[:last_write]
			row[5] = file[:readable]
		end
	end

	def attach_to_window
		
	end
	
	def detach_from_window
		
	end
end
