Multiplexing file transfers
===========================

The goal of this project is to be able to download a file from a server using sockets on multiple networking interfaces and networks while utilizing as much of the avaliable bandwidth on the interfaces as possible.

Design
------

The current design involves threaded downloader workers that grab the next chunk from the server though their assigned sockets.  Each worker is assigned a socket bound to a different IP address representing each interface.  The downloaded chunks are placed into a buffer data structure that sorts them and dumps any consecutive chunks into the file as they become avaliable.


Current status
--------------

Routing issue solved, re-writing much of it to be more OO.

Usage
-----


License
-------

This project is licensed under the MIT license, please see LICENSE.md for more information.

Contact
-------

Please feel free to contact me at haydenkparker@gmail.com
