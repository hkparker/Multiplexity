require './imux_socket.rb'
require './file_write_buffer.rb'
require './file_read_queue.rb'
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
	attr_accessor :chunk_size
	attr_accessor :server
	
	def initialize(port = 8000)
		@workers = []
		@stale_chunks = []
		@state = :new
		@reset = false
		@peer_ip = nil
		@port = port
		@chunk_size = 5242880
		@server = TCPServer.new("0.0.0.0", @port)
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
				opened = worker.open_socket(peer_ip, port, bind_ip)
				@workers << worker if opened
				workers_created += 1
			rescue
			end
		end
		@state = :idle
		return workers_created
	end
	
	#
	# This method creates a server and accepts IMUX sockets
	#
	def recieve_workers(count, listen_ip=nil, listen_port=nil)
		@state = :recieving_workers
		waiting = []
		count.times do |i|
			worker = IMUXSocket.new(self)
			waiting << Thread.new{
				Thread.current[:worker] = worker
				worker.recieve_connection(@server)
				}
		end
		waiting.each do |thread|
			begin
				Timeout::timeout(5) { thread.join }	# I dont like this -> http://stackoverflow.com/questions/231647/how-do-i-set-the-socket-timeout-in-ruby#comment4769504_231662
				@workers << thread[:worker]
			rescue
			end
		end
		@state = :idle
	end
	
	#
	# This method reads a file and serves it across the workers
	#
	def serve_file(filename)
		raise "WorkerManager is currently #{@state}.  Use another WorkerManager instance for concurrent transfers." if @state != :idle
		@state = :serving
		@imux_socket_threads = []
		file_queue = FileReadQueue.new(filename, @chunk_size)
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
	def download_file(filename)
		raise "WorkerManager is currently #{@state}.  Use another WorkerManager instance for concurrent transfers." if @state != :idle
		@state = :downloading
		buffer = Buffer.new(filename)
		@working_workers = []
		@workers.each do |worker|
			@working_workers << Thread.new{ worker.process_download(buffer, @verify, @reset) }
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
		pool_speed = 0
		bound_ips = {}
		@workers.each do |worker|
			bound_ip = worker.bind_ip
			if bound_ips[bound_ip] != nil
				bound_ips[bound_ip] += 1
			elsif
				bound_ips.merge!(bound_ip => 1)
			end
			pool_speed += worker.transfer_speed
		end
		return {:worker_count => @workers.size,
				:state => @state,
				:bound_ips => bound_ips,
				:pool_speed => pool_speed}
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
	
	def close_session
		@workers.each { |worker| worker.close_connection }
		@server.close
	end
end
