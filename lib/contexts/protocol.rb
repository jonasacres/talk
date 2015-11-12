register :protocols

property :name

tag_description
tag :scheme, :multi => true
tag :method, :required => true, :multi => true
tag :source, :class => :string
tag :extra, :multi => true, :unique => :name
tag_end
