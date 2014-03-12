Given(/^I define an enumeration named (\S+) with description (.+)$/) do |enum_name, description_text|
  make_enumeration(enum_name).add_child(make_description(description_text))
end

Then(/^there should be an enumeration named (\S+)$/) do |enum_name|
  expect(result_enumeration(enum_name)).not_to be_nil
end

Then(/^the enumeration named (\S+) should have description (.+)$/) do |enum_name, description_text|
  expect(result_enumeration(enum_name)[:description]).to eq(description_text)
end

Given(/^I define an enumeration named (\S+) with implicit description (.+)$/) do |enum_name, description_text|
  make_enumeration(enum_name).add_data(description_text)
end

Given(/^I define an enumeration$/) do
  make_enumeration
end

Given(/^I define an enumeration named (\S+)$/) do |enum_name|
  make_enumeration(enum_name)
end

Given(/^I don't give it a description$/) do
end

Given(/^I don't give it a name$/) do
end
