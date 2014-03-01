module Talk
  class Context
    class << self
      attr_reader :classname, :properties, :tags, :transforms
      attr_reader :registrations, :references
      attr_reader :validations, :final_validations, :postprocesses

      attr_reader :registry

      def initialize(classname)
        @classname = classname
        @properties = {}
        @property_map = []
        @tags = {}
        @transforms = {}

        @registrations = []
        @references = []

        @validations = {}
        @final_validations = []
        @postprocesses = []
      end

      ## Stuff to be used by context definitions
      ## All of this is documented in ./README.md
      def property(name, params={})
        raise "Duplicate property definition #{name} in #{@classname}" if @properties.has_key?(name)
        @properties[name] = params.merge({ name:name })
        @property_map.push(name)
        add_property_support(name, params)
      end

      def tag(name, params={})
        raise "Duplicate tag definition #{name} in #{@classname}" if @properties.has_key?(name)
        @tags[name] = params
        add_tag_support(name, params)
        load_child_tags(name, params)
      end

      def tag_description
        tag(:description, { :class => :string, :required => true })
        bridge_tag_to_property :description
      end

      def tag_end
        tag(:end, { :class => nil })
      end

      def register(namespace, name=:name)
        @registrations.push({ namespace:namespace, name: name })
      end

      def reference(name, namespace)
        @references.push({ namespace:namespace, name:name})
      end

      def postprocess(&block)
        @postprocesses.push block
      end

      def validate(errmsg, name, block)
        @validations[name] ||= []
        @validations[name].push( { message: errmsg, block: block } )
      end

      def validate_final(errmsg, block)
        @final_validations.push( { message: errmsg, block: block })
      end

      def bridge_tag_to_property(name)
        fixed_keys = { required: false }
        allowed_keys = [:transform, :context]

        # the new property will have parameters pre-defined fixed_keys, and also
        # parameters imported from the tag listed in allowed_keys
        params = allowed_keys.inject(fixed_keys) { |c, k| c.merge( k => @tags[name][k] ) }
        property( name, params )
      end

      ## Convenience and support methods for instance methods

      def property_at_index(idx)
        return nil unless idx < @property_map.length

        return @properties[@property_map[idx]]
      end

      def unique_key_for_tag(key)
        @tags[key][:unique]
      end

      ## Subclassing magic
      def all_contexts
        Dir["#{$:[0]}/contexts/*.rb"].collect { |file| context_for_name(name) }
      end

      def context_for_name(name)
        predefined_context_for_name(name) || make_context(name)
      end

      def predefined_context_for_name(name)
        begin
          Talk.const_get classname_for_filename(name)
        rescue NameError
          nil
        end
      end

      def make_context(name)
        define_subclass(name)
      end

      def canonical_path_for_name(name)
        File.absolute_path("lib/contexts/" + File.basename(name.to_s, ".rb") + ".rb")
      end

      def classname_for_filename(name) # /path/to/file_name.rb to FileName
        File.basename(name.to_s, ".rb").split('_').collect { |word| word.capitalize }.join("")
      end

      def define_subclass(name)
        new_classname = classname_for_filename(name)
        
        subclass = Class.new(Talk::Context) do
          initialize(new_classname)
        end

        source_file = canonical_path_for_name(name)
        subclass.class_eval( IO.read(source_file), source_file )

        Talk.const_set new_classname, subclass
      end

      ## Support stuff; avoid invoking directly
      def add_key_support(name)
        @transforms[name] = []
        @validations[name] = []
      end

      def add_property_support(name, params)
        add_key_support(name)
        add_property_allowed(name, params[:allowed]) if params.has_key?(:allowed)
        add_property_required(name) if params.has_key?(:required)
        add_property_transform(name, params[:transform]) if params.has_key?(:transform)
      end

      def add_property_allowed(name, allowed)
        ref = "#{@classname}.#{name}"
        norm_allow = normalize_allowed(name, allowed).join(", ")
        errmsg  = "#{ref}: must be one of #{allowedDesc}"

        validate( errmsg, name, lambda { |c,v| norm_allow.include? v } )
      end

      def add_property_required(name)
        ref = "#{@classname}.#{name}"
        errmsg = "#{ref}: required property cannot be omitted"

        validate_final( errmsg, lambda { |c| c.include? name } )
      end

      def add_property_transform(name, transform)
        @transforms[name] = transform
      end

      def add_tag_support(name, params)
        add_key_support(name)
        params[:class] = name unless params.has_key?(:class) # ||= won't work since class might be nil

        add_tag_singular(name) unless params[:multi]
        add_tag_required(name) if params[:required]
      end

      def add_tag_singular(name)
        ref = "#{@classname}->@#{name}"
        errmsg = "#{ref}: tag may only be added once"
        validate_final( errmsg, lambda { |c| not c.has_key? name or c[name].length <= 1 } )
      end

      def add_tag_required(name)
        ref = "#{@classname}->@#{name}"
        errmsg = "#{ref}: required tag cannot be omitted"
        validate_final( errmsg, lambda { |c| c.include? name and c[name].length > 0 } )
      end

      def load_child_tags(name, params)
        @tags.each_value { |tag| Context.context_for_name(tag[:class]) unless tag[:class].nil? }
      end

      def normalize_allowed(name, allowed)
        new_allowed = []
        remap = {}

        allowed.each do |*v| # *v -> force v to be array even when scalar
          new_allowed += v
          v.each { |u| remap[u] = v[0] }
        end

        add_property_transform(name, lambda { |c,v| remap[v] })
      end
    end
  end
end