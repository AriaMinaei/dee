ComponentHandler = require './ComponentHandler'

module.exports = class GlobalHandler extends ComponentHandler
	constructor: (_, __, @_value) ->
		super

	getValue: ->
		@_value

	isGlobal: yes
	isClass: no
	componentTypeName: "Global"
