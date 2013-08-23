Multiplexity
===========================

The goal of this project is to be able to upload or download a file to/from a server using multiple networking interfaces joined to separate networks while utilizing as much of the avaliable bandwidth on all interfaces as possible.


Current status
--------------

You can download a single file from a server at this point, and while that is working reliably there are still many missing features.  Finishing the basic functionallity and cleaning up code now.

Usage
-----

The server is the machine that has a publicly routable IP address, while the client is the machine whos interfaces are behind NAT.  You will be able to (once complete) upload and download from a server.

Requirements
------------

Ruby >= 1.9.1

Todo
----

Clean up code / finish basic features

Directory downloads

File/directory uploads

More firewall support

SSL sockets for everything

License
-------

This project is licensed under the MIT license, please see LICENSE.md for more information.

Contact
-------

Please feel free to contact me at haydenkparker@gmail.com
