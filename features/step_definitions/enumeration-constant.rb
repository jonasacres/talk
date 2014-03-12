Given(/^I define a valid constant named (\S+)$/) do |constant_name|
  @enumerations.last.add_child(make_constant(constant_name))
end

Given(/^I define a valid constant named (\S+) with value (.+)$/) do |constant_name, value|
  @enumerations.last.add_child(make_constant(constant_name, value))
end

Given(/^I define a constant named (\S+) with value (\S+) and description (.+)$/) do |constant_name, value, description_text|
  @enumerations.last.add_child(make_constant(constant_name, value).add_child(make_description(description_text)))
end

Given(/^I define a constant named (\S+) with value (\S+) and implicit description (.+)$/) do |constant_name, value, description_text|
  @enumerations.last.add_child(make_constant(constant_name, value, description_text))
end

Then(/^the enumeration (\S+) should contain a constant named (\S+)$/) do |enumeration_name, constant_name|
  enum = result_enumeration(enumeration_name)
  expect(enum).not_to be_nil

  constant = constant_in_result_enumeration(enum, constant_name)
  expect(constant).not_to be_nil
end

Then(/^the constant (\S+) should have value (.+)$/) do |constant_name, value|
  enum = result_enumeration(@enumerations.last)
  constant = constant_in_result_enumeration(enum, constant_name)
  expect(constant[:value]).to eq(value)
end

Then(/^the constant (\S+) of enumeration (\S+) should have value (\S+)$/) do |constant_name, enumeration_name, value|
  enum = result_enumeration(enumeration_name)
  constant = constant_in_result_enumeration(enum, constant_name)
  expect(constant[:value]).to eq(value)
end

Then(/^the constant (\S+) of enumeration (\S+) should have description (.+)$/) do |constant_name, enumeration_name, description_text|
  enum = result_enumeration(@enumerations.last)
  constant = constant_in_result_enumeration(enum, constant_name)
  expect(constant[:description]).to eq(description_text)
end

