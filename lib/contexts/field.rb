def dissect_type(type)
	containers = []
	while is_container?(type)
		containers.push type[-2..-1] # last two characters
		type = type[0..-3] # all but last two
	end

	containers.push type
	containers.reverse
end

def is_primitive?(type)
	primitives = [
		"uint8", "uint16", "uint32", "uint64",
		"int8", "int16", "int32", "int64",
		"string", "real", "bool", "object", "talkobject" ]
	primitives.include? type
end

def is_container?(type)
	type.end_with? "[]" or type.end_with? "{}"
end

property :type, :transform => lambda { |c,v| c.dissect_type(v) }
property :name

tag_description
tag :version, :class => :string
tag :caveat, :class => :string, :multi => true
tag :deprecated, :class => :string
tag :see, :class => :reference, :multi => true
tag_end

validate("Field name cannot start with __", :name, lambda { |ctx, name| not name.start_with?("__") })
validate_final("Field name is not a recognized primitive or class", lambda do |ctx|
	t = ctx[:type]
	return true if ctx.is_primitive?(t.first)
	ctx.crossreference_value(t.first, :classes)
	
	true
end)

