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

	about "Global values", ->
		they "are recognized by calling #Dee.register(id, value)", ->
			d.register "a", a = {}
			d.isGlobal("a").should.equal true

		they "are returned untouched", ->
			d.register "a", a = {}
			d.get("a").should.equal a

	about "all class components (singletons, attachments)", ->
		they "should have a Class.componentId", ->
			class A
			(-> d.register A).should.throw()

			class B
				@componentId: "B"
			(-> d.register B).should.not.throw()

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

	about "Accessing #Dee itself", ->
		it "is possible by calling #Dee.get('Dee')", ->
			d.get("Dee").should.equal d