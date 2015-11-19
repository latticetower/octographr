require 'parslet'

class ScalaParser < Parslet::Parser
  rule(:word_class) { str('class') }
  rule(:word_object) { str('object') }
  rule(:word_modifier) { str('private') |
    (str('private') >> space? >> str('[') >> package_name >> str(']')) |
    str('sealed') |
    str('protected') |
    str('abstract') | str('override')}

  rule(:word_case)  { str('case') }
  rule(:word_trait) { str('trait') }
  rule(:word_package) { str('package') }
  rule(:word_import) { str('import') }
  rule(:word_val) { str('val') }
  rule(:word_var) { str('var') }
  rule(:word_extends) { str('extends') }
  rule(:word_with) { str('with') }
  rule(:colon) { str(':') }
  rule(:semicolon) { str(';') }
  rule(:endl) { match('\\n') >> space? }
  rule(:dot) { str('.') }
  rule(:eof) { any.absent? }
  rule(:comma) { str(',') }

  rule(:lparen) { str('(') }
  rule(:rparen) { str(')') }
  #rule(:not_rparen) { match('[^)]*') }
  rule(:lbracket) {str('{')}
  rule(:rbracket) {str('}')}
  rule(:not_rbracket_or_rparen) {
    #some_expr |
    (
      comment.as(:comment)    |
      import_expr.as(:import) |
      object_expr.as(:object) |
      trait_expr.as(:trait) |
      class_expr.as(:class) |
      var_expression.as(:variable) |
      endl.as(:endl) |
      space.as(:space)|
      ignored_line_with_brackets.as(:ignored) | #.as(:ignored_v)
      bracketed_ignored_content.as(:ignored) #.as(:ignored_b)
       #var_expr |

    ).repeat(1) | some_expr
  }


  rule(:not_rbracket_or_rparen_ignored) { match['^(){}'].repeat(1) }

  #optional brackets with ignored content
  rule(:bracketed_ignored_content) { (not_rbracket_or_rparen_ignored.maybe >>
    (optional_brackets_ignored >>
    not_rbracket_or_rparen_ignored.maybe).repeat(1)) |
    not_rbracket_or_rparen_ignored}

  rule(:optional_brackets_ignored) {
    (lbracket >> bracketed_ignored_content.maybe >> rbracket) |
    (lparen   >> bracketed_ignored_content.maybe >> rparen)
  }
  #optional brackets with processed content
  rule(:bracket_content) { (not_rbracket_or_rparen.as(:content).maybe >>
    (optional_brackets >>
    not_rbracket_or_rparen.as(:content).maybe).repeat(1).as(:bracket_content)) |
    not_rbracket_or_rparen.as(:content).maybe}
  rule(:optional_brackets) {
    (lbracket >> bracket_content.maybe.as(:bracket_content) >> rbracket) |
    (lparen   >> bracket_content.maybe.as(:bracket_content) >> rparen)
    }



  rule(:space)      { match('\s').repeat(1) }
  rule(:space?)     { space.maybe }

  rule(:class_name) { match('[a-zA-Z0-9_-]').repeat(1) }
  rule(:package_name) { match('[a-zA-Z0-9_-]').repeat(1) }

  rule(:ignored) { match['^\n'].repeat(1).as(:ignored) >> (endl | eof) }
  rule(:ignored_with_no_brackets) { match['^{}()\n'].repeat(1).as(:ignored) >> (endl | eof) }
  def ignored_line_with(ignored_chars)
      (
        match[ignored_chars].repeat >>
        optional_brackets_ignored
      ).repeat >>
      match[ignored_chars].repeat
  end

  rule(:ignored_line_with_brackets) { ignored_line_with('^{}()\n') >> (endl | eof) }
=begin
  {
    (
      match['^{}()\n'].repeat >>
      optional_brackets_ignored
    ).repeat >>
    match['^{}()\n'].repeat >> (endl | eof)
  }
