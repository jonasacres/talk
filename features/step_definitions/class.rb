Given(/^I have defined a class named (.+)$/) do |class_name|
  make_class(class_name)
end

Given(/^I have given (.+) as a @description$/) do |description|
  last_class.add_child(make_description(description))
end

Then(/^there should be a class named (.+)$/) do |class_name|
  expect(result_class(class_name)).not_to be_nil
end

Then(/^it should have description (.+)$/) do |description|
  expect(result_class(last_class)[:description]).to eq(description)
end

Given(/^I have given (.+) as an implied description$/) do |description|
  last_class.add_data(description)
end

Given(/^I don't give a description$/) do
end

Given(/^I define another class also named (.+)$/) do |class_name|
  make_class(class_name).add_data("A description")
end

Given(/^I give it @inherits (.+)$/) do |base_class|
  last_class.add_child(TalkTag.new("@inherits").add_data(base_class))
end

Then(/^the class (.+) should have @inherits (.+)$/) do |child_class, base_class|
  expect(result_class(child_class)[:inherits]).to eq(base_class)
end

Given(/^I give it @implement (.+)$/) do |is_implemented|
  last_class.add_child(TalkTag.new("@implement").add_data(is_implemented))
end

Then(/^the class (.+) should have @implement (.+)$/) do |class_name, is_implemented|
  implemented = case is_implemented
    when 'false'
      false
    when 'true'
      true
    else
      'wtf'
  end
  expect(result_class(class_name)[:implement]).to eq(implemented)
end
