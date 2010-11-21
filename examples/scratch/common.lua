o = require 'orbiter'
h = require 'orbiter.html'
function dump(t)
  print(h.tostring(t))
end

function assert_eq(doc,str)
    assert(h.tostring(doc) == str)
end
