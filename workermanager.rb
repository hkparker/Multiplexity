require './worker.rb'
require './buffer.rb'

class WorkerManager
	attr_writer :stale_chunks	# This needs to be tested
	
	def initialize
		stale_semaphore = Mutex.new
		next_chunk_semaphore = Mutex.new
		@workers = []
		@stale_chunks = []
	end
	
	def set_worker_count
	
	end
	
	def create_new_worker
		
		@workers << Worker.new(self, next_chunk_semaphore, stale_semaphore)
	end
	
	def serve_file(filename)
		# check we aren't doing something else
		working_workers = []
		@workers.each do |worker|
			working_workers << Thread.new{ worker.serve_download }
		end
		working_workers.each do |thread|
			thread.join
		end
	end
	
	def download_file(filename, verify, reset)
		# check that thats an ok file to write to
		buffer = Buffer.new(filename)
		#check that there are active workers
		working_workers = []
		@workers.each do |worker|
			working_workers << Thread.new{ worker.process_download(verify, reset, buffer) }
		end
		working_workers.each do |thread|
			thread.join
		end
	end
	
	def get_next_chunk
		
	end
end
