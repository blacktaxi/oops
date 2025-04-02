local class = require('oops')
local _ = require('moses')

describe('base class functionality', function()
  it('anonymous class can be created', function()
    local C = class {}
    local o = C()
    assert.is_true(class.isclass(C))
    assert.is_true(class.isobject(o))
    assert.is_equal(C, o.__class)
  end)

  it('named class can be created', function()
    local C = class('Name') {}
    local o = C()
    assert.is_true(class.isclass(C))
    assert.is_true(class.isobject(o))
    assert.is_equal('Name', C.__name)
    assert.is_equal(C, o.__class)
  end)

  it('named class can have a parent', function()
    local C1 = class {}
    local C2 = class('Name', C1) {}
    local o = C2()
    assert.is_true(class.isclass(C2))
    assert.is_true(class.isobject(o))
    assert.is_equal('Name', C2.__name)
    assert.is_equal(C2, o.__class)
  end)

  it('anonymous class can have a parent', function()
    local C1 = class {}
    local C2 = class(nil, C1) {}

    local o2 = C2()
    assert.is_true(class.isclass(C2))
    assert.is_true(class.isobject(o2))
    assert.is_equal(o2.__class, C2)

    local C3 = class(C1) {}
    local o3 = C3()
    assert.is_true(class.isclass(C3))
    assert.is_true(class.isobject(o3))
    assert.is_equal(o3.__class, C3)
  end)

  it('__init method should be called', function()
    local o = (class {
      __init = function(self)
        self.field = 42
      end,
    })()

    assert.is_equal(o.field, 42)
  end)

  it('__init method should receive arguments', function()
    local o = (class {
      __init = function(self, ...)
        self.init_args = { ... }
      end,
    })(1, 2, 3, 4, 5)

    assert.is_equal(table.unpack { 1, 2, 3, 4, 5 }, table.unpack(o.init_args))
  end)

  it('inherits __init from parent class', function()
    local A = class {
      __init = function(self)
        self.x = 42
      end,
    }

    local B = class(A) {}
    local o = B()
    assert.is_equal(o.x, 42)
  end)

  it('can call parent __init via __super', function()
    local A = class {
      __init = function(self)
        self.base = true
      end,
    }

    local B = class(A) {
      __init = function(self)
        self.__super:__init()
        self.sub = true
      end,
    }

    local o = B()
    assert.is_true(o.base)
    assert.is_true(o.sub)
  end)

  it('inherits methods through multiple levels', function()
    local A = class {
      greet = function(_)
        return 'hello'
      end,
    }

    local B = class(A) {}
    local C = class(B) {}

    local o = C()
    assert.is_equal(o:greet(), 'hello')
  end)

  it('can call ancestor method explicitly', function()
    local A = class {
      greet = function(_)
        return 'A'
      end,
    }

    local B = class(A) {
      greet = function(self)
        return self.__super:greet() .. 'B'
      end,
    }

    local o = B()
    assert.is_equal(o:greet(), 'AB')
  end)

  it('ensures instance state is not shared', function()
    local C = class {
      __init = function(self)
        self.count = 0
      end,
      inc = function(self)
        self.count = self.count + 1
      end,
    }

    local a = C()
    local b = C()
    a:inc()
    assert.is_equal(a.count, 1)
    assert.is_equal(b.count, 0)
  end)

  it('methods should return values', function()
    local o = (class {
      method = function(_)
        return 5
      end,
    })()

    assert.is_equal(5, o:method())
  end)

  it('object state can be mutated', function()
    local o = (class {
      __init = function(self)
        self.state = 'initial'
      end,

      effectful_method = function(self)
        self.state = 'new'
      end,
    })()

    assert.is_equal('initial', o.state)
    o:effectful_method()
    assert.is_equal('new', o.state)
  end)

  it("class' tostring method works", function()
    local C = class {}
    local x = tostring(C)
    assert.is_equal(x:sub(1, 7), '<class:')
  end)

  it("object's tostring method works", function()
    local C = class {}
    local o = C()
    local x = tostring(o)
    assert.is_equal(x:sub(1, 10), '<object of')
  end)
end)

