module.exports = class AttachmentApplier
	constructor: (@_dee, @_sourceHandler, @_targetId, @_desc) ->
		if typeof @_desc.as isnt 'string'
			throw Error "Invalide `as` property in attachment '#{@_sourceHandler._id}' on target '#{@_targetId}'"

		@_targetContainer = @_dee._getContainer @_targetId
		@_targetContainer.addAttachmentApplier this

		@_propName = @_desc.as

	getPropName: ->
		@_propName

	getId: ->
		@_sourceHandler._id

	setupOnTarget: (targetHandler) ->
		@_setupLazyGetterOn targetHandler
		@_setupPeerDepsOn targetHandler
		@_setupPatchesOn targetHandler
		@_setupProvisionsOn targetHandler

	_setupLazyGetterOn: (targetHandler) ->
		cls = targetHandler._cls

		valuePropName = "_#{@_propName}"
		targetHandler.addUninitializedPropName valuePropName

		container = @_sourceHandler

		eval """
		function getter() {
			var prop = this.#{valuePropName};
			if (prop === null) {
				return this.#{valuePropName} = container.instantiate(this);
			} else {
				return prop;
			}
		};
		"""

		Object.defineProperty cls.prototype, @_propName, get: getter

	_setupPeerDepsOn: (targetHandler) ->
		if typeof @_desc.peerDeps is 'object'
			for propName, depId of @_desc.peerDeps
				targetHandler.addDep propName, depId

		return

	_setupPatchesOn: (targetHandler) ->
		if typeof @_desc.patches is 'object'
			for methodName, fn of @_desc.patches
				if typeof fn is 'string'
					fn = new Function "return this.#{@_propName}.#{fn}.apply(this.#{@_propName}, arguments);"

				targetHandler.patchMethod methodName, fn, @getId()

		return

	_setupProvisionsOn: (targetHandler) ->
		if typeof @_desc.provides is 'object'
			for methodName, fn of @_desc.provides
				if typeof fn is 'string'
					fn = new Function "return this.#{@_propName}.#{fn}.apply(this.#{@_propName}, arguments);"

				targetHandler.provideMethod methodName, fn, @getId()

		return