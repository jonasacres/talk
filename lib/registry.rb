module Talk
  class Registry
    class << self
      def add(name, namespace)
        raise("Duplicate registration #{name} in #{namesapce}") if registered?(name, namespace)
        @registry ||= {}
        @registry[namespace] ||= []
        @registry[namespace].push name
      end

      def registered?(name, namespace)
        not @registry.nil? and @registry.has_key? namespace and @registry[namespace].include? name
      end
    end
  end
end
