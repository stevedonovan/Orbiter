-- Orbiter, a personal web application framework
-- HTML generation using luaexpat LOM format;
-- this provides some higher-level functions for generating HTML lists
-- and tables.

local _M = {} -- our module
--local doc = require 'lxp.doc'
local doc = require 'orbiter.doc'
local text = require 'orbiter.text'
local append = table.insert

local imap,compose,concat_list,reshape2D

_M.is_doc = doc.is_tag
_M.elem = doc.elem

function _M.tostring(d)
    return doc.tostring(d,'','  ')
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
    local items = concat_list(t[field],defaults[field])
    if #items == 0 then return end
    for _,item in ipairs(items) do
        local hi = {type=rtype}
        if tag == 'link' then
            hi.rel = 'stylesheet'
        end
        if source then
            hi[source] = item
        else
            hi[1] = item
        end
        append(head,doc.elem(tag,hi))
    end
end

function _M.document(t)
    local head = doc.elem('head',doc.elem('title',t.title or 'Orbiter'))
    make_head(head,t,'styles','link','text/css','href')
    make_head(head,t,'scripts','script','text/javascript','src')
    make_head(head,t,'inline_style','link','text/css')
    make_head(head,t,'inline_script','script','text/javascript')
    local data = t.body or t

    local body = doc.elem 'body'
    for i = 1,#data do body[i] = data[i] end
    return doc.elem('html',{head,body})
end

function _M.as_text(t)
    return _M.tostring(_M.document(t))
end

--- the module is directly callable.
-- e.g. html { title = 'hello'; .... }
setmetatable(_M,{
    __call = function(o,t)
        return _M.document(t)
    end
})

-- the handlers can now return LOM, tell Orbiter about this...
function _M.content_filter(self,content,mime)
    if _M.is_doc(content) then
        return _M.tostring(content), 'text/'..content.tag
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
    if type(addr) == 'table' then addr,text = addr[1],addr[2] end
    return a{href=addr,text}
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
     end
    return fun
end

local function copy_common(src,dest)
    dest.id = src.id
    dest.style = src.style
    dest.class = dest.class
end

local function table_arg(t)
    assert(type(t) == 'table')
    local data = t.data or t
    if t.map then
        data = t.map(data)
    end    
    assert (#data > 0) 
    return data
end

local ul,ol,li = doc.tags 'ul,ol,li'

--- Generate an HTML list.
-- t must be a single-dimensional array
-- The list will be unordered by default, set t.type to 'ordered' or '#'
function _M.list(t)
    local data = table_arg(t)
    local ctor = (t.type=='ordered' or t.type=='#') and ol or ul
    local each = item_op(li,t)
    local res = imap(each,data,t.start,t.finish)
    copy_common(t,res)
    return ctor(res)
end

local _table,tr,td,th = doc.tags 'table,tr,td,th'

--- Generate an HTML table.
-- Data is either t itself or t.data if it exists, and must be a 2D array.
-- If t.headers is an array of names, then the table will have a header.
-- You can specify a range of indices to use in the data using t.start and t.finish
-- (this is useful if using t.data)
function _M.table(t)
    local data = table_arg(t)
    if t.cols then data = reshape2D(data,t.cols) end
    local each = item_op(td,t)
    local function row_op(row)
        return tr (imap(each,row))
    end
    local res = imap(row_op,data,t.start,t.finish)
    if t.headers then
        local hdrs =  tr (imap(th,t.headers))
        table.insert(res,1,hdrs)
    end
    res.border = t.border --???
    copy_common(t,res)
    return _table(res)
end

function _M.map2list(t)
    local res = {}
    for k,v in pairs(t) do
        append(res,{k,v})
    end
    return res
end

------ useful support functions local to this module -----

function imap(fun,t,i1,i2)
    local res = {}
    i2 = i2 or #t
    i1 = i1 or 1
    local j = 1
    for i = i1,i2 do
        res[j] = fun (t[i])
        j = j + 1
    end
    return res
end

function compose (f1,f2)
    return function(...)
        return f1(f2(...))
    end
end

function concat_list(l1,l2)
    l1,l2 = table.force(l1), table.force(l2)
    local res = {unpack(l1)}
    for _,v in ipairs(l2) do
        append(res,v)
    end
    return res
end

function reshape2D(t,ncols)
    local res = {}
    local row = {}
    for i = 1,#t do
        append(row,t[i])
        if i % ncols == 0 then
            append(res,row)
            row = {}
        end
    end
    return res
end

function table.copy(t)
    local res = {}
    for k,v in pairs(t) do res[k] = v end
    return res
end

function table.update(t1,t2)
    for k,v in pairs(t2) do t1[k] = v end
end

function table.force(t)
    if type(t) ~= 'table' then return {t}
    else return t
    end
end

function table.copy_map(t)
    local res = {}
    local sz = #t
    for k,v in pairs(t) do
        if type(k)~='number' or k <= 0 or k > sz then
            res[k] = v
        end
    end
    return res
end

function table.index_of(t,val)
    for k,v in pairs(t) do
        if v == val then return k end
    end
end


return _M  -- orbiter.html !
