# About TalkContext

## The Context Stack

`TalkContext` is a class to manage parsing Talk files. Each `TalkContext` corresponds to a given tag. For example, `@class` tags are managed by `ClassTalkContext`. Some tags contain primitives that are managed by more generic contexts, like `@description`, which is managed by `StringTalkContext`.

When the Talk parser hits a given tag, it instantiates a new TalkContext object of the appropriate subclass to manage parsing that tag. Since the parser was already in a context, it adds the new context to a stack.

As the parser reads in new text, it passes that text to the current context (i.e. the topmost context on the stack). There are two kinds of data that each context will manage

1. Child tags
2. Data about the tag itself

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

The `ClassTalkContext` class knows to expect a single word for a name, and that it is legal to have `@field` and `@description` tags, and it knows which context classes to use for each of them.

## Context subclasses
Defining a context subclass is easy. Here's an example from FieldTalkContext for parsing `@field` tags:

```
class FieldTalkContext < TalkContext
	unique
	property :type
	property :name

	tag_description
	tag :version, StringTalkContext, :default => "0"
	tag :caveat, StringTalkContext, :multi => true
	tag :deprecated, StringTalkContext
	tag :see, ReferenceTalkContext, :multi => true
	tag_end

	validate "Field name cannot start with __", :name { |name| not name.start_with?("__") }
end
```

This tells us to expect the following:

1. A tag that looks like @tag {type} {name} (`property :type`, `property :name`)
2. If this tag has siblings in the parent, then all the siblings should have unique name fields (`unique`)
3. An `@description` tag that behaves like typical `@description` tags (`tag_description`)
4. An optional `@version` tag that can appear at most once, and if it doesn't appear, assume it reads like `@version 0`.
5. An optional `@caveat` tag that can appear any number of times.
6. An optional `@deprecated` tag that can appear at most once.
7. An optional `@see` tag that can appear any number of times.
8. A validation test that ensures field names never start with `"__"`

## Properties
Let's start with how we declare properties. Generally speaking, properties are defined by all the text inside a Talk tag that doesn't belong to a child tag.

The order we define our properties is important. The first word will get passed to the first defined property, and the second word to the second property, and so on. (By default, properties take only one word of input, but that can be adjusted on a per-property basis.)

Defining a basic property is easy:

```
property :myProperty
```

Now we'll read in a word of text, and assign it to the `myProperty` field of the context. i.e., if you have a reference to the context as `ctx`, then you can get the value of `myProperty` via `ctx.myProperty`, and it will be a string containing the first word of data in the tag that isn't a child tag.

But let's say that you don't want to store a string -- you have a numeric property, like `size`. Now we can get into the property parameters:

```
property :size, :transform => lambda { |v| v.to_f }
```

We've specified a block that will get called on the string input, and will return the actual value to be assigned. In this case, we take the string and call `to_f` to convert it to a float.

Here's a list of allowable parameters:

| Parameter    | Datatype    |  Default   | Description
| ------------ |:-----------:|:----------:|:-----------
| :allowed | array | `nil` | Raises a parser error if the string value is not contained in the array. Array elements may be themselves arrays of strings, in which case the string value will be tested against each member of the subarray. If a match is found, the string value will be replaced with the first element of the subarray.
| :length | Integer or array | `1` | If integer, specifies the number of words to feed to the parameter. If array, specifies the minimum and maximum number of words, If the maximum is nil, any number of words may be specified to the parameter. Array form may only be used for last property in a context definition.
| :required | Boolean | `true` | If true, a parser error will be generated if the property is not defined. Only the last property of a context can have required => false.
| :transform | Block | `{ \|v\| v }` | Applies a transformation to the string value of a property prior to storing it as the value of the property.

## Tags
Defining tags is a lot like defining properties:

```
tag :title, StringTalkContext
```

The above defines an `@title` tag that represents a string, as interpretted by the `StringTalkContext` class. By default, tags are optional, so the parser **will not** generate an error if we don't see an `@title` tag. They're also unique by default, so the parser **will** generate an error if we supply more than one `@title` tag.

