-- trylua.lua
-- This is an off-line local server version of James Turner's http://trylua.org
local orbiter = require 'orbiter'
local html = require 'orbiter.html'
require 'orbiter.libs.jquery'

local lua = orbiter.new(html)

local style = [[
            body { font-family: 'Lucida Grande'; font-size: 13px; color: #444; width: 960px; }
            a { color: #333; }
            #console { font-family: 'Lucida Grande'; font-size: 13px; background: #ddd; width: 960px; height: 400px; padding: 5px 5px 15px; }
            .jquery-console-welcome { font-style: italic; color: #444; padding-bottom: 2px; }
            .jquery-console-inner { height: 100%; background: #efefef; padding: 5px; overflow: auto; }
            .jquery-console-prompt-box { color: #444; font-family: monospace; }
            .jquery-console-focus .jquery-console-cursor { background: #333; color: #eee; font-weight: bold; }
            .jquery-console-message-error { color: red; font-family: sans-serif; font-weight: bold; padding: 2px; }
            .jquery-console-message-success { color: green; font-family: monospace; padding: 2px; }
]]

local script = [[
            $(document).ready(function () {
                var lua = $('#console').console({
                    autofocus: true,
                    promptLabel: '> ',
                    continuedPromptLabel: '>> ',
                    commandHandle: function (line) {
                        if (line == 'clear') {
                            lua.reset();
                            return;
                        } 
                        var ret = '';
                        $.ajax({
                            data: { code : line }, url: '/request',
                            success: function (msg) {
                                if (msg.charAt(0) == '\\') { // server sent us an error
                                    msg = msg.substring(1)
                                    //ret = {msg:msg,className:'jquery-console-message-error' }
                                    ret = msg
                                } else {
                                    ret = msg;
                                }
                            }, 
                            error: function (msg) { ret = 'Epic fail!'; },
                            async: false,
                            timeout: 10000,
                        });
                        if (ret == 'continued') {
                            lua.continuedPrompt = true;
                        } else {
                            lua.continuedPrompt = false;
                            return ret;
                        }
                    },
                    promptHistory: true,
                    autofocus: true,
                    welcomeMessage: 'Lua 5.1.4  Copyright (C) 1994-2008 Lua.org, PUC-Rio'
                });
            });
]]

local print_buff,term_print_installed

function term_print(...)
    local args,n = {...},select('#',...)
    for i = 1,n do
        args[i] = tostring(args[i])
    end
    table.insert(print_buff,table.concat(args,'   '))
end

local env = {
    print = term_print,
}
setmetatable(env,{ __index = _G })

function eval(code)
    local status,val,f,err,rcnt
    print_buff = {}
    code,rcnt = code:gsub('^%s*=','return ')
    f,err = loadstring(code,'TMP')    
    if f then
        setfenv(f,env)
        status,val = pcall(f)
        if not status then err = val 
        else
            if #print_buff > 0 then val = table.concat(print_buff,'\n') end
            return tostring(val)
        end
    end
    if err then
        err = tostring(err):gsub('^%[string "TMP"%]:1:','')
        return '\\'..err
    end
end

local span,div = html.tags 'span,div'

function lua:index(web)
    return html {
        title = 'Try Lua Offline',
        scripts = '/resources/javascript/jquery.console.js',
        inline_style = style,
        inline_script = script,
        div{id='console',''},
        'off-line version of James Turner\'s ',
        html.link("http://trylua.org","trylua.org"),
        ', powered by ',
        html.link("http://github.com/chrisdone/jquery-console","jquery-console")
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
