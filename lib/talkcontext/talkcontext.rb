# Lifecycle:
#   Open context
#   Accumulate terms for property parsing
#   Parse and validate tags
#   Close context
#     Parse and validate properties
#     Postprocessing
#     Validate context
#     Perform registrations
#   
#   Process input into new contexts until all input is read
#   Cross-refrence each context

class TalkContext
	class << self
		@properties = {}
		@tags = {}

		@references = []
		@registrations = []
		@postprocesses = []

		@tagValidators = {}
		@propertyValidators = {}
		@finalValidators = []


		@registry = {} # should not be directly accessed by subclasses!

		attr_reader :tags, :properties
		attr_reader :references, :postprocesses, :registrations
		attr_reader :propertyValidators, :tagValidators, :finalValidators

		Dir["contexts/*.rb"].each { |file| require file }

		# Parser context definition methods
		# Documented in README.md

		def property(identifier, params = {})
			defaults = {
				:allowed => nil,
				:length => 1,
				:required => true,
				:transform => lambda { |ctx, v| v }
			}

			params.reject! { |k,v| not defaults.has_key? k } # Only allow keys already in defaults
			params = defaults.merge(params) # Merge with defaults, using params as preferred value

			@properties[identifier] = params
			setupPropertySupport(identifier, params)
		end

		def tag(identifier, contextClass, params = {})
			defaults = {
				:default => nil,
				:implicitProperty => false,
				:multi => false,
				:required => false,
				:unique => nil
			}

			params.reject! { |k,v| not defaults.has_key? k } # Only allow keys already in defaults
			params = defaults.merge(params) # Merge with defaults, using params as preferred value
			params[:context] = contextClass

			@tags[identifier] = params
			setupTagSupport(identifier, params)
		end

		def register(namespace, identifier=:name)
			@registrations.push { :identifier => identifier, :namespace => namespace }
		end

		def reference(identifier, namespace)
			@references.push({:namespace => namespace, :identifier => identifier})
		end

		def postprocess(&block)
			@postprocesses.push(block)
		end

		def validate_property(errMsg, identifier, &block)
			@propertyValidators[identifier] ||= []
			@propertyValidators[identifier].push { :message => errMsg, :validator => block }
		end

		def validate_tag(errMsg, identifier, &block)
			@tagValidators[identifier] ||= []
			@tagValidators[identifier].push { :message => errMsg, :validator => block }
		end

		def validate_final(errMsg, &block)
			@finalValidators.push { :message => errMsg, :validator => block }
		end

		# Support methods for parser context definition methods

		def addRegistration(namespace, name, context)
			@registry[namespace] ||= {}
			@registry[namespace][name] = context
		end

		def checkRegistration(namespace, name)
			return nil unless @registry.has_key? namespace
			@registry[namespace][name]
		end

		def setupArrayAllow(identifier, params)
			arrayCount = 0
			newAllowed = []
			translation = {}

			params[:allowed].each do |option|
				if option.class == "Array" then
					arrayCount += 1
					newAllowed += option
					option.each do |subopt|
						translation[subopt] = option[0]
					end
				else
					newAllowed.push(option)
					translation[option] = option
				end
			end

			if arrayCount > 0 then
				params[:transform] = lambda { |ctx, v|
					translation[v]
				}
			end

			params[:allowed] = @properties[identifier] = newAllowed
		end

		def setupPropertySupport(identifier, params)
			if params[:allowed].nil? == false then
				params[:allowed] = setupArrayAllow(identifier, params)
				validate_property "Illegal value for property #{identifier.to_s}", lambda { |ctx|
					params[:allowed].include?(ctx.instance_variable_get("@"+identifier.to_s))
				}
			end

			if params[:required] == true then
				validate_final "Missing property @#{identifier.to_s}", lambda { |ctx|
					ctx.instance_variable_get("@"+identifier.to_s) != nil
				}
			end
		end

		def setupTagSupport(identifier, params)
			if params[:implicitProperty] then
				property :__implicit, :length => [1, nil]
				postprocess { |ctx|
					if ctx.children(identifier).length > 0 then
						ctx.generateParseError("Tag @#{identifier.to_s} supplied as both tag and implicit property")
					else
						tagCtx = params[:context].new(identifier, ctx.file, ctx.line, params)
						ctx.addTag(tagCtx)
					end
				}
			end

			if params[:multi] == false then
				validate_tag "Duplicate tag @#{identifier.to_s}", lambda { |tag, ctx|
					ctx.children(identifier).length > 0
				}
			end

			if params[:required] == true then
				validate_final "Missing tag @#{identifier.to_s}", lambda { |ctx|
					ctx.children(identifier).length == 0
				}
			end

			if params[:unique].nil? == false then
				# TODO: I hate how little context we get here. We need a better way to fill out error messages.
				validate_tag "Duplicate identifier for tag @#{identifier.to_s}", lambda { |tag, ctx|
					tagId = tag.instance_variable_get("@"+params[:unique].to_s)
					ctx.children(identifier).each do |sibling|
						return false if sibling.instance_variable_get("@"+params[:unique].to_s) == tagId
					end
				}
			end
		end
	end

	attr_reader :file, :line, :tag, :params, :children

	def initialize(tag, file, line, params)
		@tag = tag
		@file = file
		@line = line
		@params = params

		@children = {}
		@words = []

		self.class.properties.keys.each do |prop|
			name = prop.to_s
			ivar = "@"+name
			instance_variable_set(ivar, nil)
			class_eval("def #{name}; #{ivar}; end")
			class_eval("def #{name}=(v); #{ivar} = v; end")
		end
	end

	## Data management
	def properties()
		result = {}
		self.class.properties.keys.each do |prop|
			result[prop] = instance_variable_get("@#{prop.to_s}")
		end

		result
	end

	# Returns a list of child contexts for a given tag name
	def children(tag)
		@children[tag.to_sym]
	end

	# Tests if we support children of the given tag name
	def hasTag?(tag)
		self.class.tags.keys.include? tag.to_sym
	end

	## Parsing

	# Parses a single word into the context
	def parse(word)
		@words.push word
	end

	# Processes all words parsed into this context
	def parseDataString
		if @words.length == 0 and params.has_key? :default then
			@words = params[:default].split
		end
		return if @words.length == 0

		wordsLeft = @words.split
		self.class.properties.each do |property, defn|
			length = defn[:length]
			propWords = []

			if length.class == "Array" then
				if wordsLeft.length - length[0] < 0 then
					generateParseError("Incomplete definition of property #{property.to_s}; "
					 + "expected at least #{length[0]} terms, got #{wordsLeft.length}")
					return
				end

				if length[1].nil? == false and wordsLeft.length - length[1] > 0 then
					generateParseError("Too many terms in property #{property.to_s}; "
						+ "expected at most #{length[1]} terms, got #{wordsLeft.length}")
					return
				end

				propWords = wordsLeft
			else
				if wordsLeft.length - length < 0 then
					generateParseError("Incomplete definition of property #{property.to_s}; "
					 + "expected #{length} terms, got #{wordsLeft.length}")
					return
				end

				propWords = wordsLeft[0..length-1]
			end

			assignProperty(property, propWords.join(' '))
			wordsLeft = wordsLeft[length .. -1]
		end
	end

	def startTag(tag, file, line)
		return nil unless hasTag? tag

		params = self.class.tags[tag]
		return nil if params[:context].nil?

		params[:context].new(tag, file, line, params)
	end

	def endTag(tagContext)
		addTag(tagContext)
	end

	def close
		self.class.postprocesses.each { |post| post.call(self) }
		parseDataString

		errors = 0
		errors += validateContext
	end

	## Intra-assignment and Post-assignment housekeeping

	def assignProperty(property, value)
		transformer = self.class.properties[property][:transform]
		transformed = transformer.call(self, value)
		instance_variable_set("@"+property.to_s, transformed)
		validateProperty(property, transformed)
	end

	def validateProperty(property, value)
		errors = 0
		self.class.propertyValidators[property].each do |validatorDef|
			if validatorDef[:block].call(value) == false then
				generateParseError(validatorDef[:message])
				errors += 1
			end
		end

		errors
	end

	def addTag(tagContext)
		errors = validateTag(tagContext, context)
		return false if errors > 0

		@children[tagContext.tag] ||= []
		@children[tagContext.tag].push tagContext
		true
	end

	def validateTag(tagCtx, context)
		errors = 0
		self.class.tagValidators[tagCtx.tag].each do |validatorDef|
			if validatorDef[:block].call(tagCtx, context) == false then
				context.generateParseError(validatorDef[:message]) 
				errors += 1
			end
		end

		errors
	end

	## Housekeeping chores to perform after context is closed

	def performRegistrations
		self.class.registrations.each do |reg|
			name = instance_variable_get("@"+reg[:identifier].to_s)
			TalkContext.addRegistration(reg[:namespace], name, self)
		end
	end

	def validateContext
		errors = 0
		self.class.finalValidators.each do |validatorDef|
			if validatorDef[:block].call == false then
				generateParseError(validatorDef[:message]) 
				errors += 1
			end
		end

		errors
	end

	def crossReference
		errors = 0
		self.class.references.each do |reference|
			namespaceNames = { :glossaries => "glossary", :classes => "class", :enumerations => "enumeration" }
			title = reference[:namespace] || "reference"
			name = instance_variable_get("@"+reference[:identifier].to_s)

			unregistered = TalkContext.checkRegistration(reference[:namespace], name).nil?
			if unregistered == true then
				generateParseError("Reference to undefined #{title} #{name}")
				errors += 1
			end
		end

		errors
	end

	## General I/O stuff

	def generateParseError(message)
		TalkParser::parseError(@tag, @file, @line, message)
	end

	def to_s
		values = []
		properties().each { |k,v| values.push "\"#{k}\": \"#{v}\"" }
		
		@children.each do |tag, contexts|
			lines = []
			contexts.each { |ctx| lines.push("\"#{ctx.to_s}\"") }
			values.push "\"@#{tag}\": [ #{lines.join(', ')} ]"
		end

		"{ #{values.join(", ")} }"
	end
end
