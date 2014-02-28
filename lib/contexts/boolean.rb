property :value, :transform => lambda { |v| v.downcase }, :allowed => [ ["0", "no", "false", "off"], ["1", "yes", "true", "on"] ]
