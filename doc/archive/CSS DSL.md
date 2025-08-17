# CSS DSL

I want to build a DSL people can use to get the same options they get from Word
to alter an existing style without knowing Css. This will involve typing a
config section at the top of a document to alter whatever stylesheet is applied
to that document (by including it inline).

What properties do people expect to be able to change?

- Font: [font name], [font size]
- Color: [font color]
- Margin: [document margin]
- Width: [document width]
- Line spacing: [line height for paragraphs] 
- Bullet: [bullet shape - even unicode?]
- Indentation: [indentation]
- After paragraph: [margin before paragraph]
- Before paragraph: [margin after paragraph]
- Smart typography: on
- Smart images: on

- Style:
  (Any CSS written here will be included verbatim in the document)
