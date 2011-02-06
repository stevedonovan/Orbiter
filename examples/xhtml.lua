-- how to generate XHTML with Orbiter:
-- has embedded SVG
local html = require 'orbiter.html'
local app = require 'orbiter'. new(html)

local h2,svg,rect = html.tags 'h2,svg,rect'

function app:index()
    return html { xml = true;   --> does the trick!
        h2 "hello",
        svg { xmlns="http://www.w3.org/2000/svg"; version="1.1";
            style="width:100%; height:100%";
            rect {x = '0', y = '0', width = '200', height = '200',
                style = 'fill:none; stroke: black'
            }
        }
    }
end

app:dispatch_get(app.index,'/')

app:run(...)
