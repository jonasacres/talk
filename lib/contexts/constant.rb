property :name
property :value, :transform => lambda { |v| eval(v) }, :required => false

tag_description
tag_end
