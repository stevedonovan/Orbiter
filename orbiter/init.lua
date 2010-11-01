--- Orbiter, a compact personal web application framework.
-- Very much inspired by Orbit, with a little webserver borrowed from Webrocks

local socket = require 'socket'

local _M = {}  --- our module
local DIRSEP = package.config:sub(1,1)
local Windows = DIRSEP == '\\'
local t_remove, t_insert, append = table.remove, table.insert, table.insert
local tracing, browser
local help_text = [[
 **** Orbiter vs 0.1 ****
--addr=IP address (default localhost)
--port=HTTP port (default 8080)
--browser=particular browser (default system)
--trace   print out some useful verbosity
--nolaunch  don't launch the browser; just run the server.
]]

--- Extract flags from an arguments list.
-- (grabbed from luarocks.util)
-- Given string arguments, extract flag arguments into a flags set.
-- For example, given "foo", "--tux=beep", "--bla", "bar", "--baz",
-- it would return the following:
-- {["bla"] = true, ["tux"] = "beep", ["baz"] = true}, "foo", "bar".
function _M.parse_flags(...)
   local args = {...}
   local flags = {}
   for i = #args, 1, -1 do
      local flag = args[i]:match("^%-%-(.*)")
      if flag then
         local var,val = flag:match("([a-z_%-]*)=(.*)")
         if val then
            flags[var] = val
         else
            flags[flag] = true
         end
         t_remove(args, i)
      end
   end
   return flags, unpack(args)
end

local function readfile (f)
	local f,err = io.open(f, 'rb')
	if not f then return nil,err end
	local s = f:read '*a'
	f:close()
	return s
end

