-- Using a template rather than htmlfication,
-- if your HTML skills are strong and/or working with a designer.
-- See examples/resources/template.ltp for the template.
-- Orbit templates use a modified version of the famous Rici lake preprocessor.
local orbiter = require 'orbiter'

local app = orbiter.new()

local page = require'orbiter.template'.templater {
    cache = true; -- switch off to reflect immediate changes
    app = app;  -- reference to us - we'll look in our /template dir
    __parent=_G; -- if you don't feel very strict ;)
    __dollar='@'; -- better than '$' for JS, esp. JQuery
}

local data = {
    'oranges','lemons','apples'
}

function app:index (web)
    return page('template.ltp',{
        data = data;
    })
end

app:dispatch_get(app.index,'/')

app:run(...)
