-- this little example can be run directly using Orbiter or
-- run under Orbit, i.e. both 'lua helloa.lua' and 'orbit helloa.lua' work
-- as expected. For the little O, memory used is about 100K and for
-- the big O, it is about 400K
local framework = require (orbit and 'orbit' or 'orbiter')

module('helloa',package.seeall,framework.new)

function index(web)
    return ([[
        <html>
        <head>
            <title>A Simple Orbit Application</title>
            <link rel="shortcut icon" href="/resources/favicon.ico">
        </head>
        <body>
        <h2>Hello, World!</h2>
        <img src='/resources/images/logo.gif'/><br/>
        Lua memory used is about %5.0f kB
        </body></html>
    ]]):format(collectgarbage 'count')
end

helloa:dispatch_get(index,'/','/index.html')
helloa:dispatch_static '/resources/images/.+'

if orbit then
    return _M    
else
    helloa:run(...) 
end


