_ = require('prelude-ls')
fs = require('fs')

file = fs.readFile 'markdown/eloquent.md', 'utf8', (err, data) ->
  return console.log err unless !err
  paragraphs = data.split "\r\n\r\n"
  paragraphs = _.map processParagraph, paragraphs
  console.log renderHTML {}
  console.log extractFootnotes paragraphs  
  console.log paragraphs

#------------------------------------------------------------------------------#
#  File Parsing 
#    - Responsible for turning the file into a JSON object
# -----------------------------------------------------------------------------#

# Processes each paragaph in the file classify it as either a <hX> or <p> based
# on the number of %%%'s there are and wraps it in a JSON object.
# String -> Object
processParagraph = (paragraph) -> 
  span = _.span (is \%), paragraph
  weight = (_.head span).length
  el = if weight > 0 then \h ++ weight else \p
  { type : el, content: splitParagraph _.last span } 
  
# Given a paragraph break it up into the fragments it might contain 
# String -> [Object]
splitParagraph = (paragraph) ->  
  return [] unless paragraph

  # determines the type of the content based on the first recursion 
  typeSwitch = (char) -->
    | char is '*' => 'emphasised'
    | char is '{' => 'footnote'
    | otherwise => 'normal'

  # determined
  same = (type) -->
    | type is 'emphasised' => (char) -> char is not \*
    | type is 'footnote' => (char) -> char is not \}
    | otherwise => (char) -> char is not \* and char is not \{


  type = typeSwitch _.head paragraph

  # we do not want to include the beginning character, (if it's a * or {)
  paragraph = _.tail paragraph unless type is 'emphasised' 
  content = _.span (same type), paragraph
  
  # similarly we want to ignore the terminating character for the the next recursion 
  rest = if type is 'normal' then _.last content else _.tail _.last content

  return [{type: type, content: _.head content}] ++ splitParagraph rest

# Takes the list of paragraphs that was created and rips out all footnotes, 
# replacing them instead with references. This WILL modify paragraphs.
# Returns only the footnotes from the list
#
# TODO: do not modify the existing array
#
# [Object] -> [Object]', [Object]
extractFootnotes = (paragraphs) ->
  footnotes = []

  replace = (fragment) -> 
    return fragment unless fragment.type is 'footnote'

    footnotes.push fragment 
    {type: 'reference', number: footnotes.length}

  _.each ((paragraph) -> paragraph.content = _.map replace, paragraph.content), paragraphs

  return footnotes

#------------------------------------------------------------------------------#
#  Document Rendering
#    - Responsible for the creation of HTML elements 
#------------------------------------------------------------------------------#

tag = (name, content, attributes) ->
  {name: name, attributes: attributes, content: content}

link = (target, text) ->
  tag "a", [], {href: target}

htmlDoc = (title, body) ->
  tag "html", [tag "head", [tag "title", [title]],
               tag "body", [body]]

escapeHTML = (text) ->
  replacements = [[/&/g "&amp;"][/"/g "&quot"][/</g "&lt;"][/>/g "&gt;"]]
  _.each ((replace) -> 
    text := text.replace _.head replace, _.last replace)
  , replacements
  return text
 
renderHTML = (element) -> 
  # [[a][b],] -> String
  stringify = _.fold (memo, attribute) -> 
    memo += "#{_.head attribute}=\"#{escapeHTML _.last attribute}"
  , '' 
  
  # {a: b} --> String
  renderAttributes = stringify <<  _.obj-to-pairs

  render = (element) --> 
    | _.isString => escapeHTML element
    | !element.content or element.content.length is 0 => 
      "<#{element.name} #{renderAttributes element.attributes} />"
    | otherwise => "<#{element.name} #{renderAttributes(element.attributes)}>
      #{_.each render, element.content} </#{element.name}>"

  render element