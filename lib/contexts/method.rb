# register :methods
reference :response, :classes, :skip => ["none"]
reference :request, :classes, :skip => ["none"]

property :name

tag :description, :class => :string
tag :request, :class => :string
tag :response, :class => :string
tag :requirements, :class => :string
tag :followup, :class => :string
tag :origin, :class => :string, :allowed => [ "client", "server", "both" ]
tag :needs, :class => :string, :allowed => [ "nothing", "connection", "both" ]
tag :extra, :multi => true, :unique => :name
tag_end
