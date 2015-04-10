ClassContainer = require './ClassContainer'

module.exports = class InstantiableContainer extends ClassContainer
	constructor: (@_dee, @_id, @_cls) ->
		super

	instantiate: (args) ->
		@_instantiate args

	isInstantiable: yes
	componentTypeName: "instantiable"
