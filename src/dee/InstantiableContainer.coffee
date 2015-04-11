ClassContainer = require './ClassContainer'

module.exports = class InstantiableContainer extends ClassContainer
	instantiate: (args) ->
		@_instantiate args

	isInstantiable: yes
	componentTypeName: "Instantiable"
	canInstantiate: yes