local orbiter = require 'orbiter'
local html = require 'orbiter.html'

local simple = orbiter.new(html)

local h2,p = html.tags 'h2,p'

function simple:index(web)
    return html {
        title = 'A simple Orbiter App';
        h2 'Simple to do easy stuff',
        p 'complex stuff made manageable',
        html.list {
            render = html.url;
            {'/section/first',"First section"},
            {'/section/second',"Second Section"}
        }
    }
end

function simple:sections(web,name)
    return html {h2 (name)}
end

simple:dispatch_get(simple.index,'/', '/index.html')
simple:dispatch_get(simple.sections, '/section/(.+)')

simple:run(...)

