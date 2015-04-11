module.exports = class TraitReactor
	constructor: (@_dee, @_id, @_desc, @_sourceContainer) ->

	applyTo: (targetContainer) ->
		@_applyPerformFn targetContainer

	_applyPerformFn: (targetContainer) ->
		performFn = if typeof @_desc is 'function'
			@_desc
		else
			@_desc.performs

		return if typeof performFn isnt 'function'

		performFn.apply null, [targetContainer, @_dee]