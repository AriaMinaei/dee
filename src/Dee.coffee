TraitManager = require './dee/TraitManager'
GlobalContainer = require './dee/GlobalContainer'
FelangeContainer = require './dee/FelangeContainer'
SingletonContainer = require './dee/SingletonContainer'
AttachmentContainer = require './dee/AttachmentContainer'
InstantiableContainer = require './dee/InstantiableContainer'
TargetAttachmentsManager = require './dee/TargetAttachmentsManager'
pluck = require 'utila/lib/array/pluck'

module.exports = class Dee
	constructor: ->
		@_containers = {}
		@_singletonsInitQueue = []
		@_targetAttachmentsManagers = {}
		@_traitManagers = {}
		@_traitsPreparationsQueue = []

		@registerGlobal "Dee", this

	###*
	 * Registers the given component(s).
	 *
	 * Examples:
	 * - register([Class] components) // registers all the classes in the
	 *   supplied array
	 * - register(Class) // registers one class component
	 * - register(componentId, componentValue) // registers the value as
	 *   a global component
	###
	register: ->
		if arguments.length is 2
			@registerGlobal arguments[0], arguments[1]
		else if arguments.length is 1
			if Array.isArray arguments[0]
				@registerMulti arguments[0]
			else
				@registerClass arguments[0]
		else
			throw Error "Invalid number of arguments '#{arguments.length}'"

		return this

	###*
	 * Registers all the classes in the supplied array
	 * @param  {[Class]} list List of the components
	###
	registerMulti: (list) ->
		for c in list
			@registerClass c

		return this

	###*
	 * Registers as a global value
	 *
	 * @param  {String} id The ID to be assigned to the component
	 * @param  {[type]} obj The object object (or any other value)
	###
	registerGlobal: (id, obj) ->
		@_ensureIdCanBeTaken id

		@_containers[id] = new GlobalContainer this, id, obj

		return this

	###*
	 * Registers a class
	 * @param  {Function} cls The class
	###
	registerClass: (cls) ->
		if typeof cls isnt 'function'
			throw Error "registerClass() only accepts functions"

		id = cls.componentId
		unless id?
			throw Error "Class `#{cls}` doesn't have a `componentId`"

		@_ensureIdCanBeTaken id

		@_containers[id] = switch cls.componentType
			when "Singleton"
				new SingletonContainer this, id, cls
			when "Attachment"
				new AttachmentContainer this, id, cls
			when "Instantiable"
				new InstantiableContainer this, id, cls
			when "Felange"
				new FelangeContainer this, id, cls
			else
				throw Error "Component '#{id}' does not have a valid type: '#{cls.componentType}'"

		return this

	_ensureIdCanBeTaken: (id) ->
		if typeof id isnt 'string'
			throw Error "Component id should be a string. '#{typeof id}' given."

		unless id.match /^[a-zA-Z]{1}[a-zA-Z0-9\_]*$/
			throw Error "Invalid component id: '#{id}'"

		if @_containers[id]?
			throw Error "A component with id '#{id}' is already registered"

		return

	_getContainer: (id) ->
		container = @_containers[id]

		unless container?
			throw Error "Component '#{id}' is not registered"

		container

	isGlobal: (id) ->
		@_getContainer(id) instanceof GlobalContainer

	isSingleton: (id) ->
		@_getContainer(id) instanceof SingletonContainer

	isInstantiable: (id) ->
		@_getContainer(id) instanceof InstantiableContainer

	isAttachment: (id) ->
		@_getContainer(id) instanceof AttachmentContainer

	get: (id) ->
		c = @_getContainer(id)
		if c.isGlobal or c.isSingleton
			c.getValue()
		else
			throw Error "#Dee.get() only returns singletons or global components.
				'#{id}' is #{c.componentTypeName}"

	instantiate: (id, args) ->
		c = @_getContainer(id)
		if c.isInstantiable
			c.instantiate args
		else
			throw Error "#Dee.instantiate() only returns for instantiable components.
				'#{id}' is #{c.componentTypeName}"

	_addSingletonToInitializationQueue: (container) ->
		@_singletonsInitQueue.push container

		return

	_removeSingletonFromInitializationQueue: (container) ->
		pluck @_singletonsInitQueue, container

	prepare: ->
		while @_singletonsInitQueue.length > 0
			@_singletonsInitQueue[0].getValue()

		while @_traitsPreparationsQueue.length > 0
			@_traitsPreparationsQueue.shift().prepare()

		return

	_getTargetAttachmentsManager: (targetId) ->
		m = @_targetAttachmentsManagers[targetId]
		unless m?
			m = new TargetAttachmentsManager this, targetId
			@_targetAttachmentsManagers[targetId] = m

		return m


	_getTraitManager: (traitId) ->
		manager = @_traitManagers[traitId]
		unless manager?
			@_traitManagers[traitId] = manager = new TraitManager this, traitId

		manager

	_queueTraitPreparation: (traitManager) ->
		@_traitsPreparationsQueue.push traitManager

		return