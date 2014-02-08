#!/usr/bin/env ruby

require 'gtk2'

## Create a new window
window = Gtk::Window.new("Multiplexity")
window.set_default_size(1300,700)
window.signal_connect("destroy") { Gtk.main_quit }


## Hosts
hosts = Gtk::VBox.new(false, 5)
hosts_tree = Gtk::ListStore.new(String, String)
hosts_top_hbox = Gtk::HBox.new(false, 0)
hosts_label = Gtk::Label.new
hosts_label.set_markup("<span size=\"x-large\" weight=\"bold\">Hosts</span>")
add_host = Gtk::Button.new("+")
add_host.signal_connect("clicked"){
	# add a host
}
hosts_filler = Gtk::HBox.new(true, 0)
hosts_top_hbox.pack_start hosts_label, false, false, 0
hosts_top_hbox.pack_start hosts_filler, true, true, 0
hosts_top_hbox.pack_start add_host, false, false, 0

host_list = []
host_list << {:state => " ", :hostname => "localhost"}
host_list << {:state => " ", :hostname => "host1"} 
host_list << {:state => " ", :hostname => "host2"}
host_list.each do |host|
	row = hosts_tree.append()
	row[0] = host[:state]
	row[1] = host[:hostname]
end

hosts_view = Gtk::TreeView.new(hosts_tree)
columns = ["","Hostname"]
columns.each_with_index do |column, i|
	renderer = Gtk::CellRendererText.new
	colum = Gtk::TreeViewColumn.new(column, renderer, :text => i)
	hosts_view.append_column(colum)
end

rclick_host_menu = Gtk::Menu.new
host_connect_item = Gtk::MenuItem.new("Connect")
host_connect_item.signal_connect("activate") {
	puts "connect"
}
host_disconnect_item = Gtk::MenuItem.new("Disconnect")
host_disconnect_item.signal_connect("activate") {
	puts "disconnect"
}
host_remove_item = Gtk::MenuItem.new("Remove")
host_remove_item.signal_connect("activate") {
	puts "remove"
}
rclick_host_menu.append(host_connect_item)
rclick_host_menu.append(host_disconnect_item)
rclick_host_menu.append(host_remove_item)
rclick_host_menu.show_all
hosts_view.signal_connect("button_press_event") do |widget, event|
	rclick_host_menu.popup(nil, nil, event.button, event.time) if event.kind_of? Gdk::EventButton and event.button == 3
end

scrolled_hosts = Gtk::ScrolledWindow.new
scrolled_hosts.add(hosts_view)
scrolled_hosts.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
hosts.pack_start hosts_top_hbox, false, false, 0
hosts.pack_start_defaults(scrolled_hosts)
## End hosts


# Queues
queues = Gtk::VBox.new(false, 5)
queues_tree = Gtk::ListStore.new(String, String, String)
queues_top_hbox = Gtk::HBox.new(false, 0)
queues_label = Gtk::Label.new
queues_label.set_markup("<span size=\"x-large\" weight=\"bold\">Queues</span>")
add_queue = Gtk::Button.new("+")
add_queue.signal_connect("clicked"){
	# Add a queue
}
queue_filler = Gtk::HBox.new(true, 0)
queues_top_hbox.pack_start queues_label, false, false, 0
queues_top_hbox.pack_start queue_filler, true, true, 0
queues_top_hbox.pack_start add_queue, false, false, 0

queue_list = []
queue_list << {:state => " ", :client => "localhost", :server => "host1"}
queue_list << {:state => " ", :client => "host1",  :server => "host2"}
queue_list << {:state => " ", :client => "localhost",  :server => "host2"}
queue_list.each do |queue|
	row = queues_tree.append()
	row[0] = queue[:state]
	row[1] = queue[:client]
	row[2] = queue[:server]
end

queues_view = Gtk::TreeView.new(queues_tree)
columns = ["","Client","Server"]
columns.each_with_index do |column, i|
	renderer = Gtk::CellRendererText.new
	colum = Gtk::TreeViewColumn.new(column, renderer, :text => i)
	colum.resizable = true if i > 0
	queues_view.append_column(colum)
end
scrolled_queues = Gtk::ScrolledWindow.new
scrolled_queues.add(queues_view)
scrolled_queues.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
queues.pack_start queues_top_hbox, false, false, 0
queues.pack_start_defaults(scrolled_queues)
## End Queues

## Tabbed section
tabbed = Gtk::Notebook.new
tabbed.set_size_request(900,400)

queue1_box = Gtk::VBox.new(true, 5)

### Hosts's files
middle_row = Gtk::HBox.new(true, 10)
local_files = Gtk::VBox.new(false, 5)
remote_files = Gtk::VBox.new(false, 5)
#######################
local_tree = Gtk::ListStore.new(String, String, String, String, String, String)
local_top_hbox = Gtk::HBox.new(false, 0)
local_label = Gtk::Label.new
local_label.set_markup("<span size=\"x-large\" weight=\"bold\">Local Files    </span>")
local_top_hbox.pack_start local_label, false, false, 0

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

remote_tree = Gtk::ListStore.new(String, String, String, String, String, String)
remote_top_hbox = Gtk::HBox.new(false, 5)
remote_label = Gtk::Label.new
remote_label.set_markup("<span size=\"x-large\" weight=\"bold\">Remote Files</span>")
remote_top_hbox.pack_start remote_label, false, false, 0

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

