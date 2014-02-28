module Talk
	class ParseError
		attr_reader :tag, :file, :line, :message
		def initialize(tag, file, line, message)
			@tag = tag
			@file = file
			@line = line
			@message = message
		end

		def to_s
			"#{@file}:#{@line}  Parse error near @#{@tag}: #{@message}"
		end
	end
end
