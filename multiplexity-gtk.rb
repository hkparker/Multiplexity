#!/usr/bin/env ruby

require 'gtk2'

multiplexity = Gtk::Window.new("Multiplexity")
multiplexity.signal_connect("delete_event") {
#	puts "You are still connected.  Quit?" if connected
	false	# yes, we can close
#	true	# no, we can't close
}
multiplexity.signal_connect("destroy") {
  Gtk.main_quit
}

### Top Row
top_row = Gtk::VBox.new(false, 0)
top_row_upper = Gtk::HBox.new(false, 0)
top_row_lower = Gtk::HBox.new(false, 0)

server_ip_label = Gtk::Label.new("Server: ")
server_ip_input = Gtk::Entry.new
control_port_label = Gtk::Label.new("Port: ")
control_port_input = Gtk::Entry.new
control_port_input.insert_text("8000", 0)
multiplex_port_label = Gtk::Label.new("Multiplex Port: ")
multiplex_port_input = Gtk::Entry.new
multiplex_port_input.insert_text("8001", 0)
chunk_size_label = Gtk::Label.new("Chunk Size: ")
chunk_size_input = Gtk::Entry.new
chunk_size_input.insert_text("3", 0)
chunk_unit = Gtk::ComboBox.new
chunk_unit.append_text("KB")
chunk_unit.append_text("MB")
chunk_unit.active = 1
socket_count_label = Gtk::Label.new("Sockets/IP: ")
socket_count_input = Gtk::Entry.new
bind_ips_label = Gtk::Label.new("Bind IPs: ")
bind_ips_input = Gtk::Entry.new
network_mode = Gtk::CheckButton.new("Multiple networks")
network_mode.signal_connect("clicked") {
	bind_ips_input.set_sensitive !bind_ips_input.sensitive?
}
route_helper_button = Gtk::Button.new("Launch route helper")
log_file = Gtk::Entry.new
log_file.insert_text("/var/log/multiplexity.log", 0)
log_file.set_sensitive false
log_option = Gtk::CheckButton.new("Log messages")
log_option.signal_connect("clicked") {
	log_file.set_sensitive !log_file.sensitive?
}
connect_button = Gtk::Button.new("Connect")
connect_button.signal_connect("clicked") {
	#
}
top_row_upper.pack_start server_ip_label, false, false, 0
top_row_upper.pack_start server_ip_input, false, false, 0
top_row_upper.pack_start control_port_label, false, false, 0
top_row_upper.pack_start control_port_input, false, false, 0
top_row_upper.pack_start multiplex_port_label, false, false, 0
top_row_upper.pack_start multiplex_port_input, false, false, 0
top_row_upper.pack_start chunk_size_label, false, false, 0
top_row_upper.pack_start chunk_size_input, false, false, 0
top_row_upper.pack_start chunk_unit, false, false, 0

top_row_lower.pack_start socket_count_label, false, false, 0
top_row_lower.pack_start socket_count_input, false, false, 0
top_row_lower.pack_start network_mode, false, false, 0
top_row_lower.pack_start bind_ips_label, false, false, 0
top_row_lower.pack_start bind_ips_input, false, false, 0
top_row_lower.pack_start route_helper_button, false, false, 0
top_row_lower.pack_start log_option, false, false, 0
top_row_lower.pack_start log_file, false, false, 0
top_row_lower.pack_start connect_button, false, false, 0


top_row.pack_start top_row_upper, false, false, 0
top_row.pack_start top_row_lower, false, false, 0
### End top row









#verify = Gtk::CheckButton.new("CRC verify chunks")
#recycle = Gtk::CheckButton.new("Recycle sockets")



### Middle Row
middle_row = Gtk::HBox.new(true, 10)
local_files = Gtk::VBox.new(false, 5)
remote_files = Gtk::VBox.new(false, 5)
#######################
local_tree = Gtk::ListStore.new(String, String, Integer, String, String, String)
local_top_hbox = Gtk::HBox.new(false, 0)
local_label = Gtk::Label.new
local_label.set_markup("<span size=\"x-large\" weight=\"bold\">Local Files</span>")
local_top_hbox.pack_start local_label, false, false, 0
##
files = []
files << {:filename => "file1", :path => "/root", :size => 1024, :type => "file", :last_write => "1/1/13 1:00 PM", :readable => "true"}
files << {:filename => "file2", :path => "/root", :size => 2024, :type => "file", :last_write => "1/1/13 2:00 PM", :readable => "true"}
files << {:filename => "file3", :path => "/root", :size => 3024, :type => "file", :last_write => "1/1/13 3:00 PM", :readable => "true"}
files << {:filename => "file4", :path => "/root", :size => 4024, :type => "file", :last_write => "1/1/13 4:00 PM", :readable => "true"}
files << {:filename => "movie.mkv", :path => "/home/hayden/data/", :size => 23987512, :type => "file", :last_write => "9/17/13 4:47 PM", :readable => "true"}
files.each do |file|
	row = local_tree.append()
	row[0] = file[:filename]
	row[1] = file[:path]
	row[2] = file[:size]
	row[3] = file[:type]
	row[4] = file[:last_write]
	row[5] = file[:readable]
