## Orbiter - a self-contained personal Web Framework

_Steve Donovan, 2010 (MIT/X11)_

Cross-platform users interfaces remain tricky to set up, but web browsers are ubiquitous. So the idea of an application providing its interface over HTTP is popular.

Orbit is my personal favourite among building-from-scratch Web frameworks (as opposed to Wiki engines like Sputnik), but the full Kepler stack can be a bit awkward to set up, especially under the following conditions:

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
    hello:dispatch_static '/images/.+'

    hello:run(...)

This first example is very Orbit-like, except for a move away from using  `module` and a move towards a more object-oriented model.  (Lua 5.2 is still a work in progress but the `module` function has definitely been deprecated.)

A big difference is that this is a _program_; you can run `lua hello.lua` from the shell and it will start serving up pages in a browser. If the browser is already open, it will open a page, otherwise launch the browser.  On my system the Lua memory returned by `collectgarbage` is about 80 kb for this script.

Like Orbit, pages can be served statically, although such patterns need to explicitly declared (this is not a path but a Lua string pattern.)  So where do the static pages live?  Oribiter assumes that the script is next to a `resources` directory, which is the root of the static filesystem for _this application_ object.  For instance, the Orbiter library also has a `resources` directory which contains `favicon.ico` and a static pattern matching it.  When the browser asks for `/favicon.ico`, Orbiter will look it up within its own resources directory..  This also goes for any extension modules; if their objects call `dispatch_static` then these patterns are looked up in their own private resources directories.  (As with any system, thinking clearly about namespaces is essential.)

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
                render = html.url;
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

Another feature of `orbiter.html` is that it provides functions to create common HTML things like lists and tables.  For instance, `html.list` is given an array (a list-like table) and by default makes an unordered list (if the table contains `type='#'` it will do an ordered list.)  By default, each item in the table is put inside `<li>` tags, but you can provide a `render` function which will convert the table items.  In this case, the `html.url` function takes a table argument `{URL,text}` and we end up with a list of links.

Again, `orbiter.html` is not compulsory.  You can use Cosmo, for instance. `orbiter.Template` is a very straightforward and stupid template facility for simple tasks (there is clearly a powerful urge to play with template engines, since there are a lot of Lua solutions.)

### User Input

This is done just as with Orbit; a handler may receive any captures from its string pattern:

    simple:dispatch_get(simple.sections, '/section/(.+)')

So the links `/section/first` and `/section/second` both go to `simple.sections`, with `first` and `second` as the extra argument.

The first argument to any handler is usually called `web` and it will contain any variables encoded in the URI. So `/section/first?p=hello` will result in `web.GET.p` being set to 'hello'.

Data from forms is usually sent using the POST method, and then `web.input` contains the variables.  For both methods, `web.headers` contain HTTP request headers, like `user_agent` and `content_type`. (I prefer the Lua-friendly form of these header names.)

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

The first thing is to define a _catch-all_ handler:

    dyn:dispatch_get(dyn.dynamic_dispatch,'/.*')

and make everything get routed through this method:

    local registered = {}

    function dyn:dynamic_dispatch(web)
        local path = web.URL
        local handler = 'handle'..path:gsub('/','_')
        -- find a handler which can match this request
        local method, pattern
        for m in pairs(self) do if m:find '^handle_' then
            local i1,i2 = handler:find(m,1,true)
            if i1 == 1 then -- we can match, e.g. handle_first_try
                method = m
                -- we use the pattern appropriate for the handler,e.g.
                -- handle_first becomes '/first(.*)'
                pattern = method:gsub('^handle',''):gsub('_','/')..'(.*)'
                break
            end
        end end
        if method then
            -- register the handler dynamically when first encountered
            if not registered[handler] then
                self:dispatch_get(self[method],pattern)
                registered[handler] = true
            end
        else -- we fall back; there's no handler ---
            return self:layout( h2 'Index!', p('path was '..path) )
        end
        return self:dispatch(web,path)
    end

So the first time it encounters something like `/first/try` it will try to match a handler with the name of `handle_first_try`; we find `handle_first` so we attach that handler to the pattern `/first(.*)`.  After registration, we can ask ourselves to dispatch that first pattern, and `handle_first` will be invoked. The extra stuff in the URL is captured as the variable `rest` passed to the handler.

#### A note on pattern matching

All patterns are assumed to be anchored and need to span the whole address (i.e. they become '^..$'). It is still possible for more than one pattern to match; in this case, the longest pattern wins, since it is the most specific. General string patterns (like /(.-)(/.*)) can be long but still very general, so the hack is to compare lengths after removing any magic characters.

If the same pattern is registered with a new handler, that new handler replaces the old handler.  This can be useful for extensions that wish to override styles, etc.)

### A Little Application Server

An Orbiter application can load other Orbiter applications; only the first app to call the `run` method succeeds in starting the server.

This application uses a very general pattern, and assumes that a URL like `/hello/` is an instruction to load `hello.lua` (assumed to be in the same directory); this registers hello's handlers so we can pass the rest of the URL (`/`) to the Hello Application.

    local orbiter = require 'orbiter'
    local html = require 'orbiter.html'

    local app = orbiter.new(html)

    local h2,p = html.tags 'h2,p'

    function app:handle_dispatch(web,script,args)
        script = script..'.lua'
        local status,err = pcall(dofile,script)
        if not status then
            return html { h2 'Error', p(err) }
        else
            -- this is a hack: set by the run() method of the last object...
            local obj = orbiter.get_last_object()
            return obj:dispatch(web,args)
        end
    end

    app:dispatch_get(app.handle_dispatch,'/(.-)(/.*)')

    app:run(...)

After it runs, then the new application's handlers are installed and things proceed as normally; try `/hello/`, '/simple-html/' and `/form1/`.  Every time `/hello/` is processed, the script is reloaded. So this is a convenient way to make a little edit and see the results immediately.


### Future Work

I have deliberately not tried to implement things like Orbit's ORM (Object-Relational Mapping) since it would add complexity and move beyond my limited areas of competence. (The time is probably ripe for a standalone Lua ORM library.)

The strategy for finding the resource directory of an extension or application is not sufficiently general to cope with LuaRocks deployment. This will require some extra work.

Being a 'personal' app server makes life more interesting, in particular much more free use of the local filesystem.  It is an ideal situation; fat bandwidth, very low latency and plenty of server power.  Using Lua tables as persistent data structures is attractive under those circumstances.

Generating HTML has always been straightforward, but producing good-looking functional pages involves getting both software and visual design together. Often one suffers at the expense of the other.  One way forward is to work at a higher level, providing prepackaged 'widgets' and making it easy to work with stylesheets in a programmatical way.




