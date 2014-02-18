class GlossaryTalkContext < TalkContext
	register :glossaries

	property :name

	tag_description
	tag :term, TermTalkContext, :multi => true, :unique => :name
	tag_end
end

