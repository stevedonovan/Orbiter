-- shows Orbiter jQuery integration:
-- - can create buttons and timers hooked into server callbacks
-- - can pass back jQuery expression encoded as chains of Lua method calls.
local orbiter = require 'orbiter'
local html = require 'orbiter.html'
local jq = require 'orbiter.libs.jquery'
local form = require 'orbiter.form'

local timer = orbiter.new(html)

-- to use jq.timer(), must call this first
jq.use_timer()

local h2,h3,div,p = html.tags 'h2,h3,div,p'
local button_  = html.tags 'button'
local k = 0

local style = [[
#modalbox {
    position: absolute;
    left: 50%;
    top: 50%;
    //width: 400px;
    //margin-left: -200px;
    //margin-top: -200px;
    background-color: #EEEEFF;
    border: 2px solid #000099;
}
#buttonrow {
    width: 100%;
    background-color: #EEEEFF;
}
]]

local script = [[
function jq_close_form(div,id) {
    $('#'+div).remove()
}

function jq_submit_form(div,id) {
    var form = $("form#"+id)
    $.post(form.attr("action"), form.serialize());
    jq_close_form(div,id);
}

]]

-- an auto form consists of an object and a form template

local obj = {
    name = 'johnny',
    age = 12
}

local f = form.new {
    obj = obj, buttons = {},
    action = "/form/submit",
    "name","name",form.non_blank,
    "age","age",form.range(1,120)
}

-- called when the form is submitted..
function timer:submit(web)
    f:prepare(web)
    return jq.alert("howzit "..obj.name.."("..obj.age..")")
end

timer:dispatch_post(timer.submit,'/form/submit')

function show_modal(f,web)
    f:prepare(web)
    -- we embed the form in a modal box
    return jq 'body' : append (
        div { id = 'modalbox';
        f:show();
        html.table {id = 'buttonrow'; {
          button_{"OK",onclick="jq_submit_form('modalbox','form1')"},
          button_{"Cancel",onclick="jq_close_form('modalbox','form1')"},
        }}
    })
end

function timer:index(web)
    return html {
        title = 'Testing Timers';
        inline_style = style;
        inline_script = script;
        h2 'Setting a timer',

         --- after a second, we'll insert the 'content' div
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


        jq.button("Show Modal",function()
            return show_modal(f,web)
        end),


    }
end

timer:dispatch_get(timer.index,'/')

timer:run(...)

--[[
            return jq 'body' : append (
                div { id = 'block';
                    p 'new stuff after content',
                    button("remove me",function()
                        return jq("#block"):remove()
                    end)
                }
            )
]]
