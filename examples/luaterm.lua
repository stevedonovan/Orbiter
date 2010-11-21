-- Lua Console using TermLib (a pure JavaScript browser console library)
-- http://www.masswerk.at/termlib/index.html
local orbiter = require 'orbiter'
local html = require 'orbiter.html'
local lua = orbiter.new(html)

local style  = [[
/* essential terminal styles */

.term {
	font-family: courier,fixed,swiss,sans-serif;
	font-size: 16px;
	color: #101099;
	background: #FFF;
}
.termReverse {
	color: #BBBBFF;
	background: #1010FF;
}
]]

local script = [[
  var term

  function termOpen() {
      term = new Terminal({
          handler: termHandler,
          //ctrlHandler: function() { if (this.inputChar == termKey.TAB) this.write('tab..') },
          //printTab: false,
          //DELisBS:true,
          termDiv: 'termDiv',
          x:20,y:20,
          rows:24,cols:80,
          greeting: 'Lua 5.1.4  Copyright (C) 1994-2008 Lua.org, PUC-Rio'
      });
      term.open();
  }

  function termHandler() {
    var line = this.lineBuffer;
    this.newLine();
    this.send ({
            url: '/request?code='+encodeURIComponent(line),
            callback: function() {
                if (this.socket.success) {
                    this.write(this.socket.responseText)
                } else if (this.socket.errno) {
                    this.write("error: " + this.socket.errstring)
                } else {
                    this.write("server returned: " + this.socket.statusText)
                }
                this.newLine()
                this.prompt();
            }
    })
  }

]]

local print_buff,term_print_installed

function term_print(...)
    local args,n = {...},select('#',...)
    for i = 1,n do
        args[i] = tostring(args[i])
    end
    table.insert(print_buff,table.concat(args,'   '))
end

local function escape(colour,s)
    s = tostring(s)
    s = s:gsub('%%','%%%%')    
    return '%c'..colour..s..'%c0'
end

function eval(code)
    local status,val,f,err,rcnt
    print_buff = {}
    code,rcnt = code:gsub('^%s*=','return')
    f,err = loadstring(code,'TMP')    
    if f then
        status,val = pcall(f)
        if not status then err = val 
        else
            if #print_buff > 0 then val = table.concat(print_buff,'\n') end
            return escape(0,val)
        end
    end
    if err then
        err = tostring(err):gsub('^%[string "TMP"%]:1:','')
        return escape(2,err)
    end
end

local span,div = html.tags 'span,div'

function lua:index(web)
    if not term_print_installed then
        print = term_print
    end
    return html {
        title = 'Lua Browser Console',
        scripts = '/resources/javascript/termlib.js',
        inline_style = style,
        inline_script = script,
        div{id='termDiv',style="position:absolute; visibility: hidden; z-index:1"},
        html.script 'termOpen()',
        'powered by ',
        html.link("http://www.masswerk.at/termlib/index.html","termlib"),
    }
end

function lua:request(web)
    local code = web.GET.code
    local res = eval(code)
    return res,'text/plain'
end

lua:dispatch_get(lua.index,'/','/index')
lua:dispatch_get(lua.request,'/request')
lua:dispatch_static('/resources/javascript.*')

lua:run(...)
