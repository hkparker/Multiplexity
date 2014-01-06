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
upper = Gtk::HBox.new(false, 0)
lower = Gtk::HBox.new(false, 0)
server_ip_label = Gtk::Label.new("Server:")
server_ip_input = Gtk::Entry.new
control_port_label = Gtk::Label.new("Port:")
control_port_input = Gtk::Entry.new
control_port_input.width_chars=5
control_port_input.insert_text("8000", 0)
multiplex_port_label = Gtk::Label.new("Multiplex Port:")
multiplex_port_input = Gtk::Entry.new
multiplex_port_input.width_chars=5
multiplex_port_input.insert_text("8001", 0)
chunk_size_label = Gtk::Label.new("Chunk Size:")
chunk_size_input = Gtk::Entry.new
chunk_size_input.width_chars=5
chunk_size_input.insert_text("5", 0)
chunk_unit = Gtk::ComboBox.new
chunk_unit.append_text("KB")
chunk_unit.append_text("MB")
chunk_unit.active = 1
socket_count_label = Gtk::Label.new("Sockets/IP:")
socket_count_input = Gtk::Entry.new
socket_count_input.width_chars=5
bind_ips_input = Gtk::Entry.new
bind_ips_input.set_sensitive false
bind_ips_input.width_chars=12
network_mode = Gtk::CheckButton.new("Bind IPs:")
network_mode.signal_connect("clicked") {
	bind_ips_input.set_sensitive !bind_ips_input.sensitive?
}
route_helper_button = Gtk::Button.new("Route helper")
route_helper_button.signal_connect("clicked") {
	# Launch route help guide
}

username = Gtk::Entry.new
login_colon = Gtk::Label.new(":")
password = Gtk::Entry.new
login_option = Gtk::CheckButton.new("Login")
login_option.signal_connect("clicked") {
	username.set_sensitive !username.sensitive?
	password.set_sensitive !password.sensitive?
}
login_option.active = true
username.set_sensitive true
password.set_sensitive true
password.visibility=false
server_secret = Gtk::Entry.new
authenticate_option = Gtk::CheckButton.new("Authenticate")
authenticate_option.signal_connect("clicked") {
	server_secret.set_sensitive !server_secret.sensitive?
}
authenticate_option.active = true
server_secret.set_sensitive true

log_file = Gtk::Entry.new
log_file.insert_text("/var/log/multiplexity.log", 0)
log_file.set_sensitive false
log_option = Gtk::CheckButton.new("Log")
log_option.signal_connect("clicked") {
	log_file.set_sensitive !log_file.sensitive?
}
connect_button = Gtk::Button.new("Connect")
connect_button.signal_connect("clicked") {
	#	Connect to server
}
upper.pack_start server_ip_label, false, false, 0
upper.pack_start server_ip_input, false, false, 0
upper.pack_start control_port_label, false, false, 0
upper.pack_start control_port_input, false, false, 0
upper.pack_start multiplex_port_label, false, false, 0
upper.pack_start multiplex_port_input, false, false, 0
upper.pack_start chunk_size_label, false, false, 0
upper.pack_start chunk_size_input, false, false, 0
upper.pack_start chunk_unit, false, false, 0
upper.pack_start socket_count_label, false, false, 0
upper.pack_start socket_count_input, false, false, 0
upper.pack_start network_mode, false, false, 0
upper.pack_start bind_ips_input, true, true, 0
upper.pack_start route_helper_button, false, false, 0

lower.pack_start login_option, false, false, 0
lower.pack_start username, false, false, 0
lower.pack_start login_colon, false, false, 0
lower.pack_start password, false, false, 0
lower.pack_start authenticate_option, false, false, 0
lower.pack_start server_secret, true, true, 0
lower.pack_start log_option, false, false, 0
lower.pack_start log_file, false, false, 0
lower.pack_start connect_button, false, false, 0

top_row.pack_start upper, false, false, 0
top_row.pack_start lower, false, false, 0
### End top row





### Middle Row
middle_row = Gtk::HBox.new(true, 10)
local_files = Gtk::VBox.new(false, 5)
remote_files = Gtk::VBox.new(false, 5)
#######################
local_tree = Gtk::ListStore.new(String, String, String, String, String, String)
local_top_hbox = Gtk::HBox.new(false, 0)
local_label = Gtk::Label.new
local_label.set_markup("<span size=\"x-large\" weight=\"bold\">Local Files    </span>")
#print_local_directory = Gtk::Button.new("pwd")
#local_directory = Gtk::Entry.new
#change_local_directory = Gtk::Button.new("cd")
local_top_hbox.pack_start local_label, false, false, 0
#local_top_hbox.pack_start print_local_directory, false, false, 0
#local_top_hbox.pack_start local_directory, false, false, 0
#local_top_hbox.pack_start change_local_directory, false, false, 0

