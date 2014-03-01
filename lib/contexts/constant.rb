property :name
property :value, :transform => lambda { |c,v| eval(v.to_s) }, :required => false

tag_description
tag_end
