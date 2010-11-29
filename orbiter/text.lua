-- Orbiter, a personal web application framework
-- Yet another little template expansion function, but dead simple (promise!).
-- Also supports Python-like string formatting by overloading % operator.
-- (see http://lua-users.org/wiki/StringInterpolation
local _M  = {}

local function basic_subst(s,t)
    return (s:gsub('%$([%w_]+)',t))
end

local format = string.format

local function formatx (fmt,...)
    local args = {...}
    local i = 1
    for p in fmt:gmatch('%%s') do
        if type(args[i]) ~= 'string' then
            args[i] = tostring(args[i])
        end
        i = i + 1
    end
    return format(fmt,unpack(args))
end

--- Python-like string formatting with % operator.
-- Note this goes further than the original, and will allow these cases:
-- 1. a single value
-- 2. a list of values
-- 3. a map of var=value pairs
-- 4. a function, as in gsub
-- For the second two cases, it uses $-variable substituion.
getmetatable("").__mod = function(a, b)
    if not b then
            return a
    elseif type(b) == "table" then
            if #b == 0 then -- assume a map-like table
                return basic_subst(a,b)
            else
                return formatx(a,unpack(b))
            end
    elseif type(b) == 'function' then
        return basic_subst(a,b)
    else
            return formatx(a,b)
    end
end

--- really basic templates;
-- t = text.Template 'hello $world'
-- print(t:subst {world = 'dolly'}).
-- (Templates are callable so subst is unnecessary)
function _M.Template(str)
    local tpl = {s=str}
    function tpl:subst(t)
        return basic_subst(str,t)
    end
    setmetatable(tpl,{
        __call = function(obj,t)
            return obj:subst(t)
        end
    })
    return tpl
end

function _M.subst(str,t)
    return _M.Template(str):subst(t)
end

return _M -- orbiter.text
