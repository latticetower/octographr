require 'parslet'

class ScalaParser < Parslet::Parser
  rule(:word_class) { str('class') }
  rule(:word_case)  { str('case') }
  rule(:word_trait) { str('trait') }
  rule(:word_package) { str('package') }
  rule(:word_import) { str('import') }
  rule(:word_val) { str('val') }
  rule(:word_var) { str('var') }
  rule(:word_extends) { str('extends') }
  rule(:word_with) { str('with') }
  rule(:colon) { str(':') }
  rule(:endl) { match('\\n') }

  rule(:space)      { match('\s').repeat(1) }
  rule(:space?)     { space.maybe }

  rule(:class_name) { match('[a-zA-Z]').repeat(1) }
  rule(:parent_classes) { space? >> word_extends >> space >>
    class_name.as(:parent_type) >> (space? >> word_with >> space >> class_name.as(:parent_type)).repeat >> space? }


  rule(:lparen) { str('(') }
  rule(:rparen) { str(')') }
  rule(:not_rparen) { match('[^)]*') }
  rule(:lbracket) {str('{')}
  rule(:rbracket) {str('}')}
  rule(:not_rbracket) { match('[^}]*') }
  rule(:comma) { space? >> str(',') >> space? }


  #todo:add rules to ignore comments

  rule(:var_name) { match('[a-zA-Z0-9_]').repeat(1) }
  rule(:var_type) { match('[a-zA-Z0-9_]').repeat(1) }
  rule(:var_expr) { space? >> (word_val | word_var).maybe >> space? >> var_name >>
      space? >> (colon >> space? >> var_type.as(:var_type)).maybe }
  rule(:var_expressions) { var_expr >> (comma >> var_expr).repeat }

  rule(:package_name) { match('a-zA-Z_-').repeat(1) }
  #todo: add complex rule to ignored {} contents


  rule(:package_expr) { word_package >> space >> package_name >> (str('.') >> package_name).repeat.maybe >> endl }
  rule(:import_expr) { word_import >> space >> package_name >> (str('.') >> package_name).repeat.maybe >> endl }

  rule(:trait_expr) { word_trait >> space >> class_name.as(:trait_name) >> space? }
  rule(:class_expr) { space? >> (word_case >> space).maybe >> word_class >>
    space >> class_name.as(:current_class) >> space? >> (lparen >> var_expressions.as(:params).maybe >> rparen).maybe >> parent_classes.as(:parent).maybe }
  rule(:some_expr) { package_expr.maybe | (import_expr | trait_expr | class_expr | (var_expr >> endl.maybe)).repeat }
  root(:some_expr)
end
