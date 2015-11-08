require 'parslet'

class ScalaParser < Parslet::Parser
  rule(:word_class) { str('class') }
  rule(:word_case)  { str('case') }
  rule(:word_trait) { str('trait') }
  rule(:word_package) { str('package') }
  rule(:word_import) { str('import') }
  rule(:word_val) { str('val') }
  rule(:word_var) { str('var') }
  rule(:colon) { str(':') }

  rule(:class_name) { match('[a-zA-Z]').repeat(1) }

  rule(:space)      { match('\s').repeat(1) }
  rule(:space?)     { space.maybe }

  rule(:lparen) { str('(') }
  rule(:rparen) { str(')') }

  rule(:var_name) { match('[a-zA-Z0-9_]').repeat(1) }
  rule(:var_type) { match('[a-zA-Z0-9_]').repeat(1) }
  rule(:var_expr) { space? >> (word_val | word_val).maybe >> space? >> var_name >>
      space? >> (colon >> space? >> var_type.as(:var_type)).maybe }


  rule(:class_expr) { space? >> (word_case >> space).maybe >> word_class >>
    space >> class_name.as(:current_class) >> space? >> (lparen >> var_expr.maybe >> rparen).maybe}
  rule(:some_expr) { word_trait | class_expr }
  root(:some_expr)
end
