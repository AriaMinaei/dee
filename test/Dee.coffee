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

	describe "All components", ->
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
			(-> d.register B).should.not.throw()

		they "can depend on globals", ->
			bi = null
			class A
				@componentId: "A"
				@isSingleton: yes
				@deps: {"bi": "b"}
				constructor: ->
					bi = @bi

			d.register A
			d.register "b", {}
			d.initializeRemainingSingletons()

			d.get("b").should.equal bi

		they "can depend on singletons", ->
			bi = null
			class A
				@componentId: "A"
				@isSingleton: yes
				@deps: {"bi": "B"}
				constructor: ->
					bi = @bi

			class B
				@componentId: "B"
				@isSingleton: yes

			d.register [A, B]
			d.initializeRemainingSingletons()

			d.get("B").should.equal bi

		they "can depend on instantiables", ->
			dep = null
			class Singleton
				@componentId: "Singleton"
				@isSingleton: yes
				@deps: {"instantiable": "Instantiable"}
				constructor: ->
					dep = @instantiable

			class Instantiable
				@componentId: "Instantiable"

			d.register [Singleton, Instantiable]
			d.initializeRemainingSingletons()

			expect(dep).to.be.instanceOf Instantiable

	about "Dependency on instantiables", ->
		it "should have customizable initializers", ->
			dep = null
			class Singleton
				@componentId: "Singleton"
				@isSingleton: yes
				@deps: {"instantiable": "Instantiable"}
				constructor: ->
					@_initInstantiable "Buick"
					dep = @instantiable

			class Instantiable
				@componentId: "Instantiable"
				constructor: (@name) ->

			d.register [Singleton, Instantiable]
			d.initializeRemainingSingletons()

			expect(dep.name).to.equal "Buick"

	about "Singleton-s", ->
		they "are recognized by having Class.isSingleton = true", ->
			class S
				@componentId: "S"
				@isSingleton: yes

			d.register S
			d.isSingleton("S").should.equal true

		they "are instantiated by calling #Dee.get()", ->
			class S
				@componentId: "S"
				@isSingleton: yes

			d.register S
			d.get("S").should.be.instanceof S

		they "are only instantiated once", ->
			class S
				@componentId: "S"
				@isSingleton: yes

			d.register S
			d.get("S").should.equal d.get("S")

		they "can have circular dependencies with each other", ->
			bi = null
			class A
				@componentId: "A"
				@isSingleton: yes
				@deps: {"bi": "B"}
				constructor: ->
					bi = @bi

			aa = null
			class B
				@componentId: "B"
				@isSingleton: yes
				@deps: {"aa": "A"}
				constructor: ->
					aa = @aa

			d.register [A, B]
			d.initializeRemainingSingletons()

			bi.should.equal d.get("B")
			aa.should.equal d.get("A")

	about "Instantiables", ->
		they "are recognized when not (Class.isSingleton? or Class.attachesTo?)", ->
			class Instantiable
				@componentId: "Instantiable"

			class Singleton
				@componentId: "Singleton"
				@isSingleton: yes

			class Attachment
				@componentId: "Attachment"
				@attachesTo: "Singleton":
					as: "attachment"

			d.register [Instantiable, Singleton, Attachment]
			d.isInstantiable("Instantiable").should.equal true
			d.isInstantiable("Attachment").should.equal false
			d.isInstantiable("Singleton").should.equal false

		they "can depend on other instantiables", ->
			class A
				@componentId: "A"
				@deps: {"b": "B"}

			class B
				@componentId: "B"

			d.register [A, B]
			d.initializeRemainingSingletons()

			d.instantiate("A").b.should.be.instanceOf B

	about "Attachments", ->
		they "are recognized by typeof Class.attachesTo === 'object'", ->
			class A
				@componentId: "A"

			class AA
				@componentId: "AA"
				@attachesTo: "A":
					as: "aa"

			d.register [A, AA]
			d.isAttachment("AA").should.equal true

		they.skip "can only attach to class components", ->

		they "can attach to singletons", ->
			class Singleton
				@componentId: "Singleton"
				@isSingleton: yes

			class Attachment
				@componentId: "Attachment"
				@attachesTo: "Singleton":
					as: "attachment"

			d.register [Attachment, Singleton]
			d.initializeRemainingSingletons()
			expect(d.get("Singleton").attachment).to.be.instanceOf Attachment

		they "can attach to instantiables", ->
			class Instantiable
				@componentId: "Instantiable"

			class Attachment
				@componentId: "Attachment"
				@attachesTo: "Instantiable":
					as: "attachment"

			d.register [Attachment, Instantiable]
			d.initializeRemainingSingletons()
			expect(d.instantiate("Instantiable").attachment).to.be.instanceOf Attachment

		they "are called with their target's instance", ->
			class Instantiable
				@componentId: "Instantiable"

			class Attachment
				@componentId: "Attachment"
				@attachesTo: "Instantiable":
					as: "attachment"

				constructor: (@target) ->

			d.register [Attachment, Instantiable]
			d.initializeRemainingSingletons()

			instantiable = d.instantiate("Instantiable")
			attachment = instantiable.attachment

			expect(attachment.target).to.be.equal instantiable

		they "can have peer deps", ->
			class A
				@componentId: "A"

			class B
				@componentId: "B"
				@attachesTo: "A":
					as: "b"
					peerDeps: {c: "C"}

			class C
				@componentId: "C"

			d.register [A, B, C]
			d.initializeRemainingSingletons()

			expect(d.instantiate("A").c).to.be.instanceOf C

	about "Method patching", ->
		it "should only be allowed if method does exist", ->
			class A
				@componentId: "A"

			class B
				@componentId: "B"
				@attachesTo: "A":
					as: "b"
					patches:
						sayHi: -> "hi"

			d.register [A, B]
			d.initializeRemainingSingletons()

			(-> d.instantiate("A")).should.throw()

		they "should ensure invokation of patched functionality precedes original method's invokation", ->
			text = ''
			class A
				@componentId: "A"
				sayHi: ->
					text += 'A'

			class B
				@componentId: "B"
				@attachesTo: "A":
					as: "b"
					patches:
						sayHi: -> text += 'B'

			d.register [A, B]
			d.initializeRemainingSingletons()
			d.instantiate("A").sayHi()

			text.should.equal "BA"

	about "Method providing", ->
		it "should only be allowed if no original method by the name exists", ->
			class A
				@componentId: "A"
				sayHi: ->

			class B
				@componentId: "B"
				@attachesTo: "A":
					as: "b"
					provides: sayHi: ->

			d.register [A, B]
			d.initializeRemainingSingletons()

			(-> d.instantiate("A")).should.throw()

		it "should add functionality", ->
			class A
				@componentId: "A"

			class B
				@componentId: "B"
				@attachesTo: "A":
					as: "b"
					provides: sayHi: -> "hi"

			d.register [A, B]
			d.initializeRemainingSingletons()

			d.instantiate("A").sayHi().should.equal "hi"


	about "Accessing #Dee itself", ->
		it "is possible by calling #Dee.get('Dee')", ->
			d.get("Dee").should.equal d