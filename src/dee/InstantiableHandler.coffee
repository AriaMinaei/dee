ClassHandler = require './ClassHandler'

module.exports = class InstantiableHandler extends ClassHandler
	instantiate: (args) ->
		@_instantiate args

	isInstantiable: yes
	componentTypeName: "Instantiable"
	canInstantiate: yes