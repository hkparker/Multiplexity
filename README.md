Multiplexity
============

Multiplexity is an inverse multiplexer for file transfers.  Files are split into chunks that are inverse multiplexed over TCP sockets.  These sockets can exist on an arbitrary number of networks and each network and have an arbitrary number of sockets.  Using multiple sockets on a single network can improve performance and evade some implementations of traffic shaping / throttling while using multiple networks allows one to maximize bandwidth consumption on each network.  Multiplexity supports a number of other options as well, including adding more sockets mid transfer, CRC verificatin of each chunk, resetting each connection after each chunk, and changing the chunk size.

Current status
--------------

Ruby has given me scaling and threading issues that are difficult to track down.  While downloads are currently working well, I will likely be using either C or Go to write a production version after I'm done prototyping.

Multiplexity API
----------------

Multiplexity has host objects.  When you connect to a host you open a single control socket to a multiplexity server, with which you can get information and send commands.  There is a special host for localhost.

    my_server = Host.new(hostname,username,password)
    localhost = Localhost.new

Between two hosts you can build a queue.  When you build a queue you setup inverse multiplexing between the hosts.  An IMUXConfig object stores information on how to set it up.  You can then use this queue to send files.

    imux_config = IMUXConfig.new
    queue = Queue.new(localhost,my_server,imux_config)
    queue.transfer_file(localhost,my_server,filename )

The first host passed into the Queue constructor is the host that opens the TCP sockets (useful if one client is behind NAT).  The first host passed in transfer_file is the source of the file.

License
-------

This project is licensed under the MIT license, please see LICENSE.md for more information.

Contact
-------

Please feel free to contact me at haydenkparker@gmail.com
