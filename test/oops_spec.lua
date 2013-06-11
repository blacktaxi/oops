require 'oops'

context('base class functionality', function ()
  test('__init__ method should be called', function ()
    local o = 
      (class ()() { __init__ = function (self) self.field = 42 end }):new()

    assert_equal(42, o.field)
  end)

  test('__init__ method should receive arguments', function ()
    local o = (class ()() { 
      __init__ = function (self, ...) 
        self.init_args = { ... }
      end 
    }):new(1, 2, 3, 4, 5)

    assert_equal({ 1, 2, 3, 4, 5 }, o.init_args)
  end)

	test('methods should return values', function ()
		local o = (class ()() { method = function(self) return 5 end }):new()

		assert_equal(5, o:method())
	end)

  test('object state can be mutated', function ()
    local o = (class ()() {
      __init__ = function (self)
        self.state = 'initial'
      end,
      effectful_method = function (self)
        self.state = 'new'
      end
    }):new()

    assert_equal('initial', o.state)
    o:effectful_method()
    assert_equal('new', o.state)
  end)

end)