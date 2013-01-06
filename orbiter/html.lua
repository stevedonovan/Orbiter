-- Orbiter, a personal web application framework
-- HTML generation using luaexpat LOM format;
-- this provides some higher-level functions for generating HTML lists
-- and tables.

local _M = {} -- our module
local doc = require 'orbiter.doc'
local text = require 'orbiter.text'
local util = require 'orbiter.util'
local append = table.insert

local imap,concat_list,reshape2D  = table.imap,table.concat_list,table.reshape2D

local compose = util.compose

_M.is_doc = doc.is_tag
_M.is_elem = doc.is_tag
_M.elem = doc.elem

function _M.tostring(d)
    return doc.tostring(d,'','  ')
end

_M.raw_tostring = doc.tostring
_M.escape = doc.xml_escape

function _M.literal(s)
    return '\001'..s
end

function _M.script(s)
    return _M.elem("script",{type="text/javascript",_M.literal(s)})
end

function _M.register(obj)
    obj.content_filter = _M.content_filter
end

-- convenience function for Orbit programs to register themselves with the bridge--
function _M.new(obj)
    if orbit then
        local bridge = require 'orbiter.bridge'
        bridge.new(obj)
    end
end

local defaults = {}

function _M.set_defaults(t)
    for k,v in pairs(t) do
        defaults[k] = concat_list(defaults[k],v)
    end
end

-- scripts and CSS usually by reference, can be directly embedded
-- within the document
local function make_head(head,t,field,tag,rtype,source)
    local items = concat_list(defaults[field],t[field])
    if #items == 0 then return end
    for _,item in ipairs(items) do
        local hi = {type=rtype}
        if tag == 'link' then
            if not rtype:find '/' then -- it's not a MIME type
                hi.rel = rtype
            else
                hi.rel = 'stylesheet'
            end
        end
        if source then
            hi[source] = item
            item = ''
        end
        hi[1] = _M.literal(item)
        append(head,doc.elem(tag,hi))
    end
end

function _M.document(t)
    local head = doc.elem('head',doc.elem('title',t.title or 'Orbiter'))
    t.favicon = t.favicon or '/resources/favicon.ico'
    make_head(head,t,'favicon','link','shortcut icon','href')
    make_head(head,t,'styles','link','text/css','href')
    make_head(head,t,'scripts','script','text/javascript','src')
    make_head(head,t,'inline_style','style','text/css')
    make_head(head,t,'inline_script','script','text/javascript')
    if t.refresh then
        append(head,doc.elem('meta',{['http-equiv']='refresh',content=t.refresh}))
    end
    local data = t.body or t
    local xmlns
    if t.xml then xmlns = "http://www.w3.org/1999/xhtml" end

    local body = table.copy_list(data)
    return doc.elem('html',{xmlns=xmlns,head,doc.elem('body',body)})
end

function _M.as_text(t)
    return _M.tostring(_M.document(t))
end

--- the module is directly callable.
-- and is short for @{document}.
-- @usage html { title = 'hello'; .... }
-- @function html
setmetatable(_M,{
    __call = function(o,t)
        return _M.document(t)
    end
})

-- the handlers can now return LOM, tell Orbiter about this...
-- Will adjust MIME type for XHTML
function _M.content_filter(self,content,mime)
    if _M.is_doc(content) then
        if content.attr.xmlns and not mime then
            mime = "application/xhtml+xml"
        end
        return _M.tostring(content), mime
    end
    return content,mime
end

local render_function

--  concatenating two functions will compose them...
debug.setmetatable(print,{
    __concat = function(f1,f2)
        f1,f2 = render_function(f1),render_function(f2)
        return function(...) return f1(f2(...)) end
    end;
    __index = {
        specialize = function(fun,defaults)
            return function(tbl)
                tbl = table.copy(table.force(tbl))
                table.update(tbl,defaults)
                local k = table.index_of(tbl,1)
                if k then
                    tbl[k] = tbl[1]
                    tbl[1] = nil
                end
                return fun(tbl)
            end
        end
    }
})

