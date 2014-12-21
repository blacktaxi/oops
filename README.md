Oops
====

[![Build Status](https://travis-ci.org/blacktaxi/oops.png?branch=master)](https://travis-ci.org/blacktaxi/oops)

```lua
local class = require 'oops'

local Duck = class {
  __init = function (self)
    self.quacks = 0
  end,

  quack = function (self)
    self.quacks = self.quacks + 1
    print('Quack! Total: ' .. self.quacks .. ' time(s).')
  end,
}

local duffy = Duck()
duffy:quack()
```

Simple [class-based](http://en.wikipedia.org/wiki/Class-based_programming) OOP for Lua with first
class classes (class definition is an expression) and comfortable syntax.

Features
--------
* Class-based inheritance: class is a factory for objects (instances).
* Classes as expressions (classes can be anonymous and/or defined and used on the spot).
* Controlled visibility scope: classes don't have to be global.
* Terse syntax: ```local Class = class { hello = function (self) print('world!') end }```.

Example
-------
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

-- 'Abstract' method.
local TalkingHuman = class(Human) {
  talk = function (self) error("Abstract method call") end
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

```
$ lua people.lua
John von Neumann says: It is a scientific fact that a von Neumann algebra or W*-algebra is a *-algebra of bounded operators on a Hilbert space that is closed in the weak operator topology and contains the identity operator..
Victor Tsoi says: Mmmrhrhgmhmmm...
Michael Moore says: According to Emmanuel Goldstein, "2 + 2 = 5."
```

To do
-----
- class methods/values
- custom metamethods (operator methods)
- static methods
- more tests
- better docstrings
- compare with other OOP libraries
