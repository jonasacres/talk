register :classes, :delimiter => '.'
reference :inherits, :classes

property :name

tag_description
tag :version, :default => "0", :class => :string
tag :field, :multi => true, :unique => :name
tag :implement, :class => :boolean, :default => true
tag :inherits, :class => :string
tag :extra, :multi => true, :unique => :name
tag_end
