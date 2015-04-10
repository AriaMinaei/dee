GlobalContainer = require './dee/GlobalContainer'
SingletonContainer = require './dee/SingletonContainer'
AttachmentContainer = require './dee/AttachmentContainer'
InstantiableContainer = require './dee/InstantiableContainer'
pluck = require 'utila/lib/array/pluck'

module.exports = class Dee
	constructor: ->
		@_containers = {}
		@_singletonsInitQueue = []

		@registerGlobal "Dee", this

	###*
	 * Registers the given component(s).
	 *
	 * Examples:
	 * register([Class] components) // registers all the classes in the supplied array
	 * register(Class) // registers one class component
	 * register(componentId, componentValue) // registers the value as a global component
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
		@_ensureIdIsAvailable id

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

		@_ensureIdIsAvailable id

		if cls.isSingleton is yes
			@_containers[id] = new SingletonContainer this, id, cls
		else if cls.attachesTo?
			@_containers[id] = new AttachmentContainer this, id, cls
		else
			@_containers[id] = new InstantiableContainer this, id, cls

		return this

	_ensureIdIsAvailable: (id) ->
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

	get: (id) ->
		@_getContainer(id).getValue()



	_addSingletonToInitializationQueue: (container) ->
		@_singletonsInitQueue.push container

		return

	_removeSingletonFromInitializationQueue: (container) ->
		pluck @_singletonsInitQueue, container


	initializeRemainingSingletons: ->
		while @_singletonsInitQueue.length > 0
			@_singletonsInitQueue[0].getValue()

		return