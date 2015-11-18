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
      expect(parser.var_arguments).to parse("val a: F, var b:P, c:PJ, d")
    end
    it "should parse type names in different situations" do
      expect(parser.var_type).to parse("Int")
      expect(parser.var_type).to parse("Seq[Int]")
      expect(parser.var_type).to parse("Map[Int,String]")
      expect(parser.var_type).to parse("Map[Int, String]")
      expect(parser.var_type).to parse("Map[Int, Map[String,Double]]")
    end
    it "should parse string with class name in different situations" do
      expect(parser.class_expr).to parse("class Cccccc")
      expect(parser.class_expr).to parse("case class Ccccf")
      expect(parser.class_expr).to parse("class DDddd()")
      expect(parser.class_expr).to parse("class FFff extends P with Y with M")
    end
    it "should parse trait name" do
      expect(parser.trait_expr).to parse("trait K")
      expect(parser.optional_brackets_ignored).to parse("{}")
      expect(parser.optional_brackets_ignored).to parse("{gggg}")
      expect(parser.optional_brackets_ignored).to parse("{g{g}g{}g}")
      #expect(parser.optional_brackets).to parse("{g{g}g{}g}")
    end
    it "should parse comments" do
      expect(parser.comment_line).to parse("//")
      expect(parser.comment_line).to parse("//\n")
      expect(parser.comment_line).to parse("///flglrjgljr")
      expect(parser.comment_line).to parse("//fhkshkh jkj class \n")
      expect(parser.comment_multiline).to parse("/**/")
      expect(parser.comment_multiline).to parse("/*l*/")
      expect(parser.comment_multiline).to parse("/*ll*/")
      expect(parser.comment_multiline).to parse("/**l*/")
      expect(parser.comment_multiline).to parse("/*l**/")
      expect(parser.comment_multiline).to parse("/***l*/")
      expect(parser.comment_multiline).to parse("/*l****/")
    end
    it "should parse complex type info" do

      expect(parser.class_expr).to parse("class C(val c: C, d:D) {\nvar c:D\nvar d : E\n      }" )
    end
    it "should parse typical import" do
      expect(parser.package_expr).to parse("package ddd.dddd.jjj")
      expect(parser.import_expr).to parse("import com.typesafe.scalalogging.slf4j.LazyLogging")

    end
  end
end
