# TOC
   - [Dee](#dee)
     - [constructor()](#dee-constructor)
     - [All components](#dee-all-components)
     - [Global values](#dee-global-values)
     - [All class components (singletons, attachments, instantiables)](#dee-all-class-components-singletons-attachments-instantiables)
     - [Dependency on instantiables](#dee-dependency-on-instantiables)
     - [Singleton-s](#dee-singleton-s)
     - [Instantiables](#dee-instantiables)
     - [Attachments](#dee-attachments)
     - [Reacting to traits](#dee-reacting-to-traits)
     - [Repos](#dee-repos)
     - [Method patching](#dee-method-patching)
     - [Method providing](#dee-method-providing)
     - [Accessing #Dee itself](#dee-accessing-dee-itself)
<a name=""></a>
 
<a name="dee"></a>
# Dee
<a name="dee-constructor"></a>
## constructor()
should work.

```js
return (function() {
  return new Dee;
}).should.not["throw"]();
```

<a name="dee-all-components"></a>
## All components
should have unique componentId-s.

```js
d.register("a", {});
return (function() {
  return d.register("a", {});
}).should["throw"]();
```

should only have componentId-s containing only alphanumerics and slashes.

```js
(function() {
  var A;
  return d.register(A = (function() {
    function A() {}
    A.componentId = "s ";
    A.componentType = "Instantiable";
    return A;
  })());
}).should["throw"]();
(function() {
  var A;
  return d.register(A = (function() {
    function A() {}
    A.componentId = "0s";
    A.componentType = "Instantiable";
    return A;
  })());
}).should["throw"]();
(function() {
  var A;
  return d.register(A = (function() {
    function A() {}
    A.componentId = "";
    A.componentType = "Instantiable";
    return A;
  })());
}).should["throw"]();
(function() {
  var A;
  return d.register(A = (function() {
    function A() {}
    A.componentId = 5;
    A.componentType = "Instantiable";
    return A;
  })());
}).should["throw"]();
return (function() {
  var A;
  return d.register(A = (function() {
    function A() {}
    A.componentId = "S0/Pack";
    A.componentType = "Instantiable";
    return A;
  })());
}).should.not["throw"]();
```

<a name="dee-global-values"></a>
## Global values
are recognized by calling #Dee.register(id, value).

```js
var a;
d.register("a", a = {});
return d.isGlobal("a").should.equal(true);
```

are returned untouched.

```js
var a;
d.register("a", a = {});
return d.get("a").should.equal(a);
```

<a name="dee-all-class-components-singletons-attachments-instantiables"></a>
## All class components (singletons, attachments, instantiables)
should have a Class.componentId.

```js
var A, B;
A = (function() {
  function A() {}
  return A;
})();
(function() {
  return d.register(A);
}).should["throw"]();
B = (function() {
  function B() {}
  B.componentId = "B";
  B.componentType = "Instantiable";
  return B;
})();
return (function() {
  return d.register(B);
}).should.not["throw"]();
```

can depend on globals.

```js
var A, bi;
bi = null;
A = (function() {
  A.componentId = "A";
  A.componentType = "Singleton";
  A.deps = {
    "bi": "b"
  };
  function A() {
    bi = this.bi;
  }
  return A;
})();
d.register(A);
d.register("b", {});
d.prepare();
return d.get("b").should.equal(bi);
```

can depend on singletons.

```js
var A, B, bi;
bi = null;
A = (function() {
  A.componentId = "A";
  A.componentType = "Singleton";
  A.deps = {
    "bi": "B"
  };
  function A() {
    bi = this.bi;
  }
  return A;
})();
B = (function() {
  function B() {}
  B.componentId = "B";
  B.componentType = "Singleton";
  return B;
})();
d.register([A, B]);
d.prepare();
return d.get("B").should.equal(bi);
```

can depend on instantiables.

```js
var Instantiable, Singleton, dep;
dep = null;
Singleton = (function() {
  Singleton.componentId = "Singleton";
  Singleton.componentType = "Singleton";
  Singleton.deps = {
    "instantiable": "Instantiable"
  };
  function Singleton() {
    dep = this.instantiable;
  }
  return Singleton;
})();
Instantiable = (function() {
  function Instantiable() {}
  Instantiable.componentId = "Instantiable";
  Instantiable.componentType = "Instantiable";
  return Instantiable;
})();
d.register([Singleton, Instantiable]);
d.prepare();
return expect(dep).to.be.instanceOf(Instantiable);
```

inherit component properties from their parents.

```js
var A, B, C;
A = (function() {
  function A() {}
  A.componentId = "A";
  A.deps = {
    "one": "one"
  };
  A.traits = ["B"];
  return A;
})();
B = (function() {
  function B() {}
  B.componentType = "Singleton";
  B.componentId = "B";
  B.deps = {
    "two": "two"
  };
  return B;
})();
C = (function() {
  function C() {}
  C.deps = {
    "three": "three"
  };
  C.componentType = "Instantiable";
  C.traits = ["C"];
  return C;
})();
B.prototype = Object.create(C.prototype);
B.prototype.constructor = C;
A.prototype = Object.create(B.prototype);
A.prototype.constructor = B;
d.register(A);
A.componentId.should.equal("A");
A.componentType.should.equal("Singleton");
A.traits.should.be.like(["B", "C"]);
return A.deps.should.be.like({
  "one": "one",
  "two": "two",
  "three": "three"
});
```

<a name="dee-dependency-on-instantiables"></a>
## Dependency on instantiables
should have customizable initializers.

```js
var Instantiable, Singleton, dep;
dep = null;
Singleton = (function() {
  Singleton.componentId = "Singleton";
  Singleton.componentType = "Singleton";
  Singleton.deps = {
    "instantiable": "Instantiable"
  };
  function Singleton() {
    this._initInstantiable("Buick");
    dep = this.instantiable;
  }
  return Singleton;
})();
Instantiable = (function() {
  Instantiable.componentId = "Instantiable";
  Instantiable.componentType = "Instantiable";
  function Instantiable(name) {
    this.name = name;
  }
  return Instantiable;
})();
d.register([Singleton, Instantiable]);
d.prepare();
return expect(dep.name).to.equal("Buick");
```

<a name="dee-singleton-s"></a>
## Singleton-s
are recognized by having Class.isSingleton = true.

```js
var S;
S = (function() {
  function S() {}
  S.componentId = "S";
  S.componentType = "Singleton";
  return S;
})();
d.register(S);
return d.isSingleton("S").should.equal(true);
```

are instantiated by calling #Dee.get().

```js
var S;
S = (function() {
  function S() {}
  S.componentId = "S";
  S.componentType = "Singleton";
  return S;
})();
d.register(S);
return d.get("S").should.be["instanceof"](S);
```

are only instantiated once.

```js
var S;
S = (function() {
  function S() {}
  S.componentId = "S";
  S.componentType = "Singleton";
  return S;
})();
d.register(S);
return d.get("S").should.equal(d.get("S"));
```

can have circular dependencies with each other.

```js
var A, B, aa, bi;
bi = null;
A = (function() {
  A.componentId = "A";
  A.componentType = "Singleton";
  A.deps = {
    "bi": "B"
  };
  function A() {
    bi = this.bi;
  }
  return A;
})();
aa = null;
B = (function() {
  B.componentId = "B";
  B.componentType = "Singleton";
  B.deps = {
    "aa": "A"
  };
  function B() {
    aa = this.aa;
  }
  return B;
})();
d.register([A, B]);
d.prepare();
bi.should.equal(d.get("B"));
return aa.should.equal(d.get("A"));
```

<a name="dee-instantiables"></a>
## Instantiables
are recognized when Class.isInstantiable === true.

```js
var Attachment, Instantiable, Singleton;
Instantiable = (function() {
  function Instantiable() {}
  Instantiable.componentId = "Instantiable";
  Instantiable.componentType = "Instantiable";
  return Instantiable;
})();
Singleton = (function() {
  function Singleton() {}
  Singleton.componentId = "Singleton";
  Singleton.componentType = "Singleton";
  return Singleton;
})();
Attachment = (function() {
  function Attachment() {}
  Attachment.componentId = "Attachment";
  Attachment.componentType = "Attachment";
  Attachment.attachesTo = {
    "Singleton": {
      as: "attachment"
    }
  };
  return Attachment;
})();
d.register([Instantiable, Singleton, Attachment]);
d.isInstantiable("Instantiable").should.equal(true);
d.isInstantiable("Attachment").should.equal(false);
return d.isInstantiable("Singleton").should.equal(false);
```

can depend on other instantiables.

```js
var A, B;
A = (function() {
  function A() {}
  A.componentId = "A";
  A.componentType = "Instantiable";
  A.deps = {
    "b": "B"
  };
  return A;
})();
B = (function() {
  function B() {}
  B.componentId = "B";
  B.componentType = "Instantiable";
  return B;
})();
d.register([A, B]);
d.prepare();
return d.instantiate("A").b.should.be.instanceOf(B);
```

<a name="dee-attachments"></a>
## Attachments
are recognized by typeof Class.attachesTo === 'object'.

```js
var A, AA;
A = (function() {
  function A() {}
  A.componentId = "A";
  A.componentType = "Instantiable";
  return A;
})();
AA = (function() {
  function AA() {}
  AA.componentId = "AA";
  AA.componentType = "Attachment";
  AA.attachesTo = {
    "A": {
      as: "aa"
    }
  };
  return AA;
})();
d.register([A, AA]);
return d.isAttachment("AA").should.equal(true);
```

can attach to singletons.

```js
var Attachment, Singleton;
Singleton = (function() {
  function Singleton() {}
  Singleton.componentId = "Singleton";
  Singleton.componentType = "Singleton";
  return Singleton;
})();
Attachment = (function() {
  function Attachment() {}
  Attachment.componentId = "Attachment";
  Attachment.componentType = "Attachment";
  Attachment.attachesTo = {
    "Singleton": {
      as: "attachment"
    }
  };
  return Attachment;
})();
d.register([Attachment, Singleton]);
d.prepare();
return expect(d.get("Singleton").attachment).to.be.instanceOf(Attachment);
```

can attach to instantiables.

```js
var Attachment, Instantiable;
Instantiable = (function() {
  function Instantiable() {}
  Instantiable.componentId = "Instantiable";
  Instantiable.componentType = "Instantiable";
  return Instantiable;
})();
Attachment = (function() {
  function Attachment() {}
  Attachment.componentId = "Attachment";
  Attachment.componentType = "Attachment";
  Attachment.attachesTo = {
    "Instantiable": {
      as: "attachment"
    }
  };
  return Attachment;
})();
d.register([Attachment, Instantiable]);
d.prepare();
return expect(d.instantiate("Instantiable").attachment).to.be.instanceOf(Attachment);
```

are called with their target's instance.

```js
var Attachment, Instantiable, attachment, instantiable;
Instantiable = (function() {
  function Instantiable() {}
  Instantiable.componentId = "Instantiable";
  Instantiable.componentType = "Instantiable";
  return Instantiable;
})();
Attachment = (function() {
  Attachment.componentId = "Attachment";
  Attachment.componentType = "Attachment";
  Attachment.attachesTo = {
    "Instantiable": {
      as: "attachment"
    }
  };
  function Attachment(target) {
    this.target = target;
  }
  return Attachment;
})();
d.register([Attachment, Instantiable]);
d.prepare();
instantiable = d.instantiate("Instantiable");
attachment = instantiable.attachment;
return expect(attachment.target).to.be.equal(instantiable);
```

can have peer deps.

```js
var A, B, C;
A = (function() {
  function A() {}
  A.componentId = "A";
  A.componentType = "Instantiable";
  return A;
})();
B = (function() {
  function B() {}
  B.componentId = "B";
  B.componentType = "Attachment";
  B.attachesTo = {
    "A": {
      as: "b",
      peerDeps: {
        c: "C"
      }
    }
  };
  return B;
})();
C = (function() {
  function C() {}
  C.componentId = "C";
  C.componentType = "Instantiable";
  return C;
})();
d.register([A, B, C]);
d.prepare();
return expect(d.instantiate("A").c).to.be.instanceOf(C);
```

<a name="dee-reacting-to-traits"></a>
## Reacting to traits
should work.

```js
var Model, Trait;
Trait = (function() {
  function Trait() {}
  Trait.componentId = "Trait";
  Trait.componentType = "Felange";
  Trait.forTraits = {
    "Model": {
      performs: function(container, dee) {
        return container.getClass().newProp = "newValue";
      }
    }
  };
  return Trait;
})();
Model = (function() {
  function Model() {}
  Model.componentId = "Model";
  Model.componentType = "Instantiable";
  Model.traits = ["Model"];
  return Model;
})();
d.register([Trait, Model]);
d.prepare();
return expect(Model.newProp).to.equal("newValue");
```

should support shorthand functions.

```js
var Model, Trait;
Trait = (function() {
  function Trait() {}
  Trait.componentId = "Trait";
  Trait.componentType = "Felange";
  Trait.forTraits = {
    "Model": function(container, dee) {
      return container.getClass().newProp = "newValue";
    }
  };
  return Trait;
})();
Model = (function() {
  function Model() {}
  Model.componentId = "Model";
  Model.componentType = "Instantiable";
  Model.traits = ["Model"];
  return Model;
})();
d.register([Trait, Model]);
d.prepare();
return expect(Model.newProp).to.equal("newValue");
```

should allow creation of repos.

```js
var BaseRepo, Model, ModelFelange;
BaseRepo = (function() {
  BaseRepo.componentType = "Singleton";
  BaseRepo.deps = {
    "dee": "Dee"
  };
  function BaseRepo() {
    this._instances = {};
    this._instantiator = null;
  }
  BaseRepo.prototype._setInstantiator = function(_instantiator) {
    this._instantiator = _instantiator;
  };
  BaseRepo.prototype.getInstance = function() {
    return this.dee.instantiate("Model", arguments);
  };
  BaseRepo.prototype._getOrCreateInstance = function(id) {
    var instance;
    id = arguments[0];
    if (this._instances[id] != null) {
      return this._instances[id];
    }
    instance = this._instantiator.instantiate(arguments);
    this._instances[id] = instance;
    return instance;
  };
  return BaseRepo;
})();
ModelFelange = (function() {
  function ModelFelange() {}
  ModelFelange.componentId = "Trait";
  ModelFelange.componentType = "Felange";
  ModelFelange.forTraits = {
    "Model": function(container, dee) {
      var ModelRepo, cls;
      cls = container.getClass();
      cls.repo = "ModelRepo";
      ModelRepo = (function() {
        ModelRepo.componentId = "ModelRepo";
        function ModelRepo() {
          BaseRepo.apply(this, arguments);
        }
        return ModelRepo;
      })();
      ModelRepo.prototype = Object.create(BaseRepo.prototype);
      ModelRepo.prototype.constructor = BaseRepo;
      return dee.register(ModelRepo);
    }
  };
  return ModelFelange;
})();
Model = (function() {
  function Model() {}
  Model.componentId = "Model";
  Model.componentType = "Instantiable";
  Model.traits = ["Model"];
  return Model;
})();
d.register([Model, ModelFelange]);
d.prepare();
return d.instantiate("Model", [10]).should.equal(d.instantiate("Model", [10]));
```

<a name="dee-repos"></a>
## Repos
should work.

```js
var Model, ModelRepo;
Model = (function() {
  function Model() {}
  Model.componentId = "Model";
  Model.componentType = "Instantiable";
  Model.repo = "ModelRepo";
  return Model;
})();
ModelRepo = (function() {
  ModelRepo.componentId = "ModelRepo";
  ModelRepo.componentType = "Singleton";
  ModelRepo.deps = {
    "dee": "Dee"
  };
  function ModelRepo() {
    this._instances = {};
    this._instantiator = null;
  }
  ModelRepo.prototype._setInstantiator = function(_instantiator) {
    this._instantiator = _instantiator;
  };
  ModelRepo.prototype.getInstance = function() {
    return this.dee.instantiate("Model", arguments);
  };
  ModelRepo.prototype._getOrCreateInstance = function(id) {
    var instance;
    id = arguments[0];
    if (this._instances[id] != null) {
      return this._instances[id];
    }
    instance = this._instantiator.instantiate(arguments);
    this._instances[id] = instance;
    return instance;
  };
  return ModelRepo;
})();
d.register([Model, ModelRepo]);
d.prepare();
d.instantiate("Model", [10]).should.equal(d.instantiate("Model", [10]));
d.instantiate("Model", [10]).should.equal(d.get("ModelRepo").getInstance(10));
return d.instantiate("Model", [11]).should.not.equal(d.get("ModelRepo").getInstance(10));
```

<a name="dee-method-patching"></a>
## Method patching
should only be allowed if method does exist.

```js
var A, B;
A = (function() {
  function A() {}
  A.componentId = "A";
  A.componentType = "Instantiable";
  return A;
})();
B = (function() {
  function B() {}
  B.componentId = "B";
  B.componentType = "Attachment";
  B.attachesTo = {
    "A": {
      as: "b",
      patches: {
        sayHi: function() {
          return "hi";
        }
      }
    }
  };
  return B;
})();
d.register([A, B]);
d.prepare();
return (function() {
  return d.instantiate("A");
}).should["throw"]();
```

should ensure invokation of patched functionality precedes original method's invokation.

```js
var A, B, text;
text = '';
A = (function() {
  function A() {}
  A.componentId = "A";
  A.componentType = "Instantiable";
  A.prototype.sayHi = function() {
    return text += 'A';
  };
  return A;
})();
B = (function() {
  function B() {}
  B.componentId = "B";
  B.componentType = "Attachment";
  B.attachesTo = {
    "A": {
      as: "b",
      patches: {
        sayHi: function() {
          return text += 'B';
        }
      }
    }
  };
  return B;
})();
d.register([A, B]);
d.prepare();
d.instantiate("A").sayHi();
return text.should.equal("BA");
```

should support using attachment's methods instead of anonymous function.

```js
var A, B, text;
text = '';
A = (function() {
  function A() {}
  A.componentId = "A";
  A.componentType = "Instantiable";
  A.prototype.sayHi = function() {
    return text += 'A';
  };
  return A;
})();
B = (function() {
  function B() {}
  B.componentId = "B";
  B.componentType = "Attachment";
  B.attachesTo = {
    "A": {
      as: "b",
      patches: {
        "sayHi": "sayHi"
      }
    }
  };
  B.prototype.sayHi = function() {
    return text += 'B';
  };
  return B;
})();
d.register([A, B]);
d.prepare();
d.instantiate("A").sayHi();
return text.should.equal("BA");
```

<a name="dee-method-providing"></a>
## Method providing
should only be allowed if no original method by the name exists.

```js
var A, B;
A = (function() {
  function A() {}
  A.componentId = "A";
  A.componentType = "Instantiable";
  A.prototype.sayHi = function() {};
  return A;
})();
B = (function() {
  function B() {}
  B.componentId = "B";
  B.componentType = "Attachment";
  B.attachesTo = {
    "A": {
      as: "b",
      provides: {
        sayHi: function() {}
      }
    }
  };
  return B;
})();
d.register([A, B]);
d.prepare();
return (function() {
  return d.instantiate("A");
}).should["throw"]();
```

should add functionality.

```js
var A, B;
A = (function() {
  function A() {}
  A.componentId = "A";
  A.componentType = "Instantiable";
  return A;
})();
B = (function() {
  function B() {}
  B.componentId = "B";
  B.componentType = "Attachment";
  B.attachesTo = {
    "A": {
      as: "b",
      provides: {
        sayHi: function() {
          return "hi";
        }
      }
    }
  };
  return B;
})();
d.register([A, B]);
d.prepare();
return d.instantiate("A").sayHi().should.equal("hi");
```

should support using attachment's methods instead of anonymous function.

```js
var A, B;
A = (function() {
  function A() {}
  A.componentId = "A";
  A.componentType = "Instantiable";
  return A;
})();
B = (function() {
  function B() {}
  B.componentId = "B";
  B.componentType = "Attachment";
  B.attachesTo = {
    "A": {
      as: "b",
      provides: {
        "sayHi": "sayHi"
      }
    }
  };
  B.prototype.sayHi = function() {
    return "hi";
  };
  return B;
})();
d.register([A, B]);
d.prepare();
return d.instantiate("A").sayHi().should.equal("hi");
```

<a name="dee-accessing-dee-itself"></a>
## Accessing #Dee itself
is possible by calling #Dee.get('Dee').

```js
return d.get("Dee").should.equal(d);
```

