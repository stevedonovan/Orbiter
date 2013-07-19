## Orbiter - a self-contained personal Web Framework

_Steve Donovan, 2010 (MIT/X11)_

Cross-platform user interfaces remain tricky to deploy, and often involve large dependencies that must be downloaded. Web browsers are ubiquitous and familiar, so an application can provide its GUI interface over HTTP.  This is a common strategy with embedded devices, where remoting is explicitly needed, but naturally the server process and the browser can be on the same machine.

[Orbit](http://keplerproject.github.com/orbit) is my personal favourite among building-from-scratch Web frameworks (as opposed to Wiki engines like [Sputnik](http://github.com/yuri/sputnik)), but the full [Kepler](http://github.com/keplerproject/kepler) stack can be a bit awkward to set up, especially under the following conditions:

 - a small script requires a GUI interface
 - a program with embedded Lua needs an interface
 - a program has a strict memory budget (e.g. embedded)

The Orbiter project has two legs, which are of equal importance but unequal length. The first is a small application server that depends only on LuaSocket, which is important for the expected use cases: small-to-medium applications and providing configuration interfaces for applications with embedded Lua. This server is 500 lines of code and does not pretend to be a full HTTP 1.1 server; it assumes that the desktop environment provides security and verification.  However, it has support for both GET and POST requests.  The programming model is based on Orbit, but without the WSAPI stack: dispatch handlers are defined for URLs specified as Lua string patterns.

### Hello, World!

Orbiter applications read very much like Orbit applications, with the emphasis shifted away from `module` and the application object becoming an instance of a general application class object.

    -- hello.lua
    local orbiter = require 'orbiter'
    local app = orbiter.new()

    function app:index(web)
      return [[
        <html><head><title>Hello from Orbiter</title></head>
        <body>
          <h2>Hello, World!</h2>
        </body></html>
      ]]
    end

    app:dispatch_get(app.index,'/')

    return app:run(...)

The runtime difference is that `hello.lua` is an _application_, not a module intended to be loaded into a WSAPI context. With the `--launch` flag it will even launch the browser after starting the built-in server.  Generally this change makes it easier to debug Orbiter applications, and certainly easier to _embed_ into an application with embedded Lua.  Such an application can have Orbiter scripts which directly drive the application through its own internal API.
  
### Generating HTML as LOM Documents

The other reason for Orbiter's existence is as a testing ground for new techniques. For instance, I wished to push the LOM document generation model as far as possible to see its strengths and weaknesses. And to see if a clear and straightforward declarative style can generate good-looking and functional interfaces, hiding the often messy interaction between CSS, JavaScript and HTML.

The second leg of Orbiter is a high-level library for generating HTML using LOM document trees. At its heart it is very much inspired by Orbit 'htmlification' except that no modification of the function environment is used; any tags needed must be declared upfront.  This involves more typing but arguably it is better to have a runtime error for an undeclared tag than to write bad HTML:

    local table_,tr,td = html.tags 'table,tr,td'

    print(table { class = 'mytable';
       tr {
          td '11', td '12'
       },
       tr {
          td '21', td '22'
       }
    })

Another key difference is that these tag constructors do not generate text directly but construct a LOM tree; LOM documents have a `__tostring` metamethod which renders them as pretty-printed HTML.  (The HTML produced by Orbit htmlfication is harder to read and requires 'beautification')

One of the questions which Orbiter poses is whether there are any other advantages to working with HTML as a LOM tree, and the performance implications for server memory and processor time. One can see a LOM document as a generalized 'rope' for efficiently generating large strings.  Also, it allows server-side DOM-style modification - an example would be `orbiter.form` which is a module for form auto-generation; if there are verification errors then the document is directly modified by changing styles and attaching title attributes, and then returned. 

An important point is that Orbit applications can use the Orbiter libraries to generate documents. In fact, any Lua web framework could do so but it fits better with Orbit because the Orbiter server model is deliberately very similar and the Orbiter libraries can easily handle the Orbit case conditionally.  I felt this was an important design goal because these libraries provide useful high-level ways of generating documents that any web application can use productively.

### Automatic Form Generation

This program can run both as an Orbiter application (`lua formtest.lua`) or as an Orbit application (`orbit formtest.lua`.)  The idea is that if we have a Lua table representing our data, then it is easy to map this automatically onto a HTML form.

    local O = orbit or require 'orbiter'
    local html = require 'orbiter.html'
    local form = require 'orbiter.form'

    local app = O.new {}

    local obj = {
        name = 'John',
        phone = '+8999',
        title = 'Dr',
        age = 25,
        hobbies = 'chess'
    }

    -- custom data constraint
    local phone_number = form.match('^%+%d+','must be international number +XXX...')

    local f = form.new {
        obj = obj; 
        title = 'Simple Generated Form',
        buttons = {'submit','try again'};
        'Name','name', form.non_blank,
        'Phone','phone',phone_number,
        'Title','title',{'Mr','Ms','Dr','Prof','Rev';size=5,multiple=true},
        'Age','age',form.irange(10,120),
        'Hobbies','hobbies',form.textarea{rows=10,cols=40},
    }

    local h2,p = html.tags 'h2,p'

    local  hashlist = html.list:specialize {map = html.map2list, render = '%s = %s'}

    function app:handle_form(web)
        print("lua memory used",collectgarbage("count"))
        if f:prepare(web) then
            return html.as_text {            
                f:show()
            }
        else
            return html.as_text {
                h2 'Form Results',
                hashlist { data = obj },
                p ("button clicked was '"..f.button..'"'),
                html.link('/','Go back!'),
            }    
        end
    end

    -- for Orbiter, we can say dispatch_any() to handle both cases, but
    -- this is needed for Orbit
    app:dispatch_get(app.handle_form,'/')
    app:dispatch_post(app.handle_form,'/')

    if orbit then -- Orbit loads the module and runs it using Xavante, etc
        return app
    else ----- we use the Orbiter micro-server
        app:run(...)
    end

