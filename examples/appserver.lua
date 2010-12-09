-- illustrates another kind of dynamic dispatch - a little 'app server'.
-- if passed '/hello/rest' it will load hello.lua and pass /rest to it.
--- / (index) now prints a useful set of links to apps.
---
--- An entertaining feature is that scripts will be reloaded if they are modified.

local orbiter = require 'orbiter'
local html = require 'orbiter.html'
local attributes = require 'lfs' . attributes

local app = orbiter.new(html)

function filetime(fname)
    local time,err = attributes(fname,'modification')
    if time then
        return time
    else
        return -1
    end
end
    
local object_of = {}
local current_script
local old_new = orbiter.new

-- classic case of monkey-patching; we will be loading these apps into our single
-- Lua state, and want to manage the namespaces. For instance, hello.lua just has '/'
-- which we would like to remap to '/hello'.  So this patch ensures that the patterns 
-- used by any loaded app will be prepended with the script name, which defines
-- a namespace.  (This hack assumes that current_script is set before the script
-- is loaded)
function orbiter.new(...)
    local obj = old_new(...)
    local prefix = '/'..current_script:gsub('%-','%%-')
    local function prepend(...)
        local args = {...}
        local res = {}
        for i = 1,#args do
            res[i] = prefix .. args[i]
        end
        return unpack(res)    
    end
    local old_dispatch_get = obj.dispatch_get
    obj.dispatch_get = function(self,callback,...)    
        return old_dispatch_get(self,callback,prepend(...))
    end
    local old_dispatch_post = obj.dispatch_post    
    obj.dispatch_post = function(self,callback,...)    
        return old_dispatch_post(self,callback,prepend(...))
    end    
    local old_dispatch_static = obj.dispatch_static
    obj.dispatch_static = function(self,...)
        return old_dispatch_static(self,prepend(...))
    end
    return obj
end

--- the second part of the hack;  if a request comes from a particular app, then 
--- the namespace must be added.  If bonzo.lua links to '/start' then this filter 
--- intercepts the original request and rewrites it as '/bonzo/start'.
orbiter.add_request_filter(function(web,file)
    if web.vars and web.vars.HTTP_REFERER then
        local referer = web.vars.HTTP_REFERER:match('http://[^/]+(.+)')
        local script = referer:match('^/[^/]+')
        if script then
            return script .. file, object_of [script]
        end
    end
end)

local h2,p = html.tags 'h2,p'

function app:handle_dispatch(web,script,args)
    args = args or '/'  -- default is index    
    current_script = script
    local obj = object_of [script]
    local lfile = script..'.lua'
    local tm  = filetime(lfile)
    if not obj or tm > obj.time then
        print('reloading',lfile)
        local status,err = pcall(dofile,lfile)
        if not status then
            return html { h2 'Error', p(err) }
        else
            -- this is a hack: set by the run() method of the last object...
            local obj = orbiter.get_last_object()
            obj.time = tm
            object_of[script] = obj
            return obj:dispatch(web,'/'..script..args)
        end
    else
        return obj:dispatch(web,'/'..script..args)
    end
end

function app:handle_index(web)
    return html {
       h2 'Examples Available',
       p 'A simple application server',
       html.list {
            render = html.link,
            '/dropdown',
            '/form1',
            '/form2',
            '/hello',
            '/simple-html',
            '/trylua'          
       }
    }
end

app:dispatch_any(app.handle_dispatch,'/(.-)(/.*)', '/(.+)')
app:dispatch_get(app.handle_index,'/')

app:run(...)


