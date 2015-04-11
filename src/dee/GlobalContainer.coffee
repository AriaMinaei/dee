ComponentContainer = require './ComponentContainer'

module.exports = class GlobalContainer extends ComponentContainer
	constructor: (_, __, @_value) ->
		super

	getValue: ->
		@_value

	isGlobal: yes
	isClass: no
	componentTypeName: "Global"
