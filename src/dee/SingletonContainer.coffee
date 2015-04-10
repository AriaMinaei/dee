ClassContainer = require './ClassContainer'

module.exports = class SingletonContainer extends ClassContainer
	constructor: (@_dee, @_id, @_cls) ->
		super

		@_value = null

		unless @isLazy()
			@_dee._addSingletonToInitializationQueue this

	getValue: ->
		unless @_value?
			@_instantiate null, (@_value) =>
				unless @isLazy()
					@_dee._removeSingletonFromInitializationQueue this

		@_value

	isLazy: ->
		@_cls.isLazy is yes

	isSingleton: yes
	componentTypeName: "singleton"