##
files = []
files << {:filename => "file1", :path => "/root", :size => "1 MB", :type => "file", :last_write => "1/1/13 1:00 PM", :readable => "true"}
files << {:filename => "file2", :path => "/root", :size => "234 KB", :type => "file", :last_write => "1/1/13 2:00 PM", :readable => "true"}
files << {:filename => "file3", :path => "/root", :size => "13.5 MB", :type => "file", :last_write => "1/1/13 3:00 PM", :readable => "true"}
files << {:filename => "file4", :path => "/root", :size => "2.2 GB", :type => "file", :last_write => "1/1/13 4:00 PM", :readable => "true"}
files << {:filename => "movie.mkv", :path => "/home/hayden/data/", :size => "17.8 GB", :type => "file", :last_write => "9/17/13 4:47 PM", :readable => "true"}
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
remote_tree = Gtk::ListStore.new(String, String, String, String, String, String)
remote_top_hbox = Gtk::HBox.new(false, 5)
remote_label = Gtk::Label.new
remote_label.set_markup("<span size=\"x-large\" weight=\"bold\">Remote Files</span>")
remote_top_hbox.pack_start remote_label, false, false, 0
##
files = []
files << {:filename => "file1", :path => "/root", :size => "2.0 MB", :type => "file", :last_write => "1/1/13 1:00 PM", :readable => "true"}
files << {:filename => "file2", :path => "/root", :size => "18 KB", :type => "file", :last_write => "1/1/13 2:00 PM", :readable => "true"}
files << {:filename => "file3", :path => "/root", :size => "128 bytes", :type => "file", :last_write => "1/1/13 3:00 PM", :readable => "true"}
files << {:filename => "file4", :path => "/root", :size => "423 MB", :type => "file", :last_write => "1/1/13 4:00 PM", :readable => "true"}
files << {:filename => "movie.mkv", :path => "/home/hayden/data/", :size => "7.8 GB", :type => "file", :last_write => "9/17/13 4:47 PM", :readable => "true"}
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
status_options = Gtk::VBox.new(false, 0)


filler = Gtk::Button.new

current_file_bar = Gtk::HBox.new(false, 5)
current_file_label = Gtk::Label.new
current_file_label.set_markup("<span weight=\"bold\">Current File:</span>")
current_file = Gtk::Label.new("filename.mkv")
file_progress = Gtk::ProgressBar.new
current_file_bar.pack_start current_file_label, false, false, 0
current_file_bar.pack_start current_file, false, false, 0
current_file_bar.pack_start file_progress, true, true, 0

current_stats_bar = Gtk::HBox.new(false, 5)
pool_speed_label = Gtk::Label.new
pool_speed_label.set_markup("<span weight=\"bold\">Pool speed:</span>")
pool_speed = Gtk::Label.new("8.4MB/s")
worker_count_label = Gtk::Label.new
worker_count_label.set_markup("<span weight=\"bold\">Worker count:</span>")
worker_count = Gtk::Label.new("85")
bound_ips_count_label = Gtk::Label.new
bound_ips_count_label.set_markup("<span weight=\"bold\">Bound IPs:</span>")
bound_ips_count = Gtk::Label.new("4")
current_stats_bar.pack_start pool_speed_label, false, false, 0
current_stats_bar.pack_start pool_speed, false, false, 0
current_stats_bar.pack_start worker_count_label, false, false, 0
current_stats_bar.pack_start worker_count, false, false, 0
current_stats_bar.pack_start bound_ips_count_label, false, false, 0
current_stats_bar.pack_start bound_ips_count, false, false, 0

authenticate_line = Gtk::HBox.new(false, 0)
secret_label = Gtk::Label.new("Secret:")
server_secret_2 = Gtk::Entry.new
re_authenticate_button = Gtk::Button.new("Authenticate")
re_authenticate_button.signal_connect("clicked") {
	# Authenticate
}
authenticate_line.pack_start secret_label, false, false, 0
authenticate_line.pack_start server_secret_2, false, false, 0
authenticate_line.pack_start re_authenticate_button, false, false, 0

small_options = Gtk::HBox.new(false, 0)
verify = Gtk::CheckButton.new("CRC verify chunks")
recycle = Gtk::CheckButton.new("Recycle sockets")
small_options.pack_start verify, false, false, 0
small_options.pack_start recycle, false, false, 0

change_worker_count = Gtk::HBox.new
add_or_remove = Gtk::ComboBox.new
add_or_remove.append_text("Add")
add_or_remove.append_text("Remove")
add_or_remove.set_active 0
worker_count = Gtk::Entry.new
worker_count.width_chars=3
worker_count.xalign=1
workers_label = Gtk::Label.new
workers_label.set_markup("<span size=\"large\" weight=\"bold\"> workers </span>")
add_bind_ip = Gtk::CheckButton.new("bind ip = ")
bind_ip_to_add = Gtk::Entry.new
bind_ip_to_add.width_chars=16
bind_ip_to_add.set_sensitive false
add_bind_ip.signal_connect("clicked") {
	bind_ip_to_add.set_sensitive !bind_ip_to_add.sensitive?
}
change_worker_button = Gtk::Button.new("Do it")
change_worker_button.signal_connect("clicked") {
	# Add or remove the number of workers
}
change_worker_count.pack_start add_or_remove, false, false, 0
change_worker_count.pack_start worker_count, false, false, 0
change_worker_count.pack_start workers_label, false, false, 0
change_worker_count.pack_start add_bind_ip, false, false, 0
change_worker_count.pack_start bind_ip_to_add, false, false, 0
change_worker_count.pack_start change_worker_button, false, false, 0




status_options.pack_start current_file_bar, false, false, 0
status_options.pack_start current_stats_bar, false, false, 0
status_options.pack_start filler, true, true, 0
status_options.pack_start authenticate_line, false, false, 0
status_options.pack_start small_options, false, false, 0
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
