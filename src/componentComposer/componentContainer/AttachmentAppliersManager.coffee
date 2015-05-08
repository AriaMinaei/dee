module.exports = class AttachmentAppliersManager
	constructor: (@_targetContainer) ->
		@_targetId = @_targetContainer._id
		@_appliersByPropName = {}
		@_hasAppliers = no
		@_canHaveAppliers = yes
		@_handler = null

	add: (applier) ->
		@_hasAppliers = yes
		unless @_canHaveAppliers
			throw Error "Component '#{@_targetId}' is not a class and cannot have attachments.
				But component '#{applier.getId()}' is trying to attach to it"

		propName = applier.getPropName()

		if @_appliersByPropName[propName]?
			otherApplier = @_appliersByPropName[propName]
			throw Error "Cannot attach '#{applier.getId()}' to
				'#{@_targetId}' as '#{propName}' because '#{otherApplier.getId()}'
				is already using that prop name."

		@_appliersByPropName[propName] = applier

		return

	setHandler: (handler) ->
		if @_handler?
			throw Error "AttachmentAppliersManager for '#{@_targetId}' already has a ComponentHandler"

		@_handler = handler

		unless @_handler.isClass
			@_canHaveAppliers = no

			if @_hasAppliers
				moreThanOne = Object.keys(@_appliersByPropName).length > 1
				throw Error "Component '#{@_targetId}' is not a class and cannot have attachments.
					But component#{if moreThanOne then 's [' else ' '}
					#{Object.keys(@_appliersByPropName).map((name) -> "'#{name}'").join(", ")}
					#{if moreThanOne then '] are' else ' is'}
					attaching to it"

		this

	setupOnTarget: (targetHandler) ->
		for _, applier of @_appliersByPropName
			applier.setupOnTarget targetHandler

		return