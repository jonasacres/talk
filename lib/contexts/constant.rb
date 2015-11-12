property :name
property :value, :transform => lambda { |c,v| eval(v.to_s).to_f }, :length => [0,nil]

tag_description :required => false, :bridge => false
tag :extra, :multi => true, :unique => :name
tag_end
