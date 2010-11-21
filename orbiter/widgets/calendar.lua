
-- http://www.softcomplex.com/products/tigra_calendar/

local html = require 'orbiter.html'

-- if extensions use the bridge dispatch_static, then Orbit applications can
-- use this as well!
local bridge = require 'orbiter.bridge'
bridge.dispatch_static('/resources/javascript/calendar.+',
'/resources/css/calendar.+',
 '/resources/images/calendar.+')

local _M = {}

html.set_defaults {
    scripts = '/resources/javascript/calendar_eu.js',
    styles = '/resources/css/calendar.css'
}

function _M.calendar(form,control)
    return html.script ( [[
 	new tcal ({
		'formname': '%s',
		'controlname': '%s'
	});   
    ]] % {form,control} )
end

local input = html.tags 'input'

function _M.date(form,control)
    return input{type='text',name=control},_M.calendar(form,control)
end

return _M