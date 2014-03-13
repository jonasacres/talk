require 'erb'

module Talk
  class Language
    include "global_helpers.rb"

    attr_reader :supported_languages

    class << self
      def initialize
        @languages = {}
      end

      def path_for_language(lang)
        File.absolute_path("lib/languages/" + File.basename(lang.to_s, ".rb") + ".rb")
      end

      def load_supported_languages
        local_dir = File.dirname(__FILE__)
        trimmed = Dir["#{local_dir}/*/"].map { |subdir| subdir.gsub(/\/$/, "") }
        supported = trimmed.select { |subdir| File.exists?(File.join(subdir, subdir+".rb")) }
        supported.each { |lang| load_language(lang) }
        supported.map { |lang| lang.to_sym }
      end

      def load_language(lang_name)
        new_classname = classname_for_filename(lang_name)
        lang = Class.new(Talk::Language) do
          initialize(new_classname)
        end

        source_file = path_for_language(lang_name)
        lang.class_eval( IO.read(source_file), source_file )
        self[lang_name] = lang
      end

      def [](lang_name)
        @languages[lang_name.to_sym]
      end

      def []=(lang_name, lang)
        @languages[lang.to_sym] = lang
      end
    end
  end

  def render(base, target)
    @base = base
    @path = path
    @target = target
    @output_path = find_output_path

    make_source
  end

  def find_output_path
    @target[:destination]
  end

  def generate_template(output_file, template_file=nil)
    template_file ||= output_file
    template_contents = IO.read(File.join(File.dirname(__FILE__), template_file))
    source = ERB.new(template_contents).result
    File.write(File.join(@output_path, output_file), source)
    source
  end

  def meta(name)
    @target[:meta].each do |meta|
      return meta[:value] if meta[:name] == name
    end

    nil
  end
end
