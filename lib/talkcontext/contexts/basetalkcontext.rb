module Talk
	class BaseTalkContext < TalkContext
		tag :class, :ClassTalkContext
		tag :method, :MethodTalkContext
		tag :enumeration, :EnumerationTalkContext
		tag :protocol, :ProtocolTalkContext
		tag :target, :TargetTalkContext
		tag :glossary, :GlossaryTalkContext
	end
end