describe('inheritance and dispatch', function()
  it('inheriting from not a class value should yield an error', function()
    assert.error(function()
      local x = 5
      local _ = class(x) {}
    end)
  end)

  it('methods should be inherited', function()
    local method_called = false

    local C1 = class {
      method = function(_)
        method_called = true
      end,
    }

    local C2 = class(nil, C1) {}

    local o = C2()
    o:method()

    assert.is_equal(true, method_called)
  end)

  it('methods should be inherited through more than one level', function()
    local method_called = false

    local C1 = class {
      method = function(_)
        method_called = true
      end,
    }

    local C2 = class(nil, C1) {}
    local C3 = class(nil, C2) {}
    local C4 = class(nil, C3) {}

    local o = C4()
    o:method()

    assert.is_equal(true, method_called)
  end)

  it('method overriding should work', function()
    local C1_method_called = false
    local C2_method_called = false

    local C1 = class {
      method = function(_)
        C1_method_called = true
      end,
    }

    local C2 = class(nil, C1) {
      method = function(_)
        C2_method_called = true
      end,
    }

    local o = C2()
    o:method()

    assert.is_true(C2_method_called)
    assert.is_false(C1_method_called)
  end)

  it('it should be possible to call method of a superclass explicitly', function()
    local C1_method_called = false
    local C2_method_called = false

    local C1 = class {
      method = function(_)
        C1_method_called = true
      end,
    }

    local C2 = class(nil, C1) {
      method = function(self)
        self.__super:method()
        C2_method_called = true
      end,
    }

    local o = C2()
    o:method()

    assert.is_true(C2_method_called)
    assert.is_true(C1_method_called)
  end)

  it('method calls should be dispatched dynamically', function()
    local create_class = function(return_value, parent_class)
      return class(nil, parent_class) {
        method = function(_)
          return return_value
        end,
      }
    end

    local C1 = create_class(1, nil)
    local C2 = create_class(2, C1)
    local C3 = create_class(3, C1)
    local C4 = create_class(4, C2)
    local C5 = create_class(5, C3)
    local C6 = class(nil, C4) {}

    assert.is_equal(
      table.unpack { 1, 2, 3, 4, 5, 4 },
      table.unpack(_.map({ C1, C2, C3, C4, C5, C6 }, function(_, cls)
        local o = cls()
        return o:method()
      end))
    )
  end)

  it('values should be inherited', function()
    local C1 = class { x = 5 }
    local C2 = class(nil, C1) {
      method = function(self)
        return self.x
      end,
    }

    local o = C2()

    assert.is_equal(o:method(), 5)
  end)

  it('values can be overridden', function()
    local C1 = class { x = 5 }
    local C2 = class(nil, C1) {
      method = function(self)
        return self.x
      end,
    }
    local C3 = class(nil, C2) { x = 6 }

    local o = C3()

    assert.is_equal(o:method(), 6)
  end)

  it('inherited values can be mutated', function()
    local C1 = class { x = 5 }
    local C2 = class(nil, C1) {
      method = function(self)
        self.x = 6
      end,
    }

    local o = C2()

    assert.is_equal(o.x, 5)
    o:method()
    assert.is_equal(o.x, 6)
  end)
end)

describe('inspection features', function()
  describe('class.isobject', function()
    it('an object is an object', function()
      local o = (class {})()
      assert.is_true(class.isobject(o))
    end)
    it('a number/table/string/nil is not an object', function()
      assert.is_false(class.isobject { x = 5 })
      assert.is_false(class.isobject(5))
      assert.is_false(class.isobject('666'))
      assert.is_false(class.isobject(nil))
    end)
  end)

  describe('class.isclass', function()
    it('a class is a class', function()
      assert.is_true(class.isclass(class { x = 5 }))
    end)
    it('a number/table/string/nil is not a class', function()
      assert.is_false(class.isclass { x = 5 })
      assert.is_false(class.isclass(5))
      assert.is_false(class.isclass('666'))
      assert.is_false(class.isclass(nil))
    end)
  end)

  describe('class.isinstanceof', function()
    local Class = class {}
    local Class2 = class(Class) {}

    it("an object is instance of it's class", function()
      assert.is_true(class.isinstanceof(Class(), Class))
    end)

    it("an object is instance of it's class' parent", function()
      assert.is_true(class.isinstanceof(Class2(), Class))
    end)

    it('a number/table/string/nil is not an instance of a class', function()
      assert.is_false(class.isinstanceof(5, Class))
      assert.is_false(class.isinstanceof({ x = 5 }, Class))
      assert.is_false(class.isinstanceof('5', Class))
      assert.is_false(class.isinstanceof(nil, Class))
    end)

    it('an object is not an instance of not a class', function()
      assert.is_false(class.isinstanceof(Class(), 5))
      assert.is_false(class.isinstanceof(Class(), '5'))
      assert.is_false(class.isinstanceof(Class(), { x = 5 }))
      assert.is_false(class.isinstanceof(Class(), nil))
    end)

    it('returns true for objects with deep class inheritance', function()
      local A = class('A') {}
      local B = class('B', A) {}
      local C = class('C', B) {}
      local D = class('D', C) {}

      local o = D()

      assert.is_true(class.isinstanceof(o, A))
      assert.is_true(class.isinstanceof(o, B))
      assert.is_true(class.isinstanceof(o, C))
      assert.is_true(class.isinstanceof(o, D))

      local E = class {}
      assert.is_false(class.isinstanceof(o, E))
    end)
  end)
end)

