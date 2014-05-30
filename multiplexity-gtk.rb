#!/usr/bin/env ruby

require 'gtk2'
require './lib/queue_tab.rb'

class MultiplexityGTK

	def initialize
		build_essentials
		@window.show_all
		Gtk.main
	end
	
	def build_essentials
		@window = Gtk::Window.new("Multiplexity")
		@window.set_default_size(1300,700)
		@window.signal_connect("destroy") { Gtk.main_quit }
		build_hosts
		add_host_view({:state => " ", :hostname => "localhost"})
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
		attach_queue_tab
	end
	
	def build_hosts
		@hosts = Gtk::VBox.new(false, 5)
		@hosts_top_hbox = Gtk::HBox.new(false, 0)
		@hosts_label = Gtk::Label.new
		@hosts_label.set_markup("<span size=\"x-large\" weight=\"bold\">Hosts</span>")
		@hosts_filler = Gtk::HBox.new(true, 0)
		@add_host = Gtk::Button.new("+")
		
		@add_host.signal_connect("clicked"){
			# start the assistent
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
	
	def add_host_view(host)
		row = @hosts_tree.append()
		row[0] = host[:state]
		row[1] = host[:hostname]
	end
	
	def build_queues
		@queues = Gtk::VBox.new(false, 5)
		@queues_top_hbox = Gtk::HBox.new(false, 0)
		@queues_label = Gtk::Label.new
		@queues_label.set_markup("<span size=\"x-large\" weight=\"bold\">Queues</span>")
		@add_queue = Gtk::Button.new("+")
		@add_queue.signal_connect("clicked"){
			# Add a queue
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
	
	def add_queue_view(queue)
		row = @queues_tree.append()
		row[0] = queue[:state]
		row[1] = queue[:hostname]
	end
	
	def attach_queue_tab
		@tabbed.append_page(QueueTab.new.queue_tab, Gtk::Label.new("a <-> b"))
	end
	
end

MultiplexityGTK.new
