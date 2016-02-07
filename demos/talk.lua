local luatalk = require('init')
local poller = luatalk.Poller()
local stdin = luatalk.StdinReader()
local client = luatalk.Client()

client:connect('/tmp/talkie')
client:on_recv(function(msg)
  print('Received: ' .. msg)
end)

stdin:on_read(function(msg)
  client:send(msg)
end)

poller:add(stdin)
poller:add(client)
poller:poll()
