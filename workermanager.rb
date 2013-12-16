require './worker.rb'
require './buffer.rb'

class WorkerManager
	attr_writer :stale_chunks	# This needs to be tested
	attr_reader :workers
	
	def initialize(server_ip, multiplex_port)
		@server_ip = server_ip
		@multiplex_port = multiplex_port
		@stale_semaphore = Mutex.new
		@next_chunk_semaphore = Mutex.new
		@workers = []
		@stale_chunks = []
		@action = nil
	end
	
	def remove_workers(count)	# need to be able to specify a bind IP to remove
		# remove even across multiple IPs if there are any
	end
	
	def remove_workers_by_ip(bind_ip, count)
		
	end
	
	def add_workers(bind_ips)
		
		
		bind_ips.each do |ip|
			worker = Worker.new(self, @next_chunk_semaphore, @stale_semaphore)
			worker.open_socket(ip, @server_ip, @multiplex_port)
			@workers << worker
		end
		
		
	end
	
	def change_worker_count(change)
		old_size = @workers.size
		if change > 0
			add_workers Array.new(change,@workers[0].bind_ip)
		elsif change < 0
			raise "Cannot reduce workers to or below zero." if @workers.size + change < 1
			# remove some workers.  set close signal?
		end
		# return the amount by which the size changed
		#new_worker.serve_download if actions == "serving"
	end
	
	# Server side
	# worker = Worker.new
	# worker.recieve_connection
	
	def serve_file(filename)
		raise "WorkerManager is currently #{action}.  Use another WorkerManager instance for concurrent transfers." if @action != nil
		@action = "serving"
		working_workers = []
		@workers.each do |worker|
			working_workers << Thread.new{ worker.serve_download }
		end
		working_workers.each do |thread|
			thread.join
		end
		@action = nil
	end
	
	def download_file(filename, verify, reset)
		raise "WorkerManager is currently #{action}.  Please use another WorkerManager instance for concurrent transfers." if @action != nil
		@action = "downloading"
		# check that thats an ok file to write to
		buffer = Buffer.new(filename)
		#check that there are avliable workers
		working_workers = []
		@workers.each do |worker|
			working_workers << Thread.new{ worker.process_download(verify, reset, buffer) }
		end
		working_workers.each do |thread|
			thread.join
		end
		@action = nil
	end
	
	def get_next_chunk
		
	end
end
