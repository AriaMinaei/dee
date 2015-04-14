module.exports = class TargetAttachmentsManager
	constructor: (@_dee, @_targetId) ->
		@_appliersByPropName = {}

	addApplier: (applier) ->
		propName = applier.getPropName()

		if @_appliersByPropName[propName]?
			otherApplier = @_appliersByPropName[propName]
			throw Error "Cannot attach '#{applier.getId()}' to
				'#{@_targetId}' as '#{propName}' because '#{otherApplier.getId()}'
				is already using that prop name."

		@_appliersByPropName[propName] = applier

		return

	setupOnTarget: (targetHandler) ->
		for _, applier of @_appliersByPropName
			applier.setupOnTarget targetHandler

		return