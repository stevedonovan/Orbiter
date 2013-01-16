local orbiter = require 'orbiter'
local template = require 'orbiter.template'

local app = orbiter.new()

local data = {
    'oranges','lemons','apples'
}

function app:index (web)
    local resp,err = template.page('template.ltp',{
        cache = true; -- switch off to reflect immediate changes
        app = app;  -- reference to us - we'll look in our /template dir
        data = data;
        __parent=_G; -- if you don't feel very strict ;)
        __dollar='@'; -- better than '$' for JS, esp. JQuery
    })
    return resp
end

app:dispatch_get(app.index,'/')

app:run(...)
