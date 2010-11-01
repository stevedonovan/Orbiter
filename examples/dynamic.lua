-- this example shows that dynamic matching by method name
-- is straightforward. The trick is to register the function when the pattern
-- first appears.

local orbiter = require 'orbiter'
local html = require 'orbiter.html'

local dyn = orbiter.new(html)

local h2,p = html.tags 'h2,p'

function dyn:handle_first (web,rest) -- anything begining with /first
   print('rest',rest)
   return self:layout( h2 'first', p(rest) )
end

function dyn:handle_second_case (web,rest)
    return self:layout( h2 'second case', p(rest) )
end

function dyn:layout(...)
    return html {
        title = 'A Dynamic Orbiter App';
        body = {...}
    }
end

local registered = {}

function dyn:dynamic_dispatch(web)
    local path = web.URL
    local handler = 'handle'..path:gsub('/','_')
    -- find a handler which can match this request
    local method, pattern
    for m in pairs(self) do
        if m:find '^handle_' then
            local i1,i2 = handler:find(m,1,true)
            if i1 == 1 then -- we can match, e.g. handle_first_try
                method = m
                -- we use the pattern appropriate for the handler,e.g.
                -- handle_first becomes '/first(.*)'
                pattern = method:gsub('^handle',''):gsub('_','/')..'(.*)'
                break
            end
        end
    end
    if method then
        -- register the handler dynamically when first encountered
        if not registered[handler] then
            self:dispatch_get(self[method],pattern)
            registered[handler] = true
        end
    else -- we fall back; there's no handler ---
        return self:layout( h2 'Index!', p('path was '..path) )
    end
    return self:dispatch(web,path)
end

dyn:dispatch_get(dyn.dynamic_dispatch,'/.*')
dyn:dispatch_get(function () os.exit() end,'/quit')

dyn:run(...)