function _M.tags (list)
    if type(list) == 'table' and type(list[1])=='table' then
        local res = {}
        for i,item in ipairs(list) do res[i] = item[1] end
        res = {doc.tags(res)}
        for i,ctor in ipairs(res) do
            local defs = table.copy_map(list[i])
            res[i] = ctor:specialize(defs)
        end
        return unpack(res)
    else
        return doc.tags(list)
    end
end

local a,img = doc.tags 'a,img'

function _M.link(addr,text)
	local id,class,title,onclick = nil
    if type(addr) == 'table' then addr,text,id,class,title,onclick = addr[1],addr[2],addr.id,addr.class,addr.title,addr.onclick end
    if not text then text = addr end
    return a{id=id,href=addr,class=class,title=title,onclick=onclick,text}
end

function _M.image(src)
    return img{src=src}
end

function _M.format(patt)
    return function(val)
        return patt % val
    end
end

function render_function(f)
    if type(f) == 'string' then
        return _M.format(f)
    else
        return f
    end
end

local function item_op(fun,t)
    if t.render then
        fun = compose(fun,render_function(t.render))
        t.render = nil
     end
    return fun
end

local function copy_common(src,dest)
--~     dest.id = src.id
--~     dest.style = src.style
--~     dest.class = src.class
    for k,v in pairs(src) do
        if type(k) == 'string' then
            dest[k] = v
        end
    end
end

local function table_arg(t)
    assert(type(t) == 'table')
    local data = t
    if t.data then
        data = t.data
        t.data = nil
    end
    if t.map then
        data = t.map(data)
        t.map = nil
    end
    return data
end

local ul,ol,li = doc.tags 'ul,ol,li'

--- Generate an HTML list.
-- either t or t.data must be a single-dimensional array. t.start and t.finish
-- can provide a range over elements to be used. If t.map exists, it's assumed
-- to be a function that processes the array. Optionally, t.render will convert
-- values into strings; may be a function or a
-- The list will be unordered by default, set t.type to 'ordered' or '#'
function _M.list(t)
    local data = table_arg(t)
    local ctor = (t.type=='ordered' or t.type=='#') and ol or ul
    local each = item_op(li,t)
    local res = imap(each,data,t.start,t.finish)
    t.type = nil
    t.start = nil
    t.finish = nil
    copy_common(t,res)
    return ctor(res)
end

local function set_table_style(res,data,styles)
    local function set_style(row,col,style)
        local attr = {}
        -- important: is this an inline CSS style, or a class name?
        if style:find ':' then attr.style = style else attr.class = style end
        res[row][col].attr = attr
    end
    local alias = {}
    if styles.alias then
        alias = styles.alias
        styles.alias = nil
    end
    for style,where in pairs(styles) do
        local svalue = alias[style] or style
        local row,col = where.row,where.col
        if row and col then
            set_style(row,col,svalue)
        elseif row then
            for col = 1,#data[1] do set_style(row,col,svalue) end
        elseif col then
            for row = 1,#data do set_style(row,col,svalue) end
        end
    end
end

local _table,tr,td,th = doc.tags 'table,tr,td,th'

--- Generate an HTML table.
-- Data is either t itself or t.data if it exists, and must be a 2D array,
-- unless if t.cols is specified, where the 1D array will be reshaped as a 2D array.
-- If t.headers is an array of names, then the table will have a header.
-- You can specify a range of indices to use in the data using t.start and t.finish
-- (this is useful if using t.data)
function _M.table(t)
    local data = table_arg(t)
    if t.cols then
        data = reshape2D(data,t.cols)
        t.cols = nil
    end
    local each = item_op(td,t)
    local function row_op(row)
        return tr (imap(each,row))
    end
    local res = imap(row_op,data,t.start,t.finish)
    t.start = nil
    t.finish = nil
    if t.headers then
        local hdrs =  tr (imap(th,t.headers))
        table.insert(res,1,hdrs)
        t.headers = nil
    end
    --res.border = t.border --??
    copy_common(t,res)
    res.width = t.width
    local res = _table(res)
    if t.styles then set_table_style(res,data,t.styles) end
    return res
end

--- this converts a map-like table into a list of {key,value} pairs.
function _M.map2list(t)
    local res = {}
    for k,v in pairs(t) do
        append(res,{k,v})
    end
    return res
end

return _M  -- orbiter.html !
