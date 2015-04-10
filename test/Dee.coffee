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