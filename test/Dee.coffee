Dee = require '../src/Dee'
about = describe
they = it

describe "Dee", ->

	d = null
	beforeEach ->
		d = new Dee

	describe "constructor()", ->
		it "should work", ->
			(-> new Dee).should.not.throw()

	describe "register()", ->
		it "should only accept component names containing only alphanumerics and underscores", ->
			(->
				d.register class A
					@componentId: "s "
					@componentType: "Instantiable"
			).should.throw()

			(->
				d.register class A
					@componentId: "0s"
					@componentType: "Instantiable"
			).should.throw()

			(->
				d.register class A
					@componentId: ""
					@componentType: "Instantiable"
			).should.throw()

			(->
				d.register class A
					@componentId: 5
					@componentType: "Instantiable"
			).should.throw()

			(->
				d.register class A
					@componentId: "S0_s"
					@componentType: "Instantiable"
			).should.not.throw()

	about "All components", ->
		they "should have unique componentId-s", ->
			d.register "a", {}
			(-> d.register "a", {}).should.throw()

	about "Global values", ->
		they "are recognized by calling #Dee.register(id, value)", ->
			d.register "a", a = {}
			d.isGlobal("a").should.equal true

		they "are returned untouched", ->
			d.register "a", a = {}
			d.get("a").should.equal a

	about "All class components (singletons, attachments, instantiables)", ->
		they "should have a Class.componentId", ->
			class A
			(-> d.register A).should.throw()

			class B
				@componentId: "B"
				@componentType: "Instantiable"
			(-> d.register B).should.not.throw()

		they "can depend on globals", ->
			bi = null
			class A
				@componentId: "A"
				@componentType: "Singleton"
				@deps: {"bi": "b"}
				constructor: ->
					bi = @bi

			d.register A
			d.register "b", {}
			d.prepare()

			d.get("b").should.equal bi

		they "can depend on singletons", ->
			bi = null
			class A
				@componentId: "A"
				@componentType: "Singleton"
				@deps: {"bi": "B"}
				constructor: ->
					bi = @bi

			class B
				@componentId: "B"
				@componentType: "Singleton"

			d.register [A, B]
			d.prepare()

			d.get("B").should.equal bi

		they "can depend on instantiables", ->
			dep = null
			class Singleton
				@componentId: "Singleton"
				@componentType: "Singleton"
				@deps: {"instantiable": "Instantiable"}
				constructor: ->
					dep = @instantiable

			class Instantiable
				@componentId: "Instantiable"
				@componentType: "Instantiable"

			d.register [Singleton, Instantiable]
			d.prepare()

			expect(dep).to.be.instanceOf Instantiable

	about "Dependency on instantiables", ->
		it "should have customizable initializers", ->
			dep = null
			class Singleton
				@componentId: "Singleton"
				@componentType: "Singleton"
				@deps: {"instantiable": "Instantiable"}
				constructor: ->
					@_initInstantiable "Buick"
					dep = @instantiable

			class Instantiable
				@componentId: "Instantiable"
				@componentType: "Instantiable"
				constructor: (@name) ->

			d.register [Singleton, Instantiable]
			d.prepare()

			expect(dep.name).to.equal "Buick"

	about "Singleton-s", ->
		they "are recognized by having Class.isSingleton = true", ->
			class S
				@componentId: "S"
				@componentType: "Singleton"

			d.register S
			d.isSingleton("S").should.equal true

		they "are instantiated by calling #Dee.get()", ->
			class S
				@componentId: "S"
				@componentType: "Singleton"

			d.register S
			d.get("S").should.be.instanceof S

		they "are only instantiated once", ->
			class S
				@componentId: "S"
				@componentType: "Singleton"

			d.register S
			d.get("S").should.equal d.get("S")

		they "can have circular dependencies with each other", ->
			bi = null
			class A
				@componentId: "A"
				@componentType: "Singleton"
				@deps: {"bi": "B"}
				constructor: ->
					bi = @bi

			aa = null
			class B
				@componentId: "B"
				@componentType: "Singleton"
				@deps: {"aa": "A"}
				constructor: ->
					aa = @aa

			d.register [A, B]
			d.prepare()

			bi.should.equal d.get("B")
			aa.should.equal d.get("A")

	about "Instantiables", ->
		they "are recognized when Class.isInstantiable === true", ->
			class Instantiable
				@componentId: "Instantiable"
				@componentType: "Instantiable"

			class Singleton
				@componentId: "Singleton"
				@componentType: "Singleton"

			class Attachment
				@componentId: "Attachment"
				@componentType: "Attachment"
				@attachesTo: "Singleton":
					as: "attachment"

			d.register [Instantiable, Singleton, Attachment]
			d.isInstantiable("Instantiable").should.equal true
			d.isInstantiable("Attachment").should.equal false
			d.isInstantiable("Singleton").should.equal false

		they "can depend on other instantiables", ->
			class A
				@componentId: "A"
				@componentType: "Instantiable"
				@deps: {"b": "B"}

			class B
				@componentId: "B"
				@componentType: "Instantiable"

			d.register [A, B]
			d.prepare()

			d.instantiate("A").b.should.be.instanceOf B

	about "Attachments", ->
		they "are recognized by typeof Class.attachesTo === 'object'", ->
			class A
				@componentId: "A"
				@componentType: "Instantiable"

			class AA
				@componentId: "AA"
				@componentType: "Attachment"
				@attachesTo: "A":
					as: "aa"

			d.register [A, AA]
			d.isAttachment("AA").should.equal true

		they "can attach to singletons", ->
			class Singleton
				@componentId: "Singleton"
				@componentType: "Singleton"

			class Attachment
				@componentId: "Attachment"
				@componentType: "Attachment"
				@attachesTo: "Singleton":
					as: "attachment"

			d.register [Attachment, Singleton]
			d.prepare()
			expect(d.get("Singleton").attachment).to.be.instanceOf Attachment

		they "can attach to instantiables", ->
			class Instantiable
				@componentId: "Instantiable"
				@componentType: "Instantiable"

			class Attachment
				@componentId: "Attachment"
				@componentType: "Attachment"
				@attachesTo: "Instantiable":
					as: "attachment"

			d.register [Attachment, Instantiable]
			d.prepare()
			expect(d.instantiate("Instantiable").attachment).to.be.instanceOf Attachment

		they "are called with their target's instance", ->
			class Instantiable
				@componentId: "Instantiable"
				@componentType: "Instantiable"

			class Attachment
				@componentId: "Attachment"
				@componentType: "Attachment"
				@attachesTo: "Instantiable":
					as: "attachment"

				constructor: (@target) ->

			d.register [Attachment, Instantiable]
			d.prepare()

			instantiable = d.instantiate("Instantiable")
			attachment = instantiable.attachment

			expect(attachment.target).to.be.equal instantiable

		they "can have peer deps", ->
			class A
				@componentId: "A"
				@componentType: "Instantiable"

			class B
				@componentId: "B"
				@componentType: "Attachment"
				@attachesTo: "A":
					as: "b"
					peerDeps: {c: "C"}

			class C
				@componentId: "C"
				@componentType: "Instantiable"

			d.register [A, B, C]
			d.prepare()

			expect(d.instantiate("A").c).to.be.instanceOf C

	about "Reacting to traits", ->
		they "should work", ->
			class Trait
				@componentId: "Trait"
				@componentType: "Felange"
				@forTraits: "Model":
					performs: (container, dee) ->
						container.getClass().newProp = "newValue"

			class Model
				@componentId: "Model"
				@componentType: "Instantiable"
				@traits: ["Model"]

			d.register [Trait, Model]
			d.prepare()

			expect(Model.newProp).to.equal "newValue"

		they "should support shorthand functions", ->
			class Trait
				@componentId: "Trait"
				@componentType: "Felange"
				@forTraits: "Model": (container, dee) ->
					container.getClass().newProp = "newValue"

			class Model
				@componentId: "Model"
				@componentType: "Instantiable"
				@traits: ["Model"]

			d.register [Trait, Model]
			d.prepare()

			expect(Model.newProp).to.equal "newValue"

		they "should allow creation of repos", ->
			class BaseRepo
				@componentType: "Singleton"
				@deps: {"dee": "Dee"}
				constructor: ->
					@_instances = {}
					@_instantiator = null

				_setInstantiator: (@_instantiator) ->

				getInstance: ->
					@dee.instantiate "Model", arguments

				_getOrCreateInstance: (id) ->
					id = arguments[0]

					if @_instances[id]?
						return @_instances[id]

					instance = @_instantiator.instantiate arguments
					@_instances[id] = instance

					instance

			class ModelFelange
				@componentId: "Trait"
				@componentType: "Felange"
				@forTraits: "Model": (container, dee) ->
					cls = container.getClass()
					cls.repo = "ModelRepo"

					dee.register class ModelRepo extends BaseRepo
						@componentId: "ModelRepo"

			class Model
				@componentId: "Model"
				@componentType: "Instantiable"
				@traits: ["Model"]

			d.register [Model, ModelFelange]
			d.prepare()

			d.instantiate("Model", [10]).should.equal d.instantiate("Model", [10])

	about "Repos", ->
		they "should work", ->
			class Model
				@componentId: "Model"
				@componentType: "Instantiable"
				@repo: "ModelRepo"

			class ModelRepo
				@componentId: "ModelRepo"
				@componentType: "Singleton"
				@deps: {"dee": "Dee"}
				constructor: ->
					@_instances = {}
					@_instantiator = null

				_setInstantiator: (@_instantiator) ->

				getInstance: ->
					@dee.instantiate "Model", arguments

				_getOrCreateInstance: (id) ->
					id = arguments[0]

					if @_instances[id]?
						return @_instances[id]

					instance = @_instantiator.instantiate arguments
					@_instances[id] = instance

					instance

			d.register [Model, ModelRepo]
			d.prepare()

			d.instantiate("Model", [10]).should.equal d.instantiate("Model", [10])
			d.instantiate("Model", [10]).should.equal d.get("ModelRepo").getInstance(10)
			d.instantiate("Model", [11]).should.not.equal d.get("ModelRepo").getInstance(10)

	about "Method patching", ->
		it "should only be allowed if method does exist", ->
			class A
				@componentId: "A"
				@componentType: "Instantiable"

			class B
				@componentId: "B"
				@componentType: "Attachment"
				@attachesTo: "A":
					as: "b"
					patches:
						sayHi: -> "hi"

			d.register [A, B]
			d.prepare()

			(-> d.instantiate("A")).should.throw()

		they "should ensure invokation of patched functionality precedes original method's invokation", ->
			text = ''
			class A
				@componentId: "A"
				@componentType: "Instantiable"
				sayHi: ->
					text += 'A'

			class B
				@componentId: "B"
				@componentType: "Attachment"
				@attachesTo: "A":
					as: "b"
					patches:
						sayHi: -> text += 'B'

			d.register [A, B]
			d.prepare()
			d.instantiate("A").sayHi()

			text.should.equal "BA"

		they "should support using attachment's methods instead of anonymous function", ->
			text = ''
			class A
				@componentId: "A"
				@componentType: "Instantiable"
				sayHi: ->
					text += 'A'

			class B
				@componentId: "B"
				@componentType: "Attachment"
				@attachesTo: "A":
					as: "b"
					patches: {"sayHi"}
				sayHi: -> text += 'B'

			d.register [A, B]
			d.prepare()
			d.instantiate("A").sayHi()

			text.should.equal "BA"

	about "Method providing", ->
		it "should only be allowed if no original method by the name exists", ->
			class A
				@componentId: "A"
				@componentType: "Instantiable"
				sayHi: ->

			class B
				@componentId: "B"
				@componentType: "Attachment"
				@attachesTo: "A":
					as: "b"
					provides: sayHi: ->

			d.register [A, B]
			d.prepare()

			(-> d.instantiate("A")).should.throw()

		it "should add functionality", ->
			class A
				@componentId: "A"
				@componentType: "Instantiable"

			class B
				@componentId: "B"
				@componentType: "Attachment"
				@attachesTo: "A":
					as: "b"
					provides: sayHi: -> "hi"

			d.register [A, B]
			d.prepare()

			d.instantiate("A").sayHi().should.equal "hi"

		it "should support using attachment's methods instead of anonymous function", ->
			class A
				@componentId: "A"
				@componentType: "Instantiable"

			class B
				@componentId: "B"
				@componentType: "Attachment"
				@attachesTo: "A":
					as: "b"
					provides: {"sayHi"}

				sayHi: -> "hi"

			d.register [A, B]
			d.prepare()

			d.instantiate("A").sayHi().should.equal "hi"

	about "Accessing #Dee itself", ->
		it "is possible by calling #Dee.get('Dee')", ->
			d.get("Dee").should.equal d