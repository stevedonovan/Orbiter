-- Orbiter, a personal web application framework
-- various general facilities like extra table operations and a simple
-- class-based OOP scheme.

local append = table.insert
local _M = {}

--- extended type of a value. If the value is a table and it has a metatable,
-- then that metatable is the type.
function _M.type_of(val)
    local tv = type(val)
    if (tv == 'table' or tv=='userdata') and getmetatable(val) then
        return getmetatable(val)
    else 
        return tv
    end
end

local Class = {}

function _M.class(base)
    local mt = {}
    base = base or Class
    table.update(mt,base)
    mt._base = base
    mt.__index = mt    
    setmetatable(mt,{
        __call = function (cmt,...) -- Type(args) is the constructor
            local obj = {}
            setmetatable(obj,mt)                
            if obj.init then obj:init(...) end
            return obj
        end
    })
    return function(body)
        if body then table.update(mt,body) end
        return mt
    end
end

--- is val an instance of the class type type?.
-- @param val any value
-- @param type a class type (metatable)
function _M.class_of(val,tp)
    local mt = _M.type_of(val)
    if type(mt)=='table'  then
        while mt do
            if mt == tp then return true end
            mt = mt._base
        end
    end
    return false
end

function table.is_plain(t)
    return type(t) == 'table' and getmetatable(t) == nil
end

function table.is_list(t)
    return table.is_plain(t) and #t > 0
end

function table.copy(t)
    local res = {}
    for k,v in pairs(t) do res[k] = v end
    return res
end

function table.copy_list(t)
    local res = {}
    for k,v in ipairs(t) do res[k] = v end
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

function table.imap(fun,t,i1,i2)
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

function _M.compose (f1,f2)
    return function(...)
        return f1(f2(...))
    end
end

function table.concat_list(l1,l2)
    l1,l2 = table.force(l1), table.force(l2)
    local res = {unpack(l1)}
    for _,v in ipairs(l2) do
        append(res,v)
    end
    return res
end

function table.reshape2D(t,ncols)
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

function table.dimensions(t)
    if type(t) ~= 'table' or #t == 0 then
        return nil
    end
    local n = #t
    local m = type(#t)=='table' and #t[1] or nil
    return n,m
end

function table.flatten(t)
    local n,m = table.dimensions(t)
    assert(m ~= nil,"must be a 2D array")
    local res = {}
    local k = 1
    for i = 1,n do for j = 1,m do
        res[k] = t[i][j]
        k = k + 1
    end end
    return res
end

function table.transpose(t)
    local nrows,ncols = table.dimensions(t)
    local arr  = table.flatten(t)
    return table.reshape2D(arr,nrows)
end

return _M
