module Talk
	class ClassTalkContext < TalkContext
		register :classes
		property :name

		tag_description
		tag :version, StringTalkContext, :default => "0"
		tag :field, ClassFieldTalkContext, :multi => true, :unique => :name
		tag :implement, BooleanTalkContext, :default => true
		tag :inherits, InheritsTalkContext
		tag_end
	end
end
