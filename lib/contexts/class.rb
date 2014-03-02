register :classes, :delimiter => '.'
property :name

tag_description
tag :version, :default => "0", :class => :string
tag :field, :multi => true, :unique => :name
tag :implement, :class => :boolean, :default => true
tag :inherits
tag_end
