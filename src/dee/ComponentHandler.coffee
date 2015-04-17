module.exports = class ComponentHandler
	constructor: (@_container) ->
		{@_dee, @_id} = @_container
		@_modifiers = []

	addModofier: (mod) ->
		@_modifiers.push mod

		this