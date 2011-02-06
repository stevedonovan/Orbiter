local O = require 'orbiter'
local html = require 'orbiter.html'
local form = require 'orbiter.form'
local substitute = require 'orbiter.template' . substitute

local app = O.new(html)
app.text = ''

local f = form.new {
    obj = app, type = 'list';
    'Template Text','text',form.textarea{rows=10,cols=40},
    buttons = {'As Text','As HTML'};
}

local pre,code,p = html.tags 'pre,code,p'

function app:index(web)
    if f:prepare(web) then
        return html {
            f:show()
        }
    else
        local result = substitute(self.text,_G)
        if f.button == 'As Text' then
            result = pre(code(result))
        else
            result = html.literal(result)
        end
        return html {
            f:show(),
            p(),
            result
        }
    end
end

app:dispatch_any(app.index,'/')

app:run(...)
