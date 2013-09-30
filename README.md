Multiplexity
============

Multiplexity is an inverse multiplexer for file transfers.  It can be used on one network with multiplex sockets, or over multiple networks.  Files are split into chunks that are asynchronously transfered over threaded workers, which can be added and removed mid transfer.  Chunk size can also be adjusted, as well as chunk CRC verification.  Multiplexity also supports optionally closing then reopening multiplex sockets after each chunk, which can improve performance on networks that use some implementations of traffic shaping / throttling.

Current status
--------------

Currently finishing the API, then going to finish the CLI, and lastly a GTK client is in the works.

Usage
-----


Examples
--------


Files
-----


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
