-- This shows how commands may be spawned asynchronously in
-- the background. (This has to be started from a handler, or at
-- least after the app:run(), since it depends on orbiter.flags)
-- So this demo needs a kick to get started, either by using a
-- browser or wget. You will get web.input.data set for each
-- line from the process output, and web.input.finis at the 
-- end.
local spawn = require 'orbiter.spawn'
local start
require 'orbiter.easy' (function(web,path)
   if not start then
      spawn.command('cat easy3.lua','/')
      start = true
   end   
   for k, v in pairs(web.input) do
      print(k,v)
   end
   return 'cool','text/plain'
end)
