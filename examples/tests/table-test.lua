require 'common'

assert_eq(h.list {'one','two', render = '(%s)'},[[

<ul>
  <li>(one)</li>
  <li>(two)</li>
</ul>]])

assert_eq( h.list {'hello', render = h.image .. '/images/%s.png' },[[

<ul>
  <li>
    <img src='/images/hello.png'/>
  </li>
</ul>]])

assert_eq( h.table {{'1','2'},{'10','20'}},[[

<table>
  <tr>
    <td>1</td>
    <td>2</td>
  </tr>
  <tr>
    <td>10</td>
    <td>20</td>
  </tr>
</table>]])

assert_eq( h.list {
   data = {dog='bonzo',cat='felix'},
   map = h.map2list,
   render = '%s = %s'
},[[

<ul>
  <li>cat = felix</li>
  <li>dog = bonzo</li>
</ul>]])

assert_eq (h.table { cols = 2;
  'here we go', 'again',
  'stuff', 'and nonsense'
},[[

<table>
  <tr>
    <td>here we go</td>
    <td>again</td>
  </tr>
  <tr>
    <td>stuff</td>
    <td>and nonsense</td>
  </tr>
</table>]])

