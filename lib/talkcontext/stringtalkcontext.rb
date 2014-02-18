class StringTalkContext < TalkContext
	property :value, :length => [1, nil]

	def to_s
		@value
	end
end

