property :type, :transform => lambda { |c, v| v.downcase }, :allowed => [ "class", ["enumeration", "enum"], "glossary" ]
property :name

reference :name, lambda { |ctx|
	{ "class" => :classes, "glossary" => :glossaries, "enumeration" => :enumerations, "enum" => :enumerations }[ctx[:type]]
}
