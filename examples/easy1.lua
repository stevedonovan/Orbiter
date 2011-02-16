-- this is the easy way to make a single-handler Orbiter app.
-- Out of nostalgia for Orbit htmlification, the callback's
-- environment is modified so that any unknown symbol is
-- seen as a tag.
--
-- (Note that you may set web.headers to add custom headers to the
-- HTTP response - this is true for all Orbiter apps.)

require 'orbiter.easy' (function(web,path)
   web.headers = {
     ['content-type'] = 'text/html',
     ['wine-age'] = 'vintage',
   }
   return html {
      h2 'hello world',
      p 'A satisfying conclustion'
   }
end)
