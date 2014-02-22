class FieldTalkContext < TalkContext
	reference :field, :classes

	property :type
	property :name

	tag_description
	tag :version, StringTalkContext, :default => "0"
	tag :caveat, StringTalkContext, :multi => true
	tag :deprecated, StringTalkContext
	tag :see, ReferenceTalkContext, :multi => true
	tag_end

	validate_property "Field name cannot start with __", :name, { |ctx, name| not name.start_with?("__") }
end
