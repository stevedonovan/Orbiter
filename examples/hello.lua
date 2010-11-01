local orbiter = require 'orbiter'

local hello = orbiter.new()

function hello:index(web)
    return ([[
        <html><body>
        <h2>Hello, World!</h2>
        <img src='/images/logo.gif'/><br/>
        Lua memory used is %5.0f kB
        </body></html>
    ]]):format(collectgarbage 'count')
end

hello:dispatch_get(hello.index,'/','/index.html')
hello:dispatch_static '/images/.+'

hello:run(...)

