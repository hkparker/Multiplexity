#!/usr/bin/env ruby

require './buffer.rb'
require './chunk.rb'
require './colors.rb'
require 'socket'

def pickFile
	puts "Please select a file to download".question
	puts "You can use ls, cd, and pwd for filesystem navigation, and exit to close.".good
	puts "Type \"download filename\" when you have selected a file for download".good
	puts "Directory downloads are not yet supported".good
	loop {
		command = ""
		until command.split(" ")[0] == "download"
			print ">"
			command = gets
			listFiles if command.chomp == "ls"
			changeDir(command) if command[0..1] == "cd"
			printDir if command.chomp == "pwd"
			system "clear" if command.chomp == "clear"
			close if command.chomp == "exit"
		end
		file = command.split(" ")[1]
		if canDownload(file) == true
			@@control_socket.puts("done")
			return file
		else
			puts "The choosen file does not exist or cannot be read.".bad
			puts "Directory downloads are not yet supported".bad
		end
	}
end

def listFiles
	puts "Files and directories in current directory:".good
	@@control_socket.puts("ls")
	@@control_socket.gets.to_i.times do |i|
		puts @@control_socket.gets
	end
end

def changeDir(dir)
	@@control_socket.puts(dir)
	puts @@control_socket.gets
end

def printDir
	@@control_socket.puts("pwd")
	puts @@control_socket.gets
end

def canDownload(file)
	@@control_socket.puts("check #{file}")
	result = @@control_socket.gets.chomp
	return false if result == "false"
	return true if result == "true"
end

def close
	puts "Closing network connections".good
	@@control_socket.puts("exit")
	puts "Exiting Multiplex client".good
	exit 0
end

puts "Loading Multiplex client ".good

puts "Please enter the IP address of the multiplex server".question
puts "Skipping and using 192.210.217.180".bad
server = "192.210.217.180"

puts "Please enter the port of the multiplex server".question
port = 8000
puts "Skipping and using #{port}".bad

puts "Opening control socket".good
begin
	@@control_socket = TCPSocket.open(server, port)
rescue
	puts "Failed to open control socket, please check your server information and try again".bad
	exit 0
end
puts "Control socket open".good
puts "Starting file selection dialog".good
file = pickFile
puts "File selected for download: #{file}".good
puts "Downloading file size".good
@@control_socket.puts(file)
size = @@control_socket.gets.to_i
puts "Size of #{file} is #{size} bytes (#{(size / 1024.0 / 1024.0).round(1)}MB, #{(size / 1024.0 / 1024.0 / 1024.0).round(1)}GB)".good
puts "Beginning setup of multiplexed connections".good

puts "Please enter the IP addresses to bind to".question
puts "Skipping and using 192.168.64.3 and 192.168.1.4".bad
ips = ["192.168.64.3","192.168.1.4"]

puts "Binding all sockets to IPs".good

@@control_socket.puts(ips.size)
sockets = []
sleep(1)




# vim /etc/iproute2/rt_tables
# added 128	multiplex0 and 129 multiplex1
# ip route add default via 10.0.2.2 table multiplex0 # where 10.0.2.2 is the IP of one of the interfaces
# ip route add default via 192.168.1.1 table multiplex1	# the other interface IP
# ip rule add from 10.0.0.0/16 table multiplex0 # CIDR notation for the subnet that the interface for multiplex0 table is on
# ip rule add from 192.168.1.0/24 table multiplex1
# ip route flush cache





begin
	ips.each do |ip|
		lhost = Socket.pack_sockaddr_in(0, ip)
		rhost = Socket.pack_sockaddr_in(port, server)
		socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
		puts "Binding socket to #{ip}".good
		socket.bind(lhost)
		puts "Success.  Connecting to #{server}".good
		socket.connect(rhost)
		sockets << socket
	end
rescue
	puts "An unknown error occured while trying to bind to the IPs.".bad
	puts "This could mean you need to run this as root.".bad
	exit(0)
end

puts "All multiplex sockets bound to IPs".good

