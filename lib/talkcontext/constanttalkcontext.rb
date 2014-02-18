class ConstantTalkContext < TalkContext
	property :name
	property :value, :transform => { |v| eval(v) }, :required => false

	tag_description
	tag_end
end

