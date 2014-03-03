# About Talk::Context

## The Context Stack

`Talk::Context` is a class to manage parsing Talk files. Each `Context` corresponds to a given tag. For example, `@class` tags are managed by a `Context` subclass defined in `contexts/class.rb`.

When the Talk parser hits a given tag, it instantiates a new `Context` object of the appropriate subclass to manage parsing that tag. Since the parser was already in a context, it adds the new context to a stack.

As the parser reads in new text, it passes that text to the current context (i.e. the topmost context on the stack). There are two kinds of data that each context will manage

1. Children (i.e. tags within the current tag)
2. Properties (i.e. data belonging to the tag itself)

As an example, consider the following Talk definition:

```
@class SomeClass
   @description This is a description of the class
   @field int32 someField
       This is a field
   @end
   @field string anotherField
       @description This is another field
   @end
@end
```

In this example, we see that the `@class` tag has one piece of data about the tag itself (the name, `SomeClass`), and 3 child tags (an `@description` and two `@field` tags).

The `Context` class defined in `contexts/class.rb` knows to expect a single word for a name, and that it is legal to have `@field` and `@description` tags, and it knows which context classes to use for each of them.

## Context subclasses
Defining a context subclass is easy. Here's an example from `contexts/class.rb` for parsing `@class` tags:

```
register :classes, :delimiter => '.'
reference :inherits, :classes

property :name

tag_description
tag :version, :default => "0", :class => :string
tag :field, :multi => true, :unique => :name
tag :implement, :class => :boolean, :default => true
tag :inherits, :class => :string
tag_end
```

This tells us to expect the following:

1. A property called 'name'
2. An `@description` tag with the default behavior
3. An `@version` tag, whose default value is `"0"` if the user doesn't specify a 4. value
4. An `@field` tag, which can appear multiple times, but must have a unique name each time
4. An `@implement` tag, interpreted by `contexts/boolean.rb` whose default value is `true`
5. An `@inherits` tag, interpreted by `contexts/string.rb`
6. Every time we create a tag in this context, we'll register its name property in the `classes` namespace, using `"."` as a delimiter
7. A requirement that if a tag parsed in this context uses `@inherits`, then the value specified must be the name of a class we define somewhere else

This sounds very complex, doesn't it? It's a bit domain-specific, but I hope you'll find it's actually quite easy to wrap your head around once you know what's going on, which is what this document is meant to help you do.

## Lifecycle

To see how a `Context` works, it helps to walk through the life of an instance from start to finish.

### Definition
Before we can instantiate an instance, we need to define the class. All `Context` subclasses inherit the class methods from `lib/context_class.rb` and the instance methods from `lib/context.rb`, and the subclasses themselves live in `lib/contexts`.

If you open up that directory, you'll see that there is no boilerplate to any of these files -- not even a formal statement that they inherit from `Context`! This is because the code you write into these files will automatically be evaluated into a new `Context` subclass created at run-time.

You might also notice that we never refer to any `Context` subclass definition files by name in the source, nor do we glob for them. The only subclass we explicitly look for is `contexts/base.rb` which defines the top-level context for parsing Talk files.

When `Context` loads this file, it will see that it declares tags, like `tag :class`. By default, `Context` will now look for `contexts/class.rb` to provide the context for tags instantiated into this context. But, we can override that behavior using parameters. Recall this line from `contexts/class.rb`:

`tag :implement, :class => :boolean`

This tells `Context` to use the subclass defined in `contexts/boolean.rb` instead.

### Instantiation

An actual `Context` instance begins when a parent context sees a tag and creates a new instance to parse it. As discussed above, the parent context knows which subclass to look for based on the actual tag definition itself.

Once the new context is created, it is pushed to the top of the context stack and receives every token from the input.

### Parsing

One-by-one, words are fed to the `Context` instance by the parser via the `Context#parse` method. These words are held in an array until the `Context` instance is closed, and then parsed for property data. If the parser sees a new tag, it will call `Context#start_tag` and the instance will return the appropriate new context to add to the context stack. This new context will now receive the data from the parser, and the current context will receive nothing until the new context ends.

