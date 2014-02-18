#!/usr/bin/ruby

module Talk
	class TalkFile
		attr_reader :filename

		def self.readFile(path)
		end

		def initialize(contents, filename=nil)
			@filename = filename
			@lines = setupLines(contents)
			@contexts = [ RootTalkContext ]
			@exceptions = []

			@lines.each do |line|
				parseLine(line)
			end
		end

		# Divides the file into lines, with the lines massaged a little
		# to make parsing easier. e.g. whitespace trimming. We might also
		# eventually do some more sophisticated massaging that manipulates the
		# order and number of lines. To future-proof, we'll store a dictionary
		# containing the actual line terms and physical line number so we can
		# get the data we want while still mapping back to physical lines.
		def setupLines(contents)
			lines = []
			lineNo = 0
			contents.split("\n").each do |line|
				lineNo += 1
				line.strip!
				lines.push {
					:lineNumber => lineNo,        # Physical line number
					:words => line.split(/\w+/),  # words, split by any whitespace
					:raw => line                  # raw line string
				}
			end

			return lines
		end

		# Parses a single line of a talk file. Takes in a dictionary with
		#  :lineNumber  =>  Physical line number in file corresponding to this
		#                   interpretted line
		#  :words       =>  Array of words from this line
		#  :raw         =>  Raw string containing the original line, with leading
		#                   and trailing whitespace stripped
		def parseLine(line)
			return parseLineWithComment(line) if lineIsComment?(line)
			return parseLineWithTag(line) if lineIsTag?(line)
			return parseLineWithData(line)
		end

		def parseLineWithComment(line)
			true # nothing to do for comment lines
		end

		def parseLineWithTag(line)
			tag = line.words[0][1 .. -1] # skip first character, which is @

			# if pop fails, try to parse in current context to use its error-handling logic
			context = popContextToTag(tag) || @contexts.last
			result = context.parseTag(line)
			if result[:error] then
				addParseError line, result[:error]
				return
			end

			if result.hasKey?(:context) and result[:context] != context then
				if result[:context].nil? @contexts.pop
				else @contexts.push(result[:context])
			end
		end

		def parseLineWithData(line)
		end

		# Identifies the context in the stack that we should apply a tag to.
		# Modifies context stack.
		def popContextToTag(tag)
			@contexts.reverse.each_index do |idx|
				if @contexts[idx].hasTag?(tag)
					@contexts = @contexts[0 .. idx]
					return @contexts.last
				end
			end

			return nil
		end

		def lineIsTag?(line)
			line.words[0][0] == '@'
		end

		def lineIsComment?(line)
			line.words[0][0] == '#'
		end

		def addParseError(line, message)
			preamble = filename.nil? ? "Line #{line[:lineNumber]}" : "#{filename}:#{line[:lineNumber]}"
			msg = "#{preamble} -- #{message}"
			exceptions.push(msg)
		end
	end
end
