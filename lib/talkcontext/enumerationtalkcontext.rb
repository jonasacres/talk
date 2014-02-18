class EnumerationTalkContext < TalkContext
	register :enumerations
	property :name

	tag_description
	tag :constant, ConstantTalkContext, :multi => true, :unique => :name
	tag_end

	postprocess {
		# If we don't specify a constant value, use C-like implicit values
		# (i.e. constant[n] = {
		#     constant[n-1] + 1    n > 0
		#        0                 otherwise
		# }
		lastConstant = nil
		children(:constant).each do |constant|
			next unless constant.value.nil?
			constant.value = lastConstant.nil? ? 0 : lastConstant.value + 1
		end
	}
end
