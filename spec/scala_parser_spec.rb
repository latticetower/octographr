require 'rspec'
require 'rspec/autorun'
require 'parslet/rig/rspec'
require __dir__ + '/../app/scala_parser.rb'

describe ScalaParser, "primitive test" do
  let(:parser) { ScalaParser.new }

  describe "ScalaParser" do
    it "should parse simple word constants" do
      expect(parser.word_class).to parse('class')
      expect(parser.word_trait).to parse('trait')
      expect(parser.word_case).to parse('case')
      expect(parser.word_package).to parse('package')
    end
    it "should parse simple var names and class names" do
      expect(parser.class_name).to parse("Rrrrrr")
      expect(parser.var_expressions).to parse("val a: F, var b:P, c:PJ, d")
    end
    it "should parse string with class name in different situations" do
      expect(parser.class_expr).to parse("class Cccccc")
      expect(parser.class_expr).to parse("case class Ccccf")
      expect(parser.class_expr).to parse("class DDddd()")
      expect(parser.class_expr).to parse("class FFff extends P with Y with M")
    end
    it "should parse trait name" do
      expect(parser.trait_expr).to parse("trait K")
      expect(parser.optional_brackets).to parse("{}")
      expect(parser.optional_brackets).to parse("{gggg}")
      expect(parser.optional_brackets).to parse("{g{g}g{}g}")
    end
  end
end
