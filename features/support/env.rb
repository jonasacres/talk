basepath = File.expand_path(File.dirname(__FILE__) + '/../../')
lib = File.join(basepath, 'lib')
$LOAD_PATH.unshift(lib) if File.directory?(lib) && !$LOAD_PATH.include?(lib)

require 'talk'
require 'pp'
require 'rspec/expectations'

class TalkTag
  attr_reader :children, :words, :tag

  def initialize(tag)
    @children = []
    @words = []
    @tag = tag
  end

  def add_child(child)
    @children.push child
    self
  end

  def add_data(new_words)
    new_words = new_words.split("\s+") if new_words.is_a? String
    @words += new_words
    self
  end

  def render(depth=0)
    indent = "\t" * depth
    s  = "#{indent}#{@tag}\n"
    s += "#{indent}\t#{@words.join(' ')}\n" unless @words.empty?
    s += (@children.collect { |x| x.render(depth+1) }).join("\n\n") + "\n" unless @children.empty?

    s
  end

  def find_child(tag, name=nil, index=0)
    matches = @children.select { |x| x.tag == tag }
    matches.select! { |x| x.words[index] == name } unless name.nil?
    matches.last
  end

  def to_s
    render
  end
end

# Define a new @class
def make_class(name=nil, description=nil)
  new_class = TalkTag.new("@class")
  new_class.add_data(name) unless name.nil?
  new_class.add_data(description) unless description.nil?
  @classes.push new_class
  @last_object = new_class
end

# Define a new @description
def make_description(text)
  @last_object = TalkTag.new("@description").add_data(text)
end

# Define a new @field
def make_field(name=nil, type=nil, description=nil)
  field = TalkTag.new("@field")
  field.add_data(type) unless type.nil?
  field.add_data(name) unless name.nil?
  field.add_data(description) unless description.nil?

  @last_object = field
end

# Define a new @see
def make_see(ref_type, ref_name)
  @last_object = TalkTag.new("@see").add_data([ref_type, ref_name])
end

# Define a new @glossary
def make_glossary(name=nil, description=nil)
  glossary = TalkTag.new("@glossary")
  glossary.add_data(name) unless name.nil?
  glossary.add_data(description) unless description.nil?
  @glossaries.push glossary

  @last_object = glossary
end

# Define a new @enumeration
def make_enumeration(name=nil, description=nil)
  enumeration = TalkTag.new("@enumeration")
  enumeration.add_data(name) unless name.nil?
  enumeration.add_data(description) unless description.nil?
  @enumerations.push enumeration

  @last_object = enumeration
end

# Find an @class by name
def class_named(class_name)
  @classes.each { |x| return x if x.words[0] == class_name }
  nil
end

# Find an @enumeration by name
def enumeration_named(enumeration_name)
  @enumerations.each { |x| return x if x.words[0] == enumeration_name }
  nil
end

# Find an @glossary by name
def glossary_named(glossary_name)
  @glossaries.each { |x| return x if x.words[0] == glossary_name }
  nil
end

# Last @class defined via make_class
def last_class
  @classes.nil? ? nil : @classes.last
end

# Last object created using one of the make_* methods
def last_object
  @last_object
end

# Renders actual talk string to give to parser
def render
  (@classes.map { |x| x.to_s }).join("\n\n")
end

# Finds a class in the result hash
def result_class(cls)
  name = cls
  name = cls.words[0] if cls.is_a? TalkTag

  @results[:class].each do |cls|
    return cls if cls[:name] == name
  end

  return nil
end

# Finds a specific field in a result class
def field_in_result_class(res_cls, field_name)
  res_cls = result_class(res_cls) if res_cls.is_a? String
  return nil if res_cls.nil?

  res_cls[:field].each do |f|
    return f if f[:name] == field_name
  end

  nil
end

# Resets the state so each scenario runs independently
def clean_slate
  @classes = []
  @glossaries = []
  @enumerations = []
  @last_object = nil
  @parser = Talk::Parser.new
  @exception = nil
  Talk::Registry.reset
end


## Generic test cases

Before do |scenario|
  clean_slate
end

Given(/^I have defined a valid class$/) do
  make_class("SomeClass").add_data("A description")
end

Given(/^I have defined a valid class named (\S+)$/) do |class_name|
  make_class(class_name).add_data("A description")
end

Given(/^I have defined a valid enumeration$/) do
  make_enumeration("AnEnumeration", "A description")
end

Given(/^I have defined a valid enumeration named (\S+)$/) do |enumeration_name|
  make_enumeration(enumeration_name, "A description")
end

Given(/^I have defined a valid glossary$/) do
  make_glossary("AGlossary", "A description")
end

Given(/^I have defined a valid glossary named (\S+)$/) do |glossary_name|
  make_glossary(glossary_name, "A description")
end

When(/^I get the result hash$/) do
  begin
    @parser.parse("scenario.talk", render)
    @results = @parser.results
  rescue => @exception
  end
end

Then(/^there should be a parse error$/) do
  expect(@exception.is_a? Talk::ParseError).to be true
end