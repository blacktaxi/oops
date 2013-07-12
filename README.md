Oops
====

[![Build Status](https://travis-ci.org/blacktaxi/oops.png?branch=master)](https://travis-ci.org/blacktaxi/oops)

Simple OOP with class-based inheritance, anonymous classes (classes are first-class values) and comfortable syntax for Lua.

Why?
----
* Existing OOP libraries for Lua either have too verbose syntax (can't define a class in a single expression) and/or are too packed with features I don't need
* I was bored, Not-Invented-Here, etc

Features
--------
* Class-based inheritance: class is a factory for objects (instances).
* Controlled visibility scope: classes don't have to be global, classes can be anonymous (defined and used at the spot).
* Terse syntax: ```class { hello = function (self) print('world!') end }```

Example
-------
```lua
require 'oops'

-- Class declaration.
local A = class {
  -- Constructor. Called upon creation of an instance.
  __init = function (self, x)
    self.x = x
  end,

  -- Method.
  method = function (self, z)
    return self.x + self.z
  end
}

-- Inheritance.
local B = class(A) {
  -- Overriding superclass' method.
  method = function (self, v)
    -- Calling superclass' method.
    local u = self.__super:method(v)
    return u * 2
  end
}

local f = function (x, y)
  -- Class instantiation.
  local o = y()

  return x - y.bar + y:foo(x)
end

local z = f(
  5, 
  -- Anonymous class.
  class {
    bar = 1,

    foo = function (self, x)
      return x * 3
    end
  })
```

A more elaborate example
--------
```lua
require 'oops'

-- Simplest class. No methods, no constructor, no inheritance.
local Creature = class { }

-- Inheritance, constructor.
local Human = class(Creature) {
  __init = function (self, name)
    self.name = name
  end
}

-- Abstract method.
local TalkingHuman = class(Human) {
  talk = abstract_method
}

-- Calling superclass constructor, overriding inherited method.
local Scientist = class(TalkingHuman) {
  __init = function (self, name, discovery)
    self.__super:__init(name)
    self.discovery = discovery
  end,

  talk = function (self)
    return 'It is a scientific fact that ' .. self.discovery .. '.'
  end
}

-- Overriding.
local Zombie = class(TalkingHuman) {
  talk = function (self) return 'Mmmrhrhgmhmmm...' end
}

-- Interacting with other objects.
local Journalist = class(TalkingHuman) {
  __init = function (self, name, interviewee)
    self.__super:__init(name)
    self.interviewee = interviewee
  end,

  talk = function (self)
    return 'According to ' .. self.interviewee.name .. ', "' ..
      self.interviewee:talk() .. '."'
  end
}

-- Array of objects.
local people = { 
  Scientist('John von Neumann', 
    'a von Neumann algebra or W*-algebra is a *-algebra of bounded' .. 
    ' operators on a Hilbert space that is closed in the weak operator' .. 
    ' topology and contains the identity operator.'),

  Zombie('Victor Tsoi'),

  -- Declaring and instantiating an anonymous class at the same time.
  Journalist('Michael Moore',
    (class(TalkingHuman) { 
      talk = function (self) return '2 + 2 = 5' end 
    })('Emmanuel Goldstein'))
}

local interview = function (who)
  -- Dynamic dispatch.
  print(who.name .. ' says: ' .. who:talk())
end

-- Polymorphism.
for _, v in pairs(people) do
  interview(v)
end
```

To do
----
- write proper docstrings
- write more tests
- compare with other OOP libraries