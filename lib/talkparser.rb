require "talkcontext/talkcontext"

class TalkParser
	@errors = []

	class << self
		attr_reader :errors

		def parseError(tag, file, line, message)
			errors.push({ :file => file, :line => line, :tag => tag, :message => message })
			puts "#{file}:#{line}  in @#{tag.to_s}: #{message}"
		end
	end

	attr_reader :filename

	def initialize()
		@contexts = [ Talk::BaseTalkContext.new ]
	end

	def parseFile(filename)
		file = File.open(filename)
		lineNumber = 0

		startErrors = self.class.errors.length
		file.each { |line|
			lineNumber +=1
			line.strip!
			parseLine(line.split, filename, lineNumber)
		}

		self.class.errors.length - startErrors # return number of errors generated in parsing this file
	end

	def parse(filename, contents)
		contents = contents.split("\n") unless contents.class == "Array"

		lineNumber = 0
		contents.each do |line|
			lineNumber += 1
			line.strip!
			parseLine(line.split, filename, lineNumber)
		end

		self.class.errors.length - startErrors # return number of errors generated in parsing this record
	end

	def parseLine(words, file, line)
		return if lineIsComment?(words)
		words.each do |word|
			if wordIsTag?(word) then
				tag = identifierFromTagWord(word)
				parseTag(tag, file, line)
			else
				@contexts.last.parse(word)
			end
		end
	end

	def parseTag(tag, file, line)
		if @contexts.last.hasTag?(tag) then
			parseSupportedTag(tag, file, line)
		else
			parseUnsupportedTag(tag, file, line)
		end
	end

	def parseSupportedTag(tag, file, line)
		currCtx = @contexts.last
		newContext = currCtx.startTag(tag, file, line)
		if newContext.nil? then
			currCtx.close
			@contexts.pop
			@contexts.last.endTag(currCtx) unless @contexts.empty?
		else
			@contexts.push newContext
		end
	end

	def parseUnsupportedTag(tag, file, line)
		stack = Array.new(@contexts)
		currCtx = stack.last
		until currCtx.nil? or currCtx.hasKey? tag
			stack.pop
			currCtx = @contexts.last
		end

		if currCtx.nil?
			TalkParser.parseError(tag, file, line, "Unsupported tag @#{tag.to_s}")
			return
		end

		until @contexts.length == stack.length
			closedCtx = @contexts.last
			closedCtx.last.close
			@contexts.pop

			@contexts.last.endTag(closedCtx)
		end

		parseSupportedTag(tag, file, line)
	end

	def wordIsTag?(word)
		word[0] == '@'
	end

	def identifierFromTagWord(word)
		word[1..-1].to_sym
	end

	def lineIsComment?(line)
		line[0][0] == '#'
	end
end
