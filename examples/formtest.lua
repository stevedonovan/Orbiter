-- Auto-generated forms demo.
-- Note that it's straightforward to run this either as an Orbiter or Orbit app.
local O = orbit or require 'orbiter'
local html = require 'orbiter.html'
local form = require 'orbiter.form'

local app = O.new {}

local obj = {
    name = 'John',
    phone = '+8999',
    title = 'Dr',
    age = 25,
    hobbies = 'chess'
}

-- custom data constraint
local phone_number = form.match('^%+%d+','must be international number +XXX...')

local f = form.new {
    obj = obj;
    title = 'Simple Generated Form',
    --action = '/'; name = 'form1';
    buttons = {'submit','try again'};
    'Name','name', form.non_blank,
    'Phone','phone',phone_number,
    'Title','title',{'Mr','Ms','Dr','Prof','Rev';size=5,multiple=true},
    'Age','age',form.irange(10,120),
    'Hobbies','hobbies',form.textarea{rows=10,cols=40},
}

local h2,p = html.tags 'h2,p'

local  hashlist = html.list:specialize {map = html.map2list, render = '%s = %s'}

local last_mem = collectgarbage("count")

function app:handle_form(web)
    local mem = collectgarbage("count")
    print("lua memory used",mem - last_mem )
    last_mem = mem
    if f:prepare(web) then  -- generating the form (GET)
        return html.as_text {
            f:show()
        }
    else -- handling the received value (POST)
        return html.as_text {
            h2 'Form Results',
            hashlist { data = obj },
            p ("button clicked was '"..f.button..'"'),
            html.link('/','Go back!'),
        }
    end
end

-- for Orbiter, we can say dispatch_any() to handle both cases, but
-- this is needed for Orbit
app:dispatch_get(app.handle_form,'/')
app:dispatch_post(app.handle_form,'/')

if orbit then -- Orbit loads the module and runs it using Xavante, etc
    return app
else ----- we use the Orbiter micro-server
    app:run(...)
end

