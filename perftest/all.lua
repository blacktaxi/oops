class = require 'oops'
local _ = require 'moses'
require 'bench'

local benchmarks = {
  { name = 'Class definition', action = function ()
    return function ()
      local C = class { }
    end
  end},
  { name = '1-inheritance class definition', action = function ()
    local C = class { }
    return function ()
      local C1 = class(C) { }
    end
  end},
  { name = '3-inheritance class definition', action = function ()
    local C = class { }
    C = class(C) { }
    C = class(C) { }
    C = class(C) { }
    return function ()
      local C1 = class(C) { }
    end
  end},
  { name = 'Instance creation', action = function ()
    local C1 = class { }
    return function ()
      local o = C1()
    end
  end},
  { name = '1-inheritance instance creation', action = function ()
    local C2 = class { }
    local C3 = class(C2) { }
    return function ()
      local o = C3()
    end
  end},
  { name = '3-inheritance instance creation', action = function ()
    local C2 = class { }
    local C3 = class(C2) { }
    local C4 = class(C3) { }
    local C5 = class(C4) { }
    return function ()
      local o = C5()
    end
  end},
  { name = 'Complex instance creation', action = function ()
    local C2 = class { x = 5, y = 6, z = function (self) return 9 end }
    return function ()
      local o = C2()
    end
  end},
  { name = 'Instance method call', action = function ()
    local C2 = class { x = 5, y = 6, z = function (self) return 9 end }
    local o = C2()
    return function ()
      o:z()
    end
  end},
  { name = '1-inheritance instance method call', action = function ()
    local C1 = class { x = 5, y = 6, z = function (self) return 9 end }
    local C2 = class(C1) { q = function (self) return 10 end }
    local o = C2()
    return function ()
      o:z()
    end
  end},
  { name = 'Instance mutation via method call', action = function ()
    local C = class { x = 0, method = function (self) self.x = self.x + 1 end }
    local o = C()
    return function ()
      o:method()
    end
  end},
  { name = 'Is-class test', action = function ()
    local C = class { }
    return function ()
      class.isclass(C)
    end
  end},
  { name = 'Is-object test', action = function ()
    local C = class { }
    local o = C()
    return function ()
      class.isobject(o)
    end
  end},
  { name = 'Is-instance-of test', action = function ()
    local C = class { }
    local o = C()
    return function ()
      class.isinstanceof(o, C)
    end
  end},
  { name = '3-inheritance is-instance-of test', action = function ()
    local C = class { }
    local C1 = class(C) { }
    local C2 = class(C1) { }
    local C3 = class(C2) { }
    local o = C3()
    return function ()
      class.isinstanceof(o, C)
    end
  end},
}

local print_results = function (results)
  for _, r in ipairs(results) do
    b, t = unpack(r)
    print(b.name .. ': ' .. t * 1000000  .. ' us')
  end
end

local results = _.map(benchmarks, function (i, x) return bench(x) end)

print_results(results)

