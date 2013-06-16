require 'oops'

local _ = require 'moses'
local inspect = require 'inspect'

context('base class functionality', function ()
  test('anonymous class can be created', function ()
    local C = class {}
    local o = C()
    assert_true(isclass(C))
    assert_true(isobject(o))
    assert_equal(C, o.__class)
  end)

  test('named class can be created', function ()
    local C = class("Name") {}
    local o = C()
    assert_true(isclass(C))
    assert_true(isobject(o))
    assert_equal("Name",  C.__name)
    assert_equal(C, o.__class)
  end)

  test('named class can have a parent', function ()
    local C1 = class {}
    local C2 = class("Name", C1) {}
    local o = C2()
    assert_true(isclass(C2))
    assert_true(isobject(o))
    assert_equal("Name",  C2.__name)
    assert_equal(C2, o.__class)
  end)

  test('anonymous class can have a parent', function ()
    local C1 = class {}
    local C2 = class(nil, C1) {}
    local o = C2()
    assert_true(isclass(C2))
    assert_true(isobject(o))
    assert_equal(C2, o.__class)
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
end)

context('inheritance and dispatch', function ()
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