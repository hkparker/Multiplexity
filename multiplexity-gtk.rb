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
top_row = Gtk::HBox.new(true, 0)

### Settings side

settings_left = Gtk::HBox.new(false, 0)
settings_right = Gtk::VBox.new(true, 0)

labels = Gtk::VBox.new(true, 0)
server_label = Gtk::Label.new("Server: ", true)
port_label = Gtk::Label.new("Port: ", true)
multiplex_port_label = Gtk::Label.new("Multiplex Port: ", true)
chunk_size_label = Gtk::Label.new("Chunk Size: ", true)
socket_count_label = Gtk::Label.new("Sockets/IP: ", true)
labels.pack_start server_label, true, true, 0
labels.pack_start port_label, true, true, 0
labels.pack_start multiplex_port_label, true, true, 0
labels.pack_start chunk_size_label, true, true, 0
labels.pack_start socket_count_label, true, true, 0

inputs = Gtk::VBox.new(true, 0)
server_ip = Gtk::Entry.new
server_port = Gtk::Entry.new
multiplex_port = Gtk::Entry.new
chunk_size = Gtk::Entry.new
chunk_unit = Gtk::ComboBox.new
chunk_unit.append_text("KB")
chunk_unit.append_text("MB")
chunk_unit.active = 1
socket_count = Gtk::Entry.new
inputs.pack_start server_ip, true, true, 0
inputs.pack_start server_port, true, true, 0
inputs.pack_start multiplex_port, true, true, 0
chunk_box = Gtk::HBox.new
chunk_box.pack_start chunk_size, true, true, 0
chunk_box.pack_start chunk_unit, true, true, 0
inputs.pack_start chunk_box, true, true, 0
inputs.pack_start socket_count, true, true, 0

settings_left.pack_start labels, true, true, 0
settings_left.pack_start inputs, true, true, 0
#settings_left.set_size_request(400, 200)
###



network_mode = Gtk::CheckButton.new("I would like to use multiple networks")
network_mode.signal_connect("clicked") {

}

bind_ip_box = Gtk::HBox.new(false, 0)
bind_ips_label = Gtk::Label.new("Bind IPs: ", true)
bind_ips = Gtk::Entry.new
bind_ip_box.pack_start bind_ips_label, false, false, 0
bind_ip_box.pack_start bind_ips, true, true, 0

small_opts = Gtk::HBox.new(true, 0)
verify = Gtk::CheckButton.new("CRC verify chunks")
recycle = Gtk::CheckButton.new("Recycle sockets")
small_opts.pack_start verify, true, true, 0
small_opts.pack_start recycle, true, true, 0

log_box = Gtk::HBox.new(false, 0)
log_option = Gtk::CheckButton.new("Log messages")
log_file = Gtk::Entry.new
log_box.pack_start log_option, false, false, 0
log_box.pack_start log_file, true, true, 0

connect_button = Gtk::Button.new("Connect")
connect_button.signal_connect("clicked") {

}

settings_right.pack_start network_mode, true, true, 0
settings_right.pack_start bind_ip_box, true, true, 0
settings_right.pack_start small_opts, true, true, 0
settings_right.pack_start log_box, true, true, 0
settings_right.pack_start connect_button, true, true, 0

top_options = Gtk::HBox.new(true, 0)
top_label = Gtk::VBox.new(true, 0)
top_input = Gtk::VBox.new(true, 0)

top_options.pack_start top_label, true, true, 0
top_options.pack_start top_input, true, true, 0

#######################

settings = Gtk::HBox.new(true, 0)
settings.pack_start settings_left, false, false, 0
settings.pack_start settings_right, false, false, 0







### route and messages
right_side = Gtk::HBox.new(true, 0)
route_setup = Gtk::VBox.new(true, 0)
messages = Gtk::VBox.new(true, 0)

#######################
image2 = Gtk::Button.new
route_setup.pack_start image2, true, true, 0
image3 = Gtk::Button.new
messages.pack_start image3, true, true, 0
#######################

right_side.pack_start route_setup, true, true, 0
right_side.pack_start messages, true, true, 0

top_row.pack_start settings, true, true, 0
top_row.pack_start right_side, true, true, 0

### End top row


### Middle Row
middle_row = Gtk::HBox.new(true, 0)
local_files = Gtk::VBox.new(true, 0)
remote_files = Gtk::VBox.new(true, 0)
#######################
image4 = Gtk::Button.new
local_files.pack_start image4, true, true, 0
image5 = Gtk::Button.new
remote_files.pack_start image5, true, true, 0
#######################
middle_row.pack_start local_files, true, true, 0
middle_row.pack_start remote_files, true, true, 0


### Bottom Row
bottom_row = Gtk::HBox.new(false, 0)
status = Gtk::VBox.new(true, 0)
queue = Gtk::VBox.new(true, 0)
#######################
image7 = Gtk::Button.new
status.pack_start image7, true, true, 0
image8 = Gtk::Button.new
queue.pack_start image8, true, true, 0
#######################
bottom_row.pack_start status, true, true, 0
bottom_row.pack_start queue, true, true, 0


all_rows = Gtk::VBox.new(false, 0)
all_rows.pack_start top_row, false, false, 0
all_rows.pack_start middle_row, true, true, 0
all_rows.pack_start bottom_row, true, true, 0

multiplexity.add(all_rows)
multiplexity.show_all
Gtk.main
