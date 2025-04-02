# Oops

[![Build](https://github.com/blacktaxi/oops/actions/workflows/ci.yml/badge.svg)](https://github.com/blacktaxi/oops/actions/workflows/ci.yml) [![LuaRocks](https://img.shields.io/luarocks/v/blacktaxi/oops.svg)](https://luarocks.org/modules/blacktaxi/oops) [![License](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](LICENSE)

```lua
local class = require 'oops'

-- Define a class
local Duck = class {
  __init = function (self)
    self.quacks = 0
  end,

  quack = function (self)
    self.quacks = self.quacks + 1
    print('Quack! Total: ' .. self.quacks .. ' time(s).')
  end,
}

-- Instantiate and use the class
local daffy = Duck()
daffy:quack()
```

Oops is a lightweight, expressive, [class-based](http://en.wikipedia.org/wiki/Class-based_programming) OOP system for Lua. It features first-class classes, clean inheritance, and concise syntax — all in pure Lua.

## Features

- Class-based single inheritance: class is a factory of objects (instances).
- Classes as expressions (classes can be anonymous and/or defined and used on the spot).
- Controlled visibility scope: classes don't have to be global.
- Concise syntax: `local Class = class { hello = function (self) print('world!') end }`.
- Class fields and methods (a-la Python)
- Custom metamethod support

## Use

1.  `$ luarocks install oops`
2.  `local class = require 'oops'`

## Examples

Inheritance and superclass constructor:

```lua
local Person = class {
  __init = function(self, name)
    self.name = name
  end,
}

local Student = class(Person) {
  __init = function(self, name, school)
    self.__super:__init(name)
    self.school = school
  end,
}

print(Student("Ada", "Academy").name)  -- prints: Ada
```

Anonymous class instance:

```lua
local greeter = (class {
  greet = function(self) print("Hello!") end
})()

greeter:greet()  -- prints: Hello!
```

Runtime type checking:

```lua
local class = require("oops").class
local isinstanceof = require("oops").isinstanceof

local A = class {}
local B = class(A) {}

local obj = B()
print(isinstanceof(obj, A))  -- true
print(isinstanceof(obj, B))  -- true
```

Class fields and methods:

```lua
local class = require("oops")

local Counter = class {
  __class = {
    value = 0,

    increment = function(cls)
      cls.value = cls.value + 1
    end,
  },
}

Counter:increment()
Counter:increment()

print("Counter value:", Counter.value)  --> 2

-- Subclass inherits class method, but not shared field
local Sub = class(Counter) {}
Sub:increment()

print("Counter value:", Counter.value)  --> 2
print("Sub value:", Sub.value)          --> 1
```

Metamethod support:

```lua
local Vector = class {
  __init = function(self, x, y)
    self.x, self.y = x, y
  end,

  __add = function(self, other)
    -- note how we're using self.__class to create a new Vector instance, since the
    -- local Vector is not yet defined
    return self.__class(self.x + other.x, self.y + other.y)
  end,

  __eq = function(a, b)
    return a.x == b.x and a.y == b.y
  end,

  __tostring = function(self)
    return "(" .. self.x .. ", " .. self.y .. ")"
  end,
}

local a = Vector(1, 2)
local b = Vector(3, 4)
local c = a + b

print(c)        --> (4, 6)
print(a == b)   --> false
```

> ⚠️ Note: \_\_ipairs is not supported in Lua 5.3 and later (use regular iterator methods instead).

For more examples see [`examples/](./examples).

## Development

To start:

```bash
make deps && make all
```

Performance benchmark:

```bash
make perf
```

## To do

- compare with other OOP libraries

## License

BSD 3-clause.
