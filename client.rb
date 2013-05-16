#!/usr/bin/env ruby

require './buffer.rb'
require './chunk.rb'
require './colors.rb'
require 'socket'

def pickFile
	puts "Please select a file to download".question
	puts "You can use ls, cd, and pwd for filesystem navigation.".good
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
	@@control_socket.puts("done")
	puts "Exiting Multiplex client".good
	exit 0
end

puts "Loading Multiplex client ".good + "-- proof of concept code - version 0.0.1".teal

puts "Please enter the IP address of the multiplex server".question
puts "Skipping and using 127.0.0.1".bad
server = "127.0.0.1"

puts "Please enter the port of the multiplex server".question
puts "Skipping and using 8000".bad
port = "8000"

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
