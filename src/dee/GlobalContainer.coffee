ComponentContainer = require './ComponentContainer'

module.exports = class GlobalContainer extends ComponentContainer
	constructor: (@_dee, @_id, @_value) ->
		super

	getValue: ->
		@_value

	isGlobal: yes
	isClass: no