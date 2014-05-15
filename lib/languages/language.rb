require 'erb'
require 'fileutils'

def classname_for_filename(name) # /path/to/file_name.rb to FileName
  File.basename(name.to_s, ".rb").split('_').collect { |word| word.capitalize }.join("")
end

def is_primitive?(type)
  primitives = [
    "uint8", "uint16", "uint32", "uint64",
    "int8", "int16", "int32", "int64",
    "string", "real", "bool", "object", "talkobject" ]
  primitives.include? type
end

module Talk
  class Language
    attr_reader :supported_languages

    class << self
      def path_for_language(lang)
        File.absolute_path(File.join(File.dirname(__FILE__), "#{lang}/#{lang}.rb"))
      end

      def load_supported_languages
        @languages ||= {}

        local_dir = File.dirname(__FILE__)
        trimmed = Dir["#{local_dir}/*/"].map { |subdir| subdir.gsub(/\/$/, "") }
        supported = trimmed.select { |subdir| File.exists?(File.join(subdir, File.basename(subdir)+".rb")) }
        supported.each { |lang| load_language(lang) }
        supported.map { |lang| lang.to_sym }
      end

      def load_language(lang_name)
        lang_name = File.basename(lang_name.to_s, ".rb").to_sym
        new_classname = classname_for_filename(lang_name)
        source_file = path_for_language(lang_name)

        lang = Class.new(Talk::Language) {}

        lang.class_eval( IO.read(source_file), source_file )
        lang.class_eval( "def path\n\t\"#{File.dirname(source_file)}\"\nend" )
        lang.class_eval( "def name\n\t\"#{lang_name}\"\nend" )
        @languages[lang_name.to_sym] = lang
      end

      def language_named(lang_name)
        load_supported_languages if @languages.nil?
        @languages[lang_name.to_sym].new
      end
    end

    def initialize
      @written = {}
    end

    def render(base, target)
      @base = base
      @target = target
      @output_path = find_output_path

      make_source
      prune if @target[:prune]
    end

    def write(path, contents, conditional=true)
      @written[File.absolute_path(path)] = contents
      return if conditional and File.exists? path and IO.read(path) == contents
      
      FileUtils::mkdir_p(File.dirname(path))
      File.write(path, contents)
    end

    def prune
      # Delete anything we didn't conditionally write, unless it's a directory
      dirs = []
      Dir.glob(@output_path+"/**/*").each do |path|
        abs_path = File.absolute_path(path)
        unless @written.has_key?(abs_path) then
          if File.directory?(abs_path) then
            dirs.push abs_path
          else
            FileUtils::rm(abs_path)
          end
        end
      end

      # Now sort the directories by length, so longest directories are first
      # Since these are abspaths, that should guarantee subdirectories come before parents
      # Then delete each empty directory, tested by containing no entries other than '.' and '..'
      dirs.sort! { |a,b| b.length <=> a.length }
      dirs.each { |dir| FileUtils::rmdir(dir) if (Dir.entries(dir) - %w{ . .. }).empty? }
    end

    def find_output_path
      @target[:destination]
    end

    def generate_template(output_file, template_file=nil)
      template_file ||= output_file + ".erb"
      template_contents = IO.read(File.join(self.path, "templates", template_file))
      erb = ERB.new(template_contents)
      erb.filename = template_file
      source = erb.result(binding)
      filename = File.join(@output_path, output_file)
      write(filename, source)
      source
    end

    def meta(name)
      return nil if @target[:meta].nil?
      name = name.to_s

      @target[:meta].each do |meta|
        return meta[:value] if meta[:name].to_s == name
      end

      nil
    end

      def string_overlap(a,b)
      [a.length, b.length].min.times do |i|
        if a[i] != b[i] then
          return "" if i == 0
          return a[0..i-1]
        end
      end

      a.length < b.length ? a : b
    end

    def wrap_text_to_width(text, width=80, preamble="")
      width -= preamble.length
      words = text.split(/\s+/)
      lines = []

      words.each do |word|
        if lines.empty? or (lines.last + " " + word).length >= width then
          lines.push (preamble + word)
        else
          lines.last << " " + word
        end
      end

      lines.empty? ? "" : lines.join("\n")
    end

    def common_class_prefix
      prefix = nil
      @base[:class].each do |cls|
        if prefix.nil? then
          prefix = cls[:name]
        else
          prefix = string_overlap(prefix, cls[:name])
          return nil if prefix.length == 0
        end
      end

      prefix
    end

    def classname_for_filename(name) # /path/to/file_name.rb to FileName
      File.basename(name.to_s, ".rb").split('_').collect { |word| word.capitalize }.join("")
    end

    def truncated_name(name)
      name = name[:name] if name.is_a? Hash
      name.split('.').last
    end
  end
end
