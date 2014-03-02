reference :name, :classes

property :type
property :name

tag_description
tag :version, :class => :string, :default => "0"
tag :caveat, :class => :string, :multi => true
tag :deprecated, :class => :string
tag :see, :class => :reference, :multi => true
tag_end

validate("Field name cannot start with __", :name, lambda { |ctx, name| not name.start_with?("__") })
