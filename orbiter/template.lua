-- Orbiter, a personal web application framework
-- Lua template preprocessor
-- Originally by Ricki Lake.
--

local append,format = table.insert,string.format

local parse1,parse2 = "()","(%b())()"
local parse_dollar

local load = load

if _VERSION:match '5%.1$' then -- Lua 5.1 compatibility
    function load(str,name,mode,env)
        local chunk,err = loadstring(str,name)
        if chunk then setfenv(chunk,env) end
        return chunk,err
    end
end

local function parseDollarParen(pieces, chunk, s, e)
    local s = 1
    for term, executed, e in chunk:gmatch (parse_dollar) do
        append(pieces,
            format("%q..(%s or '')..",chunk:sub(s, term - 1), executed))
        s = e
    end
    append(pieces, format("%q", chunk:sub(s)))
end
-------------------------------------------------------------------------------
local function parseHashLines(chunk)
    local pieces, s, args = chunk:find("^\n*#ARGS%s*(%b())[ \t]*\n")
    if not args or find(args, "^%(%s*%)$") then
        pieces, s = {"return function(_put) ", n = 1}, s or 1
    else
        pieces = {"return function(_put, ", args:sub(2), n = 2}
    end
    while true do
        local ss, e, lua = chunk:find ("^#+([^\n]*\n?)", s)
        if not e then
            ss, e, lua = chunk:find("\n#+([^\n]*\n?)", s)
            append(pieces, "_put(")
            parseDollarParen(pieces, chunk:sub(s, ss))
            append(pieces, ")")
            if not e then break end
        end
        append(pieces, lua)
        s = e + 1
    end
    append(pieces, " end")
    return table.concat(pieces)
end

local template = {}

function template.substitute(str,env)
    env = env or {}
    if env.__parent then
        setmetatable(env,{__index = env._parent})
    end
    local out,res = {}
    parse_dollar = parse1..(env.__dollar or '$')..parse2
    local code = parseHashLines(str)
    local fn,err = load(code,'TMP','t',env)
    if not fn then return nil,err end
    res,fn = pcall(fn)
    if not res then return nil,err end
    res,err = pcall(fn,function(s)
        out[#out+1] = s
    end)
    if not res then return nil,err end
    return table.concat(out)
end

function template.page(file,env)
    local f,err = io.open(file)
    if not f then return nil, err end
    local tmpl = f:read '*a'
    f:close()
    return template.substitute(tmpl,env)
end

return template