#### Tag transformation

When a tag closes, it has the opportunity to have a transformation applied to it, via the `:transform` parameter. This provides `Context` classes an ability to perform additional processing on tag data that is specific to the needs of the parent.

#### Tag validation

After any and all transformations have been applied to the tag, the `Context` instance may run optional validation tests against it to ensure that it contains an acceptable value.

### Closure

A `Context` can be closed when it either starts a tag whose handler class is defined to be `nil` (as is the case with the `tag_end` macro for generating `@end` tag support), or if the parser encounters a tag that the active `Context` subclass does not handle but a parent `Context` does.

Once a context closes, it begins closure processing, which includes property parsing, registration and post-processing.

#### Property parsing

Recall that all non-tag data is accumulated into the `Context` instance. During the property parsing phase, the `Context` instance assigns this data to individual properties. Each property may have transformations and validations applied to it, exactly as tags do.

#### Post-processing

`Context` subclasses may supply optional post-processing blocks using the `postprocess` method. These blocks serve as a final transformation of the entire class.

#### Registration

If the tag registers any of its properties in a namespace, that registration is now done.

### Finalization

After all input has been parsed, the parser will close all open contexts and call the `finalize` method on each `Context` instance. Instances will be finalized in the order they were closed in, so that the first instance to close will be the first to finalize, and the base instance will be the last to finalize.

Finalization is a phase in which validations are performed that may depend upon an inter-relation between tags, e.g. dependencies between @glossary names and @see references.

#### Final validation

A `Context` instance may supply a final validation block to perform last-minute custom validation prior to cross-referencing, or to implement its own form of cross-referencing that goes beyond the sophistication of the built-in cross-referencing facility.

#### Cross-referencing

If a `Context` subclass references symbols (like class names), the parser will now check that these symbols are actually defined. For instance, the @see tag will make references to things like glossaries. In this phase, a parse error is generated if these references point to things we haven't defined yet.

## Writing Subclasses
### Creating the subclass

To create a subclass to support a new tag, you need to do 3 things:

1. Refer to your new tag somewhere in the hierarchy. For example, if you're creating a new `@foobar` tag that is valid at the base level, then open `contexts/base.rb` and write a line like `tag :foobar`.
2. Create the implementation for your new tag. By default, `Context` will use the tag name itself as the basis of the filename, so it will look for `contexts/foobar.rb` in our example.
3. Write the implementation. This is the fun part!

### Writing the implementation

Your subclass file does not need any boiler plate. You **do not** need to use any class or module definitions. When your code is executed, it will be in a scope that looks like this:

```ruby
module Talk
  class YourSubclass << Context
  	class << self
	  # your code will be injected here
	end
  end
end
```

Context has most, or all of the machinery you'll need to define your subclass, using a handful of methods.

| method | description
|--|--
|**property**|Define a new property
|**tag**|Define a new tag
|**tag_description**|Shorthand to create a typical @description tag
|**tag_end**|Shorthand to create typical @end tag
|**register**|Register a property of the instance into a namespace, ensuring uniqueness and allowing cross-referencing
|**reference**|Require that a property of the instance match a key registered into a namespace by another context
|**validate**|Perform a validation of a property or tag immediately upon parsing
|**postprocess**|Perform a transformation on the entire object after parsing all files, but before final validation
|**validate_final**|Perform a validation of the entire object after parsing all files, but before cross-referencing
|**bridge_tag_to_property**|Allow a child tag to get its property data from the property data of this tag

#### property(name, params={})
Ex.: `property :name`

Generate support for a property with a given name and optional parameters.

Parameters:

| key | description | default
|--|--|--
| :allowed | Array of allowable values. Throws parse error if a value is set that is not within the allowed values. | nil
| :length | Integer or array. If integer, number of words to expect in a property. If array, then array must have 2 integers with minimum and maximum number of words to expect in a property. The maximum may be nil to indicate an unbounded property. | 1
| :required | Boolean. If true, throws parse error if property is not set. | true
| :transform | Block, taking \|context, value\| as input, returning modified value as output. Invoked prior to validating value. | nil