describe('class class fields', function()
  it('supports class fields via __class', function()
    local C = class {
      __class = {
        version = '1.0',
      },
    }

    assert.is_equal(C.version, '1.0')
  end)

  it('supports class methods via __class', function()
    local C = class {
      __class = {
        get_version = function(_)
          return '1.0'
        end,
      },
    }

    assert.is_equal(C:get_version(), '1.0')
  end)

  it('does not copy class fields to instances', function()
    local C = class {
      __class = {
        counter = 42,
      },
    }

    local o = C()
    assert.is_nil(o.counter)
  end)

  it('inherits class fields from parent', function()
    local Base = class {
      __class = {
        tag = 'base',
      },
    }

    local Derived = class('Derived', Base) {}

    assert.is_equal(Derived.tag, 'base')
  end)

  it('allows class method to access and mutate class-level fields', function()
    local C = class {
      __class = {
        count = 0,
        next_id = function(cls)
          cls.count = cls.count + 1
          return cls.count
        end,
      },
    }

    local id1 = C:next_id()
    local id2 = C:next_id()

    assert.is_equal(id1, 1)
    assert.is_equal(id2, 2)
  end)

  it('mutates class field in parent and does not reflect in child', function()
    local A = class {
      __class = {
        count = 0,
      },
    }

    local B = class(A) {}

    A.count = A.count + 1
    assert.is_equal(B.count, 0)
  end)

  it('mutates class field in child and does not reflect in parent', function()
    local A = class {
      __class = {
        count = 0,
      },
    }

    local B = class(A) {}

    B.count = B.count + 1
    assert.is_equal(A.count, 0)
  end)

  it('allows class method to mutate shared field but does not propagate to child', function()
    local Counter = class {
      __class = {
        value = 0,
        increment = function(cls)
          cls.value = cls.value + 1
        end,
      },
    }

    local Sub = class(Counter) {}

    Counter:increment()
    Counter:increment()
    assert.is_equal(Counter.value, 2)
    assert.is_equal(Sub.value, 0)
  end)

  it('allows class method to mutate shared field but does not propagate to parent', function()
    local Counter = class {
      __class = {
        value = 0,
        increment = function(cls)
          cls.value = cls.value + 1
        end,
      },
    }

    local Sub = class(Counter) {}

    Sub:increment()
    Sub:increment()
    assert.is_equal(Counter.value, 0)
    assert.is_equal(Sub.value, 2)
  end)

  it('shadows class field by assignment', function()
    local A = class {
      __class = { name = 'Base' },
    }
    local B = class(A) {}
    B.name = 'Child'
    assert.is_equal(B.name, 'Child')
    assert.is_equal(A.name, 'Base')
  end)

  it('inherits and calls class methods', function()
    local A = class {
      __class = {
        info = function(cls)
          return 'Hello from ' .. (cls.name or 'Anonymous')
        end,
      },
    }
    local B = class(A) {}
    B.name = 'B'
    assert.is_equal(B:info(), 'Hello from B')
  end)

  it('child can shadow class field without affecting parent', function()
    local A = class {
      __class = {
        kind = 'A',
      },
    }

    local B = class(A) {}
    B.kind = 'B' -- shadows parent field

    assert.is_equal(A.kind, 'A')
    assert.is_equal(B.kind, 'B')
  end)

  it('mutating table shared between relatives', function()
    local A = class {
      __class = {
        data = { val = 1 },
      },
    }

    local B = class(A) {}

    B.data.val = 99
    -- B and A share the same table
    assert.is_equal(A.data.val, 99)
    assert.is_equal(B.data.val, 99)
  end)

  it('can assign a new class field in child without affecting parent', function()
    local A = class {
      __class = {
        a = 1,
      },
    }

    local B = class(A) {}
    B.b = 2

    assert.is_nil(A.b)
    assert.is_equal(B.b, 2)
  end)

  it('allows class method override in subclass', function()
    local A = class {
      __class = {
        foo = function()
          return 'A'
        end,
      },
    }
    local B = class(A) {
      __class = {
        foo = function()
          return 'B'
        end,
      },
    }
    assert.is_equal(B:foo(), 'B')
    assert.is_equal(A:foo(), 'A')
  end)

  it('class method does not access instance state', function()
    local C = class {
      __init = function(self)
        self.name = 'oops'
      end,
      __class = {
        say_name = function(self)
          return self.name -- should be nil
        end,
      },
    }

    assert.is_nil(C:say_name())
  end)

  it('does not copy class fields into instances', function()
    local C = class {
      __class = { x = 1 },
    }

    local o = C()
    assert.is_nil(o.x)
  end)
end)

