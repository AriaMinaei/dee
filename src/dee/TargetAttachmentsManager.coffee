module.exports = class TargetAttachmentsManager
	constructor: (@_dee, @_targetId) ->
		@_handlersByPropName = {}

	addHandler: (handler) ->
		propName = handler.getPropName()

		if @_handlersByPropName[propName]?
			otherHandler = @_handlersByPropName[propName]
			throw Error "Cannot attach '#{handler.getId()}' to
				'#{@_targetId}' as '#{propName}' because '#{otherHandler.getId()}'
				is already using that prop name."

		@_handlersByPropName[propName] = handler

		return

	setupOnTarget: (targetContainer) ->
		for _, handler of @_handlersByPropName
			handler.setupOnTarget targetContainer

		return