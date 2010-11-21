-- using orbiter.html with an Orbit application
require"orbit"
local html = require 'orbiter.html'

module("hello", package.seeall, orbit.new)

local h2,p = html.tags 'h2,p'

function index(web)    
    return html.as_text {
        title = 'A simple Orbit App';
        h2 'Simple to do easy stuff',
        p 'complex stuff made manageable;',
        p 'here using orbiter.html for rendering',
        html.list {
            render = html.link;
            {'/section/first',"First section"},
            {'/section/second',"Second Section"}
        }
    }
end

function sections(web,name)
    return html.as_text {h2 (name)}
end

hello:dispatch_get(index,'/', '/index.html')
hello:dispatch_get(sections, '/section/(.+)')

return _M


