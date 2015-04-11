ClassContainer = require './ClassContainer'

module.exports = class SingletonContainer extends ClassContainer
	constructor: ->
		super

		@_value = null

		unless @isLazy()
			@_dee._addSingletonToInitializationQueue this

	getValue: ->
		unless @_value?
			@_instantiate null

		@_value

	_onInstantiation: (@_value) ->
		unless @isLazy()
			@_dee._removeSingletonFromInitializationQueue this

		return

	isLazy: ->
		@_cls.isLazy is yes

	isSingleton: yes
	componentTypeName: "Singleton"