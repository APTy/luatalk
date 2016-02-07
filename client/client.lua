local ffi = require('ffi')

local Client = {}
Client.__index = Client
setmetatable(Client, { __call = function(self, ...) return self.new(...) end })

--[[ Return a new UNIX socket Client ]]--
function Client.new()
  local self = setmetatable({}, Client)
  self._on_recv = function() return nil end
  return self
end

--[[ Open a new UNIX socket connection to a server at `sock_path` ]]--
function Client:connect(sock_path)
  --[[ Create a socket ]]--
  self.fd = ffi.C.socket(ffi.C.AF_UNIX, ffi.C.SOCK_STREAM, 0)
  assert(self.fd ~= -1, 'socket(): ' .. ffi.string(ffi.C.strerror(ffi.errno())))

  --[[ Connect to the server ]]--
  local remote_sock = ffi.new('struct sockaddr_un')
  remote_sock.sun_family = ffi.C.AF_UNIX
  remote_sock.sun_path = sock_path
  assert(ffi.C.connect(self.fd, ffi.cast('struct sockaddr *', remote_sock), ffi.sizeof(remote_sock)) ~= 1, 'connect(): ' .. ffi.string(ffi.C.strerror(ffi.errno())))
end

--[[ Send some information ]]--
function Client:send(msg)
  local sent = ffi.C.send(self.fd, msg, ffi.C.strlen(msg), 0)
  assert(sent ~= -1, 'send(): ' .. ffi.string(ffi.C.strerror(ffi.errno())))
end

--[[ User-defined message handler ]]--
function Client:on_recv(fn)
  self._on_recv = fn
end

--[[ Close the connection to the server ]]--
function Client:close()
  ffi.C.close(self.fd)
end

--[[ Interface method for a pollable object ]]--
function Client:_on_poll()
  local chunk_size = 4096
  local buf = ffi.new('char [?]', chunk_size)
  local recv_len = ffi.new('ssize_t')

  repeat
    ffi.C.memset(buf, 0, chunk_size)
    recv_len = ffi.C.recv(self.fd, buf, ffi.new('size_t', chunk_size), 0)

    if recv_len == 0 then
      assert(ffi.C.close(self.fd) ~= -1, 'close()' .. ffi.string(ffi.C.strerror(ffi.errno())))
    else
      assert(recv_len ~= -1, 'recv(): ' .. ffi.string(ffi.C.strerror(ffi.errno())))
      self._on_recv(ffi.string(buf))
    end
  until recv_len < chunk_size
end

return Client
