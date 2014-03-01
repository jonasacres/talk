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
      parse_error("Unsupported tag @#{tag}", file, line) unless self.class.tags.has_key?[tag]
      tag_class = self.class.tags[tag][:class]
      if tag_class.nil? then
        # @end tags use a nil class
        close
        nil
      else
        Context.context_for_name(tag_class).new(tag, file, line)
      end
    end

    def end_tag(context)
      context.close
      check_child_uniqueness(context) if self.class.unique_key_for_tag(context.tag)
      add_tag(context)
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
      @contents[key]
    end

    def []=(key, value)
      if value.is_a? Array then
        value = value.map { |v| validated_value_for_key(key, transformed_value_for_key(key, value)) }
      else
        value = validated_value_for_key(key, transformed_value_for_key(key, value))
      end

      @contents[key] = value
    end

    def add_tag(context)
      key = context.tag
      self[key.to_sym] ||= []
      self[key.to_sym].push validated_value_for_key(key, transformed_value_for_key(key, context))
    end

    ## Support for parser

    def check_child_uniqueness(child)
      # we could do this as a validator, but then we'd lose ability to show sibling info
      return unless self.has_key child.tag
      key = self.class.unique_key_for_tag(child.tag)

      self[child.tag].each do |sibling|
        errmsg = "Child tag @#{child.tag} must have unique #{key} value; previously used in sibling at line #{sibling.line}"
        parse_error(errmsg, child.file, child.line) if child[key] == sibling[key]
      end
    end

    def process_property_words
      ranges = property_ranges
      ranges.each_idx do |idx|
        range = ranges[idx]
        property = self.class.property_at_index(idx)
        self[property[:name]] = @property_words[range[0] .. range[1]].join(" ")
      end
    end

    def postprocess
      self.class.postprocesses.each { p.call(self) }
    end

    def final_validation
      self.class.final_validations.each { |v| parse_error(v[:message]) unless v[:block].call(self) }
    end

    def register
      self.class.registrations.each { |r| Registry.add(self[r[:name]], r[:namespace]) }
    end

    def crossreference
      self.class.references.each do |r|
        registered = Registry.registered?(self[r[:name]], r[:namespace])
        parse_error("Cross-reference failed: no symbol #{self[r[:name]]} in #{r[:namespace]}") unless registered
      end
    end

    ## Key manipulation

    def transformed_value_for_key(key, value)
      self.class.transforms[key].each { |t| value = transform.call(self, value) }
      value
    end

    def validated_value_for_key(key, value)
      self.class.validators[key].each { |v| parse_error(v[:message]) unless v[:block].call(self, value) }
      value
    end

    ## Property manipulation

    def property_ranges(word_count)
      self.class.properties.inject([]) do |ranges, prop_def|
        len = prop_def[:length]
        offset = ranges.empty? ? 0 : ranges.last[1]

        if len.is_a? Array then
          ranges.push(property_range_for_variable_len(offset, word_count, prop_def))
        else
          length_ok = word_count - offset <= len
          parse_error("Property #{prop_def[:name]} takes #{len} words; got #{word_count}") unless length_ok
          ranges.push([offset, len])
        end
      end
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
      raise ParseError.new(@tag, file || @file, line || @line, message)
    end
  end
end
