Multiplexity
===========================

Multiplexity is an application designed to transfer files and directories over multiple sockets, network interfaces, and networks.  The original goal was to transfer files using multiple networking interfaces joined to separate networks while utilizing as much of the avaliable bandwidth as possible.  In testing, however, it became clear that even on a single network using multiple sockets to transfer smaller chunks of a file could improve performance due to some implementations of traffic shaping / throttling.


Current status
--------------

I'm changing a lot of code to simplify the API and make creating user interfaces / scripts easier to write.  I am also working on a gtk client.

Usage
-----



Examples
--------

Todo
----

Re-write downloader workers
online addition and subtraction of workers
online chunk resize


Requirements
------------

Ruby >= 1.9.1

rpam (http://rpam.rubyforge.org/) required for server when PAM authentication is used


License
-------

This project is licensed under the MIT license, please see LICENSE.md for more information.

Contact
-------

Please feel free to contact me at haydenkparker@gmail.com
