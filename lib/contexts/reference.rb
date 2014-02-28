property :type, :transform => { |v| v.downcase }, :allowed => [ "class", "enum", "glossary" ]
property :name

reference :name {
	{ "class" => :classes, "glossary" => :glossaries, "enumeration" => :enumerations }[self.type]
}
