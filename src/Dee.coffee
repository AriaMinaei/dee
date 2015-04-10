GlobalContainer = require './dee/GlobalContainer'

module.exports = class Dee
	constructor: ->
		@_containers = {}

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
		container = @_getContainer id

		container instanceof GlobalContainer

	get: (id) ->
		@_getContainer(id).getValue()