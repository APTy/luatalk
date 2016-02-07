local luatalk = require('init')
local server = luatalk.SocketServer()

server:on_recv(function(fd, msg)
  print(string.format('User %d says: %s', fd, msg))
  server:broadcast(msg)
end)

server:listen('/tmp/talkie')
