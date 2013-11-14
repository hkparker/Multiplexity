Multiplexity
============

Multiplexity is an inverse multiplexer for file transfers.  Files are split into chunks that are inverse multiplexed over TCP sockets.  These sockets can exist on an arbitrary number of networks and each network and have an arbitrary number of sockets.  Using multiple sockets on a single network can improve performance and evade some implementations of traffic shaping / throttling while using multiple networks allows one to maximize bandwidth consumption on each network.  Multiplexity supports a number of other options as well, including adding more sockets mid transfer, CRC verificatin of each chunk, resetting each connection after each chunk, and changing the chunk size.

Current status
--------------

Ruby has given me scaling and threading issues that are difficult to track down.  While downloads are currently working well, I will likely be using either C or Go to write a production version after I'm done prototyping.

License
-------

This project is licensed under the MIT license, please see LICENSE.md for more information.

Contact
-------

Please feel free to contact me at haydenkparker@gmail.com
