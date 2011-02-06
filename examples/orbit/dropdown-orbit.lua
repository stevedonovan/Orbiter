require 'orbit'
local html = require 'orbiter.html'

module("dropdown_test", package.seeall, orbit.new, html.new)

local dropdown = require 'orbiter.controls.dropdown'
local calendar = require 'orbiter.controls.calendar'

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
        p(),
        form { name = 'form1',
            'A date entry field', calendar.date('form1','text1')    
        }
}
end

dropdown_test:dispatch_get(index,'/')

return _M

