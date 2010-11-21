-- orbiter.orbit acts as a bridge for registering static dispatches
-- that works with both Orbiter and Orbit

local _M = {}

function _M.dispatch_static(...)
    if orbit then    
        -- remember to strip off the starting @
        local path = debug.getinfo(2, "S").source:sub(2):gsub('\\','/')
        if path:find '/' then
            path = path:gsub('/[%w_]+%.lua$','')
        else -- invoked just as script name
            path = '.'
        end
        local function static_handler(web)
            local fpath = path..web.path_info
            return obj:serve_static(web,fpath)
        end
        obj.dispatch_get(static_handler,...)
        end
    else
        obj = require 'orbiter'. new()
        obj:dispatch_static(obj,...)
    end
end

return _M


