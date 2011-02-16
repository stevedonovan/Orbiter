o = require 'orbiter'
h = require 'orbiter.html'
function dump(t)
  print(h.tostring(t))
end

function assert_eq(doc,str)
    local s = h.tostring(doc)
    if s ~= str then
        print('h',s)
        print('s',str)
        io.stderr:write('were not equal\n')
        os.exit(1)
    end
end
