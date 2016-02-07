local ffi = require('ffi')

local Connection = {}
Connection.__index = Connection
setmetatable(Connection, { __call = function(self, ...) return self.new(...) end })

--[[ Return a new Connection ]]--
function Connection.new(fd)
  local self = setmetatable({}, Connection)
  self._on_recv = function() return nil end
  self.fd = fd  -- Interface property for a pollable object
  return self
end

--[[ Interface method for a pollable object ]]--
function Connection:_on_poll()
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

--[[ User-defined message handler ]]--
function Connection:on_recv(fn)
  self._on_recv = fn
end

return Connection
