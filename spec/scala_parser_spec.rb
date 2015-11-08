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
    end
    it "should parse string with class name in different situations" do
    end
  end
end