describe('metamethods', function()
  it('__add works', function()
    local V = class {
      __init = function(self, x)
        self.x = x
      end,
      __add = function(a, b)
        return a.__class(a.x + b.x)
      end,
    }
    assert.is_equal((V(1) + V(2)).x, 3)
  end)

  it('__sub works', function()
    local V = class {
      __init = function(self, x)
        self.x = x
      end,
      __sub = function(a, b)
        return a.__class(a.x - b.x)
      end,
    }
    assert.is_equal((V(5) - V(3)).x, 2)
  end)

  it('__mul works', function()
    local V = class {
      __init = function(self, x)
        self.x = x
      end,
      __mul = function(a, b)
        return a.__class(a.x * b.x)
      end,
    }
    assert.is_equal((V(3) * V(4)).x, 12)
  end)

  it('__div works', function()
    local V = class {
      __init = function(self, x)
        self.x = x
      end,
      __div = function(a, b)
        return a.__class(a.x / b.x)
      end,
    }
    assert.is_true(math.abs((V(10) / V(4)).x - 2.5) < 0.001)
  end)

  it('__mod works', function()
    local V = class {
      __init = function(self, x)
        self.x = x
      end,
      __mod = function(a, b)
        return a.__class(a.x % b.x)
      end,
    }
    assert.is_equal((V(10) % V(3)).x, 1)
  end)

  it('__pow works', function()
    local V = class {
      __init = function(self, x)
        self.x = x
      end,
      __pow = function(a, b)
        return a.__class(a.x ^ b.x)
      end,
    }
    assert.is_equal((V(2) ^ V(3)).x, 8)
  end)

  it('__unm works', function()
    local V = class {
      __init = function(self, x)
        self.x = x
      end,
      __unm = function(a)
        return a.__class(-a.x)
      end,
    }
    assert.is_equal((-V(5)).x, -5)
  end)

  it('__eq works', function()
    local P = class {
      __init = function(self, x)
        self.x = x
      end,
      __eq = function(a, b)
        return a.x == b.x
      end,
    }
    assert.is_true(P(1) == P(1))
    assert.is_false(P(1) == P(2))
  end)

  it('__lt works', function()
    local P = class {
      __init = function(self, x)
        self.x = x
      end,
      __lt = function(a, b)
        return a.x < b.x
      end,
    }
    assert.is_true(P(1) < P(2))
  end)

  it('__le works', function()
    local P = class {
      __init = function(self, x)
        self.x = x
      end,
      __le = function(a, b)
        return a.x <= b.x
      end,
    }
    assert.is_true(P(1) <= P(2))
    assert.is_true(P(2) <= P(2))
  end)

  it('__len works', function()
    local L = class {
      __init = function(self, xs)
        self.xs = xs
      end,
      __len = function(self)
        return #self.xs
      end,
    }
    assert.is_equal(#L { 1, 2, 3 }, 3)
  end)

  it('__tostring works', function()
    local T = class {
      __init = function(self, label)
        self.label = label
      end,
      __tostring = function(self)
        return 'Label: ' .. self.label
      end,
    }
    assert.is_equal(tostring(T('foo')), 'Label: foo')
  end)

  it('__pairs works', function()
    local M = class {
      __init = function(self)
        self.data = { a = 1, b = 2 }
      end,
      __pairs = function(self)
        return pairs(self.data)
      end,
    }
    local keys = {}
    for k in pairs(M()) do
      keys[k] = true
    end
    assert.is_true(keys.a and keys.b)
  end)

  if tonumber(_VERSION:match('Lua (%d+%.%d+)')) < 5.3 then
    it('__ipairs works', function()
      local A = class {
        __init = function(self)
          self.items = { 10, 20, 30 }
        end,
        __ipairs = function(self)
          return ipairs(self.items)
        end,
      }
      local sum = 0
      for _, v in ipairs(A()) do
        sum = sum + v
      end
      assert.is_equal(sum, 60)
    end)
  end

  it('__call works', function()
    local Callable = class {
      __init = function(self, name)
        self.name = name
      end,
      __call = function(self, x)
        return self.name .. x
      end,
    }
    local f = Callable('Hi ')
    assert.is_equal(f('there'), 'Hi there')
  end)
end)
