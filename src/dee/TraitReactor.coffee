module.exports = class TraitReactor
	constructor: (@_dee, @_id, @_desc, @_sourceHandler) ->

	applyTo: (targetHandler) ->
		@_applyPerformFn targetHandler

	_applyPerformFn: (targetHandler) ->
		performFn = if typeof @_desc is 'function'
			@_desc
		else
			@_desc.performs

		return if typeof performFn isnt 'function'

		performFn.apply null, [targetHandler, @_dee]