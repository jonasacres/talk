def string_overlap(a,b)
  Math.min(a.length, b.length).times do |i|
    if a[i] != b[i] then
      return "" if i == 0
      return a[0..i-1]
    end
  end

  a.length < b.length ? a : b
end

def common_class_prefix
  prefix = nil
  @base[:class].each do |cls|
    if prefix.nil? then
      prefix = cls[:name]
    else
      prefix = string_overlap(prefix, cls)
      return nil if prefix.length == 0
    end
  end
end

def classname_for_filename(name) # /path/to/file_name.rb to FileName
  File.basename(name.to_s, ".rb").split('_').collect { |word| word.capitalize }.join("")
end

