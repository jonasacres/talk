# Main entry point 
# First the Enumeration, Protocol, and Glossary files are processed, followed by the class files

def make_source
  @namespace = common_class_prefix if meta(:namespace) == "true"
  @prefix = meta(:classprefix) if meta(:classprefix)
  master_files = [ "TalkEnumeration.swift", "TalkProtocol.swift", "TalkGlossary.swift"]
  master_files.each { |template| generate_template(template) }
  
  @base[:class].each do |cls|
    @current_class = cls
    @current_class[:field] ||= []
    file_base = filename_for_class(cls)
     generate_template(file_base+".swift", "class.swift.erb")
  end
end

# Returns string representing the file path of the talk class.  
# If the namespace meta tag is set to true then the path is the same as on the file system
# If namespace is set to true then all files will be under the class folder
def filename_for_class(cls)
  class_dir = "classes"
  if meta(:namespace) == "true" then
    namespace = cls[:name][@namespace.length..-1].split(".")[0..-2]
    return File.join(class_dir, truncated_name(cls)) if namespace.empty?

    namespace = namespace[1..-1] while namespace[0].length == 0
    File.join(class_dir, namespace.join("/"), truncated_name(cls))
  else
    File.join(class_dir, truncated_name(cls))
  end
end

# Returns a string with the class prefix appended if one is set, called from the swift class erb template
def class_name(name)
  if @prefix then
    @prefix + name[:name].split(".").last
  else
    name[:name]
  end
end

# Returns a string that contains the talkfile path and line number the tag appears on
def definition_reference(tag=nil)
  "@talkFile #{tag[:__meta][:file]}:#{tag[:__meta][:line]}" unless tag.nil?
end

# Returns a string to indicate the contents were autogenerated 
# if a tag is passed then the underlying talk file and line number are included
def autogenerated_warning(tag=nil)
  <<-AUTOGEN_DONE
// Autogenerated from Talk
// Please do not edit this file directly. Instead, modify the underlying .talk files.
// #{definition_reference(tag)}
  AUTOGEN_DONE
end

# Returns the string for defning a class variable, called form the swift class erb file
def field_variable(field,cls)
  lines = []
  var_def = "\tvar #{mapped_name(cls, field, :field)}:#{field_datatype(field,field[:type])}"
  if field[:type].last == "object" || !is_primitive?(field[:type].last) then
    lines.push(var_def+"? = nil")
  elsif
    lines.push(var_def+" = #{field_datatype(field,field[:type])}()")
  end
  lines.join("\n")
end

# Returns a string that represents a fields data type 
def field_datatype(field, type)
  return converted_field_type(type.last) if type.length == 1
  t = type.last

  r = field_datatype(field, type[0 .. -2])
  if is_array? t then
    "Array<#{r}>"
  elsif is_dict? t then
    "Dictionary<String, #{convert_field_for_map(r)}>"
  else
    nil
  end
end

# Returns the swift specific type given a talk field and type 
def converted_field_type(type)
  if is_primitive? type then
    case type
    when "string"
      "String"
    when "real"
      "Double"
    when "bool"
      "Bool"
    when "object"
      "Any"
    when "talkobject"
      @prefix+rootclass
    when "int8"
      "Int"
    when "uint8"
      "Int"
    when "int16"
      "Int"
    when "uint16"
      "Int"
    when "int32"
      "Int"
    when "uint32"
      "Int"
    when "int64"
      "Int"
    when "uint64"
      "Int"
    end
  else
    @prefix+truncated_name(type)
  end
end

# Returns the swift data type for use in declaring dictionaries
def convert_field_for_map(field)
  case field
  when "byte"
    "UInt8"
  when "short"
    "Short"
  when "int"
    "Int"
  when "long"
    "Int"
  when "double"
    "Double"
  when "string"
    "String"
  else
    field
  end
end

# Returns a shortened tag name by splitting on the "/" and uppercasing each element before joing back into a single string 
def shortened_name(name)
  name = (name.split("/").map { |x| x[0].upcase + x[1..-1] }).join("")
end

