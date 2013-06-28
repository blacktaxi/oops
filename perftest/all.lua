require 'oops'
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
  { name = 'Instance test', action = function ()
    local C2 = class { x = 5, y = 6, z = function (self) return 9 end }
    local o = C2()
    return function ()
      isinstanceof(o, C2)
    end
  end},
}

local print_results = function (results)
  for _, r in ipairs(results) do
    b, ips = unpack(r)
    print(b.name .. ': ' .. ips  .. ' ips')
  end
end

local results = _.map(benchmarks, function (i, x) return bench(x) end)

print_results(results)

