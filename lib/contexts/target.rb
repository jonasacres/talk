property :name

tag_description
tag :language, :class => :string
tag :destination, :class => :string
tag :map, :multi => true
tag :meta, :multi => true, :unique => :name
tag :rootclass
tag :template, :class => :string
tag_end
