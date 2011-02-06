-- Paging table data.
-- this shows the usefulness of the start and finish parameters of html.table.
local orbiter = require 'orbiter'
local html = require 'orbiter.html'
local app = orbiter.new (html)

local mytable = {}
local sin,cos = math.sin,math.cos
for K = 1,200 do
    local x = math.pi*K/50
    mytable[K] = {x,sin(x),cos(x),sin(x)*cos(x)}
end

local page_size = 20
local num_pages = math.ceil(#mytable/page_size)

local style = [[
table {
    width: 100%;
    font-family: monospaced;
	border: outset 1px gray;
	border-collapse: collapse;
	background-color: white;
}
table th {
	border: inset 1px gray;
	padding: 1px;
	background-color: white;
}
table td {
	border:  insert 1px gray;
	padding: 1px;
	background-color: white;
}
.neg {
    color: red;
}
]]

local br = html.tags 'br'

-- useful trick for conditional inclusion of elements
local function If(condn,val) 
    if condn then return val else return '' end 
end

--- note how the table renderer can return a class or style for the <li>
--- as well as contents
local function cell_render(x)
    local res = { ('%+8.3f'):format(x) }
    if x < 0 then res.class = 'neg' end
    return res
end

function app:index(web)
    local page = tonumber(web.input.page) or 1
    local start = (page-1)*page_size + 1
    local finish = math.min(start + page_size - 1,#mytable)
    return html {
        inline_style = style;
        html.table {
            headers = {'x','sin(x)','cos(x)','sin(x)*cos(x)'},
            render = cell_render,
            data = mytable,
            start = start, finish = finish
        },
        br(),
        'showing page '..page..' of '..num_pages..'  ',
        If(start > 1, html.link('/?page='..(page-1),'<<')),
        If(finish < #mytable,  html.link('/?page='..(page+1),'>>')),
    }
end

app:dispatch_get(app.index,'/')

app:run(...)
