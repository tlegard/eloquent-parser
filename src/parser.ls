_ = require('prelude-ls')
fs = require('fs')
util = require('util')

# reads in a markdown file and spits out HTML 
file = fs.readFile 'markdown/eloquent.md', 'utf8', (err, data) ->
  return console.log err unless !err
  blocks = _.map processBlocks, data.split "\r\n\r\n"
  footnotes = _.map footnote, extractFootnotes blocks
  body = (_.map renderBlock, blocks) ++ footnotes
  fs.writeFile 'index.html', renderHTML (htmlDoc "The Test", body)

#------------------------------------------------------------------------------#
#  File Parsing 
#    - Responsible for turning the file into a JSON object
# -----------------------------------------------------------------------------#

# Processes each block elemnt in the file classify it as either a <hX> or <p>
# based on the number of %%%'s there are and converts it to a JSON object.
# String -> {}
processBlocks = (block) -> 
  # essentially an alias to hide away some of the _.span logic
  #  [a ,b] -> ""
  splitOn = (context) -> splitBlock _.last context

  header = _.span (is \%), block

  if _.head header then {type: \h ++ that.length, content: splitOn header}
  else then {type: 'p', content: splitOn header}

# Given a block break it up into the span type elements it might contain 
# String -> [{}]
splitBlock = (paragraph) ->  
  return [] unless paragraph

  # determines the type of the content based on the first recursion 
  # Char -> String
  typeOf = (char) -->
    | char is \* => 'emphasised'
    | char is \{ or char is \} => 'footnote'
    | otherwise => 'normal'

  # returns a test for span, so that we get all of the characters of that type
  # 
  # TODO: simplify, is closure needed? 
  # String -> Function 
  same = (type) -->
    | type is 'emphasised' => (char) -> (typeOf char) is not 'emphasised'
    | type is 'footnote' => (char) -> (typeOf char) is not 'footnote'
    | otherwise => (char) -> (typeOf char) is 'normal'

  type = typeOf _.head paragraph

  # we do not want to include the beginning character, (if it's a * or {)
  paragraph = _.tail paragraph unless type is 'normal' 
  
  # [String, String]
  content = _.span (same type), paragraph

  # similarly we want to ignore the terminating character for the the next 
  # frame
  rest = if type is 'normal' then _.last content else _.tail _.last content

  return [{type: type, content: _.head content}] ++ splitBlock rest

# Takes the list of paragraphs that was created and rips out all footnotes, 
# replacing them instead with references. This WILL modify paragraphs.
# Returns only the footnotes from the list
#
# TODO: do not modify the existing array
#
# [Object] -> [Object]', [Object]
extractFootnotes = (paragraphs) ->
  footnotes = []

  grabFootnote = (fragment) -> 
    return fragment unless fragment.type is 'footnote'

    footnotes.push fragment 
    fragment.number = footnotes.length
    {type: 'reference', number: footnotes.length}

  transform = (p) -> p.content = _.map grabFootnote, p.content
  _.each transform, paragraphs

  return footnotes

#------------------------------------------------------------------------------#
#  DOM Creation
#    - Responsible for the creation of JSON HTML elements 
#    - Of the form $el = {name: String, content: [$el], attributes: [{}]}
#------------------------------------------------------------------------------#
# base constructor "", [$el], {}-> {}
tag = (name, content, attributes) ->
  {name: name, attributes: attributes, content: content}

# generates <a> objects "", $el -> {}
link = (target, $text) ->  tag "a", [$text], {href: target}

# generates <img> objects, "" -> {}
image = (src) -> tag "img", [], {src: src}

# generates boilerplate <html> "", [$el]
htmlDoc = (title, body) ->  
  tag "html", [(tag 'head', [(tag 'title', [title]), tag 'link', [], 
    {href: './css/style.css', type: 'text/css', rel: 'stylesheet'}]),
    (tag 'body', body)]

# generates <sup><a></a></sup> for footnotes int -> {}
reference = (number) -> tag 'sup', [link "\#footnote#{number}", "#{number}"]

# generators <a name=""></a> for linking 
footnote = (footnote) ->
  a = tag "a", ["[#{footnote.number}]"], {name: "footnote#{footnote.number}"}
  tag "p", [tag "small", [a, footnote.content]], {class: 'footnote'}

# responsible for rendering block type elements: <h1>'s, <p>'s etc.
renderBlock = ($el) ->  
  renderSpan = (fragment) ->
    renderType = (type) -->
      | type is 'reference' => reference fragment.number
      | type is 'emphasised' => tag 'em', [fragment.content]
      | type is 'normal' => fragment.content

    renderType fragment.type
  
  tag $el.type, (_.map renderSpan, $el.content)

#------------------------------------------------------------------------------#
#  DOM Rendering 
#    - Responsible for rendering HTML for the JSON elements 
#------------------------------------------------------------------------------#

# replaces reserved characters from HTML with their escaped equlivant
# String -> String'
escapeHTML = (text) ->
  return unless text
  
  replacements = [[/&/g "&amp;"][/"/g "&quot"][/</g "&lt;"][/>/g "&gt;"]]
  
  apply = (replace) -> text := text.replace (._head replace), (_.last replace)
  
  _.each apply, replacements
  
  return text
 
# converts the JSON $el's into true HTML 
# {} -> 
renderHTML = ($el) -> 
  # [[a][b],] -> String
  concatAttr = (m, a) ->  m += " #{_.head a}=\"#{escapeHTML _.last a}\""

  # [String] -> String
  concatEl = _.fold1 (m, $el) -> m += "#{$el}"

  # [[a][b],] -> String 
  stringify = _.fold concatAttr, ''
  
  # {a: b} --> String
  renderAttributes = stringify <<  _.obj-to-pairs

  # {} -> String
  render = ($el) --> 
    | _.is-type 'String', $el => "#{escapeHTML $el}"
    | !$el.content or $el.content.length is 0 => 
      "<#{$el.name}#{renderAttributes $el.attributes} />"
    | otherwise => 
      "<#{$el.name}#{renderAttributes($el.attributes)}>
       #{concatEl(_.map render, $el.content)}</#{$el.name}>"
  render $el