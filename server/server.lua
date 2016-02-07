local ffi = require('ffi')
local Poller = require('lib/poller')
local Connection = require('server/connection')

local SocketServer = {}
SocketServer.__index = SocketServer
setmetatable(SocketServer, { __call = function(self, ...) return self.new(...) end })

--[[ Return a new UNIX socket SocketServer ]]--
function SocketServer.new(params)
  local self = setmetatable({}, SocketServer)

  params = params or {}
  self.connection_backlog = params.connection_backlog or 10
  self.poller = Poller()
  self._on_recv = function() return nil end
  self.connections = {}

  return self
end

--[[ Listen an accept UNIX socket connects ]]--
function SocketServer:listen(sock_path)
  local local_sock = ffi.new('struct sockaddr_un')

  --[[ Create a new socket ]]--
  self.fd = ffi.C.socket(ffi.C.AF_UNIX, ffi.C.SOCK_STREAM, 0)
  assert(self.fd ~= -1, 'socket(): ' .. ffi.string(ffi.C.strerror(ffi.errno())))
  self.poller:add(self)

  --[[ Bind to the socket file ]]--
  local_sock.sun_family = ffi.C.AF_UNIX
  local_sock.sun_path = sock_path
  unlink = ffi.C.unlink(sock_path)
  assert(ffi.C.bind(self.fd, ffi.cast('struct sockaddr *', local_sock), ffi.sizeof(local_sock)) ~= -1, 'bind(): ' .. ffi.string(ffi.C.strerror(ffi.errno())))

  --[[ Listen on the socket descriptor ]]--
  assert(ffi.C.listen(self.fd, self.connection_backlog) ~= -1, 'listen(): ' .. ffi.string(ffi.C.strerror(ffi.errno())))

  --[[ Poll for new connections or received data ]]--
  self.poller:poll()
end

--[[ Send a string to the specified connection ]]--
function SocketServer:send(fd, msg)
  sent = ffi.C.send(fd, msg, #msg, 0)
  assert(sent ~= -1, 'send(): ' .. ffi.string(ffi.C.strerror(ffi.errno())))
end

--[[ Broadcast a message to all connections ]]--
function SocketServer:broadcast(msg)
  local sent
  for fd, connection in pairs(self.connections) do
    sent = ffi.C.send(fd, msg, #msg, 0)
    assert(sent ~= -1, 'send(): ' .. ffi.string(ffi.C.strerror(ffi.errno())))
  end
end

--[[ User-defined message handler ]]--
function SocketServer:on_recv(fn)
  self._on_recv = fn
end

--[[ Close all socket connections ]]--
function SocketServer:close()
  for i, fd in ipairs(self.connections) do
    ffi.C.close(fd)
  end
  ffi.C.close(self.fd)
end

--[[ Interface method for a pollable object ]]--
function SocketServer:_on_poll()
  local remote_sock = ffi.new('struct sockaddr_un')
  local remote_len = ffi.new("int32_t[1]")
  local cfd = ffi.C.accept(self.fd, ffi.cast('struct sockaddr *', remote_sock), remote_len)
  assert(cfd ~= -1, 'accept(): ' .. ffi.string(ffi.C.strerror(ffi.errno())))

  --[[ Create a new Connection and add it to the SocketServer's Poller ]]--
  local connection = Connection(cfd)
  connection:on_recv(function(msg)
    self._on_recv(cfd, msg)
  end)
  self.poller:add(connection)
  self.connections[cfd] = connection
end

return SocketServer
