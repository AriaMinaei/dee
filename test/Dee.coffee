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

	about "All class components (singletons, attachments)", ->
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

	about "Accessing #Dee itself", ->
		it "is possible by calling #Dee.get('Dee')", ->
			d.get("Dee").should.equal d