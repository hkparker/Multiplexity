class IMUXConfig
	attr_accessor :sockets_per_ip
	attr_accessor :bind_ips
	attr_accessor :port
	attr_accessor :chunk_size
	attr_accessor :recycle_sockets
	attr_accessor :verify
	attr_accessor :listen_ip

	def initialize(sockets_per_ip=25,
				   bind_ips=[], port=8001,
				   chunk_size=5242880,
				   recycle_sockets=false,
				   verify_chunk=false,
				   listen_ip="0.0.0.0")
		@sockets_per_ip = sockets_per_ip
		@bind_ips = bind_ips
		@port = port
		@chunk_size = chunk_size
		@recycle_sockets = recycle_sockets
		@verify = verify_chunk
		@listen_ip = listen_ip
	end
	
	def client_config
		@bind_ips = Array.new(@sockets_per_ip, nil) if @bind_ips.size == 0
		bound_ip_hash = {}
		@bind_ips.each do |bind_ip|
			bind_ip = "nil" if bind_ip == nil
			if bound_ip_hash[bind_ip] != nil
				bound_ip_hash[bind_ip] += 1
			elsif
				bound_ip_hash.merge!(bind_ip => 1)
			end
		end
		bind_ip_string = ""
		bound_ip_hash.each do |ip, count|
			bind_ip_string += "#{ip}-#{count};"
		end
		return "#{bind_ip_string}:#{@port}:#{@recycle_sockets.to_s}:#{@veriy.to_s}"
	end
	
	def server_config
		@bind_ips = Array.new(@sockets_per_ip, nil) if @bind_ips.size == 0
		return "#{@listen_ip}:#{@port}:#{@bind_ips.size}:#{@chunk_size}"
	end
end
