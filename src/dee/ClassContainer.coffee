ComponentContainer = require './ComponentContainer'

module.exports = class ClassContainer extends ComponentContainer
	constructor: ->
		super

		@_classPreparedForInstantiation = no

		@_uninitializedPropNames = []
		@_finalDepsMap = {}

	_prepareClassForInstantiation: ->
		if @_classPreparedForInstantiation is no
			@_classPreparedForInstantiation = yes
		else
			return

		@_dee._targetAttachmentsManagers[@_id]?.setupOnTarget this

		if typeof @_cls.deps is 'object'
			for propName, depId of @_cls.deps
				@addDep propName, depId

		return

	addDep: (propName, depId) ->
		original = @_finalDepsMap[propName]
		if original?
			if original is depId
				return
			else
				throw Error "Double dependency for '#{@_id}'. Prop '#{propName}'
					was a dep on '#{original}', but now it's being set on '#{depId}'"

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

		@_finalDepsMap[propName] = depId
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

	patchMethod: (methodName, fn, sourceComponentId) ->
		@_prepareMethodForPatching methodName

		fnName = "_#{methodName}By#{sourceComponentId}"
		@_cls::[fnName] = fn

		functionStr = @_cls::[methodName].toString()
		functionStr = functionStr.split("\n")
		functionStr.pop()
		functionStr.shift()
		functionStr.unshift "this.#{fnName}.apply(this, arguments);"

		@_cls::[methodName] = new Function functionStr.join("\n")

	_prepareMethodForPatching: (methodName, sourceComponentId) ->
		originalFn = @_cls::[methodName]
		unless originalFn?
			throw Error "Method '##{@_id}.#{methodName}()' doesn't exist, thus it
				cannot be patched by '#{sourceComponentId}'"

		renamedName = '__' + methodName + 'Unpatched'
		@_cls::[renamedName] = @_cls::[methodName]

		@_cls::[methodName] = Function "return this.#{renamedName}.apply(this, arguments);"

	provideMethod: (methodName, fn, sourceComponentId) ->
		if @_cls::[methodName]?
			throw Error "Method '##{@_id}.#{methodName}()' already exist, thus it
				cannot be provided by '#{sourceComponentId}'"

		@_cls::[methodName] = fn

	isClass: yes