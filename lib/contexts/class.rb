register :classes
property :name

tag_description
tag :version, :default => "0", :context => :string
tag :field, :multi => true, :unique => :name
tag :implement, :context => :boolean, :default => true
tag :inherits
tag_end
