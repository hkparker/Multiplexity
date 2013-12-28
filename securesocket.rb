require 'socket'
require 'openssl'
require 'base64'

class SecureSocket
	attr_reader :peer_address
	
	def initialize(ip_address, port, bind_ip=nil, shared_key=nil)
	
		if bind_ip == nil
			@socket = TCPSocket.open(ip_address, port)
		else
			lhost = Socket.pack_sockaddr_in(0, bind_ip)
			rhost = Socket.pack_sockaddr_in(port, ip_address)
			@socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
			@socket.bind(lhost)
			@socket.connect(rhost)
		end
		
		
		
		if shared_key == nil
			# define the shared key
			# shared_key = encrypt_stuff
		end
	
	
	####
		@socket = TCPSocket.open(ip_address, port)
		params = Base64.decode64(@socket.gets)
		dh = OpenSSL::PKey::DH.new(params)
		dh.generate_key!
		@socket.puts dh.pub_key.to_s(16)
		server_public_key = @socket.gets.to_i(16)
		shared_key = dh.compute_key(server_public_key)
		case shared_key.size
			when 128
				@aes_encryption = OpenSSL::Cipher.new('AES-128-CBC')
				@es_decryption = OpenSSL::Cipher.new('AES-128-CBC')
			when 256
				@aes_encryption = OpenSSL::Cipher.new('AES-256-CBC')
				@es_decryption = OpenSSL::Cipher.new('AES-256-CBC')
			else
				raise "Key size doesn't match supported ciphers"
		end
		@aes_encryption.encrypt
		@aes_decryption.decrypt
		@aes_encryption.key = shared_key
		@aes_decryption.key = shared_key
	end
	
	def assign_socket(socket)
		@socket = socket
	end
	
	def open(ip_address, port, bind_ip=nil, shared_key=nil)
		# optionally provide bind ip, switch which ruby class to use based on that
		# also optionally pass a shared key which will bypass DH exchange?
		# or perhaps have a dh exchange be another method and raise error if no key?
	end
	
	def puts(string)
		iv = @aes_encryption.random_iv
		ciphertext = @aes_encryption.update(string) + @aes_encryption.final
		encoded_iv = Base64.encode64(iv)
		encoded_ciphertext = Base64.encode64(ciphertext).gsub("\n","")
		@socket.puts encoded_iv
		@socket.puts encoded_ciphertext
	end
	
	def gets
		encoded_iv = @socket.gets
		encoded_data = @socket.gets
		iv = Base64.decode64(encoded_iv)
		ciphertext = Base64.decode64(encoded_data)
		@aes_decryption.iv = iv
		cleartext = @aes_decryption.update(ciphertext) + @aes_decryption.final
		cleartext
	end
end

class SecureServer
	attr_reader :bind_ip
	attr_reader :bind_port
	
	def initialize(bind_ip, bind_port)
		@bind_ip = bind_ip
		@bind_port = bind_port
		@server = TCPServer.new(@bind_ip, @bind_port)
	end
	
	def accept(shared_key=nil)
		insecure_socket = @server.accept
		# handshake encryption
		socket = SecureSocket.new
		socket.assign_socket insecure_socket
	end
end
