pluck = require 'utila/lib/array/pluck'
TraitManager = require './dee/TraitManager'
ClassHandler = require './dee/ClassHandler'
GlobalHandler = require './dee/GlobalHandler'
FelangeHandler = require './dee/FelangeHandler'
SingletonHandler = require './dee/SingletonHandler'
AttachmentHandler = require './dee/AttachmentHandler'
ComponentContainer = require './dee/ComponentContainer'
InstantiableHandler = require './dee/InstantiableHandler'

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
		c = @_getContainer id
		c.setHandler new GlobalHandler c, obj

		return this

	_getContainer: (id) ->
		container = @_containers[id]

		unless container?
			if typeof id isnt 'string'
				throw Error "Component id should be a string. '#{typeof id}' given."

			unless id.match /^[a-zA-Z]{1}[a-zA-Z0-9\/]*$/
				throw Error "Invalid component id: '#{id}'"

			@_containers[id] = container = new ComponentContainer this, id

		container

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

		ClassHandler.prepareClass cls

		c = @_getContainer id

		c.setHandler switch cls.componentType
			when "Singleton"
				new SingletonHandler c, cls
			when "Attachment"
				new AttachmentHandler c, cls
			when "Instantiable"
				new InstantiableHandler c, cls
			when "Felange"
				new FelangeHandler c, cls
			else
				throw Error "Component '#{id}' does not have a valid type: '#{cls.componentType}'"

		return this

	_getHandler: (id) ->
		handler = @_containers[id].getHandler()

		unless handler?
			throw Error "Component '#{id}' is not registered"

		handler

	isGlobal: (id) ->
		@_getHandler(id) instanceof GlobalHandler

	isSingleton: (id) ->
		@_getHandler(id) instanceof SingletonHandler

	isInstantiable: (id) ->
		@_getHandler(id) instanceof InstantiableHandler

	isAttachment: (id) ->
		@_getHandler(id) instanceof AttachmentHandler

	get: (id) ->
		h = @_getHandler(id)
		if h.isGlobal or h.isSingleton
			h.getValue()
		else
			throw Error "#Dee.get() only returns singletons or global components.
				'#{id}' is #{h.componentTypeName}"

	instantiate: (id, args) ->
		h = @_getHandler(id)
		if h.isInstantiable
			h.instantiate args
		else
			throw Error "#Dee.instantiate() only returns for instantiable components.
				'#{id}' is #{h.componentTypeName}"

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

	_getTraitManager: (traitId) ->
		manager = @_traitManagers[traitId]
		unless manager?
			@_traitManagers[traitId] = manager = new TraitManager this, traitId

		manager

	_queueTraitPreparation: (traitManager) ->
		@_traitsPreparationsQueue.push traitManager

		return