middle_row.pack_start local_files, true, true, 0
middle_row.pack_start remote_files, true, true, 0

### Stats and Queue
bottom_row = Gtk::HBox.new(true, 10)
status = Gtk::VBox.new(false, 5)
queue = Gtk::VBox.new(false, 5)

status_top_hbox = Gtk::HBox.new(false, 0)
status_label = Gtk::Label.new
status_label.set_markup("<span size=\"x-large\" weight=\"bold\">Status</span>")
status_options = Gtk::VBox.new(false, 5)

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
state_label = Gtk::Label.new
state_label.set_markup("<span weight=\"bold\">State:</span>")
state = Gtk::Label.new("transferring")

current_stats_bar.pack_start pool_speed_label, false, false, 0
current_stats_bar.pack_start pool_speed, false, false, 0
current_stats_bar.pack_start worker_count_label, false, false, 0
current_stats_bar.pack_start worker_count, false, false, 0
current_stats_bar.pack_start bound_ips_count_label, false, false, 0
current_stats_bar.pack_start bound_ips_count, false, false, 0
current_stats_bar.pack_start state_label, false, false, 0
current_stats_bar.pack_start state, false, false, 0

authenticate_line = Gtk::HBox.new(false, 0)
secret_label = Gtk::Label.new("Secret:")
server_secret_2 = Gtk::Entry.new
re_authenticate_button = Gtk::Button.new("Authenticate")
re_authenticate_button.signal_connect("clicked") {
	# Authenticate
}
auth_status_label = Gtk::Label.new("Authentication status:")
auth_status = Gtk::Label.new("Secure")
authenticate_line.pack_start secret_label, false, false, 0
authenticate_line.pack_start server_secret_2, false, false, 0
authenticate_line.pack_start re_authenticate_button, false, false, 0
authenticate_line.pack_start auth_status_label, false, false, 5
authenticate_line.pack_start auth_status, false, false, 0

buttons_bar = Gtk::HBox.new(false, 0)
pause_button = Gtk::Button.new("Pause")
resume_button = Gtk::Button.new("Resume")
cancel_button = Gtk::Button.new("Cancel Transfer")
disconnect_button = Gtk::Button.new("Disconnect")
buttons_bar.pack_start pause_button, false, false, 0
buttons_bar.pack_start resume_button, false, false, 0
buttons_bar.pack_start cancel_button, false, false, 0
buttons_bar.pack_start disconnect_button, false, false, 0

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
status_options.pack_start buttons_bar, false, false, 0
status_options.pack_start authenticate_line, false, false, 0
status_options.pack_start small_options, false, false, 0
status_options.pack_start change_worker_count, false, false, 0
status_top_hbox.pack_start status_label, false, false, 0
status.pack_start status_top_hbox, false, false, 0
status.pack_start status_options, true, true, 0

queue_files = Gtk::VBox.new(false, 5)
queue_tree = Gtk::ListStore.new(String, String, String, String)
queue_top_hbox = Gtk::HBox.new(false, 5)
queue_label = Gtk::Label.new
queue_label.set_markup("<span size=\"x-large\" weight=\"bold\">Queue</span>")
queue_top_hbox.pack_start queue_label, false, false, 0
files = []
files << {:filename => "file1", :size => "2.0 MB", :direction => "up", :details => "/root/file1 ==> /home/file1"}
files << {:filename => "file2", :size => "18 KB", :direction => "down", :details => "/home/file2 <== /root/file2"}
files << {:filename => "file3", :size => "128 bytes", :direction => "down", :details => "/home/file3 <== /root/file3"}
files.each do |file|
	row = queue_tree.append()
	row[0] = file[:filename]
	row[1] = file[:size]
	row[2] = file[:direction]
	row[3] = file[:details]
end
queue_view = Gtk::TreeView.new(queue_tree)
queue_view.reorderable=true
columns = ["File Name","Size","Direction","Details"]
columns.each_with_index do |column, i|
	renderer = Gtk::CellRendererText.new
	colum = Gtk::TreeViewColumn.new(column, renderer, :text => i)
	colum.resizable = true
	queue_view.append_column(colum)
end
scrolled_queue = Gtk::ScrolledWindow.new
scrolled_queue.add(queue_view)
scrolled_queue.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
queue_files.pack_start queue_top_hbox, false, false, 0
queue_files.pack_start_defaults(scrolled_queue)

bottom_row.pack_start status, true, true, 0
bottom_row.pack_start queue_files, true, true, 0
### tabbed page1

queue1_box.pack_start_defaults middle_row
queue1_box.pack_start_defaults bottom_row

tabbed.append_page(queue1_box, Gtk::Label.new("localhost <--> host1"))
tabbed.append_page(Gtk::VBox.new, Gtk::Label.new("host1 <--> host2"))
## End tabbed section

## Create new vbox for left side
vbox = Gtk::VBox.new(true, 0)
vbox.set_size_request(300,400)
vbox.pack_start hosts, true, true, 0
vbox.pack_start queues, true, true, 0

## Create new hbox for left and tabbed
hbox = Gtk::HBox.new(false, 0)
hbox.pack_start vbox, false, false, 0
hbox.pack_start tabbed, true, true, 0
## Add hbox to window and start GTK
window.add(hbox)
window.show_all
Gtk.main
