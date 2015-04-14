module.exports = class ComponentContainer
	constructor: (@_dee, @_id) ->
		@_handler = null

	setHandler: (handler) ->
		if @_handler?
			throw Error "Component `#{@_id}` already has a handler"

		@_handler = handler

		this

	getHandler: ->
		@_handler