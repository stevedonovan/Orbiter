require 'common'

dump(h.table { cols = 2,
  styles  = {
    alias = {red='color:red',blue='active'},
    red = {row=1,col=1},
    blue = {row=2}
  };
  'here we go', 'again',
  'stuff', 'and nonsense'
})
