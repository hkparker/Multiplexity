class QueueTab
	attr_accessor :queue_tab
	def initialize(client, server, transfer_queue)
		@client = client
		@server = server
		@transfer_queue = transfer_queue
		build_essentials
	end
	
	def build_essentials
		@queue_tab = Gtk::VBox.new(true, 5)
		files_row = Gtk::HBox.new(true, 10)
		client_files = build_client_box
		server_files = build_server_box
		files_row.pack_start client_files, true, true, 0
		files_row.pack_start server_files, true, true, 0
		queue_row = Gtk::HBox.new(true, 10)
		status = build_status_box
		queue = build_queue_box
		queue_row.pack_start status, true, true, 0
		queue_row.pack_start queue, true, true, 0
		@queue_tab.pack_start files_row, true, true, 0
		@queue_tab.pack_start queue_row, true, true, 0
	end
	
	def build_client_box
		client_files = Gtk::VBox.new(false, 5)
		@client_tree = Gtk::ListStore.new(String, String, String, String, String, String)
		client_top_hbox = Gtk::HBox.new(false, 0)
		client_label = Gtk::Label.new
		client_label.set_markup("<span size=\"x-large\" weight=\"bold\">Client Files</span>")
		client_top_hbox.pack_start client_label, false, false, 0
		client_view = Gtk::TreeView.new(@client_tree)
		client_view.reorderable=true
		columns = ["File Name","Path","Size","Type","Last Write","Readable"]
		columns.each_with_index do |column, i|
			renderer = Gtk::CellRendererText.new
			colum = Gtk::TreeViewColumn.new(column, renderer, :text => i)
			colum.resizable = true
			client_view.append_column(colum)
		end
		scrolled_client = Gtk::ScrolledWindow.new
		scrolled_client.add(client_view)
		scrolled_client.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
		client_files.pack_start client_top_hbox, false, false, 0
		client_files.pack_start_defaults(scrolled_client)
		return client_files
	end
	
	def build_server_box
		server_files = Gtk::VBox.new(false, 5)
		@server_tree = Gtk::ListStore.new(String, String, String, String, String, String)
		server_top_hbox = Gtk::HBox.new(false, 5)
		server_label = Gtk::Label.new
		server_label.set_markup("<span size=\"x-large\" weight=\"bold\">Server Files</span>")
		server_top_hbox.pack_start server_label, false, false, 0
		server_view = Gtk::TreeView.new(@server_tree)
		server_view.reorderable=true
		columns = ["File Name","Path","Size","Type","Last Write","Readable"]
		columns.each_with_index do |column, i|
			renderer = Gtk::CellRendererText.new
			colum = Gtk::TreeViewColumn.new(column, renderer, :text => i)
			colum.resizable = true
			server_view.append_column(colum)
		end
		scrolled_server = Gtk::ScrolledWindow.new
		scrolled_server.add(server_view)
		scrolled_server.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
		server_files.pack_start server_top_hbox, false, false, 0
		server_files.pack_start_defaults(scrolled_server)
		return server_files
	end

	def build_status_box
		status = Gtk::VBox.new(false, 5)
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
		return status
	end
	
	def build_queue_box
		queue_files = Gtk::VBox.new(false, 5)
		queue_tree = Gtk::ListStore.new(String, String, String, String)
		queue_top_hbox = Gtk::HBox.new(false, 5)
		queue_label = Gtk::Label.new
		queue_label.set_markup("<span size=\"x-large\" weight=\"bold\">Queue</span>")
		empty_queue = Gtk::Button.new("Empty queue")
		queue_top_hbox.pack_start queue_label, false, false, 0
		queue_top_hbox.pack_start empty_queue, false, false, 0


		# queue files
		#files were inserted here



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
	end

	def update_files(host, host_tree)
		files = host.get_server_files()
		files.each do |file|
			row = host_tree.append()
			row[0] = file[:filename]
			row[1] = file[:path]
			row[2] = file[:size]
			row[3] = file[:type]
			row[4] = file[:last_write]
			row[5] = file[:readable]
		end
	end
end
