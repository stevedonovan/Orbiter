o = require 'orbiter'
h = require 'orbiter.html'
function dump(t)
  print(h.tostring(t))
end

dump( h.list {'one','two', render = '(%s)'})
dump( h.list {'hello', render = h.image .. '/images/%s.png' })

dump( h.table {{'1','2'},{'10','20'}})

dump( h.list {
   data = {dog='bonzo',cat='felix'},
   map = h.map2list,
   render = '%s = %s'
})

dump (h.table { cols = 2;
  'here we go', 'again',
  'stuff', 'and nonsense'
})

