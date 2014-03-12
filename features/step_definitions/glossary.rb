Given(/^I define a glossary named (\S+) with description (.+)$/) do |glossary_name, description_text|
  make_glossary(glossary_name).add_child(make_description(description_text))
end

Then(/^there should be a glossary named (\S+)$/) do |glossary_name|
  expect(result_glossary(glossary_name)).not_to be_nil
end

Then(/^the glossary named (\S+) should have description (.+)$/) do |glossary_name, description_text|
  expect(result_glossary(glossary_name)[:description]).to eq(description_text)
end

Given(/^I define a glossary named (\S+) with implicit description (.+)$/) do |glossary_name, description_text|
  make_glossary(glossary_name).add_data(description_text)
end

Given(/^I define a glossary$/) do
  make_glossary
end

Given(/^I define a glossary named (\S+)$/) do |glossary_name|
  make_glossary(glossary_name)
end
