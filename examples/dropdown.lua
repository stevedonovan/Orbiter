local orbiter = require 'orbiter'
local html = require 'orbiter.html'
local dropdown = require 'orbiter.widgets.dropdown'
local calendar = require 'orbiter.widgets.calendar'

local self = orbiter.new(html)

local h2,form,hr,div,p = html.tags 'h2,form,hr,div,p'

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
    div {style='clear:both',''},
    form { name = 'form1',
        'A date entry field', calendar.date('form1','text1')    
    },
    p(html.link('http://javascript-array.com/','Drop-down menu by javascript-array.com')),
}
end

self:dispatch_get(self.index,'/')

self:run(...)
