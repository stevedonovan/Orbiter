--- Orbiter, a compact personal web application framework.
-- This provides a dead easy, lazy way to write simple scripts
-- with Orbit-style htmlification where unknown functions must be
-- tag names!
-- 
-- require 'orbiter.easy' (function(web,path)
--   return web.html {
--      h2 'hello world',
--      p 'A satisfying conclustion'
--   }
--  end)

local orbiter = require 'orbiter'
local html = require 'orbiter.html'
local args_ = arg
local _G = _G
local htags = html.tags

return function(callback)    
    local app = orbiter.new(html)    
    
    app:dispatch_static '/resources/.+'

    -- modify the callback's environment so it will first look globally,
    -- and then assume that  everything else must be tag names
    local env = setmetatable({html = html},{
        __index = function(T,tag) -- T is environment of function...
            local glob = _G[tag]
            if glob then return glob end
            T[tag] = htags(tag)
            return T[tag]
        end
    })
    
    setfenv(callback,env)
    
    function app:index(web,path)
        web.html = html
        return callback(web,path)
    end
    
    app:dispatch_any(app.index,'(/.*)')

    return app:run(unpack(args_))
end
