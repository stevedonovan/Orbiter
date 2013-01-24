local orbiter = require 'orbiter'
local html = require 'orbiter.html'
local dropdown = require 'orbiter.controls.dropdown'
local calendar = require 'orbiter.controls.calendar'

-- 'us' mm/dd/yyyy, 'eu' 'dd-mm-yyyy' or 'db' 'yyyy-mm-dd'
calendar.set_mode 'eu'

local self = orbiter.new(html,'tags')

function self:index()
    return html {
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
    },
    H3 'Credits',
    p{"Drop-down menu by",html.link('http://javascript-array.com/')},
    p{"Calendar control by",html.link("http://www.softcomplex.com/products/tigra_calendar/")},
}
end

self:dispatch_get(self.index,'/')

self:run(...)
