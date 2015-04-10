ComponentContainer = require './ComponentContainer'

module.exports = class ClassContainer extends ComponentContainer
	constructor: ->
		super

	_instantiate: (args, preconstructCb) ->
		obj = Object.create @_cls.prototype
		obj.constructor = @_cls

		preconstructCb?(obj)

		if typeof @_cls.deps is 'object'
			for propName, depId of @_cls.deps
				try depContainer = @_dee._getContainer depId
				catch
					throw Error "Unkown component '#{depId}', dependency of '#{@_id}'"

				if depContainer.isGlobal or depContainer.isSingleton
					obj[propName] = depContainer.getValue()

		@_cls.apply(obj, args)

		obj

	isClass: yes