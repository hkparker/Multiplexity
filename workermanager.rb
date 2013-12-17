require './worker.rb'
require './buffer.rb'

class WorkerManager
	attr_writer :stale_chunks	# This needs to be tested
	
	def initialize(server_ip, multiplex_port)
		@server_ip = server_ip
		@multiplex_port = multiplex_port
		@stale_semaphore = Mutex.new
		@next_chunk_semaphore = Mutex.new
		@workers = []
		@stale_chunks = []
		@state = "idle"
		@paused = false
	end
	
	def remove_workers(count)
		# remove even across multiple IPs if there are any
	end
	
	def remove_workers_by_ip(bind_ip, count)
		# remove count workers with the bind_ip bind_ip
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
		raise "WorkerManager is currently #{@state}.  Use another WorkerManager instance for concurrent transfers." if @state != nil
		@state = "serving"
		working_workers = []
		@workers.each do |worker|
			working_workers << Thread.new{ worker.serve_download }
		end
		working_workers.each do |thread|
			thread.join
		end
		@state = "idle"
	end
	
	def download_file(filename, verify, reset)
		raise "WorkerManager is currently #{@state}.  Please use another WorkerManager instance for concurrent transfers." if @state != nil
		@state = "downloading"
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
		@state = "idle"
	end
	
	def get_next_chunk
		
	end
	
	def get_stats
		idle_workers = 0
		connecting_workers = 0
		downloading_workers = 0
		serving_workers = 0
		@workers.each do |worker|
			case worker.state
				when "idle"
					idle_workers += 1
				when "connecting"
					connecting_workers += 1
				when "downloading"
					downloading_workers += 1
				when "serving"
					serving_workers += 1
			end
			bound_ips = {}
			bound_ip = worker.bind_ip
			if bound_ips.include? bound_ip
				bound_ips[bound_ip] += 1
			elsif
				bound_ips << bound_ip
				bound_ips.merge!(bound_ip => 1)
			end
		end
		bound_ips_string = ""
		bound_ips.each_pair do |ip, count|
			bound_ips_string += "#{ip}:#{count};"
		end
		return {:server_ip => @server_ip,
				:multiplex_port => @multiplex_port,
				:worker_count => @workers.size,
				:idle_workers => idle_workers,
				:connecting_workers => connecting_workers,
				:downloading_workers => downloading_workers,
				:serving_workers => serving_workers,
				:state => @state
				:pause => @pause
				:bound_ips => bound_ips_string}
	end
	
	def pause_workers
		return 1 if @paused
		@workers.each do |worker|
			worker.pause = true
		end
		@paused = true
	end
	
	def resume_workers
		return 1 if not @paused
		@workers.each do |worker|
			worker.pause = false
		end
		@paused = false
	end
	
end
