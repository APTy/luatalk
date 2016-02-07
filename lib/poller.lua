local ffi = require('ffi')
local bit = require('bit')

local Poller = {}
Poller.__index = Poller
setmetatable(Poller, { __call = function(self, ...) return self.new(...) end })

--[[ Return a new Poller ]]--
function Poller.new(num_fds)
  local self = setmetatable({}, Poller)
  self.num_fds = 0
  self.pollables = {}
  self.fds = ffi.new('struct pollfd[?]', num_fds or 20)
  return self
end

--[[ Add a new pollable object that has a `fd` property and `_on_poll()` method ]]--
function Poller:add(obj)
  self.pollables[obj.fd] = obj
  self.fds[self.num_fds].fd = obj.fd
  self.fds[self.num_fds].events = ffi.C.POLLIN
  self.num_fds = self.num_fds + 1
end

--[[ Remove a file descriptor from being polled ]]--
function Poller:remove(fd)
  -- Decrement the number of fds
  self.num_fds = self.num_fds - 1

  -- Find the index of the fd in the `pollfd` struct array
  local index
  for i = 0, self.num_fds do
    if self.fds[i].fd == fd then index = i break end
  end

  -- If the removed fd is not last in the list, move the last one to its now `empty` spot
  if index and index ~= self.num_fds then
    self.fds[index].fd = self.fds[self.num_fds].fd
    self.fds[index].events = self.fds[self.num_fds].events
  end
end

--[[ Run the poll loop ]]--
function Poller:poll()
  while true do
    assert(ffi.C.poll(self.fds, self.num_fds, ffi.C.POLL_INDEF) ~= -1, 'poll(): ' .. ffi.string(ffi.C.strerror(ffi.errno())))

    for i = 0, self.num_fds - 1 do
      --[[ Check if the file descriptor is ready ]]--
      if bit.band(self.fds[i].revents, ffi.C.POLLIN) == ffi.C.POLLIN then
        self.pollables[self.fds[i].fd]:_on_poll()
      end

      --[[ Check for any unexpected file descriptor errors ]]--
      if bit.band(self.fds[i].revents, ffi.C.POLLERR) == ffi.C.POLLERR then
        self:remove(self.fds[i].fd)
      elseif bit.band(self.fds[i].revents, ffi.C.POLLHUP) == ffi.C.POLLHUP then
        self:remove(self.fds[i].fd)
      elseif bit.band(self.fds[i].revents, ffi.C.POLLNVAL) == ffi.C.POLLNVAL then
        self:remove(self.fds[i].fd)
      end
    end
  end
end

return Poller
