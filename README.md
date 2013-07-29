Multiplexity
===========================

The goal of this project is to be able to upload or download a file to/from a server using multiple networking interfaces joined to separate networks while utilizing as much of the avaliable bandwidth on all interfaces as possible.


Current status
--------------

You can download a single file from a server at this point, and while that is working reliably there are still many missing features.  Not really ready for use yet.

Usage
-----

The server is the machine that has a publicly routable IP address, while the client is the machine whos interfaces are behind NAT.  You will be able to (once complete) upload and download from a server.

Requirements
------------

Ruby >= 1.9.1

Todo
----

Clean up code, a lot

Clean up experience (more options for save location, handle duplicate filenames, better exception handling, etc)

File uploads

Auto detect filewall and adjust syntax (support ipfw, pfctl, etc).  Better system for adding firewall modules.

Directory transfers

SSL sockets for everything

Switch many options to command line flags

License
-------

This project is licensed under the MIT license, please see LICENSE.md for more information.

Contact
-------

Please feel free to contact me at haydenkparker@gmail.com
