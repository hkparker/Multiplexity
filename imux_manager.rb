require './imux_socket.rb'
require './file_write_buffer.rb'
require 'socket'
require 'timeout'

#
# This class controls instances of IMUXSocket.  It provides higher level
# control over an inverse multiplex session, such as opening all the imux
# sockets, adding and removing them dynamically, and providing fault
# tolerance if one of the sockets is closed.  It can also be used to get
# information on the status of the imux session.
#

class IMUXManager
	attr_accessor :stale_chunks
	
	def initialize
		@workers = []
		@stale_chunks = []
		@state = :new
		@paused = false
		@reset = false
		@verify = false
		@peer_ip = nil
		@port = nil
	end
	
	#
	# This method should be called only once during the creation of the IMUX session
	#
	def create_workers(peer_ip, port, bind_ips)
		@state = :creating_workers
		@peer_ip = peer_ip
		@port = port
		workers_created = 0
		bind_ips.each do |bind_ip|
			begin
				worker = IMUXSocket.new(self)
				worker.open_socket(peer_ip, port, bind_ip)
				@workers << worker
				workers_created += 1
			rescue
			end
		end
		@state = :idle
		return workers_created
	end
	
	#
	# This method should be used to adjust the worker setup after the IMUX session is created
	#
	def change_worker_count(change, bind_ip)
		old_state = @state
		@state = :adjusting_workers
		old_size = @workers.size
		socket_change = 0
		raise "Add workers with WorkerManager#create_workers first" if old_size == 0
		if change > 0
			socket_change = create_workers(@peer_ip, @port, Array.new(change, bind_ip))
		elsif change < 0
			raise "Cannot reduce workers to or below zero." if @workers.size + change < 1
			socket_change = 0
			change.abs.times do |i|
				success = remove_worker(bind_ip)
				socket_change -= 1 if success
			end
		end
		@state = old_state
		return socket_change
	end
	
	#
	# This method creates a server and accepts IMUX sockets
	#
	def recieve_workers(listen_ip, listen_port, count)
		@state = :recieving_workers
		server = TCPServer.new(listen_ip, listen_port)
		waiting = []
		count.times do |i|
			worker = IMUXSocket.new(self)
			waiting << Thread.new{
				Thread.current[:worker]  = worker
				worker.recieve_connection(server)
				}
		end
		waiting.each do |thread|
			begin
				Timeout::timeout(5) { thread.join }	# I dont like this -> http://stackoverflow.com/questions/231647/how-do-i-set-the-socket-timeout-in-ruby#comment4769504_231662
				@workers << thread[:worker]
			rescue
			end
		end
		server.close
		@state = :idle
	end
	
	#
	# This method reads a file and serves it across the workers
	#
	def serve_file(filename)
		raise "WorkerManager is currently #{@state}.  Use another WorkerManager instance for concurrent transfers." if @state != :idle
		@state = :serving
		@imux_socket_threads = []
		file_queue = FileReadQueue.new(filename)
		@workers.each do |worker|
			@imux_socket_threads << Thread.new{ worker.serve_download(file_queue) }
		end
		@imux_socket_threads.each do |thread|
			thread.join
		end
		@imux_socket_threads = []
		@state = :idle
	end
	
	#
	# This method has all the workers download chunks into a buffer
	#
	def download_file(filename, verify, reset)
		raise "WorkerManager is currently #{@state}.  Use another WorkerManager instance for concurrent transfers." if @state != :idle
		@state = :downloading
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
	
	#
	# This method returns all information about the IMUXManager's state
	#
	def get_stats
		idle_workers = 0
		connecting_workers = 0
		downloading_workers = 0
		serving_workers = 0
		pool_speed = 0
		bound_ips = {}
		@workers.each do |worker|
			case worker.state
				when :idle
					idle_workers += 1
				when :connecting
					connecting_workers += 1
				when :downloading
					downloading_workers += 1
				when :serving
					serving_workers += 1
			end
			bound_ip = worker.bind_ip
			if bound_ips[bound_ip] != nil
				bound_ips[bound_ip] += 1
			elsif
				bound_ips.merge!(bound_ip => 1)
			end
			pool_speed += worker.transfer_speed
		end
		return {:server_ip => @peer_ip,
				:multiplex_port => @port,
				:worker_count => @workers.size,
				:idle_workers => idle_workers,
				:connecting_workers => connecting_workers,
				:downloading_workers => downloading_workers,
				:serving_workers => serving_workers,
				:state => @state,
				:pause => @pause,
				:bound_ips => bound_ips,
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
		return 1 if !@paused
		@workers.each do |worker|
			worker.pause = false
		end
		@paused = false
	end
	
	def enable_reset
		return 1 if @reset
		@workers.each do |worker|
			worker.reset = true
		end
		@reset = true
	end
	
	def disable_reset
		return 1 if !@reset
		@workers.each do |worker|
			worker.reset = false
		end
		@reset = false
	end
	
	def enable_verification
		return 1 if @verify
		@workers.each do |worker|
			worker.verify = true
		end
		@verify = true
	end
	
	def disable_verification
		return 1 if !@verify
		@workers.each do |worker|
			worker.verify = false
		end
		@verify = false
	end
	
	def remove_worker(bind_ip)
		@workers.each do |worker|
			if worker.bind_ip == bind_ip
				worker.close_connection
				@workers.delete worker
				return true
			end
			return false
		end
	end
end
