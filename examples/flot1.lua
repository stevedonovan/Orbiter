-- using the Flot client-side charting library with
-- statically generated data.
-- See http://stevedonovan.github.com/lua-flot/flot-lua.html
local orbiter = require 'orbiter'
local html = require 'orbiter.html'
local flot = require 'orbiter.controls.flot'

local self = orbiter.new(html)


function make_gaussian (m,s,values)
   local s2 = 2*s^2
   local norm = 1/math.sqrt(math.pi*s2)
   local res = {}
   for i = 1,#values do
      res[i] = norm*math.exp(-(values[i]-m)^2/s2)
   end
   return res
end

local xvalues = flot.range(0,10,0.1)
local n1 = make_gaussian (5,1,xvalues)
local npoint7 = make_gaussian (5,0.7,xvalues)

-- sampled Guassian with random noise
local n1r,n1rx,k = {},{},1
for i = 1,#xvalues,3 do
   n1r[k] = n1[i] + math.random()/10 - 0.05
   n1rx[k] = xvalues[i]
   k = k + 1
end

local plot = flot.Plot {
   grid = {
      markings = { -- a filled plot annotation
         {xaxis={from=4,to=6},color="#FFEEFE"}
      }
   },
   -- this provides x coordinates for all series!
   xvalues = xvalues
}

-- then the y data can be provided as a simple array
plot:add_series('norm s=1',n1)
plot:add_series('norm s=0.7',npoint7)
-- can also specify with explicit x and y coord arrays
plot:add_series('data',{x=n1rx,y=n1r},{points={show=true}})

-- an alternative to explicit declaration of tags is
-- to use html.tags as a lazy table

local T = html.tags

function self:index()
    return html {
        T.h2 'Drawing a Flot Graph',
        plot:show(),
        T.p {
            "Demonstrating Static Data generation ",
            html.link("http://stevedonovan.github.com/lua-flot/flot-lua.html","with Lua")
        }
    }
end

self:dispatch_get(self.index,'/')

self:run(...)
