register :enumerations
property :name

tag_description
tag :constant, :multi => true, :unique => :name
tag_end

postprocess do
	# If we don't specify a constant value, use C-like implicit values
	# (i.e. constant[n] = {
	#     constant[n-1] + 1    n > 0
	#        0                 otherwise
	# }
	last_constant = nil
	children(:constant).each do |constant|
		next unless constant.value.nil?
		constant.value = last_constant.nil? ? 0 : last_constant.value + 1
	end
end
