Given(/^I define a term$/) do
  @glossaries.last.add_child(make_term)
end

Given(/^I define a term named (\S+)$/) do |term_name|
  @glossaries.last.add_child(make_term(term_name))
end

Given(/^I define a term named (\S+) with value (\S+)$/) do |term_name, value|
  term = make_term(term_name, value)
  @glossaries.last.add_child(term)
end

Given(/^I define a term named (\S+) with value (\S+) and description (.+)$/) do |term_name, value, description_text|
  @glossaries.last.add_child(make_term(term_name, value, description_text))
end

Then(/^the glossary (\S+) should contain a term named (\S+)$/) do |glossary_name, term_name|
  term = term_in_result_glossary(result_glossary(glossary_name), term_name)
  expect(term).not_to be_nil
end

Then(/^the term (\S+) of glossary (\S+) should have value (\S+)$/) do |term_name, glossary_name, value|
  term = term_in_result_glossary(result_glossary(glossary_name), term_name)
  expect(term[:value]).to eq(value)
end

Then(/^the term (\S+) of glossary (\S+) should have description (.+)$/) do |term_name, glossary_name, description_text|
  term = term_in_result_glossary(result_glossary(glossary_name), term_name)
  expect(term[:description]).to eq(description_text)
end
