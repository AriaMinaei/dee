ClassHandler = require './ClassHandler'
AttachmentApplier = require './AttachmentApplier'

module.exports = class AttachmentHandler extends ClassHandler
	constructor: ->
		super

		@_processDescriptions()

	_processDescriptions: ->
		for targetId, desc of @_cls.attachesTo
			@_processDescription targetId, desc

		return

	_processDescription: (targetId, desc) ->
		applier = new AttachmentApplier this, targetId, desc
		manager = @_dee._getTargetAttachmentsManager targetId

		manager.addApplier applier

	instantiate: (target) ->
		@_instantiate [target]

	isAttachment: yes
	componentTypeName: "Attachment"
	canInstantiate: yes