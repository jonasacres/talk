require "parse_error.rb"
require "context"

module Talk
  attr_reader :contexts
  @contexts = {}

  class Parser
    def self.error(tag, file, line, message)
      near_msg = tag.nil? ? "" : " near @#{tag}"
      raise ParseError, "#{file}:#{line}  parse error#{near_msg}: #{message}"
    end

    def initialize()
      @contexts = [ Context.context_for_name(:base).new("base", "n/a", "0") ]
    end

    def parse_file(filename)
      parse(filename, IO.read(filename))
    end

    def parse(filename, contents)
      contents = contents.split("\n") unless contents.class == "Array"
      contents.each_with_index { |line, line_num| parse_line(line.strip.split, filename, line_num+1) }
    end

    def parse_line(words, file, line)
      return if line_is_comment?(words)

      @file = file
      @line = line
      words.each { |word| parse_word(word) }
    end

    def parse_word(word)
      @word = word

      if word_is_tag?(word) then
        parse_tag(identifier_from_tag_word(word))
      else
        @contexts.last.parse(word, @file, @line)
      end
    end

    def parse_tag(tag)
      @tag = tag
      @contexts.last.has_tag?(tag) ? parse_supported_tag : parse_unsupported_tag
    end

    def parse_supported_tag
      new_context = @contexts.last.start_tag(@tag, @file, @line)
      if new_context.nil? then
        curr_ctx = @contexts.pop
        @contexts.last.end_tag(curr_ctx) unless @contexts.empty?
      else
        @contexts.push new_context
      end
    end

    def parse_unsupported_tag
      stack = Array.new(@contexts)
      stack.pop until stack.empty? or stack.last.has_tag? @tag

      parse_error("tag not supported in @#{@contexts.last.tag.to_s}") if stack.empty?

      close_active_context until @contexts.last == stack.last

      parse_supported_tag
    end

    def close_active_context
      closed_ctx = @contexts.pop

      @contexts.last.end_tag(closed_ctx) unless @contexts.empty?
    end

    def word_is_tag?(word)
      word[0] == '@'
    end

    def identifier_from_tag_word(word)
      word[1..-1].to_sym
    end

    def line_is_comment?(line)
      line.length > 0 and line[0].length > 0 and line[0][0] == '#'
    end

    def parse_error(message)
      raise Talk::Parser.error(@tag, @file, @line, message)
    end
  end
end
