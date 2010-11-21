local orbiter = require 'orbiter'

local hello = orbiter.new()

function hello:index(web)
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

hello:dispatch_get(hello.index,'/','/index.html')
hello:dispatch_static '/resources/images/.+'

hello:run(...)

