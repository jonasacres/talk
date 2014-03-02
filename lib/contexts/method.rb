register [:methods, :origin]
reference :response, :classes, :skip => [nil, "none"]
reference :request, :classes, :skip => [nil, "none"]
reference :followup, :classes, :skip => [nil, "none"]

property :name

tag_description
tag :response, :class => :string
tag :request, :class => :string
tag :followup, :class => :string
tag :requirements, :class => :string
tag :origin, :class => :string, :allowed => [ "client", "server", "both" ]

tag_end