| Parameter    | Datatype    |  Default   | Description
| ------------ |:-----------:|:----------:|:-----------
| :default | String | `nil` | If specified, and no property data is provided for the child tag in the input, then the given string will be supplied as property data to the child tag.
| :implicitProperty | Boolean | `false` | If true, all property data supplied to the context beyond the last defined property will be sent as property data to the child tag.
| :multi | Boolean | `false` | If `false`, a parser error will be generated if the tag appears more than once in the context.
| :required | Boolean | `false` | If true, a parser error will be generated if the tag does not appear in the context.
| :unique | Symbol | `nil` | If non-nil, a parser error will be generated if two sibling tags of this type have matching property values identified by the given symbol

### tag_description
A lot of contexts in Talk end up with an `@description` tag that behaves identically everywhere: it's a string, it's required, and it's an implicit property. Rather than write out the long definition in every context that needs it, the `tag_description` convenience method applies the same `tag` definition.

### tag_end
Similarly, a lot of contexts have an `@end` tag that signals the parser to pop the current context off the stack. As a matter of convenience, and to make it easier to change this definition in the future, use the `tag_end` method.

## Validations
### register
A lot of definitions made in Talk tags need to be discoverable by name elsewhere. For example, if we define an `@field` whose type is a class that we defined in an `@class` somewhere, then we're going to want to be able to cross-reference that by checking our list of `@class` definitions to see if we have one with that name.

We can declare that items defined in a tag will be searchable in a given namespace using the `register` method. For example, we can put this in the ClassTalkContext class to cause it to register in the `:classes` namespace using its `:name` property:

```
register :classes, :name
```

Since it is so common to register using `:name`, the `register` method assumes you will use `:name` by default. The following code snippet is equivalent to the one above:

```
register :classes
```

Namespaces presently used:

| Namespace | Description
|-----------|------------
| :classes | `@class` definitions
| :enumerations | `@enumeration` definitions
| :glossaries | `@glossaries` definitions

This has the side effect of creating a layer of parser validation: the parser will generate an error if a tag attempts to register in the same namespace with the same name as an existing tag. So, if you have two `@class` definitions with the same name, it will generate a parser error via the `register` method.

### reference
Sometimes a tag will reference something defined by another tag, and we would like the parser to cross-reference that and validate that we did in fact provide a definition for the thing being referenced. For example, `@field` will reference datatypes defined using `@class`.

```
reference :name, :glossaries
```

This will cause the parser to validate that there is an object named after the `:name` property in the `:classes` namespace.

Sometimes, you may not know what namespace to check. An example of this is a `@see` tag, which might reference a class, glossary or enum. In this case, you may pass a block returning the appropriate namespace:

```
reference :name, {
	{ "class" => :classes, "glossary" => :glossaries, "enumeration" => :enumerations }[self.type]
}
```

This block is consulted to determine the namespace to check `:name` against.

### postprocess
After all input is processed for a tag, it might be necessary to do some postprocessing logic. This is the case if, for example, you have child tags whose data is in some way semantically related to their siblings. `@enumeration` is a good example of this, since the `@constant` tags can have implied value with C enum-like semantics.

`postprocess` defines a block that runs after all input has been parsed and the context has closed, but before validation tests are run:

```
postProcess {
	# do some stuff
}
```

### validate_tag and validate_property
If you've read this far, you've probably noticed that all the most common validation tests are semantically implied. Sometimes you need something a little more unusual. For example, `@field` does not allow names that start with `"__"`, as a means to leave a reserved namespace for serialization book-keeping.

`validate_property` provides a way to do this. The following invocation causes a block to get called every time we set the `:name` property. If the block returns false, a parser error is generated, with the string we specify.

```
validate_property "Field name cannot start with __", :name, { |name| not name.start_with?("__") }
```

We can use this for tags, too, with `validate_tag`, with identical syntax. In this case, the block will be invoked with a reference to the context object for the tag. This lets us impose requirements on tags that exist because of the relationship they have with their parent, and not because of an inherent nature of the tag itself.

### validate_final
In some cases, we might want to do an overall validation after all the tags and properties have been read in. In this case, you may use `validate_final`:

```
validate_final "Overall validation failed", { testSomething }
```
