register [:name, :language]

property :name

tag_description
tag :language, :class => :string
tag :destination, :class => :string
tag :map, :multi => true
tag :rootclass
tag :template, :class => :string
tag_end
