require 'common'
ls = {'one','two','three'}

h2,p,form = h.tags 'h2,p,form'

hh = h2:specialize{class='bozo'}

a,b = h.tags {{'a',class='A'},{'b',class='B'}}

text,button = h.tags {  {'input',type='text',name=1}, {'input',type='submit',value=1} }

assert_eq(h{form{
  name='form1',action='/results',method='post';
  h.table { cols = 2;
  "first parameter", text "first",
  "second parameter", text "second",
  },
  button 'submit'
}},[[

<html>
  <head>
    <title>Orbiter</title>
  </head>
  <body>
    <form name='form1' method='post' action='/results'>
      <table>
        <tr>
          <td>first parameter</td>
          <td>
            <input name='first' type='text'/>
          </td>
        </tr>
        <tr>
          <td>second parameter</td>
          <td>
            <input name='second' type='text'/>
          </td>
        </tr>
      </table>
      <input value='submit' type='submit'/>
    </form>
  </body>
</html>]])