end
##
local_view = Gtk::TreeView.new(local_tree)
local_view.reorderable=true
columns = ["File Name","Path","Size","Type","Last Write","Readable"]
columns.each_with_index do |column, i|
	renderer = Gtk::CellRendererText.new
	colum = Gtk::TreeViewColumn.new(column, renderer, :text => i)
	colum.resizable = true
	local_view.append_column(colum)
end
scrolled_local = Gtk::ScrolledWindow.new
scrolled_local.add(local_view)
scrolled_local.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
local_files.pack_start local_top_hbox, false, false, 0
local_files.pack_start_defaults(scrolled_local)
##########
remote_tree = Gtk::ListStore.new(String, String, Integer, String, String, String)
remote_top_hbox = Gtk::HBox.new(false, 5)
remote_label = Gtk::Label.new
remote_label.set_markup("<span size=\"x-large\" weight=\"bold\">Remote Files</span>")
remote_top_hbox.pack_start remote_label, false, false, 0
##
files = []
files << {:filename => "file1", :path => "/root", :size => 1024, :type => "file", :last_write => "1/1/13 1:00 PM", :readable => "true"}
files << {:filename => "file2", :path => "/root", :size => 2024, :type => "file", :last_write => "1/1/13 2:00 PM", :readable => "true"}
files << {:filename => "file3", :path => "/root", :size => 3024, :type => "file", :last_write => "1/1/13 3:00 PM", :readable => "true"}
files << {:filename => "file4", :path => "/root", :size => 4024, :type => "file", :last_write => "1/1/13 4:00 PM", :readable => "true"}
files << {:filename => "movie.mkv", :path => "/home/hayden/data/", :size => 23987512, :type => "file", :last_write => "9/17/13 4:47 PM", :readable => "true"}
files.each do |file|
	row = remote_tree.append()
	row[0] = file[:filename]
	row[1] = file[:path]
	row[2] = file[:size]
	row[3] = file[:type]
	row[4] = file[:last_write]
	row[5] = file[:readable]
end
##
remote_view = Gtk::TreeView.new(remote_tree)
remote_view.reorderable=true
columns = ["File Name","Path","Size","Type","Last Write","Readable"]
columns.each_with_index do |column, i|
	renderer = Gtk::CellRendererText.new
	colum = Gtk::TreeViewColumn.new(column, renderer, :text => i)
	colum.resizable = true
	remote_view.append_column(colum)
end
scrolled_remote = Gtk::ScrolledWindow.new
scrolled_remote.add(remote_view)
scrolled_remote.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
remote_files.pack_start remote_top_hbox, false, false, 0
remote_files.pack_start_defaults(scrolled_remote)
#######################
middle_row.pack_start local_files, true, true, 0
middle_row.pack_start remote_files, true, true, 0


### Bottom Row
bottom_row = Gtk::HBox.new(true, 10)
status = Gtk::VBox.new(false, 5)
queue = Gtk::VBox.new(false, 5)
#######################
status_top_hbox = Gtk::HBox.new(false, 0)
status_label = Gtk::Label.new
status_label.set_markup("<span size=\"x-large\" weight=\"bold\">Status</span>")
status_options = Gtk::VBox.new


filler = Gtk::Button.new
change_worker_count = Gtk::HBox.new
add_or_remove = Gtk::ComboBox.new
add_or_remove.append_text("Add")
add_or_remove.append_text("Remove")
add_or_remove.set_active 0
worker_count = Gtk::Entry.new
workers_label = Gtk::Label.new
workers_label.set_markup("<span size=\"large\" weight=\"bold\"> workers </span>")
add_bind_ip = Gtk::CheckButton.new("bind ip = ")
bind_ip_to_add = Gtk::Entry.new
bind_ip_to_add.set_sensitive false
add_bind_ip.signal_connect("clicked") {
	bind_ip_to_add.set_sensitive !bind_ip_to_add.sensitive?
}
change_worker_button = Gtk::Button.new("Do it")
change_worker_button.signal_connect("clicked") {

}

change_worker_count.pack_start add_or_remove, false, false, 0
change_worker_count.pack_start worker_count, false, false, 0
change_worker_count.pack_start workers_label, false, false, 0
change_worker_count.pack_start add_bind_ip, false, false, 0
change_worker_count.pack_start bind_ip_to_add, true, true, 0
change_worker_count.pack_start change_worker_button, false, false, 0

status_options.pack_start filler, true, true, 0
status_options.pack_start change_worker_count, false, false, 0
status_top_hbox.pack_start status_label, false, false, 0
status.pack_start status_top_hbox, false, false, 0
status.pack_start status_options, true, true, 0
####
queue_top_hbox = Gtk::HBox.new(false, 0)
queue_label = Gtk::Label.new
queue_label.set_markup("<span size=\"x-large\" weight=\"bold\">Queue</span>")
image8 = Gtk::Button.new
queue_top_hbox.pack_start queue_label, false, false, 0
queue.pack_start queue_top_hbox, false, false, 0
queue.pack_start image8, true, true, 0
#######################
bottom_row.pack_start status, true, true, 0
bottom_row.pack_start queue, true, true, 0
### End Bottom Row



all_rows = Gtk::VBox.new(false, 10)
all_rows.pack_start top_row, false, false, 0
all_rows.pack_start middle_row, true, true, 0
all_rows.pack_start bottom_row, true, true, 0

multiplexity.add(all_rows)
multiplexity.show_all
Gtk.main
