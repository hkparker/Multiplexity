#!/usr/bin/env ruby

require 'gtk2'
require 'resolv'
require './lib/queue_tab.rb'
require './lib/transfer_queue.rb'
require './lib/host.rb'
require './lib/imux_config.rb'

class MultiplexityGTK

	def initialize
		@host_objects = []
		@queue_objects = []
		@tabs = []
		build_essentials
		@window.show_all
		Gtk.main
	end
	
	def build_essentials
		@window = Gtk::Window.new("Multiplexity")
		@window.set_default_size(1300,700)
		@window.signal_connect("destroy") { Gtk.main_quit }
		build_hosts
		add_host(Localhost.new())
		build_queues
		@tabbed = Gtk::Notebook.new
		@tabbed.set_size_request(1000,500)
		vbox = Gtk::VBox.new(false, 0)
		vbox.set_size_request(300,400)
		settings = Gtk::Button.new("Settings")
		route_help = Gtk::Button.new("Routing help")
		vbox.pack_start @hosts, true, true, 0
		vbox.pack_start @queues, true, true, 0
		vbox.pack_start settings, false, false, 0
		vbox.pack_start route_help, false, false, 0
		hbox = Gtk::HBox.new(false, 0)
		hbox.pack_start vbox, false, false, 0
		hbox.pack_start @tabbed, true, true, 0
		@window.add(hbox)
		#attach_queue_tab
	end
	
	def build_hosts
		@hosts = Gtk::VBox.new(false, 5)
		@hosts_top_hbox = Gtk::HBox.new(false, 0)
		@hosts_label = Gtk::Label.new
		@hosts_label.set_markup("<span size=\"x-large\" weight=\"bold\">Hosts</span>")
		@hosts_filler = Gtk::HBox.new(true, 0)
		@add_host = Gtk::Button.new("+")
		
		@add_host.signal_connect("clicked"){
			ask_for_a_host
		}

		@hosts_tree = Gtk::ListStore.new(String, String)
		@hosts_view = Gtk::TreeView.new(@hosts_tree)
		columns = ["","Hostname"]
		columns.each_with_index do |column, i|
			renderer = Gtk::CellRendererText.new
			colum = Gtk::TreeViewColumn.new(column, renderer, :text => i)
			@hosts_view.append_column(colum)
		end

		@rclick_host_menu = Gtk::Menu.new
		@host_connect_item = Gtk::MenuItem.new("Connect")
		@host_connect_item.signal_connect("activate") {
			puts "connect"
		}
		@host_disconnect_item = Gtk::MenuItem.new("Disconnect")
		@host_disconnect_item.signal_connect("activate") {
			puts "disconnect"
		}
		@host_remove_item = Gtk::MenuItem.new("Remove")
		@host_remove_item.signal_connect("activate") {
			puts "remove"
		}
		@rclick_host_menu.append(@host_connect_item)
		@rclick_host_menu.append(@host_disconnect_item)
		@rclick_host_menu.append(@host_remove_item)
		@rclick_host_menu.show_all
		@hosts_view.signal_connect("button_press_event") do |widget, event|
			@rclick_host_menu.popup(nil, nil, event.button, event.time) if event.kind_of? Gdk::EventButton and event.button == 3
		end

		@scrolled_hosts = Gtk::ScrolledWindow.new
		@scrolled_hosts.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)

		@hosts_top_hbox.pack_start @hosts_label, false, false, 0
		@hosts_top_hbox.pack_start @hosts_filler, true, true, 0
		@hosts_top_hbox.pack_start @add_host, false, false, 0
		@scrolled_hosts.add(@hosts_view)
		@hosts.pack_start @hosts_top_hbox, false, false, 0
		@hosts.pack_start @scrolled_hosts, true, true, 0
	end
	
	def add_host(host)
		@host_objects << host
		row = @hosts_tree.append()
		row[0] = ""
		row[1] = host.hostname
	end
	
	def remove_host(host)
		@hosts.delete(host)
		# remove from view
	end
	
	def build_queues
		@queues = Gtk::VBox.new(false, 5)
		@queues_top_hbox = Gtk::HBox.new(false, 0)
		@queues_label = Gtk::Label.new
		@queues_label.set_markup("<span size=\"x-large\" weight=\"bold\">Queues</span>")
		@add_queue = Gtk::Button.new("+")
		@add_queue.signal_connect("clicked"){
			build_a_queue
		}
		@queue_filler = Gtk::HBox.new(true, 0)
		
		@queues_tree = Gtk::ListStore.new(String, String, String)
		@queues_view = Gtk::TreeView.new(@queues_tree)
		@columns = ["","Client","Server"]
		@columns.each_with_index do |column, i|
			renderer = Gtk::CellRendererText.new
			colum = Gtk::TreeViewColumn.new(column, renderer, :text => i)
			colum.resizable = true if i > 0
			@queues_view.append_column(colum)
		end
		
		@scrolled_queues = Gtk::ScrolledWindow.new
		@scrolled_queues.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)

		@queues_top_hbox.pack_start @queues_label, false, false, 0
		@queues_top_hbox.pack_start @queue_filler, true, true, 0
		@queues_top_hbox.pack_start @add_queue, false, false, 0
		@scrolled_queues.add(@queues_view)
		@queues.pack_start @queues_top_hbox, false, false, 0
		@queues.pack_start @scrolled_queues, true, true, 0
	end
	
	def add_queue(queue)
		@queue_objects << queue
		row = @queues_tree.append()
		row[0] = queue[:state]
		row[1] = queue[:hostname]
	end
	
	def attach_queue_tab(client, server, transfer_queue)
		tab = QueueTab.new(client, server, transfer_queue)
		@tabs << tab
		page = tab.queue_tab
		page.show_all
		@tabbed.append_page(page, Gtk::Label.new("#{client.hostname} <-> #{server.hostname}"))
	end
	
	def ask_for_a_host
		add_host_box = Gtk::Dialog.new("New Host")
		add_host_box.signal_connect('response') { add_host_box.destroy }

		vbox = Gtk::VBox.new(false, 0)
		hostname_port_line = Gtk::HBox.new(false, 5)
		hostname_label = Gtk::Label.new("Hostname: ")
		hostname_entry = Gtk::Entry.new()
		port_label = Gtk::Label.new("Port: ")
		port_entry = Gtk::Entry.new()
		port_entry.width_chars = 5
		port_entry.set_text("8000")
		pass_connect_line = Gtk::HBox.new(false, 5)
		password_label = Gtk::Label.new("Password: ")
		password_entry = Gtk::Entry.new()
		connect_button = Gtk::Button.new("Connect")
		hostname_port_line.pack_start hostname_label, false, false, 0
		hostname_port_line.pack_start hostname_entry, true, true, 0
		hostname_port_line.pack_start port_label, false, false, 0
		hostname_port_line.pack_start port_entry, false, false, 0
		pass_connect_line.pack_start password_label, false, false, 0
		pass_connect_line.pack_start password_entry, false, false, 0
		pass_connect_line.pack_start connect_button, true, true, 0
		
		connect_button.signal_connect("clicked") {
			error = attempt_to_connect(hostname_entry.text, port_entry.text, password_entry.text)
			if error != nil
				dialog = Gtk::MessageDialog.new($main_application_window, 
									Gtk::Dialog::DESTROY_WITH_PARENT,
									Gtk::MessageDialog::QUESTION,
									Gtk::MessageDialog::BUTTONS_CLOSE,
									"Could not connect to host: #{error}")
				dialog.run
				dialog.destroy
			else
				add_host_box.destroy
			end
		}
		
		vbox.pack_start hostname_port_line, false, false, 5
		vbox.pack_start pass_connect_line, false, false, 5
		add_host_box.vbox.add(vbox)
		add_host_box.show_all	
	end

	def build_ip_config_line
		line = Gtk::HBox.new(false, 5)
		ip_entry = Gtk::Entry.new
		ip_entry.width_chars=3
		ip_label = Gtk::Label.new("IPs")
		bound = Gtk::CheckButton.new("Bound")
		bind_ip = Gtk::Entry.new
		bound.signal_connect("toggeled") {
			bin_ip.set_sensitive !bind_ip.sensitive?
		}
		bin_ip.set_sensitive = false
		line.pack_start ip_entry, false, false, 0
		line.pack_start ip_label, false, false, 0
		line.pack_start bound, false, false, 0
		line.pack_start bind_ip, true, true, 0
		return line
	end

	def build_a_queue
		add_queue_box = Gtk::Dialog.new("New queue")
		add_queue_box.signal_connect('response') { add_queue_box.destroy }

		vbox = Gtk::VBox.new(false, 5)
		
		host_section = Gtk::VBox.new(false, 5)
		host_selection_label = Gtk::Label.new()
		host_selection_label.set_markup("<span size=\"x-large\" weight=\"bold\">Select hosts</span>")
		host_selection_line = Gtk::HBox.new(false, 5)
		client_label = Gtk::Label.new("Client: ")
		client_selection = Gtk::ComboBox.new()
		@host_objects.each do |host|
			client_selection.append_text host.hostname
		end
		server_label = Gtk::Label.new("Server: ")
		server_selection = Gtk::ComboBox.new()
		@host_objects.each do |host|
			server_selection.append_text host.hostname
		end
		host_selection_line.pack_start client_label, false, false, 0
		host_selection_line.pack_start client_selection, true, true, 0
		host_selection_line.pack_start server_label, false, false, 0
		host_selection_line.pack_start server_selection, true, true, 0
		host_section.pack_start host_selection_label, false, false, 0
		host_section.pack_start host_selection_line, false, false, 0
		
		imux_section = Gtk::VBox.new(false, 0)
		imux_section_label = Gtk::Label.new()
		imux_section_label.set_markup("<span size=\"x-large\" weight=\"bold\">IMUX Settings</span>")
		bound_ip_box = Gtk::VBox.new(false, 0)
		add_ip_button = Gtk::Button.new("Add another IP")
		add_ip_button.signal_connect("clicked"){
			bound_ip_box.pack_start build_ip_config_line.show_all, false, false, 0
		}
		
		imux_section.pack_start imux_section_label, false, false, 0
		imux_section.pack_start bound_ip_box, true, true, 0
		imux_section.pack_start add_ip_button, false, false, 0

		create_button = Gtk::Button.new("Create queue")
		create_button.signal_connect("clicked"){
			client = nil
			server = nil
			transfer_queue = nil
			@host_objects.each do |host|
				client = host if host.hostname == client_selection.active_text
				server = host if host.hostname == server_selection.active_text
			end
			if server == nil || client == nil
				dialog = Gtk::MessageDialog.new($main_application_window, 
									Gtk::Dialog::DESTROY_WITH_PARENT,
									Gtk::MessageDialog::QUESTION,
									Gtk::MessageDialog::BUTTONS_CLOSE,
									"Please select both a server and a client.")
				dialog.run
				dialog.destroy
				break
			end
			imux_config = IMUXConfig.new()	# ok so actually parse the input and make this object
			transfer_queue = TransferQueue.new(client, server, imux_config)
			Thread.new{ loop{ puts transfer_queue.message_queue.pop } }
			if !transfer_queue.opened
				dialog = Gtk::MessageDialog.new($main_application_window, 
									Gtk::Dialog::DESTROY_WITH_PARENT,
									Gtk::MessageDialog::QUESTION,
									Gtk::MessageDialog::BUTTONS_CLOSE,
									"The transfer queue could not be built correctly.  See the messages box for more information.")
				dialog.run
				dialog.destroy
				break
			end
			attach_queue_tab(client, server, transfer_queue)
		}
		
		vbox.pack_start host_section, false, false, 0
		vbox.pack_start imux_section, false, false, 0
		vbox.pack_start create_button, false, false, 0
		add_queue_box.vbox.add(vbox)
		add_queue_box.show_all	
	end
	
	def attempt_to_connect(hostname, port, password)
		begin
			port = port.to_i
		rescue
			return "port is not an integer"
		end
		host = Host.new(hostname, port, password)
		error = host.handshake
		return error if error != nil
		add_host(host)
		return nil
	end
end

MultiplexityGTK.new
