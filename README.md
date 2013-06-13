Multiplexing file transfers
===========================

The goal of this project is to be able to download a file from a server using sockets on multiple networking interfaces and networks while utilizing as much of the avaliable bandwidth on the interfaces as possible.

Design
------

The current design involves threaded downloader workers that grab the next chunk from the server though their assigned sockets.  Each worker is assigned a socket bound to a different IP address representing each interface.  The downloaded chunks are placed into a buffer data structure that sorts them and dumps any consecutive chunks into the file as they become avaliable.


Current status
--------------

Having routing problems.

My "server.rb" and "client.rb" files will probably be rewritten once I get everything to work to be a bit better designed.  The @@control_socket is my way of negotiating between the server and client.  My current workflow is to run ./server on the server and ./client on the client, with the server ip and interface ips written into the client for now.

Usage
-----


License
-------

This project is licensed under the MIT license, please see LICENSE.md for more information.

Contact
-------

Please feel free to contact me at haydenkparker@gmail.com
