local orbiter = require 'orbiter'
local text = require 'orbiter.text'

local form = orbiter.new()

local html = text.Template [[
    <html><body>
    $body
    </body></html>
]]

local form1 = [[
<form name="input" action="/results" method="post">
First name: <input title='firstname' type="text" name="firstname" /><br />
Last name: <input title='lastname' type="text" name="lastname" /><br />
<input type="submit" value="Submit" />
</form>
]]        

function form:show(web)
    return html {
        body =  form1
    }
end

local function make_list(t)
   local append = table.insert
   local res = {}
   append(res,'<ul>')
   for k,v in pairs(t) do
        append(res,'<li>%s = %s</i>' % {k,v})
   end
   append(res,'</ul>')
   return table.concat(res,'\n')
end

local results = text.Template [[
    <h2>Form Variables</h2>
    $body1
    <h2>HTTP Headers</h2>
    $body2
]]

function form:results(web)
   local vars_list = make_list(web.input) -- for POST; use web.GET for GET
   local headers = make_list(web.vars)
   return html { body = results { body1 = vars_list, body2 = headers }}
end

form:dispatch_get(form.show,'/','/index.html')
form:dispatch_post(form.results,'/results')

form:run(...)
