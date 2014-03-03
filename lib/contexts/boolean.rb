property :value, :transform => lambda { |ctx,v| v.downcase }, :allowed => [ ["0", "no", "false", "off"], ["1", "yes", "true", "on"] ]

def to_val
	self[:value] == "0" ? false : true
end
