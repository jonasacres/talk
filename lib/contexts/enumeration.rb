register :enumerations, :delimiter => '.'
property :name

tag_description
tag :constant, :multi => true, :unique => :name
tag_end

postprocess lambda { |ctx|
	# If we don't specify a constant value, use C-like implicit values
	# (i.e. constant[n] = {
	#     constant[n-1] + 1    n > 0
	#        0                 otherwise
	# }
	ctx[:constant].inject(0) do |value, constant|
		value = constant[:value] unless constant[:value].nil?
		constant[:value] = value
		value += 1
	end
}
