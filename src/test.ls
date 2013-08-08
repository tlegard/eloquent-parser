p = require('prelude-ls')
fs = require('fs')

file = fs.readFile 'markdown/eloquent.md', 'utf8', (err, data) ->
  return console.log err unless !err
  paragraphs = data.split "\r\n\r\n"
  p.map processParagraph, paragraphs
   
processParagraph = (paragraph) -> 
  span = p.span (is \%), paragraph
  weight = (p.head span).length
  el = if weight > 0 then \h ++ weight else \p
  { type : el, content: splitParagraph p.last span } 
  
splitParagraph = (paragraph) ->  
  return ''
 
  
typeSwitch = (char) -->
  | char is '*' => 'emphasised'
  | char in '{' => 'footnote'
  | otherwise	=> 'normal'