#!/usr/bin/env ruby

require 'gtk2'

class MultiplexityGTK

	def initialize
		@window = Gtk::Window.new("Multiplexity")
		@window.set_default_size(1300,700)
		@window.signal_connect("destroy") { Gtk.main_quit }
		
	end
	
	def build_essentials
		
	end
	
	def add_host
	
	end
	
	def attch_queue_tab
	
	end
	
end

#MultiplexityGTK.new
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

host_assistant = Gtk::Assistant.new()
host_assistant.signal_connect("close"){
	puts "!"
	host_assistant.main_quit
}
add_host.signal_connect("clicked"){
	host_assistant.show_all()
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
tabbed.set_size_request(1000,500)

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
recycle_sockets = Gtk::CheckButton.new("Recycle sockets")

current_stats_bar.pack_start pool_speed_label, false, false, 0
current_stats_bar.pack_start pool_speed, false, false, 0
current_stats_bar.pack_start worker_count_label, false, false, 0
current_stats_bar.pack_start worker_count, false, false, 0
current_stats_bar.pack_start bound_ips_count_label, false, false, 0
current_stats_bar.pack_start bound_ips_count, false, false, 0
current_stats_bar.pack_start recycle_sockets, false, false, 0



change_chunk_size = Gtk::HBox.new
chunk_number = Gtk::Entry.new
chunk_unit = Gtk::ComboBox.new
chunk_unit.append_text("KB")
chunk_unit.append_text("MB")
chunk_unit.set_active 1
change_chunk_size_button = Gtk::Button.new("Update chunk size")
change_chunk_size_button.signal_connect("clicked"){
	# change chunk size
}

change_chunk_size.pack_start chunk_number, false, false, 0
change_chunk_size.pack_start chunk_unit, false, false, 0
change_chunk_size.pack_start change_chunk_size_button, false, false, 0

messages_top_bar = Gtk::HBox.new(false, 0)
messages_label = Gtk::Label.new
messages_label.set_markup("<span size=\"x-large\" weight=\"bold\">Messages</span>")
messages_top_bar.pack_start messages_label, false, false, 0
messages = Gtk::TextView.new



status_options.pack_start current_file_bar, false, false, 0
status_options.pack_start current_stats_bar, false, false, 0
status_options.pack_start change_chunk_size, false, false, 0
status_top_hbox.pack_start status_label, false, false, 0
status.pack_start status_top_hbox, false, false, 0
status.pack_start status_options, false, false, 0
status.pack_start messages_top_bar, false, false, 0
status.pack_start messages, true, true, 0


# start queue
queue_files = Gtk::VBox.new(false, 5)
queue_tree = Gtk::ListStore.new(String, String, String, String)
queue_top_hbox = Gtk::HBox.new(false, 5)
queue_label = Gtk::Label.new
queue_label.set_markup("<span size=\"x-large\" weight=\"bold\">Queue</span>")
empty_queue = Gtk::Button.new("Empty queue")
queue_top_hbox.pack_start queue_label, false, false, 0
queue_top_hbox.pack_start empty_queue, false, false, 0


# queue files
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
vbox = Gtk::VBox.new(false, 0)
vbox.set_size_request(300,400)
settings = Gtk::Button.new("Settings")
route_help = Gtk::Button.new("Routing help")
vbox.pack_start hosts, true, true, 0
vbox.pack_start queues, true, true, 0
vbox.pack_start settings, false, false, 0
vbox.pack_start route_help, false, false, 0

## Create new hbox for left and tabbed
hbox = Gtk::HBox.new(false, 0)
hbox.pack_start vbox, false, false, 0
hbox.pack_start tabbed, true, true, 0
## Add hbox to window and start GTK
window.add(hbox)
window.show_all
Gtk.main
