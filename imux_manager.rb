require './worker.rb'
require './buffer.rb'

class WorkerManager
	attr_writer :stale_chunks	# This needs to be tested
	
	def initialize
		@client_semaphore = Mutex.new
		@server_semaphore = Mutex.new
		@workers = []
		@stale_chunks = []
		@state = "idle"
		@paused = false
	end
	
	def add_workers(server_ip, multiplex_port, bind_ips)
		added = 0
		bind_ips.each do |bind_ip|
			begin
				worker = Worker.new(self, @client_semaphore, @server_semaphore)
				worker.open_socket(server_ip, multiplex_port, bind_ip)
	#			case @state
	#				when "serving"
	#					@working_workers << Thread.new{ worker.serve_download }
	#				when "downloading"
	#					@working_workers << Thread.new{ worker.process_download(verify, reset, buffer) }
	#			end
				@workers << worker
				added += 1
			rescue
			end
		end
		return added
	end
	
	def remove_workers_by_ip(bind_ip, count)
		stopped = 0
		@workers.each do |worker|
			break if stopped == count
			if worker.bind_ip == bind_ip
				remove_worker worker
				stopped += 1
			end
		end
	end
	
	def change_worker_count(change)
		old_size = @workers.size
		raise "Add workers with WorkerManager#add_workers first" if old_size == 0
		if change > 0
			change = add_workers (@workers[0].server_ip,@workers[0].multiplex_port,Array.new(change,@workers[0].bind_ip))
			# add evenly across multiple IPs if there are any
		elsif change < 0
			raise "Cannot reduce workers to or below zero." if @workers.size + change < 1
			# remove even across multiple IPs if there are any
		end
		old_size+change
	end
	
	def recieve_workers(listen_ip, listen_port, count, sync_string)
		server = TCPServer.new(listen_ip, listen_port)
		waiting = []
		count.times do |i|
			worker = Worker.new(self, @client_semaphore, @server_semaphore)
			waiting << Thread.new{ worker.recieve_connection(server) }
		end
		waiting.each do |thread|
			thread.join
		end
		server.close
	end
	
	def serve_file(filename)
		raise "WorkerManager is currently #{@state}.  Use another WorkerManager instance for concurrent transfers." if @state != "idle"
		@state = "serving"
		@working_workers = []
		@workers.each do |worker|
			@working_workers << Thread.new{ worker.serve_download }
		end
		@working_workers.each do |thread|
			thread.join
		end
		@working_workers = []
		@state = "idle"
	end
	
	def download_file(filename, verify=false, reset=false)
		raise "WorkerManager is currently #{@state}.  Use another WorkerManager instance for concurrent transfers." if @state != "idle"
		@state = "downloading"
		buffer = Buffer.new(filename)
		@working_workers = []
		@workers.each do |worker|
			@working_workers << Thread.new{ worker.process_download(buffer, verify, reset) }
		end
		@working_workers.each do |thread|
			thread.join
		end
		@working_workers = []
		@state = "idle"
	end
	
	def get_next_chunk
		if @stale_chunks.size > 0
			return @stale_chunks.shift
		end
		chunk_size = get_next_chunk_size
		if chunk_size == 0
			return nil
		else
			@id += 1 # here?
			return {:id => @id, :data => @current_file.read(chunk_size)}
		end		
	end
	
	def get_stats
		idle_workers = 0
		connecting_workers = 0
		downloading_workers = 0
		serving_workers = 0
		pool_speed = 0
		bound_ips = {}
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
			bound_ip = worker.bind_ip
			if bound_ips.include? bound_ip
				bound_ips[bound_ip] += 1
			elsif
				bound_ips << bound_ip
				bound_ips.merge!(bound_ip => 1)
			end
			pool_speed += worker.transfer_speed
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
				:state => @state,
				:pause => @pause,
				:bound_ips => bound_ips_string,
				:pool_speed => pool_speed}
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
	
	# methods to turn on/off crc and recycle on all workers
	
	private
	
	def remove_worker(worker)
		worker.close_connections
		@workers.delete worker
	end
	
end
