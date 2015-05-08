ClassHandler = require './ClassHandler'

module.exports = class SingletonHandler extends ClassHandler
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