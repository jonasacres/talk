module Talk
  class Registry
    class << self
      def add(name, namespace, file, line)
        if registered?(name, namespace) then
          old_reg = @registry[namespace][name]
          raise("Duplicate registration #{name} in #{namespace}\n\t#{file}:#{line}\n\t#{old_reg[:file]}:#{old_reg[:line]}")
        end
        
        @registry ||= {}
        @registry[namespace] ||= {}
        @registry[namespace][name] = { :file => file, :line => line }
      end

      def registered?(name, namespace)
        not @registry.nil? and @registry.has_key? namespace and @registry[namespace].has_key? name
      end
    end
  end
end
