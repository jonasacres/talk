property :value, :transform => lambda { |v| v.to_f }

def to_val
	self[:value]
end
