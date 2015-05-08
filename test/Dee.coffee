ComponentComposer = require '../src/ComponentComposer'
about = describe
they = it

describe "ComponentComposer", ->

	cc = null
	beforeEach ->
		cc = new ComponentComposer

	describe "constructor()", ->
		it "should work", ->
			(-> new ComponentComposer).should.not.throw()

	about "All components", ->
		they "should have unique componentId-s", ->
			cc.register "a", {}
			(-> cc.register "a", {}).should.throw()

		they "should only have componentId-s containing only alphanumerics and slashes", ->
			(->
				cc.register class A
					@componentId: "s "
					@componentType: "Instantiable"
			).should.throw()

			(->
				cc.register class A
					@componentId: "0s"
					@componentType: "Instantiable"
			).should.throw()

			(->
				cc.register class A
					@componentId: ""
					@componentType: "Instantiable"
			).should.throw()

			(->
				cc.register class A
					@componentId: 5
					@componentType: "Instantiable"
			).should.throw()

			(->
				cc.register class A
					@componentId: "S0/Pack"
					@componentType: "Instantiable"
			).should.not.throw()

	about "Global values", ->
		they "are recognized by calling #ComponentComposer.register(id, value)", ->
			cc.register "a", a = {}
			cc.isGlobal("a").should.equal true

		they "are returned untouched", ->
			cc.register "a", a = {}
			cc.get("a").should.equal a

	about "All class components (singletons, attachments, instantiables)", ->
		they "should have a Class.componentId", ->
			class A
			(-> cc.register A).should.throw()

			class B
				@componentId: "B"
				@componentType: "Instantiable"
			(-> cc.register B).should.not.throw()

		they "can depend on globals", ->
			bi = null
			class A
				@componentId: "A"
				@componentType: "Singleton"
				@deps: {"bi": "b"}
				constructor: ->
					bi = @bi

			cc.register A
			cc.register "b", {}
			cc.prepare()

			cc.get("b").should.equal bi

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

			cc.register [A, B]
			cc.prepare()

			cc.get("B").should.equal bi

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

			cc.register [Singleton, Instantiable]
			cc.prepare()

			expect(dep).to.be.instanceOf Instantiable

		they "inherit component properties from their parents", ->
			class A
				@componentId: "A"
				@deps: {"one"}
				@traits: ["B"]

			class B
				@componentType: "Singleton"
				@componentId: "B"
				@deps: {"two"}

			class C
				@deps: {"three"}
				@componentType: "Instantiable"
				@traits: ["C"]

			B:: = Object.create C::
			B::constructor = C

			A:: = Object.create B::
			A::constructor = B

			cc.register A
			A.componentId.should.equal "A"
			A.componentType.should.equal "Singleton"
			A.traits.should.be.like ["B", "C"]
			A.deps.should.be.like {"one", "two", "three"}

		they "use an extension of the original class", ->
			class Instantiable
				@componentId: "Instantiable"
				@componentType: "Instantiable"

			cc.register Instantiable
			cc.prepare()

			cc.instantiate("Instantiable").constructor.should.not.equal Instantiable

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

			cc.register [Singleton, Instantiable]
			cc.prepare()

			expect(dep.name).to.equal "Buick"

	about "Singleton-s", ->
		they "are recognized by having Class.componentType == 'Singleton'", ->
			class S
				@componentId: "S"
				@componentType: "Singleton"

			cc.register S
			cc.isSingleton("S").should.equal true

		they "are instantiated by calling #ComponentComposer.get()", ->
			class S
				@componentId: "S"
				@componentType: "Singleton"

			cc.register S
			cc.get("S").should.be.instanceof S

		they "are only instantiated once", ->
			class S
				@componentId: "S"
				@componentType: "Singleton"

			cc.register S
			cc.get("S").should.equal cc.get("S")

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

			cc.register [A, B]
			cc.prepare()

			bi.should.equal cc.get("B")
			aa.should.equal cc.get("A")

	about "Instantiables", ->
		they "are recognized when Class.componentType == 'Instantiable'", ->
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

			cc.register [Instantiable, Singleton, Attachment]
			cc.isInstantiable("Instantiable").should.equal true
			cc.isInstantiable("Attachment").should.equal false
			cc.isInstantiable("Singleton").should.equal false

		they "can depend on other instantiables", ->
			class A
				@componentId: "A"
				@componentType: "Instantiable"
				@deps: {"b": "B"}

			class B
				@componentId: "B"
				@componentType: "Instantiable"

			cc.register [A, B]
			cc.prepare()

			cc.instantiate("A").b.should.be.instanceOf B

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

			cc.register [A, AA]
			cc.isAttachment("AA").should.equal true

		they "can attach to singletons", ->
			class Singleton
				@componentId: "Singleton"
				@componentType: "Singleton"

			class Attachment
				@componentId: "Attachment"
				@componentType: "Attachment"
				@attachesTo: "Singleton":
					as: "attachment"

			cc.register [Attachment, Singleton]
			cc.prepare()
			expect(cc.get("Singleton").attachment).to.be.instanceOf Attachment

		they "can attach to instantiables", ->
			class Instantiable
				@componentId: "Instantiable"
				@componentType: "Instantiable"

			class Attachment
				@componentId: "Attachment"
				@componentType: "Attachment"
				@attachesTo: "Instantiable":
					as: "attachment"

			cc.register [Attachment, Instantiable]
			cc.prepare()
			expect(cc.instantiate("Instantiable").attachment).to.be.instanceOf Attachment

		they "cannot attach to global values", ->
			class Attachment
				@componentId: "Attachment"
				@componentType: "Attachment"
				@attachesTo: "valueObject":
					as: "attachment"

			cc.register Attachment
			(-> cc.register 'valueObject', {}).should.throw()

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

			cc.register [Attachment, Instantiable]
			cc.prepare()

			instantiable = cc.instantiate("Instantiable")
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

			cc.register [A, B, C]
			cc.prepare()

			expect(cc.instantiate("A").c).to.be.instanceOf C

	about "Reacting to traits", ->
		they "should work", ->
			class Trait
				@componentId: "Trait"
				@componentType: "Felange"
				@forTraits: "Model":
					performs: (container, componentComposer) ->
						container.getClass().newProp = "newValue"

			class Model
				@componentId: "Model"
				@componentType: "Instantiable"
				@traits: ["Model"]

			cc.register [Trait, Model]
			cc.prepare()

			expect(cc.instantiate('Model').constructor.newProp).to.equal "newValue"

		they "should support shorthand functions", ->
			class Trait
				@componentId: "Trait"
				@componentType: "Felange"
				@forTraits: "Model": (container, componentComposer) ->
					container.getClass().newProp = "newValue"

			class Model
				@componentId: "Model"
				@componentType: "Instantiable"
				@traits: ["Model"]

			cc.register [Trait, Model]
			cc.prepare()

			expect(cc.instantiate('Model').constructor.newProp).to.equal "newValue"

		they "should allow creation of repos", ->
			class BaseRepo
				@componentType: "Singleton"
				@deps: {"componentComposer": "ComponentComposer"}
				constructor: ->
					@_instances = {}
					@_instantiator = null

				_setInstantiator: (@_instantiator) ->

				getInstance: ->
					@componentComposer.instantiate "Model", arguments

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
				@forTraits: "Model": (container, componentComposer) ->
					cls = container.getClass()
					cls.repo = "ModelRepo"

					class ModelRepo
						@componentId: "ModelRepo"
						constructor: ->
							BaseRepo.apply this, arguments

					ModelRepo.prototype = Object.create BaseRepo.prototype
					ModelRepo::constructor = BaseRepo

					componentComposer.register ModelRepo

			class Model
				@componentId: "Model"
				@componentType: "Instantiable"
				@traits: ["Model"]

			cc.register [Model, ModelFelange]
			cc.prepare()

			cc.instantiate("Model", [10]).should.equal cc.instantiate("Model", [10])

	about "Repos", ->
		they "should work", ->
			class Model
				@componentId: "Model"
				@componentType: "Instantiable"
				@repo: "ModelRepo"

			class ModelRepo
				@componentId: "ModelRepo"
				@componentType: "Singleton"
				@deps: {"componentComposer": "ComponentComposer"}
				constructor: ->
					@_instances = {}
					@_instantiator = null

				_setInstantiator: (@_instantiator) ->

				getInstance: ->
					@componentComposer.instantiate "Model", arguments

				_getOrCreateInstance: (id) ->
					id = arguments[0]

					if @_instances[id]?
						return @_instances[id]

					instance = @_instantiator.instantiate arguments
					@_instances[id] = instance

					instance

			cc.register [Model, ModelRepo]
			cc.prepare()

			cc.instantiate("Model", [10]).should.equal cc.instantiate("Model", [10])
			cc.instantiate("Model", [10]).should.equal cc.get("ModelRepo").getInstance(10)
			cc.instantiate("Model", [11]).should.not.equal cc.get("ModelRepo").getInstance(10)

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

			cc.register [A, B]
			cc.prepare()

			(-> cc.instantiate("A")).should.throw()

		it "should ensure invokation of patched functionality precedes original method's invokation", ->
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

			cc.register [A, B]
			cc.prepare()
			cc.instantiate("A").sayHi()

			text.should.equal "BA"

		it "should support using attachment's methods instead of anonymous function", ->
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

			cc.register [A, B]
			cc.prepare()
			cc.instantiate("A").sayHi()

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

			cc.register [A, B]
			cc.prepare()

			(-> cc.instantiate("A")).should.throw()

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

			cc.register [A, B]
			cc.prepare()

			cc.instantiate("A").sayHi().should.equal "hi"

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

			cc.register [A, B]
			cc.prepare()

			cc.instantiate("A").sayHi().should.equal "hi"

	about "Accessing #ComponentComposer itself", ->
		it "is possible by calling #ComponentComposer.get('ComponentComposer')", ->
			cc.get("ComponentComposer").should.equal cc