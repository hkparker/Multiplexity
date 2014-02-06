require 'socket'
require 'openssl'
require 'base64'

class SecureSocket
	attr_reader :shared_key
	
	# add recycle method?
	
	def initialize(key=nil, socket=nil)
		@socket = socket
		@shared_key = key
		@encryption = nil
		@decryption = nil
		if @shared_key != nil
			@encryption = OpenSSL::Cipher.new("AES-128-CBC")
			@encryption.encrypt
			@encryption.key = key
			@decryption = OpenSSL::Cipher.new("AES-128-CBC")
			@decryption.decrypt
			@decryption.key = key
		end
	end

	def open(ip_address, port, bind_ip=nil)
		if bind_ip == nil
			@socket = TCPSocket.open(ip_address, port)
		else
			lhost = Socket.pack_sockaddr_in(0, bind_ip)
			rhost = Socket.pack_sockaddr_in(port, ip_address)
			@socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
			@socket.bind(lhost)
			@socket.connect(rhost)
		end
		if @encryption == nil || @decryption == nil
			params = Base64.decode64(@socket.gets)
			dh = OpenSSL::PKey::DH.new(params)
			dh.generate_key!
			@socket.puts dh.pub_key.to_s(16)
			server_public_key = @socket.gets.to_i(16)
			@shared_key = dh.compute_key(server_public_key)
			@encryption = OpenSSL::Cipher.new("AES-128-CBC")
			@encryption.encrypt
			@encryption.key = @shared_key
			@decryption = OpenSSL::Cipher.new("AES-128-CBC")
			@decryption.decrypt
			@decryption.key = @shared_key
		end
	end
	
	def puts(string)
		iv = @encryption.random_iv
		ciphertext = @encryption.update(string) + @encryption.final
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
		@decryption.iv = iv
		cleartext = @decryption.update(ciphertext) + @decryption.final
		cleartext
	end
	
	def peer_address
		socket_class = @socket.class
		if socket_class == Socket
			return @socket.local_address.ip_address
		elsif socket_class == TCPSocket
			return @socket.peeraddr[3]
		else
			return nil
		end
	end
	
	def close
		@socket.close
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
		if shared_key == nil
			dh = OpenSSL::PKey::DH.new(1024)
			params = dh.to_s
			insecure_socket.puts Base64.encode64(params).gsub("\n","")
			client_public_key = insecure_socket.gets.to_i(16)
			insecure_socket.puts dh.pub_key.to_s(16)
			shared_key = dh.compute_key(client_public_key)
		end
		socket = SecureSocket.new(shared_key, insecure_socket)
		socket
	end
	
	def close
		@server.close
	end
end