-- Python-like string formatting with % operator
-- (see http://lua-users.org/wiki/StringInterpolation
getmetatable("").__mod = function(a, b)
    if not b then
            return a
    elseif type(b) == "table" then
            return a:format(unpack(b))
    else
            return a:format(b)
    end
end

--- really basic templates;
-- t = orbiter.Template 'hello $world'
-- print(t:subst {world = 'dolly'}).
-- (Templates are callable so subst is unnecessary)
function _M.Template(str)
    local tpl = {s=str}
    function tpl:subst(t)
        return (self.s:gsub('%$([%w_]+)',t))
    end
    setmetatable(tpl,{
        __call = function(obj,t)
            return obj:subst(t)
        end
    })
    return tpl
end

function _M.subst(str,t)
    return _M.Template(str):subst(t)
end

local MT = {}
MT.__index = MT

function _M.new(extension)
    local obj = setmetatable({},MT)
    -- remember to strip off the starting @
    local path = debug.getinfo(2, "S").source:sub(2):gsub('\\','/')
    if path:find '/' then
        path = path:gsub('/[%w_]+%.lua$','')
    else -- invoked just as script name
        path = '.'
    end
    obj.root = path
    obj.resources = obj.root..'/resources'
    if extension then
        obj.content_filter = extension.content_filter
    end
    return obj
end

---- launch the browser ----

local browsers = {
    "x-www-browser","gnome-open","xdg-open"
}

local function shell(cmd)
    local f = io.popen 'uname -s'
    local line = f:read()
    f:close()
    return line
end

local function uname()
    return shell 'uname s'
end

local function which(prog)
    return shell ('which %s 2> /dev/null' % prog)
end

function launch_browser (url,browser)
    if Windows then
        os.execute('rundll32 url.dll,FileProtocolHandler '..url)
        return
    end
    if not browser then
        local os = uname()
        if line == 'Darwin' then
            browser = 'open'
        else
            for _,p in ipairs(browsers) do
                if which(p) then browser = p; break end
            end
        end
    end
    os.execute(browser..' '..url..'&')
end

----- URL pattern dispatch --------------

local dispatch_set_handler

local function static_handler(obj,web)
    local content,mime = obj:read_content(web.URL)
    if not content then
        return '404 Not Found',false
    else
        return content,mime
    end
end

function MT:dispatch_get(callback,...)
    dispatch_set_handler(self,callback,...)
end

function MT:dispatch_static(...)
    dispatch_set_handler(self,static_handler,...)
end

local patterns = {}

function dispatch_set_handler(obj,callback,...)
    local pats = {...}
    if #pats == 1 then
        local pat = pats[1]
        assert(type(pat) == 'string')
        pat = '^'..pat..'$'
        local pat_rec = {pat=pat,callback=callback,self=obj}
        -- objects can override existing patterns, so we look for this pattern
        local idx
        for i = 1,#patterns do
            if patterns[i].pat == pat then idx = i; break  end
        end
        if idx then
            patterns[idx] = pat_rec
        else
            append(patterns,pat_rec)
        end
    else
        for _,pat in ipairs (pats) do
            dispatch_set_handler(obj,callback,pat)
        end
    end
end

-- The idea here is that if multiple patterns match an url,
-- then pick the longest such pattern.
-- Very general patterns (like /(.-)(/.*)) can be long, but very general.
-- So we use the length after stripping out any magic characters.
-- returns the callback, the pattern captures, and the object (if any)
local function match_patterns(request)
    local max_pat = 0
    local max_captures
    if tracing then trace('input request '..request) end
    for i = 1,#patterns do
        local pat = patterns[i].pat
        local captures = {request:match(pat)}
        local pat_size = #(pat:gsub('[%(%)%.%+%-%*]',''))
        if #captures > 0 and pat_size > max_pat then
            max_i = i
            max_pat = pat_size
            max_captures = captures
            if tracing then trace('matching '..pat..' '..pat_size) end
        end
    end
    if max_captures then
        return patterns[max_i].callback,max_captures,patterns[max_i].self
    end
end

-- this is the object used by Orbiter itself to provide one basic piece of furniture,
-- the favicon.
local self = _M.new()
self:dispatch_static '/favicon%.ico'

--------------- HTTP Server --------------------
----  A little web server, based on code by Samuel Saint-Pettersen ----
-- headers and error handling much improved by Ignacio

local mime_types = {
    gif = 'image/gif',
    ico = 'image/x-icon',
    png = 'image/png',
    html = 'text/html',
    js = 'text/javascript',
    css = 'text/css',
    other = 'text/plain',
}

local function url_decode(url)
    url = url:gsub('%+','  ')
    return (url:gsub('%%(%x%x)',function(c)
        c = tonumber(c,16)
        return ('%s'):format(string.char(c))
    end))
end

local function url_split(vars)
    local res = {}
    for pair in vars:gmatch('[^&]+') do
        local k,v = pair:match('([^=]+)=(.+)')
        v = url_decode(v)
        res[k] = v
    end
    return res
end

local function send_error (client, code, message)
	local header = "HTTP/1.1 " .. code .. "\r\nContent-Type:text/html\r\n"
	local msg = (
    [[<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>%s</title>
</head><body>
<h1>%s</h1>
<p>%s</p>
<hr/>
<small>Orbiter web server v0.1</small>
</body></html>]]):format(code, code, message or code)
	header = header .. "Content-Length:" .. #msg .. "\r\n\r\n"
	client:send(header)
	client:send(msg)
end

local function send_headers (client,code, type, length)
	client:send( ("HTTP/1.1 %s\r\nContent-Type: %s\r\nContent-Length: %d\r\nConnection: close\r\n\r\n"):format(code, type, length) )
end

-- process headers from a connection (borrowed from socket.http)
-- note that the variables have '-' replaced as '_' to make them better Lua
-- variables (e.g. content_length)
local function receiveheaders(sock)
    local line, name, value, err
    local headers = {}
    -- get first line
    line, err = sock:receive()
    if err then return nil, err end
    -- headers go until a blank line is found
    while line ~= "" do
        -- get field-name and value
        name, value = line:match "^(.-):%s*(.*)"
        if not (name and value) then return nil, "malformed reponse headers" end
        name = name:lower():gsub('%-','_')
        -- get next line (value might be folded)
        line, err  = sock:receive()
        if err then return nil, err end
        -- unfold any folded values
        while line:find("^%s") do
            value = value .. line
            line = sock:receive()
            if err then return nil, err end
        end
        -- save pair in table
        if headers[name] then headers[name] = headers[name] .. ", " .. value
        else headers[name] = value end
    end
    return headers
end

function MT:get_path_to(file)
    local res = self.resources .. file
    return res
end

function MT:read_content(file)
    if file == '/' then file = '/index.html' end
    local extension = file:match('%.(%a+)$') or 'other'
    local content = readfile (self:get_path_to(file))
    if content then
        if tracing then trace('returning '..self.resources .. file) end
        local mime = mime_types[extension] or 'text/plain'
        return content,mime
    else
        return false
    end
end

function MT:dispatch(web,path)
    local action,captures,obj = match_patterns(path)
    if not action then return nil end
    return action(obj,web,unpack(captures))
end

local OK = '200 OK'
local running,last_obj

function _M.get_last_object()
    return last_obj
end

function trace(stuff)
    io.stderr:write(stuff,'\n')
end

function MT:run(...)
    local args,flags
    flags,args = _M.parse_flags(...)
    local addr = flags['addr'] or 'localhost'
    local port = flags['port'] or '8080'
    local URL = 'http://'..addr..':'..port
    local fake = flags['test']
    last_obj = self

    if running then return
    else running = true
    end

    tracing = flags['trace']

    if flags['help'] then
        print(help_text)
        os.exit()
    end

    if fake then addr = fake
    else print ("Orbiter serving on "..URL)
    end

    if not flags['nolaunch'] and not fake then
        launch_browser(URL,flags['browser'])
    end

    -- create TCP socket on addr:port: allow for a debug hook
    local server_ctor = fake and require 'orbiter.fake' or socket.bind
    local server = assert(server_ctor(addr, tonumber(port)))
    -- loop while waiting for a user agent request
    while 1 do
        -- wait for a connection
        local client = server:accept()
        -- set timeout - 1 minute
        client:settimeout(60)
        -- receive request from user agent
        local request, err = client:receive()
        --print('request',request,err)
        -- if there's no error, return the requested page
        if not err then
            local content,file,action,captures,obj
            if tracing then trace('request: '..request) end
            local method = request:match '^([A-Z]+)'
            local headers,err = receiveheaders(client)
            if method == 'POST' then
                local size = tonumber(headers.content_length)
                vars = client:receive(size)
                if tracing then trace('vars '..vars) end
            end
            -- resolve requested file from user agent request
            file = request:match('(/%S*)')
            if method == 'GET' then
                url,vars = file:match('([^%?]+)%?(.+)')
                if url then file = url end
            end
            vars = vars and url_split(vars) or {}
            action,captures,obj = match_patterns(file)
            if action then
                -- @doc handlers may specify the MIME type of what they
                -- return, if they choose; default is HTML.
                -- @doc GET parms are GET field, POST parms in input.field,
                -- HTTP headers are in headers field; URL always contains
                -- the full URL matched
                local web = {URL = file, headers = headers}
                web[method=='GET' and 'GET' or 'input'] = vars
                status,content,mime = pcall(action,obj,web,unpack(captures))
                if status then
                    if not content then
                        status = false
                        content = '404 Request Failed'
                    elseif mime == false then
                        status = false
                    end
                end
                if status then
                    -- @doc if the app or extension object defines a content_filter method,
                    -- it will receive the content and mime type, and is expected to
                    -- return the same.
                    if self.content_filter then
                        content,mime = self:content_filter(content,mime)
                     end
                    send_headers(client,OK,mime or 'text/html',#content)
                    client:send(content)
                else
                    send_error(client,content)
                end
            else -- unmatched pattern!!
                send_error (client,'404 Not Found')
            end
        else
            print 'que? client receive failed'
        end
        -- done with client, close request
        client:close()
    end
end

return _M  -- orbiter!
