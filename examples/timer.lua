-- shows Orbiter jQuery integration:
-- - can create buttons and timers hooked into server callbacks
-- - can pass back jQuery expression encoded as chains of Lua method calls.
local orbiter = require 'orbiter'
local html = require 'orbiter.html'
local jq = require 'orbiter.libs.jquery'

local timer = orbiter.new(html)

-- to use jq.timer(), must call this first 
jq.use_timer()

local h2,h3,div,p = html.tags 'h2,h3,div,p'
local k = 0

function timer:index(web)
    return html {
        title = 'Testing Timers';
        h2 'Setting a timer',
        jq.button('Click me!',function()
            return jq "#content" : find 'p' 
                : eq(0) : html 'no more strings!'
                : _end()
                : eq(1) : html 'ditto!'
        end),
        jq.button("Start timer",function()            
            return jq.timer(1000,function()
                k = k + 1
                if k == 6 then
                    return jq.cancel_timer()
                else
                    return jq '#content' : after(p('go '..k))
                end
            end)
        end),
        html.script(jq.timeout(500,function()
            return jq 'h2' : css ('color','red') : after (
                div { id = "content";
                    h3 'Lua Syntax for JQuery expressions',
                    p '(strings are irritating)',
                    h3 'Can be used with htmlification',
                    p '(avoiding more strings)'
                }                
            )
        end)),        
    }
end

timer:dispatch_get(timer.index,'/')

timer:run(...)

