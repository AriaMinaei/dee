ComponentHandler = require './ComponentHandler'

module.exports = class GlobalHandler extends ComponentHandler
	constructor: (_, @_value) ->
		super

	getValue: ->
		@_value

	isGlobal: yes
	isClass: no
	componentTypeName: "Global"