The `:allowed` property has a bit of extra magic to it: you can use nested arrays to normalize a range of allowed values to the first element of the subarray. Check out this example from `contexts/boolean.rb`:

`property :value, :transform => lambda { |ctx,v| v.downcase }, :allowed => [ ["0", "no", "false", "off"], ["1", "yes", "true", "on"] ]`

This says that I'm allowed to specify "0", "NO", "no", "False" or "oFF", but it'll all get stored as "0". Likewise, "1", "yes", "true" and "on" get stored as "1".

#### tag(name, params={})
Ex.: `tag :version, :class => :string`

Generate support for a tag with a given name and optional parameters.

Parameters:

| key | description | default
|--|--|--
| :class | Symbol. Name of `Context` subclass to use for parsing this tag | Tag name
| :multi | Boolean. Do not generate parse error if tag appears twice. | false
| :required | Boolean. Generate parse error if tag is omitted. | false

#### tag_description
Ex.: `tag_description`

Generate support for a @description tag with typical sematics. See source for details.

#### tag_end
Ex.: `tag_end`

Generate support for a @end tag with typical semantics. See source for details.

#### register(namespace, params={})
Ex.: `register :classes`

Ensure the uniqueness of a given name or identifier in an object by registering it in a namespace. By default, registers the :name property.

Parameters:

| key | description | default
|--|--|--
| :name | Symbol. Name of property containing string to be registered in namespace | :name
| :delimiter | String. Character to use in splitting multi-level identifiers. | nil

The `:delimiter` field is a helpful bit of shorthand. For instance, `context/class.rb` uses `delimiter => '.'`. This allows us to register a class like `@class com.example.some.long.ClassName`, but reference it later as `@field ClassName someField`, or even `@field some.long.ClassName someField`.

#### reference(name, namespace, params={})
Ex.: `reference :request, :classes, :skip => ["none"]`

Ensure that a string specified in a given tag or property is registered in the given namespace. Causes a parse error to be generated if the symbol is not registered after all files are parsed.

namespace can be a symbol, or a block. If namespace is a block, it takes the form `{ |ctx| :some_namespace }`. That is, it takes in the `Context` instance as a parameter and returns the namespace as a result.

If a tag is named as a reference, the `:value` property of the tag will be used as the string.

Parameters:

| key | description | default
|--|--|--
| :skip | Array. Contains strings of values that are permitted regardless of whether or not they are registered in any namespace. | []


#### validate(message, name, block)
Ex. `validate("Field name cannot start with __", :name, lambda { |ctx, name| not name.start_with?("__") })`

Invokes the given block when a tag or property is set. Generates a parse error with the supplied message if the block returns false.

The block receives two arguments: a reference to the `Context` instance, and the proposed value being validated. The value is **not** set into the `Context` at the time the validate block is called.

Because the error message is compiled at the time the class is defined, you cannot place references to the offending value inside the message. If this isn't suitable, consider just generating a parse error yourself inside the block.

A given property or tag can have multiple `validate` blocks attached to it.

#### postprocess(block)
Ex. `postprocess lambda { |ctx| do_stuff; }`

Invokes a given block after ALL files have been parsed, but before final validation and cross-referencing.

#### validate_final(message, block)
Ex. `validate_final("An error message", lambda { |ctx| test_something; }

Invokes the given block after ALL files have been parsed, but before final validation and cross-referencing. Generates a parse error with the supplied message if the block returns false.

#### bridge_tag_to_property(name)
Ex. `bridge_tag_to_property :description`

Allows the trailing property data of this tag to be passed as property data to a child tag. This is used in `@description` tags to make both of these variants parse:

```
@class SomeClass
  @description This is a class
@end
```

```
@class SomeClass This is a class
```