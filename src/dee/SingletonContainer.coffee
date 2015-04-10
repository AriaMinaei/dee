ClassContainer = require './ClassContainer'

module.exports = class SingletonContainer extends ClassContainer
	constructor: (@_dee, @_id, @_cls) ->
		super

		@_value = null

	getValue: ->
		unless @_value?
			@_instantiate null, (@_value) =>

		@_value