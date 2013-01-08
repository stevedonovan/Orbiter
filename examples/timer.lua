-- shows Orbiter jQuery integration:
-- - can create buttons and timers hooked into server callbacks
-- - can pass back jQuery expression encoded as chains of Lua method calls.
local orbiter = require 'orbiter'
local html = require 'orbiter.html'
local jq = require 'orbiter.libs.jquery'
local form = require 'orbiter.form'
local modal = require 'orbiter.controls.modal'

local self = orbiter.new(html)

-- to use jq.timer(), must call this first
jq.use_timer()

-- an auto form consists of an object and a form template

self.name = 'johnny'
self.age = 12

local f = modal.new { obj = self;
    "name","name",form.non_blank,
    "age","age",form.range(1,120),

    action = function(self)
        return jq.alert("howzit "..self.name.."("..self.age..")")
    end
}

local h2,h3,div,p = html.tags 'h2,h3,div,p'
local button_  = html.tags 'button'
local k = 0

function self:index(web)
    return html {
        title = 'Testing Timers';
        inline_style = style;
        inline_script = script;
        h2 'Setting a timer',

         --- after a second, we'll insert the 'content' div
        jq.timeout_script(500,function()
            return jq 'h2' : css ('color','red') : after (
                div { id = "content";
                    h3 'Lua Syntax for JQuery expressions',
                    p '(strings are irritating)',
                    h3 'Can be used with htmlification',
                    p '(avoiding more strings)'
                }
            )
        end),

        -- very simplest kind of callback
        jq.button("Alert",function()
            return jq.alert("bonzo!")
        end),

        -- a JQuery-like expression in Lua; the inserted div
        -- has two paras which we patch to new values
        jq.button('Patch Strings',function()
            return jq "#content" : find 'p'
                : eq(0) : html 'no more strings!'
                : _end()
                : eq(1) : html 'ditto!'
        end),

        -- the timer callback adds stuff after inserted div
        jq.button("Start Timer",function()
            return jq.timer(1000,function()
                k = k + 1
                if k == 6 then
                    return jq.cancel_timer()
                else
                    return jq '#content' : after(p('go '..k))
                end
            end)
        end),

        -- showing off modal dialogs
        jq.button("Show Modal",function()
            return f:show_modal(web)
        end),


    }
end

self:dispatch_get(self.index,'/')

self:run(...)

