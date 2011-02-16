--- Orbiter, a compact personal web application framework.

local orbiter = require 'orbiter'
local spawn = orbiter.new()

function spawn.command(cmd,url)
    local flags = orbiter.flags
    url = 'http://'..flags.addr..':'..flags.port..url
    local spawner = spawn:get_path_to '/resources/spawner.lua'
    local cmdline = ('%s %s %s "%s" & '):format(flags.lua,spawner,url,cmd)
    print(cmdline)
    return os.execute(cmdline)
end

return spawn

