-- The form1 example, done using orbiter.html.
--
-- Shows how function specialization can help to factor out common patterns.
--
local orbiter = require 'orbiter'
local html = require 'orbiter.html'

local form2 = orbiter.new(html)

local text,button = html.tags {
  {'input',type='text',name=1},
  {'input',type='submit',value=1,name='button'},
}

local h2,form,select,option = html.tags 'h2,form,select,option'

function loption(ls)
    local res = {}
    for i,v in ipairs(ls) do
         res[i] =  option{value=v, v}
    end
    return unpack(res)
end

function form2:show(web)
    return html {
        form { name = 'input', action='/results',method='post';
          html.table { cols = 2;
          "first parameter", text "firstname",
          "second parameter", text "secondname",
          "choices",select {name='choices',loption {'banana', 'apple','pear'}}
          },
          button 'submit', button 'again'
        }
    }
end

local  hashlist = html.specialize (html.list, {map = html.map2list, render = '%s = %s'})

function form2:results(web)
    return html {
        h2 'Form Variables',
        hashlist{data=web.input},
        h2 'HTTP Headers',
        hashlist{data=web.vars}
    }
end

form2:dispatch_get(form2.show,'/','/index.html')
form2:dispatch_post(form2.results,'/results')

form2:run(...)
