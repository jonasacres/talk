class NumericTalkContext < TalkContext
	property :value, :transform => lambda { |v| v.to_f }

	def to_f
		@value
	end
end
