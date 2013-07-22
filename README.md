Multiplexity
===========================

The goal of this project is to be able to upload or download a file to/from a server using multiple networking interfaces joined to separate networks while utilizing as much of the avaliable bandwidth on all interfaces as possible.


Current status
--------------

All the PoC stuff is done, just need to put it together.  At this point expect everything to be completely non-functional, I'm hoping to have useful code in about a month.

Usage
-----

The server is the machine that has a publicly routable IP address, while the client is the machine whos interfaces are behind NAT.  You will be able to (once complete) upload and download from a server.

Requirements
------------

Ruby >= 1.9.1

Todo
----

More options for save location, handle duplicate filenames

File uploads

Directory transfers

SSL sockets for everything

Switch many options to command line flags

License
-------

This project is licensed under the MIT license, please see LICENSE.md for more information.

Contact
-------

Please feel free to contact me at haydenkparker@gmail.com
