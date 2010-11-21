## Orbiter - a self-contained personal Web Framework

_Steve Donovan, 2010 (MIT/X11)_

Cross-platform users interfaces remain tricky to deploy, but web browsers are ubiquitous. So the idea of an application providing its interface over HTTP is popular.

[Orbit](http://keplerproject.github.com/orbit) is my personal favourite among building-from-scratch Web frameworks (as opposed to Wiki engines like [Sputnik](http://github.com/yuri/sputnik)), but the full [Kepler](http://github.com/keplerproject/kepler) stack can be a bit awkward to set up, especially under the following conditions:

 - a small script requires an interface
 - a program with embedded Lua needs an interface
 - a program has a strict memory budget (e.g. embedded)

Well, imitation being the most sincere form of flattery led to Orbiter, which is a mini-Orbit.  The basic Orbiter core (built-in web server and pattern dispatch) is about 450 lines and only depends on LuaSocket.  However, the design is intended to be as extensible as possible;  `orbiter.html` provides an HTML-generating module which is useful but not essential.

Orbiter is a Lua library that scripts can use to launch their interfaces using their own private web server.   One of the consequences of this is that debugging Orbiter scripts is much more straightforward.

The other reason for Orbiter's existence is as a testing ground for new techniques. For instance, I wished to push the LOM document generation model as far as possible to see its strengths and weaknesses. And to see if a clear and straightforward declarative style can generate good-looking and functional interfaces, hiding the often messy interaction between CSS, JavaScript and HTML.

### Hello, World

    -- hello.lua
    local orbiter = require 'orbiter'

    local hello = orbiter.new()

    function hello:index(web)
        return ([[
            <html><body>
            <h2>Hello, Lua!</h2>
            <img src='/images/logo.gif'/>
            Lua memory used is %5.0f kB
            </body></html>
        ]]):format(collectgarbage 'count')
    end

    hello:dispatch_get(hello.index,'/','/index.html')
    hello:dispatch_static '/resources/images/.+'

    hello:run(...)

This first example is very Orbit-like, except for a move away from using  `module` and a move towards a more object-oriented model.  (Lua 5.2 is still a work in progress but the `module` function has definitely been deprecated.)

A big difference is that this is a _program_; you can run `lua hello.lua` from the shell and it will start serving up pages in a browser. If the browser is already open, it will open a page, otherwise launch the browser.  On my system the Lua memory returned by `collectgarbage` is about 80 kb for this script.

Like Orbit, pages can be served statically, although such patterns need to explicitly declared (this is not a path but a Lua string pattern.)  So where do the static pages live?  Oribiter assumes that the directory of the script is the root of the static filesystem for _this application_ object.  For instance, the Orbiter library also has a `resources` directory which contains `favicon.ico` and a static pattern matching it.  When the browser asks for `/resources/favicon.ico`, Orbiter will look it up within its _own_ resources directory..  This also goes for any extension modules; if their objects call `dispatch_static` then these patterns are looked up in their own private resources directories.  (As with any system, thinking clearly about namespaces is essential.)

Orbiter provides a convenient test mode where you pass it a URL and see exactly what it would return to the browser:

    $> lua hello.lua --test=/
    HTTP/1.1 200 OK
    Content-Type: text/html
    Content-Length: 156
    Connection: close

        <html><body>
        <h2>Hello, Lua!</h2>
        <img src='/images/logo.gif'/><br/>
        Lua memory used is    88 kB
        </body></html>


### Orbiter and HTML Generation

    -- simple-html.lua
    local orbiter = require 'orbiter'
    local html = require 'orbiter.html'

    local simple = orbiter.new(html)

    local h2,p = html.tags 'h2,p'

    function simple:index(web)
        return html {
            title = 'A simple Orbiter App';
            h2 'Simple to do easy stuff',
            p 'complex stuff made manageable',
            html.list {
                render = html.link;
                {'/section/first',"First section"},
                {'/section/second',"Second Section"}
            }
        }
    end

    function simple:sections(web,name)
        return html {h2 (name)}
    end

    simple:dispatch_get(simple.index,'/', '/index.html')
    simple:dispatch_get(simple.sections, '/section/(.+)')

    simple:run(...)

This example will also seem familar to Orbit programmers, especially the 'htmlification' in expressions like `h2 'Simple to do easy stuff'`. However, the tags used must be predeclared.  Not so convenient, but in practice it is better to let Lua crash on an undefined tag than risk generating odd HTML.

The method used by `orbiter.html` is to generate LOM (Lua Object Model) trees and pretty-print them into valid (X)HTML.  One advantage of this over Orbit htmlification is that the result tends to be easier to read (it is 'beautified').  But please note the `orbiter.new(html)`; we have to tell Orbiter that this object's handlers will not be returning plain-jane text, but LOM documents.  Under the hood, after the handlers have been called, then the `content_filter` method of the application object is called. This can be defined by the application, but the convention is that if an extension wishes to change what the core sees and sends out, it shall define a `content_filter` function and so passing the extension to `orbiter.new` will install that content filter.  In this case, the content filter converts the LOM document into pretty text.

Another feature of `orbiter.html` is that it provides functions to create common HTML things like lists and tables.  For instance, `html.list` is given an array (a list-like table) and by default makes an unordered list (if the table contains `type='#'` it will do an ordered list.)  By default, each item in the table is put directly inside `<li>` tags, but you can provide a `render` function which will first convert the table items.  In this case, the `html.url` function takes a table argument `{URL,text}` and we end up with a list of links.

It is perfectly possible to use `orbiter.html` with Orbit itself, there is nothing magical going on, except that you do have to call `html.as_text` explicitly to render the LOM before it is returned by the handler. See `examples/orbit2.lua`.

### Templates, Format Operator and Renderers

Again, `orbiter.html` is not compulsory.  You can use [Cosmo](http://cosmo.luaforge.net/), for instance.

`orbiter.text.Template` (contained in `orbiter.text`) is a very straightforward and stupid template facility for simple tasks. E.g.

    local results = text.Template [[
        <h2>Form Variables</h2>
        $body1
        <h2>HTTP Headers</h2>
        $body2
    ]]

defines a template which is callable, so that `results { body1 = vars_list, body2 = headers }` will expand the template replacing with the contents of the table.

This module also overloads the modulo operator (see the [wiki](http://lua-users.org/wiki/StringInterpolation) for the original) so that `'hello %s' % 10` is entirely equivalent to `('hello %s'):format(10)` - this remains useful for the common case of wanting control over floating-point formats. This Python-style formatting supports `'%s = %s' % {'cat','felix'}` but also `'$animal = $name' % {animal='cat',name='felix'}`.

It is common in `orbiter.html` to specify a render function to convert data items into text.  As a convenience, the concatenation operator `..` has been defined for functions and means 'function composition'.  That is,

    f .. g   === function(...) return f(g(...)) end
    
It is useful to play with the LOM-generation facilities directly in an interactive prompt. (Remember these functions do not generate text directly, but these LOM objects have a `__tostring` metamethod that prints them out nicely.)
    
    $ lua 
    Lua 5.1.4  Copyright (C) 1994-2008 Lua.org, PUC-Rio
    > H = require 'orbiter.html'
    > = H.image 'lua.png'
    <img src='lua.png'/>
    > fn = H.image .. '/images/%s.png'
    > = fn 'lua'
    <img src='/images/lua.png'/>
    > = H.list{'one','two','three',render=H.image .. '/images/%s.png'}
    <ul>
      <li>
        <img src='/images/one.png'/>
      </li>
      <li>
        <img src='/images/two.png'/>
      </li>
      <li>
        <img src='/images/three.png'/>
      </li>
    </ul>
    
Here format strings are considered to be functions, defined by the `%` format operator.  So this notation is shorthand for the following function:

    render = function(s) return H.image('/images/%s.png' % s) end

Both `html.list` and `html.table` also take a `map` function, which is used to reform the data first. `html.map2list` takes a table of name/value pairs and makes it into a list of pairs, e.g. `{A=B}` becomes `{{A,B}}`. In this case, we do not get any particular order of the pairs, since order is not defined for hash data.

    > animals = {dog='bonzo',cat='felix'}
    > = H.list{data=animals,map=H.map2list,render='%s = %s'}
    <ul>
      <li>cat = felix</li>
      <li>dog = bonzo</li>
    </ul>

We've seen the `html.tags` function, which generates tag constructor functions. You can use any tags, and it will cheerfully generate XML with them.

    > fred,alice = H.tags 'fred,alice'
    > = fred{alice'band'}
    <fred>
      <alice>band</alice>
    </fred>
    
    
Together with `..`, the custom function metatable also provides a 'method' called `specialize`:

    > fred = fred:specialize{class='formal'}
    > return  fred{alice'band'}
    <fred class='formal'>
      <alice>band</alice>
    </fred>

There is another way to specialize tag functions, which is to use the alternate syntax for `html.tags`, where it is given a list of tag specifiers:

    > text,button = H.tags {  {'input',type='text',name=1},
    .. {'input',type='submit',value=1} }
    > = text 'hello'
    <input name='hello' type='text'/>
    > = button 'help'
    <input value='help' type='submit'/>

Note how the special field/value combination `name = 1` which says that the single argument of the resulting constructor shall be assigned to the attribute `name`.

This makes for more readable forms:

    form{
      name='form1',action='/results',method='post';
      html.table { cols = 2;
      "first parameter", text "first",
      "second parameter", text "second",
      },
      button 'submit'
    }

### User Input

This is done just as with Orbit; a handler may receive any captures from its string pattern:

    simple:dispatch_get(simple.sections, '/section/(.+)')

So the links `/section/first` and `/section/second` both go to `simple.sections`, with `first` and `second` as the extra argument.

The first argument to any handler is usually called `web` and it will contain any variables encoded in the URI. So `/section/first?p=hello` will result in `web.GET.p` being set to 'hello'.

Data from forms is usually sent using the POST method, and then `web.POST` contains the variables.  For both methods, `web.input` contains the combined variables.

`web.vars` contains HTTP request headers, like `HTTP_USER_AGENT` and `HTTP_CONTENT_TYPE`.

### Fun with Dynamic Dispatch

It would be cool if Orbiter handlers could be written like so:


    function dyn:handle_first (web,rest)
       return self:layout( h2 'first', p(rest) )
    end

    function dyn:handle_second_case (web,rest)
        return self:layout( h2 'second case', p(rest) )
    end

    function dyn:layout(...)
        return html {
            title = 'A Dynamic Orbiter App';
            body = {...}
        }
    end

The idea is that `handle_first` would be called for any pattern begining with `/first...', and `handle_second_case` would be called for `/second/case..`

The first thing is to define a _catch-all_ handler, which works for both GET and POST requests:

    dyn:dispatch_any(dyn.dynamic_dispatch,'/.*')

and make everything get routed through this method:

    local registered = {}

    function dyn:dynamic_dispatch(web, path)
        if path:find '_' then path = path:gsub('_','/') end
        local handler = web.method..path:gsub('/','_')
        -- find a handler which can match this request
        local obj_method, pattern
        local mpat = '^'..web.method
        for m in pairs(self) do
            if m:find (mpat..'_') then
                local i1,i2 = handler:find(m,1,true)
                if i1 == 1 then -- we can match, e.g. get_first_try
                    obj_method = m
                    -- we use the pattern appropriate for the handler,e.g.
                    -- get_first becomes '/first(.*)'
                    pattern = obj_method:gsub(mpat,''):gsub('_','/')..'(.*)'
                    break
                end
            end
        end
        if obj_method then
            -- register the handler dynamically when first encountered
            if not registered[handler] then
                local dispatch = web.method=='get' and self.dispatch_get or self.dispatch_post
                dispatch(self,self[obj_method],pattern)
                registered[handler] = true
            end
        else -- we fall back; there's no handler ---
            return self:layout( h2 'Index!', p('path was '..path) )
        end
        return self:dispatch(web,path)
    end


So the first time it encounters something like `/first/try` it will try to match a handler with the name of `handle_first_try`; we find `handle_first` so we attach that handler to the pattern `/first(.*)`.  After registration, we can ask ourselves to dispatch that first pattern, and `handle_first` will be invoked. The extra stuff in the URL is captured as the variable `rest` passed to the handler.  See `examples/dynamic.lua` for the working example.

#### A note on pattern matching

All patterns are assumed to be anchored and need to span the whole address (i.e. they become '^..$'). It is still possible for more than one pattern to match; in this case, the longest pattern wins, since it is the most specific. General string patterns (like /(.-)(/.*)) can be long but still very general, so the hack is to compare lengths after removing any magic characters.

If the same pattern is registered with a new handler, that new handler replaces the old handler.  This can be useful for extensions that wish to override styles, etc.

### A Little Application Server

An Orbiter application can load other Orbiter applications; only the first app to call the `run` method succeeds in starting the server.  It is trivial to compile and load Lua scripts on the fly, but the _interesting_ problem is how to manage the namespaces.  After all, most scripts tend to generate something for '/', and if these scripts are all loaded, then the patterns must be somehow modified so that they can co-exist.

`appserver.lua` handles this by monkey-patching `orbiter.new` and redefining the `dispatch_*` methods of the new app object.  So if a script `hello.lua` has a match '/', the modified `dispatch_get` will prepend `hello` so the match is '/hello/', and so forth.  So all the app object patterns will hopefully be in separate namespaces.

But what about links inside generated HTML?  Rather than worry about modifying HTML generation, Orbiter provides a mechanism for examining the incoming requests and potentially modifying them - the _request filter_.  `appserver.lua` defines a request filter that looks at the 'referer' header (which in WSAPI style is `web.vars.HTTP_REFERER`) and deduces the application that originated the request.  It can then again prepend the application name as the namespace and continue as before.

`appserver` is not yet working with `dynamic.lua`, but this is a goal.

There is an entertaining difference between entering '/hello' and '/hello/' - the first case does not represent a valid `hello` pattern, so it always gets shunted through `appserver`s handler. This means that if `hello.lua` changes, it will be automatically reloaded, which can be very useful.  In the second case, '/hello/' _is_ a pattern supported by `hello`, so it never goes through `appserver`.  I've yet to decide whether this is a bug or a feature.

### Widgets: Prepackaged Functionality

Web programming is often an untidy mix of server-side code and client-side HTML, CSS and JavaScript. Being basically a desktop GUI programmer by inclination and training,  I feel that there should be more disciplined separation of these functions.

Consider the simple two-level drop-down menu presented at [javascript-array.com](http://javascript-array.com/scripts/simple_drop_down_menu/). The implementation is straightforward, about forty lines of JavaScript with the magic chiefly done by the stylesheet, but the markup is awkward.  Fortunately we don't have to construct this by hand (or by template)  since `orbiter.html` is geared towards precisely this kind of data transformation into markup.

First, the code is put into its own module, `orbiter.widgets.dropdown`. Since the stylesheet and code is so short, we can inline it efficiently.  The `html.set_defaults` function can be used to add items to the `<head>` element of the generated HTML code for the application. In this case, we set the `inline_style` and the `inline_script` fields.  (These fields are in general lists, so they are added to any existing defaults.)

The actual transformation is straightforward:

    local a,div = html.tags 'a,div'

    local function item(label,idx,items)
        local id = "m"..idx
        local link = a { href='#',onmouseover="mopen('"..id.."')",onmouseout="mclosetime()", label}
        local idiv = div {id = id, onmouseover="mcancelclosetime()" ,onmouseout="mclosetime()"}
        local j = 1
        for i = 1,#items,2 do
            idiv[j] = html.link(items[i+1],items[i])
            j = j + 1
        end
        return { link, idiv }
    end

    function _M.menu(items)
        local ls = {}
        local j = 1
        for i = 1,#items,2 do
            ls[j] = item(items[i],j,items[i+1])
            j = j + 1
        end
        ls.id = 'sddm'
        return html.list(ls)
    end

To use the menu, all an application has to do is require the particular widget module and call its `menu` function:

    local dropdown = require 'orbiter.widgets.dropdown'
    
    ....
    
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
        ....
    end        

In this way, the implementation details (no matter how sordid) can be kept away from the main application, which accesses the functionality in a natural Lua style.

(An advantage of this inline approach is that it's easy to make the styles into templates, so that the application has an opportunity to harmonize the drop-down menu styles with its own chosen theme.)

The second example widget wraps up the [Tigra Calendar](http://www.softcomplex.com/products/tigra_calendar/).  Here the script is more substantial and there are a number of small images which make  the control look good, so the sensible approach here is to serve up the scripts, styles and images statically.

`orbiter.widget.calendar` shows the strategy; we use `dispatch_static` for these resources, and use `set_defaults` to set `scripts` and `styles`, which are URIs.  Remember, for Orbiter these resources are local to the module, with the convention that they are in a `resources` folder next to the module.  This allows a widget-style extension to deliver just about anything, like a style theme or an icon set.

The actual code is an anti-climax:

    function _M.calendar(form,control)
        return html.script ( [[
        new tcal ({
            'formname': '%s',
            'controlname': '%s'
        });   
        ]] % {form,control} )
    end

Since such widgets could be useful for Orbit programmers as well, I've introduced some bridging code so that Orbit applications can also use Orbiter widgets. Look at the `dropdown-orbit.lua` example - the key statements are:

    local bridge = require 'orbiter.bridge'

    module("dropdown_test", package.seeall, orbit.new, bridge.new)

That is, `bridge.new` becomes another function that gets called with the new module object.  Please note that the actual widgets must be loaded _after_ the `module` statement, since they may want to setup some static dispatches. This is somewhat clumsy, and likely to change in later versions: but the point is that the non-core parts of Orbiter can be used by Orbit.

### Future Work

I have deliberately not tried to implement things like Orbit's ORM (Object-Relational Mapping) since it would add complexity and move beyond my limited areas of competence. (The time is probably ripe for a standalone Lua ORM library anyway.)

The strategy for finding the resource directory of an extension or application is not sufficiently general to cope with LuaRocks deployment. This will require some extra work.

Being a 'personal' app server makes life more interesting, in particular much more free use of the local filesystem.  It is an ideal situation; fat bandwidth, very low latency and plenty of server power.  Using Lua tables as persistent data structures is attractive under those circumstances.

Generating HTML has always been straightforward, but producing good-looking functional pages involves getting both software and visual design together. Often one suffers at the expense of the other.  One way forward is to work at a higher level, providing prepackaged 'widgets' and making it easy to work with stylesheets in a programmatical way.




