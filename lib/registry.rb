class Array
  def each_prefix
    self.length.times do |i|
      yield(self[0..i])
    end
  end
end

module Talk
  class RegistryEntry
    attr_reader :file, :line

    def initialize(file=nil, line=nil)
      @file = file
      @line = line
      @children = {}
    end

    def make_entry(file, line)
      @file = file
      @line = line
    end

    def [](key)
      @children[key]
    end

    def []=(key, value)
      @children[key] = value
    end

    def keys
      @children.keys
    end

    def each(&block)
      @children.each &block
    end

    def has_children?
      not @children.empty?
    end

    def is_entry?
      @file != nil
    end

    def to_s
      is_entry? ? "#{@file}:#{@line}" : "container"
    end
  end

  class Registry
    class << self
      def add(name, namespace, file, line, delimiter=nil)
        if registered?(name, namespace) then
          old_reg = get_registrations(name, namespace).last
          Talk::Parser.error(nil, file, line, "Duplicate registration #{name} in #{namespace}; previously defined at #{old_reg}")
        end

        @registry ||= {}
        @registry[namespace] ||= {}
        split_name = delimiter.nil? ? [*name] : name.to_s.split(delimiter)

        # create each level of the split name
        level = @registry[namespace]
        split_name[0..-2].each do |component| # all but the last component
          level[component] ||= RegistryEntry.new
          level = level[component]
        end

        level[split_name.last] ||= RegistryEntry.new(file, line)
        level[split_name.last].make_entry(file, line) # in case it already existed as a container
        add_reverse_lookup(split_name, namespace, level[split_name.last], delimiter)
      end

      def add_reverse_lookup(split_name, namespace, entry, delimiter)
        @reverse ||= {}
        @reverse[namespace] ||= {}
        split_name.reverse.each_prefix do |prefix|
          name = prefix.reverse.join(delimiter)
          @reverse[namespace][name] ||= []
          @reverse[namespace][name].push entry
        end
      end

      def get_registrations(name, namespace, match_exact = false)
        @registry ||= {}
        exact = get_exact_registrations(name, namespace)
        
        return exact unless exact.empty?
        return [] if match_exact

        get_inexact_registrations(name, namespace)
      end

      def get_exact_registrations(name, namespace)
        level = @registry[namespace]
        [*name].each do |component|
          return [] if level.nil?
          level = level[component]
        end

        return [*level] if not level.nil? and level.is_entry?
        []
      end

      def get_inexact_registrations(name, namespace)
        return [] if @reverse.nil? or @reverse[namespace].nil? or @reverse[namespace][name].nil?
        @reverse[namespace][name]
      end

      def registered?(name, namespace, match_exact = false)
        not get_registrations(name, namespace, match_exact).empty?
      end

      def render_level(level, at_depth=1)
        indent = "    "*at_depth
        s = ""
        level.keys.sort.each do |key|
          value = level[key]
          s += indent + key
          s += " (entry from #{File.basename(value.file)}:#{value.line})" if value.is_entry?
          s += "\n"
          s += render_level(value, at_depth+1)
        end

        s
      end

      def reset
        @registry = nil
        @reverse = nil
      end

      def to_s
        return "Empty registry" if @registry.nil? or @registry.empty?
        s = ""
        @registry.keys.sort.each do |namespace|
          level = @registry[namespace]
          s += "Namespace #{namespace}:\n"
          s += render_level(level)
        end

        s
      end
    end
  end
end
