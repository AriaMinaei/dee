ComponentContainer = require './ComponentContainer'
TraitReactor = require './TraitReactor'

module.exports = class ClassContainer extends ComponentContainer
	constructor: (_, __, @_cls) ->
		super

		@_classPreparedForInstantiation = no
		@_uninitializedPropNames = []
		@_finalDepsMap = {}
		@_hasRepo = no

		@_prepareTraitReactors()
		@_prepareTraitReactions()

	_prepareTraitReactors: ->
		descs = @_cls.forTraits
		return if typeof descs isnt 'object'

		for traitId, desc of descs
			reactor = new TraitReactor @_dee, traitId, desc, this
			@_dee._getTraitManager(traitId).addReactor reactor

		return

	_prepareTraitReactions: ->
		unless Array.isArray @_cls.traits
			@_traits = []
			return

		@_traits = [].concat @_cls.traits

		for traitId in @_traits
			@_dee._getTraitManager(traitId).reactTo this

		return

	_prepareClassForInstantiation: ->
		if @_classPreparedForInstantiation is no
			@_classPreparedForInstantiation = yes
		else
			return

		if @isInstantiable and @_cls.repo?
			@_hasRepo = yes
			@_repo = @_dee.get @_cls.repo
			@_repo._setInstantiator
				instantiate: =>
					@_actualltInstantiate arguments

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

	_instantiate: (args) ->
		@_prepareClassForInstantiation()

		unless @_hasRepo
			@_actualltInstantiate args
		else
			@_repo._getOrCreateInstance.apply @_repo, args

	_actualltInstantiate: (args) ->
		obj = Object.create @_cls.prototype
		obj.constructor = @_cls

		for propName in @_uninitializedPropNames
			obj[propName] = null

		@_onInstantiation obj, args
		@_cls.apply obj, args

		obj

	_onInstantiation: ->
		# Only singletons would overwrite this

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

	getClass: ->
		@_cls

	isClass: yes