require 'context_class'
require 'registry'

module Talk
  class Context
    attr_reader :tag, :file, :line

    include Enumerable

    def initialize(tag, file, line)
      @tag = tag
      @file = file
      @line = line
      @contents = {}

      @property_words = []
    end

    ## Parser interface

    def parse(word, file, line)
      @property_words.push word
    end

    def start_tag(tag, file, line)
      parse_error("Unsupported tag @#{tag}", file, line) unless self.class.tags.has_key?(tag)
      tag_class = self.class.tags[tag][:class]

      # @end tags use a nil class
      tag_class.nil? ? nil : Context.context_for_name(tag_class).new(tag, file, line)
    end

    def end_tag(context)
      context.close
      check_child_uniqueness(context) if self.class.unique_key_for_tag(context.tag)
      add_tag(context)
    end

    def has_key?(key)
      @contents.has_key?(key.to_sym)
    end

    def has_tag?(tag)
      self.class.has_tag?(tag)
    end

    def key_multiplicity(key)
      key = key.to_sym
      return 0 unless @contents.has_key?(key) and not @contents[key].nil?
      return 1 unless @contents[key].is_a? Array or @contents[key].is_a? Hash
      return @contents[key].length
    end

    def close
      process_property_words
      postprocess
      final_validation
      register
    end

    def finalize
      crossreference
    end

    ## Operators and other standard-ish public methods

    def each
      @contents.each { |v| yield v }
    end

    def [](key)
      @contents[key.to_sym]
    end

    def []=(key, value)
      if value.is_a? Array then
        value = value.map { |v| validated_value_for_key(key, transformed_value_for_key(key, value)) }
      else
        value = validated_value_for_key(key, transformed_value_for_key(key, value))
      end

      @contents[key.to_sym] = value
    end

    def add_tag(context)
      key = context.tag
      self[key.to_sym] ||= []
      self[key.to_sym].push validated_value_for_key(key, transformed_value_for_key(key, context))
    end

    ## Support for parser

    def check_child_uniqueness(child)
      # we could do this as a validator, but then we'd lose ability to show sibling info
      return unless self.has_key? child.tag
      key = self.class.unique_key_for_tag(child.tag)

      self[child.tag].each do |sibling|
        errmsg = "Child tag @#{child.tag} must have unique #{key} value; previously used in sibling at line #{sibling.line}"
        parse_error(errmsg, child.file, child.line) if child[key] == sibling[key]
      end
    end

    def process_property_words
      ranges = property_ranges
      ranges.each_with_index do |range, idx|
        property = self.class.property_at_index(idx)
        value = @property_words[range[0] .. range[1]].join(" ")
        self[property[:name]] = value
      end
    end

    def postprocess
      self.class.postprocesses.each { |p| p.call(self) }
    end

    def final_validation
      self.class.final_validations.each { |v| parse_error(v[:message]) unless v[:block].call(self) }
    end

    def register
      self.class.registrations.each { |r| Registry.add(self[r[:name]], r[:namespace], self.file, self.line) }
    end

    def crossreference
      self.class.references.each do |r|
        registered = Registry.registered?(self[r[:name]], r[:namespace])
        parse_error("Cross-reference failed: no symbol #{self[r[:name]]} in #{r[:namespace]}") unless registered
      end
    end

    ## Key manipulation

    def transformed_value_for_key(key, value)
      if self.class.transforms.has_key?(key) then
        self.class.transforms[key].inject(value) { |v, t| t.call(self, v) }
      else
        value
      end
    end

    def validated_value_for_key(key, value)
      self.class.validations[key].each { |v| parse_error(v[:message]) unless v[:block].call(self, value) }
      value
    end

    ## Property manipulation

    def property_ranges
      word_count = @property_words.length
      ranges = []

      self.class.properties.each do |prop_name, prop_def|
        len = prop_def[:length]
        offset = ranges.empty? ? 0 : ranges.last[1]+1
        msg_start = "@#{self.tag} property '#{prop_name}' "

        if len.is_a? Array then
          new_range = property_range_for_variable_len(offset, word_count, prop_def)
        else
          if offset >= word_count then
            parse_error(msg_start+"cannot be omitted") if prop_def[:required]
            new_range = [1, 0]
          else
            length_ok = (word_count - offset >= len)
            parse_error(msg_start+"got #{word_count-offset} of #{len} words") unless length_ok
            new_range = [offset, offset+len-1]
          end        
        end

        ranges.push new_range if new_range[1] >= new_range[0]
      end

      ranges
    end

    def property_range_for_variable_len(offset, word_count, prop_def)
      words_left = word_count - offset
      meets_min = words_left >= prop_def[:length][0]
      meets_max = prop_def[:length][1].nil? or words_left <= prop_def[:length][1]

      parse_error("Property #{prop_def[:name]} takes at least #{min} words; got #{word_count}") unless meets_min
      parse_error("Property #{prop_def[:name]} takes at most #{max} words; got #{word_count}") unless meets_max

      [ offset, word_count-1 ]
    end

    ## Output

    def parse_error(message, file=nil, line=nil)
      Talk::Parser.error(@tag, file || @file, line || @line, message)
    end

    def render_element(indent_level, key, element)
        if element.methods.include? :render then
          element.render(indent_level)
        else
          "\t" * indent_level + "#{key.to_s} -> '#{element.to_s}'\n"
        end
    end

    def render(indent_level=0)
      indent = "\t" * indent_level
      str = indent + "@" + self.tag.to_s + "\n"
      @contents.each do |key, value|
        if value.is_a? Array then
          str = value.inject(str) { |s, element| s + render_element(indent_level+1, key, element) }
        else
          render_element(indent_level+1, key, value)
        end
      end

      str
    end

    def to_s
      render
    end
  end
end
