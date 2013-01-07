-- using the Flot client-side charting library with
-- AJAX data.
-- See http://stevedonovan.github.com/lua-flot/flot-lua.html
local orbiter = require 'orbiter'
local html = require 'orbiter.html'
local flot = require 'orbiter.controls.flot'
local jq = require 'orbiter.libs.jquery'
local form = require 'orbiter.form'
local self = orbiter.new(html)

--- evaluating Lua expressions within the math table context
local load = load

if _VERSION:match '5%.1$' then -- Lua 5.1 compatibility
    function load(str,name,mode,env)
        local chunk,err = loadstring(str,name)
        if chunk then setfenv(chunk,env) end
        return chunk,err
    end
end

local function evaluate (expr)
    local res
    local chunk,err = load('return '..expr,'TMP','t',math)
    if err then error(err,2) end
    return chunk()
end

local plot = flot.Plot { -- legend at 'south east' corner
   legend = { position = "se" },
   zoom = {interactive=true},
   pan = {interactive=true},
   xaxis = { zoomRange = {0.1,10}, panRange={-10,10}},
   yaxis = { zoomRange = {0.1,10}, panRange={-10,10}},
}

-- implicit form actions are just app methods,
function self:generate_series ()
    local f,xmin,xmax,xdelta
    -- sometimes exception handling is the Way to Go
    local ok,err = pcall(function()
        f = evaluate('function(x) return '..self.expr..' end')
        xmin = evaluate(self.xmin)
        xmax = evaluate(self.xmax)
        xdelta = evaluate(self.xdelta)
        local data,append = {},table.insert
        for x = xmin,xmax,xdelta do
            append(data,{x,f(x)})
        end
        plot:clear()
        plot:add_series(self.expr,data)
    end)
    -- form actions can be called in the context of a JQuery AJAX post request,
    -- and in that case they can return JS to be evaluated.
    if not ok then
        return jq.alert("error: ",err)
    else
        return jq.eval(plot:update())
    end

end

self.expr = 'sin(x)*cos(2*x)*sin(x/2)'
self.xmin = '0'
self.xmax = '2*pi'
self.xdelta = '0.1'

local f = form.new {
    obj = self, type = 'line';  -- let it run along
    buttons = {}, -- no buttons please!
    action = self.generate_series; -- implicit handler: calls prepare()

   -- fields
    "expr","expr",form.non_blank,
    "start","xmin",5,  -- note: integer constraint is input size
    "finish","xmax",5,
    "step",'xdelta',5,
}

local T = html.tags

function self:index(web)
    f:prepare(web)
    return html {
        T.h2 'Plotting a Lua Expression using Flot',
        plot:show(),
        f:show(),
        jq.button("Go",f), -- want a JQuery button to submit the form
        html.script(jq.timeout(300,f)), -- force a form submission after 300ms
    }
end

self:dispatch_get(self.index,'/')

self:run(...)
