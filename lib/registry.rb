module Talk
  class Registry
    class << self
      def add(name, namespace, file, line)
        if registered?(name, namespace) then
          old_reg = get_registration(name, namespace)
          Talk::Parser.error(nil, file, line, "Duplicate registration #{name} in #{namespace_to_s(namespace)}; previously defined at #{old_reg[:file]}:#{old_reg[:line]}")
        end

        @registry ||= {}
        level = @registry
        [*namespace].each do |space|
          level[space] ||= {}
          level = level[space]
        end

        level[name] = { :file => file, :line => line }
      end

      def get_registration(name, namespace, match_exact = false)
        level = @registry
        [*namespace].each do |space|
          level = level[space]
          return nil if level.nil?
        end

        level[name]
      end

      def namespace_to_s(namespace)
        [*namespace].join("::")
      end

      def registered?(name, namespace, match_exact = false)
        # TODO: Inexact matching
        name = name.value.to_sym if name.methods.include? :value
        not @registry.nil? and @registry.has_key? namespace and @registry[namespace].has_key? name
      end
    end
  end
end
