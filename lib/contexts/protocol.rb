register :protocols

property :name

tag_description
tag :scheme, :multi => true, :required => true
tag :method, :required => true, :multi => true
tag :source, :class => :string
tag_end
