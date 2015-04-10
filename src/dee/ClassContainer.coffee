ComponentContainer = require './ComponentContainer'

module.exports = class ClassContainer extends ComponentContainer
	constructor: ->
		super

		@_classPreparedForInstantiation = no

		@_uninitializedPropNames = []


	_prepareClassForInstantiation: ->
		if @_classPreparedForInstantiation is no
			@_classPreparedForInstantiation = yes
		else
			return

		if typeof @_cls.deps is 'object'
			for propName, depId of @_cls.deps
				try depContainer = @_dee._getContainer depId
				catch
					throw Error "Unkown component '#{depId}', dependency of '#{@_id}'"

				if depContainer.isGlobal or depContainer.isSingleton
					@_setupGlobalOrSingletonDep propName, depContainer
				# else if depContainer.isInstantiable
				# 	obj[propName] = depContainer.instantiate()
				# else
				# 	# todo: better error
				# 	throw Error "Attachment?"

	_setupGlobalOrSingletonDep: (propName, depContainer) ->
		valuePropName = "_#{propName}"
		@_uninitializedPropNames.push valuePropName
		# initializerMethodName = "_init#{propName[0].toUpperCase() + propName.substr(1, propName.length)}"

		eval """
		function getter() {
			var prop = this.#{valuePropName};
			if (prop === null) {
				return this.#{valuePropName} = depContainer.getValue();
			} else {
				return prop;
			}
		};
		"""

		Object.defineProperty @_cls.prototype, propName, get: getter

		return

	_instantiate: (args, preconstructCb) ->
		@_prepareClassForInstantiation()

		obj = Object.create @_cls.prototype
		obj.constructor = @_cls

		preconstructCb?(obj)

		for propName in @_uninitializedPropNames
			obj[propName] = null

		@_cls.apply(obj, args)

		obj

	isClass: yes