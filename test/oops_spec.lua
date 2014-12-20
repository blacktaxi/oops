local class = require 'oops'

local _ = require 'moses'
local inspect = require 'inspect'

context('base class functionality', function ()
  test('anonymous class can be created', function ()
    local C = class {}
    local o = C()
    assert_true(class.isclass(C))
    assert_true(class.isobject(o))
    assert_equal(C, o.__class)
  end)

  test('named class can be created', function ()
    local C = class("Name") {}
    local o = C()
    assert_true(class.isclass(C))
    assert_true(class.isobject(o))
    assert_equal("Name",  C.__name)
    assert_equal(C, o.__class)
  end)

  test('named class can have a parent', function ()
    local C1 = class {}
    local C2 = class("Name", C1) {}
    local o = C2()
    assert_true(class.isclass(C2))
    assert_true(class.isobject(o))
    assert_equal("Name",  C2.__name)
    assert_equal(C2, o.__class)
  end)

  test('anonymous class can have a parent', function ()
    local C1 = class {}
    local C2 = class(nil, C1) {}

    local o2 = C2()
    assert_true(class.isclass(C2))
    assert_true(class.isobject(o2))
    assert_equal(o2.__class, C2)

    local C3 = class(C1) {}
    local o3 = C3()
    assert_true(class.isclass(C3))
    assert_true(class.isobject(o3))
    assert_equal(o3.__class, C3)
  end)

  test('__init method should be called', function ()
    local o = 
      (class { __init = function (self) self.field = 42 end })()

    assert_equal(o.field, 42)
  end)

  test('__init method should receive arguments', function ()
    local o = (class {
      __init = function (self, ...)
        self.init_args = { ... }
      end 
    })(1, 2, 3, 4, 5)

    assert_equal(unpack({ 1, 2, 3, 4, 5 }), unpack(o.init_args))
  end)

  test('methods should return values', function ()
    local o = (class { method = function(self) return 5 end })()

    assert_equal(5, o:method())
  end)

  test('object state can be mutated', function ()
    local o = (class {
      __init = function (self)
        self.state = 'initial'
      end,

      effectful_method = function (self)
        self.state = 'new'
      end
    })()

    assert_equal('initial', o.state)
    o:effectful_method()
    assert_equal('new', o.state)
  end)

  test('class\' tostring method works', function ()
    local C = class { }
    local x = tostring(C)
    assert_equal(x:sub(1, 7), '<class:')
  end)

  test('object\'s tostring method works', function ()
    local C = class { }
    local o = C()
    local x = tostring(o)
    assert_equal(x:sub(1, 10), '<object of')
  end)
end)

context('inheritance and dispatch', function ()
  test('inheriting from not a class value should yield an error', function ()
    assert_error(function ()
      local x = 5
      local C = class(x) { }
    end)
  end)

  test('methods should be inherited', function ()
    local method_called = false

    local C1 = class {
      method = function (self)
        method_called = true
      end
    }

    local C2 = class(nil, C1) {}

    local o = C2()
    o:method()

    assert_equal(true, method_called)
  end)

  test('methods should be inherited through more than one level', function ()
    local method_called = false

    local C1 = class {
      method = function (self)
        method_called = true
      end
    }

    local C2 = class(nil, C1) {}
    local C3 = class(nil, C2) {}
    local C4 = class(nil, C3) {}

    local o = C4()
    o:method()

    assert_equal(true, method_called)
  end)

  test('method overriding should work', function ()
    local C1_method_called = false
    local C2_method_called = false

    local C1 = class {
      method = function (self)
        C1_method_called = true
      end
    }

    local C2 = class(nil, C1) {
      method = function (self)
        C2_method_called = true
      end
    }

    local o = C2()
    o:method()

    assert_true(C2_method_called)
    assert_false(C1_method_called)
  end)

  test('it should be possible to call method of a superclass explicitly', function ()
    local C1 = class {
      method = function (self)
        C1_method_called = true
      end
    }

    local C2 = class(nil, C1) {
      method = function (self)
        self.__super:method()
        C2_method_called = true
      end
    }

    local o = C2()
    o:method()

    assert_true(C2_method_called)
    assert_true(C1_method_called)
  end)

  test('method calls should be dispatched dynamically', function ()
    local create_class = function(return_value, parent_class)
      return class(nil, parent_class) {
        method = function (self)
          return return_value
        end
      }
    end

    local C1 = create_class(1, nil)
    local C2 = create_class(2, C1)
    local C3 = create_class(3, C1)
    local C4 = create_class(4, C2)
    local C5 = create_class(5, C3)
    local C6 = class(nil, C4) {}

    assert_equal(
      unpack({ 1, 2, 3, 4, 5, 4 }),
      unpack(_.map({ C1, C2, C3, C4, C5, C6 },
        function (i, cls)
          local o = cls()
          return o:method()
        end))
    )
  end)

  test('values should be inherited', function ()
    local C1 = class { x = 5 }
    local C2 = class(nil, C1) { method = function(self) return self.x end }

    local o = C2()

    assert_equal(o:method(), 5)
  end)

  test('values can be overridden', function ()
    local C1 = class { x = 5 }
    local C2 = class(nil, C1) { method = function(self) return self.x end }
    local C3 = class(nil, C2) { x = 6 }

    local o = C3()

    assert_equal(o:method(), 6)
  end)

  test('inherited values can be mutated', function ()
    local C1 = class { x = 5 }
    local C2 = class(nil, C1) { method = function(self) self.x = 6 end }

    local o = C2()

    assert_equal(o.x, 5)
    o:method()
    assert_equal(o.x, 6)
  end)

end)

context('inspection features', function ()
  context('class.isobject', function ()
    test('an object is an object', function ()
      local o = (class { })()
      assert_true(class.isobject(o))
    end)
    test('a number/table/string/nil is not an object', function ()
      assert_false(class.isobject({ x = 5 }))
      assert_false(class.isobject(5))
      assert_false(class.isobject('666'))
      assert_false(class.isobject(nil))
    end)
  end)

  context('class.isclass', function ()
    test('a class is a class', function ()
      assert_true(class.isclass(class { x = 5 }))
    end)
    test('a number/table/string/nil is not a class', function ()
      assert_false(class.isclass({ x = 5 }))
      assert_false(class.isclass(5))
      assert_false(class.isclass('666'))
      assert_false(class.isclass(nil))
    end)
  end)

  context('class.isinstanceof', function ()
    local C = class { }
    local C2 = class(C) { }

    test('an object is instance of it\'s class', function ()
      assert_true(class.isinstanceof(C(), C))
    end)
    test('an object is instance of it\'s class\' parent', function ()
      assert_true(class.isinstanceof(C2(), C))
    end)
    test('a number/table/string/nil is not an instance of a class', function ()
      assert_false(class.isinstanceof(5, C))
      assert_false(class.isinstanceof({ x = 5 }, C))
      assert_false(class.isinstanceof('5', C))
      assert_false(class.isinstanceof(nil, C))
    end)
    test('an object is not an instance of not a class', function ()
      assert_false(class.isinstanceof(C(), 5))
      assert_false(class.isinstanceof(C(), '5'))
      assert_false(class.isinstanceof(C(), { x = 5 }))
      assert_false(class.isinstanceof(C(), nil))
    end)
  end)

end)