property :name

tag_description
tag :language, :class => :string
tag :destination, :class => :string
tag :map, :multi => true
tag :meta, :multi => true, :unique => :name
tag :rootclass, :class => :string
tag :template, :class => :string
tag :prune, :class => :boolean
tag :extra, :multi => true, :unique => :name
tag_end
