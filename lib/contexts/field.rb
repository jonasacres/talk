reference :field, :classes

property :type
property :name

tag_description
tag :version, :context => :string, :default => "0"
tag :caveat, :context => :string, :multi => true
tag :deprecated, :context => :string
tag :see, :multi => true
tag_end

validate "Field name cannot start with __", :name, { |ctx, name| not name.start_with?("__") }