=end

  #comments:
  rule(:comment_line) { str('//') >> (ignored | endl | eof).as(:comment_text) }
  rule(:comment_multiline) { str("/*") >> dynamic { |s,c|
    content_length = s.chars_until('*/')
    if content_length > 0
      match('.').repeat(content_length, content_length).as(:comment_text) >> str("*/")
    else
      str("*/")
    end
     }
  }
  rule(:comment){ comment_line | comment_multiline }

  #basic package
  rule(:package_expr) { word_package >> space >>
    (package_name >> (dot >> package_name).repeat).as(:package_name) >> (endl | eof) }

  #basic import
  rule(:import_expr) { word_import >> space >>
    #comment.maybe >> space? >>
    ((package_name >> dot).repeat >> class_name) >> (endl | eof) } #.as(:import_line)

  #object and class
  rule(:parent_classes_tail) {
    var_type.as(:parent_type) >>
    (match[' '].repeat(1) >> word_with >> space >> parent_classes_tail.as(:rest)
    ).maybe }
  rule(:parent_classes) { word_extends >> space >> parent_classes_tail }

  rule(:object_expr) { (word_modifier >> space).repeat >>
    word_object >> str(' ').repeat(1) >> class_name.as(:name) >>
    (match[' '].repeat >> parent_classes.as(:parent)).maybe >> space? >>
    (lbracket >>
      (
        bracket_content.as(:optional_brackets) |
        bracketed_ignored_content.as(:ignored_brackets)
      ).maybe >> rbracket
    ).maybe
  }

  rule(:class_expr) { (word_modifier >> space).maybe >>
    (word_case >> space).maybe >> word_class >> space >> class_name.as(:name) >> match[' '].repeat >>
      (lparen >> (
          var_arguments.as(:params) |
          bracketed_ignored_content.as(:ignored_brackets)
          ).maybe >> rparen
      ).maybe >>
    (space? >> parent_classes.as(:parent)).maybe >> space? >>
    (lbracket >>
      (
        bracket_content.as(:optional_brackets) |
        bracketed_ignored_content.as(:ignored_brackets)
      ).maybe >> rbracket
    ).maybe
  }

  #trait
  rule(:trait_expr) { (word_modifier >> space).repeat >> word_trait >>
    space >> class_name.as(:name) >> (match[' '].repeat(1) >> parent_classes.as(:parent)).maybe >>
    space? >> (lbracket >>
      (
        bracket_content.as(:optional_brackets) |
        bracketed_ignored_content.as(:ignored_brackets)
      ).maybe >> rbracket
    ).maybe
    }

  #variables
  rule(:var_name) { match('[a-zA-Z0-9_]').repeat(1) }
  rule(:var_simple_type) { match('[a-zA-Z0-9_]').repeat(1) }

  rule(:ignored_param_value) { ignored_line_with('^(){},\\n') }
  #these are constructor/method parameters divided by commas:
  rule(:var_arg) { (word_val | word_var).maybe >> space? >> var_name.as(:name) >>
      match[' '].repeat >> (colon >> space? >>
      (
        (var_type.as(:var_type) >>
        (match[' '].repeat >> str('=') >> ignored_param_value) |
        ignored_param_value)
       ).maybe
      ).maybe }
  rule(:var_arguments) { (space? >> comma.maybe >> space? >> var_arg).repeat }

  rule(:var_expression) { (word_modifier >> str(' ').repeat).repeat >> (word_val | word_var) >> str(' ').repeat(1) >> var_name >>
      str(' ').repeat >> (colon >> space? >>
      var_type.as(:var_type) >>
      (match[' '].repeat >> str('=') >> ignored_param_value ).maybe
      ).maybe }

  rule(:var_type_list) {
    space? >> (var_type >> space? >> comma >> space? >> var_type_list).as(:next) | var_type.as(:next)  >> space? }
  rule(:var_type) { var_simple_type.as(:type) >> (str("[") >> var_type_list.as(:subtype) >> str("]")).maybe }



  #root rule
  rule(:some_expr) { (
      comment |
      package_expr |
      import_expr |
      object_expr.as(:object) |
      class_expr.as(:class) |
      trait_expr.as(:trait) |
      #var_expression.as(:variable) |
      endl | #.as(:endl) |
      space | #.as(:space) |
      ignored
    ).repeat(1).as(:elements) }
  root(:some_expr)

  def parse_file(file)
    parse(file)
  rescue Parslet::ParseFailed => failure
    puts failure.cause.ascii_tree
    {}
  end
end


class ScalaTransformer < Parslet::Transform
    rule(:type => simple(:x)) { x.to_s }
    rule(:type => simple(:x), :next => simple(:y)) { [x.to_s, y.to_s] }
    rule(:type => simple(:x), :next => sequence(:y)) { y.map(&:to_s).unshift(x.to_s) }
    rule(:next => sequence(:x)) {x}
    rule(:next => simple(:x)) {[x]}
    rule(:subtype => simple(:y)) {[y]}
    rule(:type => simple(:x), :subtype => sequence(:y)) { y.unshift(x.to_s) }
    rule(:parent_type => simple(:x)) {[x] }
    rule({ :parent_type => simple(:x), :rest => {:parent_type => sequence(:y)}}) {y.unshift(x).uniq}
    rule({ :parent_type => sequence(:x), :rest => {:parent_type => sequence(:y)}}) { (y << x).flatten.uniq }
    rule({ :parent_type => simple(:x), :rest => sequence(:y)}) { y.unshift(x).uniq }
    rule({:parent_type => sequence(:x), :rest => sequence(:y)}) { (y << x).flatten.uniq }
    rule(:parent_type => sequence(:x)) {x}
    rule(:parent_type => simple(:x)) {[x]}
    rule(:var_type => simple(:x)) {[x]}
    rule(:var_type => sequence(:x)) {x}
    rule({:name => simple(:z), :var_type => sequence(:x)}) {x}
    rule(:name => simple(:x)){ }
 end
