register :glossaries, :delimiter => '.'

property :name

tag_description
tag :term, :multi => true, :unique => :name
tag :extra, :multi => true, :unique => :name
tag_end
