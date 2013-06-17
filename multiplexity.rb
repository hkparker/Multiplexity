require './colors.rb'

class Multiplexity
	# methods used to report errors
	def verbose_out
	
	end
end

class MultiplexityServer
	def initialize(client)
		@client = client
		self.handshake
	end
	def handshake
		@client.close if @client.gets.chomp != "HELLO Multiplexity"
		@client.puts "HELLO Client"
		socket_count = @client.gets.chomp
		@client.close if (socket_count.slice! "SOCKETS ") != "SOCKETS "
		socket_count = socket_count.to_i
		@client.puts "SOCKETS OK"
		self.setup_multiplex
	end
	def setup_multiplex
		# this method ensures that all sockets are open correctly and that multiplex transfers are now ready.  hand over to transfer
	end
	def something
		# a method to transfer files.
		# loop {process_command server.gets} ... or something
	end
	
	def process_command
		# take command from server
	end
end

class MultiplexityClient
	def initialize
	
	end
	def handshake
		@socket_count = 0
		@server.puts "HELLO Multiplexity"
		@server.close if @server.gets.chomp != "HELLO Client"
		@server.puts "SOCKETS #{@socket_count}"
		self.setup_multiplex if @server.gets.chomp == "SOCKETS OK"
	end
	def setup_multiplex
		
	end
end
