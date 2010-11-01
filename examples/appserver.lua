-- illustrates another kind of dynamic dispatch - a little 'app server'.
-- if passed '/hello/rest' it will load hello.lua and pass /rest to it.

local orbiter = require 'orbiter'
local html = require 'orbiter.html'

local app = orbiter.new(html)

local h2,p = html.tags 'h2,p'

function app:handle_dispatch(web,script,args)
    print('parms',script,args)
    script = script..'.lua'
    local status,err = pcall(dofile,script)
    if not status then
        return html { h2 'Error', p(err) }
    else
        -- this is a hack: set by the run() method of the last object...
        local obj = orbiter.get_last_object()
        return obj:dispatch(web,args)
    end
end

app:dispatch_get(app.handle_dispatch,'/(.-)(/.*)')

app:run(...)


