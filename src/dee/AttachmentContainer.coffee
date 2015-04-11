ClassContainer = require './ClassContainer'
AttachmentHandler = require './AttachmentHandler'

module.exports = class AttachmentContainer extends ClassContainer
	constructor: (@_dee, @_id, @_cls) ->
		super

		@_processDescriptions()

	_processDescriptions: ->
		for targetId, desc of @_cls.attachesTo
			@_processDescription targetId, desc

		return

	_processDescription: (targetId, desc) ->
		handler = new AttachmentHandler this, targetId, desc
		manager = @_dee._getTargetAttachmentsManager targetId

		manager.addHandler handler

	instantiate: (target) ->
		@_instantiate [target]

	isAttachment: yes
	componentTypeName: "Attachment"
	canInstantiate: yes