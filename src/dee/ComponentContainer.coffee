AttachmentAppliersManager = require './componentContainer/AttachmentAppliersManager'

module.exports = class ComponentContainer
	constructor: (@_dee, @_id) ->
		@_handler = null
		@_attachmentAppliersManager = null
		# @_queuedModifiers = []

	setHandler: (handler) ->
		# console.log @_handler?
		if @_handler?
			throw Error "Component `#{@_id}` is already registered"

		@_handler = handler
		@_attachmentAppliersManager?.setHandler @_handler

		# for mod in @_queuedModifiers
		# 	@_handler.addModifier mod

		this

	getHandler: ->
		@_handler

	addAttachmentApplier: (applier) ->
		@_getAttachmentAppliersManager().add applier

		this

	_getAttachmentAppliersManager: ->
		unless @_attachmentAppliersManager?
			@_attachmentAppliersManager = new AttachmentAppliersManager this

			if @_handler?
				@_attachmentAppliersManager.setHandler @_handler

		@_attachmentAppliersManager

	hasAttachmentAppliersManager: ->
		@_attachmentAppliersManager?

		@_attachmentAppliersManager

	# addModifier: (mod) ->
	# 	if @_handler?
	# 		@_handler.addModifier mod
	# 	else
	# 		@_queuedModifiers.push mod

	# 	this