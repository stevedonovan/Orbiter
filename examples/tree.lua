local orbiter = require 'orbiter'
local html = require 'orbiter.html'
local util = require 'orbiter.util'
local jq = require 'orbiter.libs.jquery'
local data_to_id,set_handler,set_data = jq.data_to_id, jq.set_handler, jq.set_data

local app = orbiter.new(html)

html.set_defaults {
    styles = "/resources/css/jquery.treeview.css",  
    scripts = "/resources/javascript/jquery.treeview.js",
    inline_script = [[
    function treeview_create(id,body) {
        var select = "#"+id;
        if (body.length == 0)
            $(select).treeview();
        else {
            var bb = $(body).appendTo(select);  //  replaceAll appendTo
            $(select).treeview({add: bb});
        }
        jq_set_click(select+" li",id);
    }
    ]]
}

-- make sure we can serve the above resources and the images associated
-- with the style sheet
app:dispatch_static('/resources/css/.+')
app:dispatch_static('/resources/javascript/.+')


local span,li = html.tags 'span,li'

local function tree_request_handler(klass,idata,tdata,id)
    if klass:find('collapsable') then
        return jq.call_handler(idata,tdata,id,'expanding')
    elseif klass:find('expandable') then
        return jq.call_handler(idata,tdata,id,'collapsing')
    else
        return false
    end
end

-- this generates the <span> inside the <li> that contains a file tree node.
-- the id is a representation of the data, the label is tostring(data);
-- this id becomes the id of the <li> when li() gets this as an argument.
function file (data)
    local label = tostring(data)
    local args = {label,class='file'}
    if data.attribs then
        table.update(args,data.attribs)
    end
    return {        
        span(args),
        id = data_to_id(data)
    }
end

Labelled = util.class() {
    __tostring = function(self) return self.label end
}

link = util.class(Labelled) {
    init = function(self,url,label)
        self.label = label
        self.attribs = {
            title = url
        }
    end;
}

local Folder = util.class(){
    init = function(self,t) table.update(self,t) end
}

function process_children(children)
    for i,item in ipairs(children) do
        if not util.class_of(item,Folder) and not html.is_doc(item) then 
            children[i] = file(item)
        end
    end
end

function fragment(children)
    local ff = folder(children)
    return li(ff)
end

-- likewise, the <span> inside the <li> of a folder tree node
function folder (children)
    local label = table.remove(children,1)
    local hidden = children.hidden
    children.hidden = nil
    local data = children.data or label
    children.data = nil    
    if hidden and #children==0 then children = {''} end
    process_children(children)
    return Folder{span{label,class='folder'},
               html.list(children),id=data_to_id(data),class=hidden and 'closed' or nil}
end


action = util.class(Labelled) {
    init = function(self,label,action)
        self.label = label
        self.click = action
    end,
}

-- return the HTML list, plus some JS to create the treeview and associate
-- a click event with its <li> elements
function treeview (t)
    local id = t.id
    if not id then error("must supply id for treeview") end
    t.class = 'filetree'
    local this = set_data(id,t.data)
    this.click_handler = tree_request_handler
    set_handler('click',id,t)
    set_handler('expanding',id,t)
    set_handler('collapsing',id,t)
    return {         
        html.list(t),
        html.script ('treeview_create("%s","")' % id)
    }
end

function tree_fragment(id,t)
    local bb = fragment(t)
    local markup = html.raw_tostring(bb)
    print('markup\n',markup)
    return 'treeview_create("%s","%s")' % {id,markup}
end

function add_tree(t)
    return function() return tree_fragment(t.id,t) end
end        

-- note that any item in the html list can itself be a simple list; in this case
-- the items will be appended to the list. This allows the treeview() function
-- to do its magic without needing to return a single element.
function app:index(web)
    return html {
        treeview{id='browser'; 
            click = function(data)
                return jq.alert("clicked "..tostring(data))
            end;
            expanding = function(data)
                return jq.alert("expanding "..tostring(data))
            end;
            folder{'hello',
                'hello again',
                action('click me',function() return jq.alert 'thanks!' end),
                folder{'dolly',
                    folder{"alice",
                        "band", "wonderland"
                    },
                    folder{'fred',
                        hidden = true,
                        'fred','Pebbles','Wilma',
                        }
                },
                link('http://snippets.luacode.org','so fine')
             }
        },
        jq.button('Add',add_tree{id="browser",
                    "more",
                    'and again',
                    'finally'
        });            
    }
end

app:dispatch_get(app.index,'/')


app:run(...)
