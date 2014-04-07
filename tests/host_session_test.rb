#!/usr/bin/env ruby

require 'socket'
require './session.rb'
require './host.rb'

class HostSessionTest
	def initialize
	end
	
	def test_can_connect_host_to_session
		@host = Localhost.new
		return true
	end

	def test_can_get_remote_files
		@host.get_remote_files
		return true
	end

	def test_can_get_pwd
		@host.get_remote_dir
		return true
	end

	def test_can_change_directory
		@host.change_remote_directory ".."
		@host.change_remote_directory "multiplexity"
		return true
	end
	
	def test_can_create_directory
		@host.create_directory "testdir"
		return true
	end

	def test_can_remove_item
		@host.delete_item "testdir"
		return true
	end
	
	def test_can_close_socket
		@host.close
		return true
	end
	
end

test = HostSessionTest.new
puts "test_can_connect_host_to_session => #{test.test_can_connect_host_to_session}"
puts "test_can_get_remote_files => #{test.test_can_get_remote_files}"
puts "test_can_get_pwd => #{test.test_can_get_pwd}"
puts "test_can_change_directory => #{test.test_can_change_directory}"
puts "test_can_create_directory => #{test.test_can_create_directory}"
puts "test_can_remove_item => #{test.test_can_remove_item}"
puts "test_can_close_socket => #{test.test_can_close_socket}"
