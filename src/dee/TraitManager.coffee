module.exports = class TraitManager
	constructor: (@_dee, @_id) ->
		@_reactors = []
		@_containers = []
		@_queue = []
		@_queuedInDee = no

	addReactor: (reactor) ->
		@_reactors.push reactor
		@_queueReaction reactor, container for container in @_containers

		this

	reactTo: (container) ->
		@_containers.push container
		@_queueReaction reactor, container for reactor in @_reactors

		this

	_queueReaction: (reactor, container) ->
		@_queue.push {reactor, container}

		unless @_queuedInDee
			@_dee._queueTraitPreparation this

		return



	prepare: ->
		@_queuedInDee = no

		while @_queue.length > 0
			{reactor, container} = @_queue.shift()
			@_applyReaction reactor, container

		return

	_applyReaction: (reactor, container) ->
		reactor.applyTo container