require 'socket'
require 'openssl'
require 'base64'

class SecureSocket
	attr_accessor :ciphers
	attr_reader :cipher
	attr_reader :shared_key
	
	def initialize(cipher=nil, key=nil, socket=nil)
		@socket = socket
		@encryption = nil
		@decryption = nil
		if cipher != nil && key != nil
			@encryption = OpenSSL::Cipher.new(cipher)
			@encryption.encrypt
			@encryption.key = key
			@decryption = OpenSSL::Cipher.new(cipher)
			@decryption.decrypt
			@decryption.key = key
		end
		@ciphers = ['AES-128-CBC', 'AES-192-CBC', 'AES-256-CBC', 'CAST5-CBC', 'CAMELLIA-128-CBC', 'CAMELLIA-192-CBC', 'CAMELLIA-256-CBC']
		@cipher = cipher
		@shared_key = key
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
			server_ciphers = @socket.gets.split(",")
			begin
				@cipher = best_cipher(@ciphers, server_ciphers)
				@socket.puts @cipher
			rescue
				@socket.puts "NONE"
				@socket.close
				raise 'No compatable ciphers'
			end
			params = Base64.decode64(@socket.gets)
			dh = OpenSSL::PKey::DH.new(params)
			dh.generate_key!
			@socket.puts dh.pub_key.to_s(16)
			server_public_key = @socket.gets.to_i(16)
			@shared_key = dh.compute_key(server_public_key)
			@encryption = OpenSSL::Cipher.new(@cipher)
			@encryption.encrypt
			@encryption.key = @shared_key
			@decryption = OpenSSL::Cipher.new(@cipher)
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
	
	private
	
	def best_cipher(local, remote)
		local.each do |cipher|
			return cipher if remote.include? cipher
		end
		raise "No compatable ciphers"
	end
end

class SecureServer
	attr_reader :bind_ip
	attr_reader :bind_port
	attr_accessor :ciphers
	
	def initialize(bind_ip, bind_port)
		@bind_ip = bind_ip
		@bind_port = bind_port
		@server = TCPServer.new(@bind_ip, @bind_port)
		@ciphers = ['AES-128-CBC', 'AES-192-CBC', 'AES-256-CBC', 'CAST5-CBC', 'CAMELLIA-128-CBC', 'CAMELLIA-192-CBC', 'CAMELLIA-256-CBC']
	end
	
	def accept(cipher=nil, shared_key=nil)
		insecure_socket = @server.accept
		if cipher == nil || shared_key == nil
			ciphers_string = ""
			@ciphers.each do |cipher|
				ciphers_string += "#{cipher},"
			end
			insecure_socket.puts ciphers_string
			cipher = insecure_socket.gets.chomp
			if cipher == "NONE"
				insecure_socket.close
				raise "No compatable ciphers"
			end
			encryption_object = OpenSSL::Cipher.new(cipher)
			dh_size = encryption_object.random_key.size * 64
			dh = OpenSSL::PKey::DH.new(dh_size)
			params = dh.to_s
			insecure_socket.puts Base64.encode64(params).gsub("\n","")
			client_public_key = insecure_socket.gets.to_i(16)
			insecure_socket.puts dh.pub_key.to_s(16)
			shared_key = dh.compute_key(client_public_key)
		end
		socket = SecureSocket.new(cipher, shared_key, insecure_socket)
		socket
	end
	
	def close
		@server.close
	end
end
