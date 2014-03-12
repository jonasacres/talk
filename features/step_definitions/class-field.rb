Before do |scenario|
  clean_slate
end

Given(/^I give it a field named (\S+) of type (\S+) and description (.+)$/) do |name, type, description|
  last_class.add_child(make_field(name, type).add_child(make_description(description)))
end

Then(/^the field (\S+) should have type (\S+) and description (.+)$/) do |name, type, description|
  field = field_in_result_class("SomeClass", name)
  expect(field).not_to be_nil
  expect(field[:description]).to eq(description)
  expect(field[:type].length).to eq(1)
  expect(field[:type][0]).to eq(type)
end

Given(/^I give it a field named (\S+) of type (\S+) and implicit description (.+)$/) do |name, type, description|
  last_class.add_child(make_field(name, type, description))
end

Given(/^I give it a valid field named (\S+) of type (\S+)$/) do |name, type|
  last_class.add_child(make_field(name, type, "A description"))
end

Then(/^the field (\S+) should have type (\S+)$/) do |name, type|
  field = field_in_result_class(last_class.words[0], name)
  expect(field).not_to be_nil
  expect(field[:type].length).to eq(1)
  expect(field[:type][0]).to eq(type)
end

Given(/^I give it a valid field named (\S+)$/) do |name|
  last_class.add_child(make_field(name, "uint32", "A description"))
end

Given(/^I give (\S+) @see (\S+) (\S+)$/) do |field_name, ref_type, ref_name|
  last_class.find_child("@field", field_name, 1).add_child(make_see(ref_type, ref_name))
end

Then(/^the field (\S+) should have an @see (\S+) (\S+)$/) do |field_name, ref_type, ref_name|
  pending # express the regexp above with the code you wish you had
end

Given(/^I give (\S+) @caveat (.+)$/) do |field_name, caveat_text|
  caveat = TalkTag.new("@caveat").add_data(caveat_text)
  last_class.find_child("@field", field_name, 1).add_child(caveat)
end

Then(/^the field (\S+) should have a @caveat (.+)$/) do |field_name, caveat_text|
  field = field_in_result_class("SomeClass", field_name)
  expect(field[:caveat]).to include(caveat_text)
end

Given(/^I give (\S+) @deprecated (.+)$/) do |field_name, deprecation_text|
  deprecated = TalkTag.new("@deprecated").add_data(deprecation_text)
  last_class.find_child("@field", field_name, 1).add_child(deprecated)
end

Then(/^the field (\S+) should have @deprecated (.+)$/) do |field_name, deprecation_text|
  field = field_in_result_class("SomeClass", field_name)
  expect(field[:deprecated]).to eq(deprecation_text)
end

Given(/^I give (\S+) @version (.+)$/) do |field_name, version_string|
  version = TalkTag.new("@version").add_data(version_string)
  last_class.find_child("@field", field_name, 1).add_child(version)
end

Then(/^the field (\S+) should have @version (.+)$/) do |field_name, version_string|
  field = field_in_result_class("SomeClass", field_name)
  expect(field[:version]).to eq(version_string)
end

