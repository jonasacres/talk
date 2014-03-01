property :type, :transform => lambda { |ctx, v| v.downcase }, :allowed => [ "class", "enum", "glossary" ]
property :name

reference :name, lambda {
	{ "class" => :classes, "glossary" => :glossaries, "enumeration" => :enumerations }[self.type]
}
