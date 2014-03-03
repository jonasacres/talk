# register :methods
reference :response, :classes, :skip => ["none"]
reference :request, :classes, :skip => ["none"]
reference :followup, :classes, :skip => ["none"]

property :name

tag_description
tag :response, :class => :string
tag :request, :class => :string
tag :followup, :class => :string
tag :requirements, :class => :string
tag :origin, :class => :string, :allowed => [ "client", "server", "both" ]

tag_end
