property :name
property :value, :length => [0,nil]

tag_description :bridge => false, :required => false
tag :extra, :multi => true, :unique => :name
tag_end

postprocess lambda { |ctx|
  if ctx[:value].nil? or ctx[:value].length == 0 then
    ctx[:value] = ctx[:name]
  end
}
