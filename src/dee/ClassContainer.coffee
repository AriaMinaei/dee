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
				else if depContainer.isInstantiable
					@_setupInstantiableDep propName, depContainer
				else
					# todo: better error
					throw Error "Attachment?"

		@_dee._targetAttachmentsManagers[@_id]?.setupOnTarget this

		return

	_setupGlobalOrSingletonDep: (propName, depContainer) ->
		valuePropName = "_#{propName}"
		@addUninitializedPropName valuePropName

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

	_setupInstantiableDep: (propName, depContainer) ->
		valuePropName = "_#{propName}"
		@addUninitializedPropName valuePropName
		initializerMethodName = if propName[0] is '_'
			"__init#{propName[1].toUpperCase() + propName.substr(2, propName.length)}"
		else
			"_init#{propName[0].toUpperCase() + propName.substr(1, propName.length)}"

		eval """
		function initialize() {
			return this.#{valuePropName} = depContainer.instantiate(arguments);
		};
		"""

		@_cls::[initializerMethodName] = initialize

		eval """
		function getter() {
			var prop = this.#{valuePropName};
			if (prop === null) {
				return this.#{valuePropName} = this.#{initializerMethodName}();
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

		for propName in @_uninitializedPropNames
			obj[propName] = null

		preconstructCb?(obj)
		@_cls.apply(obj, args)

		obj

	addUninitializedPropName: (name) ->
		if name in @_uninitializedPropNames
			throw Error "Prop name '#{name}' is already set on '#{@_id}'"

		@_uninitializedPropNames.push name

		return

	isClass: yes