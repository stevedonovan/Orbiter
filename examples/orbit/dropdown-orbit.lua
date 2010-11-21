require 'orbit'
local html = require 'orbiter.html'
local bridge = require 'orbiter.bridge'

module("dropdown_test", package.seeall, orbit.new, bridge.new)

local dropdown = require 'orbiter.widgets.dropdown'
local calendar = require 'orbiter.widgets.calendar'

local h2,form,hr,div,p = html.tags 'h2,form,hr,div,p'

function index()
    return html.as_text {
        h2 'Packaging a Drop-down menu',
        dropdown.menu {
            'First',{
                'Impressions','#',
                'sight','#'
            },
            'Second',{
                'thoughts','#',
                'sight','#'
            }
        },
        div {style='clear:both',''},
        form { name = 'form1',
            'A date entry field', calendar.date('form1','text1')    
        }
}
end

dropdown_test:dispatch_get(index,'/')

return _M

