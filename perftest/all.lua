local class = require('oops')
local _ = require('moses')
local bench = require('bench')

local benchmarks = {
  {
    name = 'Class definition',
    action = function()
      return function()
        local C = class {}
      end
    end,
  },
  {
    name = '1-inheritance class definition',
    action = function()
      local C = class {}
      return function()
        local C1 = class(C) {}
      end
    end,
  },
  {
    name = '3-inheritance class definition',
    action = function()
      local C = class {}
      C = class(C) {}
      C = class(C) {}
      C = class(C) {}
      return function()
        local C1 = class(C) {}
      end
    end,
  },
  {
    name = 'Instance creation',
    action = function()
      local C1 = class {}
      return function()
        local o = C1()
      end
    end,
  },
  {
    name = '1-inheritance instance creation',
    action = function()
      local C2 = class {}
      local C3 = class(C2) {}
      return function()
        local o = C3()
      end
    end,
  },
  {
    name = '3-inheritance instance creation',
    action = function()
      local C2 = class {}
      local C3 = class(C2) {}
      local C4 = class(C3) {}
      local C5 = class(C4) {}
      return function()
        local o = C5()
      end
    end,
  },
  {
    name = 'Complex instance creation',
    action = function()
      local C2 = class {
        x = 5,
        y = 6,
        z = function(self)
          return 9
        end,
      }
      return function()
        local o = C2()
      end
    end,
  },
  {
    name = 'Instance method call',
    action = function()
      local C2 = class {
        x = 5,
        y = 6,
        z = function(self)
          return 9
        end,
      }
      local o = C2()
      return function()
        o:z()
      end
    end,
  },
  {
    name = '1-inheritance instance method call',
    action = function()
      local C1 = class {
        x = 5,
        y = 6,
        z = function(self)
          return 9
        end,
      }
      local C2 = class(C1) {
        q = function(self)
          return 10
        end,
      }
      local o = C2()
      return function()
        o:z()
      end
    end,
  },
  {
    name = 'Instance mutation via method call',
    action = function()
      local C = class {
        x = 0,
        method = function(self)
          self.x = self.x + 1
        end,
      }
      local o = C()
      return function()
        o:method()
      end
    end,
  },
  {
    name = 'Is-class test',
    action = function()
      local C = class {}
      return function()
        class.isclass(C)
      end
    end,
  },
  {
    name = 'Is-object test',
    action = function()
      local C = class {}
      local o = C()
      return function()
        class.isobject(o)
      end
    end,
  },
  {
    name = 'Is-instance-of test',
    action = function()
      local C = class {}
      local o = C()
      return function()
        class.isinstanceof(o, C)
      end
    end,
  },
  {
    name = '3-inheritance is-instance-of test',
    action = function()
      local C = class {}
      local C1 = class(C) {}
      local C2 = class(C1) {}
      local C3 = class(C2) {}
      local o = C3()
      return function()
        class.isinstanceof(o, C)
      end
    end,
  },
  {
    name = 'Static field read',
    action = function()
      local C = class {
        __class = {
          foo = 42,
        },
      }
      return function()
        local _ = C.foo
      end
    end,
  },
  {
    name = 'Static field write',
    action = function()
      local C = class {
        __class = {
          foo = 0,
        },
      }
      return function()
        C.foo = C.foo + 1
      end
    end,
  },
  {
    name = 'Inherited static field read',
    action = function()
      local Base = class {
        __class = {
          shared = 'hello',
        },
      }
      local Sub = class(Base) {}
      return function()
        local _ = Sub.shared
      end
    end,
  },
  {
    name = 'Static method call',
    action = function()
      local C = class {
        __class = {
          hello = function(cls)
            return 'hi'
          end,
        },
      }
      return function()
        C:hello()
      end
    end,
  },
  {
    name = 'Inherited static method call',
    action = function()
      local A = class {
        __class = {
          ping = function(cls)
            return 'pong'
          end,
        },
      }
      local B = class(A) {}
      return function()
        B:ping()
      end
    end,
  },
}

local function format_ops_per_sec(ops)
  local units = { '', 'K', 'M', 'G' }
  local i = 1
  while ops >= 1000 and i < #units do
    ops = ops / 1000
    i = i + 1
  end
  return string.format('%.2f %sops/sec', ops, units[i])
end

local function print_results(results)
  print(
    string.format('%-25s %-18s %-15s %s', 'Benchmark', 'Ops/sec', 'Time/op (µs)', 'Mem/1000 (KB)')
  )
  print(string.rep('-', 70))

  for _, r in ipairs(results) do
    local b, tpi, mpi = table.unpack(r)
    local ops = 1 / tpi
    local us_per_op = tpi * 1e6
    local kb_per_1000 = mpi * 1000

    print(
      string.format(
        '%-25s %-18s %-15.2f %.2f',
        b.name,
        format_ops_per_sec(ops),
        us_per_op,
        kb_per_1000
      )
    )
  end
end

local results = _.map(benchmarks, function(i, x)
  return bench(x)
end)

print_results(results)
