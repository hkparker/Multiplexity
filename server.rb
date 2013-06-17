#!/usr/bin/ruby

require 'socket'
require './colors.rb'

server = TCPServer.new("0.0.0.0", 80)

control_socket = server.accept

loop{
	command = control_socket.gets.chomp
	if command == "ls"
		files = Dir.entries(Dir.getwd)
		control_socket.puts(files.size.to_s)
		files.each do |file|
			file += "/" if Dir.exists?(file)
			control_socket.puts(file)
		end
	elsif command[0..1] == "cd"
		begin
			new_dir = command.split(" ")[1]
			Dir.chdir(new_dir)
			control_socket.puts("Changed directory to #{new_dir}".good)
		rescue
			control_socket.puts("Unable to change directory to #{new_dir}".bad)
		end
	elsif command == "pwd"
		control_socket.puts(Dir.pwd)
	elsif command[0..4] == "check"
		begin
			file = command.split(" ")[1]
			if FileTest.readable?(file) == true && Dir.exists?(file) != true
				control_socket.puts("true")
			else
				control_socket.puts("false")
			end
		rescue
			control_socket.puts("false")
		end
	end
	break if command == "done"
	exit(0) if command == "exit"
}

file = control_socket.gets.chomp
control_socket.puts("#{File.size(file)}")

sockets = []
control_socket.gets.to_i.times do |i|
	puts "waiting for a multiplex socket"
	sockets << server.accept
	puts "got a multiplex socket"
end
