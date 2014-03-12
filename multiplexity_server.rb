#!/usr/bin/ruby

require 'socket'
require './session.rb'

#settings = {:daemonize => false,
			#:pid_file => false,
			#:use_auth => true
			#}

#server = TCPServer.new("0.0.0.0", 8000)
#client = server.accept
#multiplex_server = MultiplexityServer.new(client)
#multiplex_server.handshake
#multiplex_server.setup_multiplex
#multiplex_server.process_commands


class MultiplexityServer

end

# Authentication is done by ther server

	#def handshake
		#begin
			#hello = @client.gets.chomp
			#if hello != "HELLO Multiplexity"
				#@client.close
				#return false
			#end
			#@client.puts "HELLO Client"
			#login = @client.gets.chomp
			#if login == "ANONYMOUS"
				#if !@allow_anonymous
					#@client.puts "Anonymous NO"
					#@client.close
					#return false
				#else
					#@client.puts "Anonymous OK"
			#else
					#login = login.split(":")
					#username = login[0]
					#password = login[1]
					## either @client.puts "user ok" or "user no"
			#end
			#@auth_mandatory ? @client.puts("AUTH MANDATORY") : @client.puts("AUTH NOMANDATORY")
			
			#return true
		#rescue
			#@client.close
			#return false
		#end
	#end

	#def authenticate_client(secret)
		#shared_secret = OpenSSL::Digest::SHA256.hexdigest "#{secret}#{@client.shared_secret}"
		#smp = SMP.new shared_secret
		#@client.puts(smp.step2(@client.gets))
		#@client.puts(smp.step4(@client.gets))
		#return smp.match
	#end
