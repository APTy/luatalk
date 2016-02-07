# luatalk

Interprocess communication over UNIX domain sockets with LuaJIT. The following is a simple example of how to start a server and send it a message from a client:

``` lua
-- server.lua
local server = require('init').SocketServer()

server:on_recv(function(fd, msg)
  print('Received this message: ' .. msg)
end)

server:listen('/tmp/demo')
```

``` lua
-- client.lua
local client = require('init').Client()
client:connect('/tmp/demo')
client:send('Groovy!')
```

And just like that, you're communicating from one process to another!

```
$ luajit server.lua &
$ luajit client.lua
Received this message: Groovy!
```

Note: to run in any other directory, you'll need to add this repo's root folder into your `LUA_PATH`:

```
$ cd luatalk
$ export LUA_PATH=$LUA_PATH\;`pwd`/?.lua
```

## Server

The `SocketServer` manages the sending and receiving of data to and from its `Connection`s. It provides the following API to achieve that goal:

#### listen(socket_path)
Starts to listen for connections on the specified `socket_path` (e.g. `/tmp/mysocket`).

#### send(client, message)
Sends a message to the specified client.

#### broadcast(message)
Broadcasts a message to all connected clients.

#### on_recv(callback)
Accepts a function to be called any time data is received from a client. The callback is passed two parameters: the client's id and the message that it sent (e.g. `callback(3, 'hello!')`).

#### close()
Closes the connection to all existing clients, as well as the master `listen` descriptor.

#### connections
Table that contains a list of all `Connection`s, keyed by file descriptor.


## Client

The `SocketClient` provides a simple API for connecting, sending messages, and receiving messages from a `SocketServer`.

#### connect(socket_path)
Connects to a server listening on on the `socket_path` (e.g. `/tmp/mysocket`).

#### send(message)
Sends a message to the server.

#### on_recv(callback)
Accepts a function to be called any time data is received from the server. The callback is passed the message that was received (e.g. `callback('hello!')`).

#### close()
Closes the connection to the server.


## Poller

The `Poller` offers synchronous I/O multiplexing capability. Objects wishing to take advantage of its poll loop should implement the `pollable` pseudo-interface.

#### add(fd)
Add a file descriptor to the main poll loop.

#### remove(fd)
Remove a file descriptor from the main poll loop.

#### poll(fd)
Run the main poll loop, which will execute and block indefinitely.

#### Pollable Interface
- **fd** - property that defines the file descriptor that `Poller` will examine.
- **_on_poll()** - a method that defines the behavior that should be taken when the file descriptor is ready.
