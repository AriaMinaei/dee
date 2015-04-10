module.exports = class AttachmentHandler
	constructor: (@_container, @_targetId, @_desc) ->
		if typeof @_desc.as isnt 'string'
			throw Error "Invalide `as` property in attachment '#{@_container._id}' on target '#{@_targetId}'"

		@_propName = @_desc.as

	getPropName: ->
		@_propName

	getId: ->
		@_container._id

	setupOnTarget: (targetContainer) ->
		@_setupLazyGetterOn targetContainer
		@_setupPeerDepsOn targetContainer
		@_setupPatchesOn targetContainer
		@_setupProvisionsOn targetContainer

	_setupLazyGetterOn: (targetContainer) ->
		cls = targetContainer._cls

		valuePropName = "_#{@_propName}"
		targetContainer.addUninitializedPropName valuePropName

		container = @_container

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

	_setupPeerDepsOn: (targetContainer) ->
		if typeof @_desc.peerDeps is 'object'
			for propName, depId of @_desc.peerDeps
				targetContainer.addDep propName, depId

		return

	_setupPatchesOn: (targetContainer) ->
		if typeof @_desc.patches is 'object'
			for methodName, fn of @_desc.patches
				if typeof fn is 'string'
					fn = new Function "return this.#{@_propName}.#{fn}.apply(this.#{@_propName}, arguments);"

				targetContainer.patchMethod methodName, fn, @getId()

		return

	_setupProvisionsOn: (targetContainer) ->
		if typeof @_desc.provides is 'object'
			for methodName, fn of @_desc.provides
				if typeof fn is 'string'
					fn = new Function "return this.#{@_propName}.#{fn}.apply(this.#{@_propName}, arguments);"

				targetContainer.provideMethod methodName, fn, @getId()

		return