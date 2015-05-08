ClassHandler = require './ClassHandler'
AttachmentApplier = require './AttachmentApplier'

module.exports = class AttachmentHandler extends ClassHandler
	constructor: ->
		super

		@_processDescriptions()

	_processDescriptions: ->
		for targetId, desc of @_cls.attachesTo
			new AttachmentApplier @_dee, this, targetId, desc

		return

	instantiate: (target) ->
		@_instantiate [target]

	isAttachment: yes
	componentTypeName: "Attachment"
	canInstantiate: yes