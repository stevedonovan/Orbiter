local orbiter = require 'orbiter'
local html = require 'orbiter.html'

--local dump = require 'pl.pretty'.dump

-- constraints

function range(x1,x2)
    return function(x)
        if x < x1 or x > x2 then return false,'must be between %f and %f' % {x1,x2} 
        else return x end
    end
end

function match(pat,err)
    return function(s)
        if not s:find(pat) then return false,err else return s end
    end
end

non_blank = match('^%S+$', 'may not be blank')

function irange(n1,n2)
    return function(x)
        if x < n1 or x > n2 then return false,'must be between %d and %d' % {n1,n2} 
        elseif math.floor(x) ~= x then return false,'must be an integer'
        else return x
        end
    end
end

local converters = {
    number = {
        tostring = tostring,
        parse = function(s)
            local res = tonumber(s)
            if not res then return false,'not a number'
            else return res
            end
        end
    },
    boolean = {
        tostring = tostring,
        parse = function(s) return s=='true' and true or false end
    },
    string = {
        tostring = tostring,
        parse = tostring,
    }
}

local input,select,option,form_ = html.tags 'input,select,option,form'

local function generate_control(obj,var,constraint)
    local value = obj[var]
    local vtype = type(value)
    local cntrl
    local converter = converters.string
    if vtype == 'number' then
        converter = converters.number
        cntrl = input{type='text',name=var,value=converter.tostring(value)}
    elseif vtype == 'boolean' then
        converter = converters.boolean
        cntrl = input{type='checkbox',name=var,value=converter.tostring(value)}
    elseif vtype == 'string' then
        if table.is_list(constraint) then
            cntrl = select{name=var}
            for i,v in ipairs(constraint) do
                cntrl[i] = option{value=v,v}
                if v == value then
                    cntrl[i].selected = 'selected'
                end
            end
            constraint = nil
        else
            cntrl = input{type='text',name=var,value=value}
        end
    end
    return cntrl,converter,constraint
end

local form = {}

function form.new (t)    
    local f = { spec_of = {}, spec_table = t }
    f.validate = form.validate
    f.show = form.show
    return f
end

function form.show (self)
    local append = table.insert
    local t = self.spec_table
    local obj = t.obj
    local res = {}
    for i = 1,#t,3 do
        -- each row has these three values
        local label,var,constraint = t[i],t[i+1],t[i+2]
        local cntrl,converter,constraint = generate_control(obj,var,constraint)
        local spec = {label=label,cntrl=cntrl,converter=converter,constraint=constraint} 
        append(res,spec)
        self.spec_of[var] = spec
    end
    -- wrap up as a table
    self.spec_list = res
    local tbl = {}
    for i,item in ipairs(res) do
        tbl[i] = {item.label,item.cntrl}
    end
    self.body = form_{
        name = t.name;
        action = t.action;
        method = t.method;
        html.table{  data = tbl   },
        input {type='submit',value='submit'}
    }
    return self.body
end



function form.validate (self,values)
    local ok = true    
    local res = {}
    --pretty.dump(values)
    for var,value in pairs(values) do
        local spec = self.spec_of[var]
        if spec then
            spec.cntrl:set_attrib('value',value)
            local val,err = spec.converter.parse(value)
            if val and spec.constraint then
                val,err = spec.constraint(val)
            end
            if err then
                ok = false
                spec.cntrl:set_attribs {
                    style='background:pink',
                    title = err
                }
            else
                res[var] = val
            end
        end
    end
    if not ok then
        return false, self.body
    else
        table.update(obj,res)
        return true
    end
end


local app = orbiter.new(html)

obj = {
    name = 'John',
    phone = '+8999',
    title = 'Dr',
    age = 25
}

local f = form.new {
    obj = obj; 
    action = '/results'; name = 'form1';
    'Name','name',non_blank,
    'Phone','phone',match('^%+%d+','must be international number +DDDDD...'),
    'Title','title',{'Mr','Ms','Dr','Prof','Rev'},
    'Age','age',irange(10,120),
}

local h2 = html.tags 'h2'

function app:show(web)
    return html {
        h2 'Auto Generated Form',
        f:show()
    }
end

local  hashlist = html.list:specialize {map = html.map2list, render = '%s = %s'}

function app:request(web)
    local ok,resp = f:validate(web.input)
    if ok then
        return html {
            h2 'Form Results',
            hashlist { data = obj }
        }
    else
        return html {
            h2 'Errors in Form',
            resp
        }
    end
end

app:dispatch_get(app.show,'/')
app:dispatch_get(app.request,'/results')

app:run(...)

