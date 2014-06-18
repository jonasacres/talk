# register :methods
reference :response, :classes, :skip => ["none"]
reference :request, :classes, :skip => ["none"]

property :name

tag_description
tag :request, :class => :string
tag :response, :class => :string
tag :requriements, :class => :string
tag :origin, :class => :string, :allowed => [ "client", "server", "both" ]
tag :needs, :class => :string, :allowed => [ "nothing", "connection", "both" ]
tag_end