# Returns a string representing a documentation block for use in XCode's quick help feature, appended before a class or struct
def documentation_block(tag,struct_name, indent_level=0)
  lines = []
  indent = "\t" * indent_level
  lines.push(indent + "/**")
  lines.push(wrap_text_to_width(tag[:description], 80, indent + " *  ")) unless tag[:description].nil?
  lines.push(definition_reference(tag))
  lines.push(indent + "  ")
  lines.push((tag[child_type_for_type(struct_name)].map { |child_type| indent + " - "+ child_type[:name]+": "+ (child_type[:description].nil? ? "" : child_type[:description] )}).join("\n"))
  lines.push(indent + " */")
  lines.join("\n")
end

# Returns a string representing a struct declaration, includes a documentation block 
def struct_block(tag,struct_name, indent_level=1)
  lines = []
  indent = "\t" * indent_level

  lines.push("/**")
  lines.push("Talk" + struct_name)
  lines.push(" ")
  lines.push((tag.map { |child| " - "+ child[:name]+": "+ (child[:description].nil? ? "" : child[:description] )}).join("\n"))
  lines.push("*/")
  lines.push(" ")
  lines.push("struct " + "Talk" + struct_name + " {")
  lines.push(" ")
  tag.each do |child| 
    seen_children = []
    lines.push(documentation_block(child,struct_name,indent_level))
    lines.push(indent + "struct " + struct_name_for_type(struct_name,child) + " {")
    child[child_type_for_type(struct_name)].each do |child_type|
        unless seen_children.include? child_type[:name]
            lines.push( indent+indent+definition_for_child_type(struct_name,child_type))
            seen_children.push(child_type[:name])
        end
    end
    
    lines.push(indent + "}")
  end
  lines.push("}")
  lines.join("\n")
end

# Returns a string used in naming a struct based on the type of struct being declared
def struct_name_for_type(type,tag)
  case type.downcase
    when "protocol"
      shortened_name(tag[:name])
    when "glossary"
      tag[:name].split(".").last
    when "enumeration"
      tag[:name].split(".").last
    end
end

# Returns the child type for a given tag type, used in enumerating the correct child key
def child_type_for_type(type)
  case type.downcase
    when "protocol"
      :method
    when "glossary"
      :term
    when "enumeration"
      :constant
    when "class"
      :field
    end
end

# Returns a string used to declare a struct variable based on the type of struct
def definition_for_child_type(type,tag)
    case type.downcase
    when "protocol"
      "static let "+ tag[:name]+" = \"" + tag[:name] + "\""
    when "glossary"
      "static let "+ tag[:name]+" = \"" + tag[:name] + "\""
    when "enumeration"
      "static let #{tag[:name]} = #{tag[:value].to_i}"
    end
end

# The following methods return strings for declaring methods and protocols for various JSON<->Object mapping frameworks
# The two major ones supported are:
# * tailor - https://github.com/zenangst/Tailor
# * objectmapper - https://github.com/Hearst-DD/ObjectMapper

def mapper_block(mapper,cls)
  case mapper.downcase
    when "tailor"
      tailor_block(cls)
    when "argo"
      argo_block(cls)
    when "objectmapper"
      objectmapper_block(cls)
  end
end

def mapper_protocol(mapper,cls)
  case mapper.downcase
      when "tailor"
        ",Mappable"
      when "objectmapper"
        ",Mappable"
    end unless is_subclass?(cls)
end

def tailor_block(cls)
  lines = []  
  map = ""
  map = "map" if is_subclass?(cls)

  lines.push("\trequired convenience init(_ map: [String : AnyObject]) {")
  lines.push("\t\tself.init(" + map + ")") 
  cls[:field].map do |f|  
    lines.push("\t\t"+mapped_name(cls, f, :field)+"\t<- map.property(\""+ f[:name] +"\")")
  end
  lines.push("\t}")
  lines.join("\n")
end

def objectmapper_block(cls)
  lines = []  
  lines.push("\trequired init?(map: Map) {")
  lines.push("\t\tsuper.init(map: map)") if is_subclass?(cls)
  lines.push("\t}")
  lines.push(" ")
  if is_subclass?(cls) then
    lines.push("\toverride func mapping(map: Map) {")
  else
    lines.push("\tfunc mapping(map: Map) {")
  end
  cls[:field].map do |f|  
    lines.push("\t\t"+mapped_name(cls, f, :field)+"\t<- map[\""+ f[:name] +"\"]")
  end
  lines.push("\t}")
  lines.join("\n")
end

