-- using Rici Lake's famous SlightlyLessSimpleLuaTemplate
-- engine with Orbiter
local O = require 'orbiter'
local html = require 'orbiter.html'
local form = require 'orbiter.form'
local substitute = require 'orbiter.template' . substitute

local app = O.new(html)
app.text = [[
<ul>
# for i = 1,4 do
<li>hello @(i)</li>
# end
</ul>
]]

local f = form.new {
    obj = app, type = 'list';
    'Template Text','text',form.textarea{rows=10,cols=40},
    buttons = {'As Text','As HTML'};
}

local pre, code, p = html.tags 'pre, code, p'

function app:index(web)
    if f:prepare(web) then -- GET: present form!
        return html {
            f:show()
        }
    else -- POST: form plus result
        -- customize to use '@' instead of '$' (which fights with JS)
        local result = substitute(self.text,{
            __parent = _G,
            __dollar = '@',
        })
        if f.button == 'As Text' then
            result = code(pre(result))
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
