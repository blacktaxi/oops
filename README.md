# Oops

[![Build Status](https://travis-ci.org/blacktaxi/oops.png?branch=master)](https://travis-ci.org/blacktaxi/oops)

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

Lightweight [class-based](http://en.wikipedia.org/wiki/Class-based_programming) OOP for Lua with first class classes (class definition is an expression) and comfortable syntax.

Oops is a lightweight, expressive, [class-based](http://en.wikipedia.org/wiki/Class-based_programming) OOP system for Lua. It features first-class classes, clean inheritance, and concise syntax — all in pure Lua.

## Features

- Class-based single inheritance: class is a factory of objects (instances).
- Classes as expressions (classes can be anonymous and/or defined and used on the spot).
- Controlled visibility scope: classes don't have to be global.
- Concise syntax: `local Class = class { hello = function (self) print('world!') end }`.
- Performance-optimized.

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

For more examples see [`examples/](./examples).

## To do

- class methods/values
- custom metamethods (operator methods)
- static methods
- more tests
- better docstrings
- compare with other OOP libraries

## License

BSD 3-clause.
