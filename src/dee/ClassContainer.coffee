ComponentContainer = require './ComponentContainer'

module.exports = class ClassContainer extends ComponentContainer
	constructor: ->
		super

	_instantiate: (args, preconstructCb) ->
		obj = Object.create @_cls.prototype
		obj.constructor = @_cls

		preconstructCb?(obj)

		# if desc.hasGlobalDeps()
		# 	for propName, depId of desc.getGlobalDeps()
		# 		obj[propName] = @get(depId)

		@_cls.apply(obj, args)

		obj