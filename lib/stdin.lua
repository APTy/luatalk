local ffi = require('ffi')

local StdinReader = {}
StdinReader.__index = StdinReader
setmetatable(StdinReader, { __call = function(self, ...) return self.new(...) end })

--[[ Return a new StdinReader ]]--
function StdinReader.new()
  local self = setmetatable({}, StdinReader)
  self._on_read = function() return nil end
  self.fd = ffi.C.STDIN  -- Interface property for a pollable object
  return self
end

--[[ Interface method for a pollable object ]]--
function StdinReader:_on_poll()
  local chunk_size = 4096
  local buf = ffi.new('char [?]', chunk_size)
  local read = ffi.C.read(self.fd, buf, chunk_size)
  assert(read ~= -1, 'read(): ' .. ffi.string(ffi.C.strerror(ffi.errno())))
  self._on_read(ffi.string(buf, read - 1))
end

--[[ User-defined message handler ]]--
function StdinReader:on_read(fn)
  self._on_read = fn
end

return StdinReader
