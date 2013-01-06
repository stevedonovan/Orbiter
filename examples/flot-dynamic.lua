-- using the Flot client-side charting library with
-- AJAX data.
-- See http://stevedonovan.github.com/lua-flot/flot-lua.html
local orbiter = require 'orbiter'
local html = require 'orbiter.html'
local flot = require 'orbiter.controls.flot'
local jq = require 'orbiter.libs.jquery'

local self = orbiter.new(html)


local sin,cos = {},{}
for i = 1,100 do
   local x = i/10
   sin[i] = {x,math.sin(x)}
   cos[i] = {x,math.cos(x)}
end

local plot = flot.Plot { -- legend at 'south east' corner
   legend = { position = "se" },
}
plot:add_series("sin",sin)

local T = html.tags

function self:index()
    return html {
        T.h2 'Drawing a Flot Graph',
        plot:render(),
        T.p {
            "Demonstrating Dynamic Data generation ",
            jq.button("Press me for More",function()
                plot:add_series("cos",cos)
                return plot:update()
            end)
        }
    }
end

self:dispatch_get(self.index,'/')

self:run(...)
