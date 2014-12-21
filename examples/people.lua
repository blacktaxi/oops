local class = require 'oops'

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

-- array of objects
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
  -- dynamic dispatch
  print(who.name .. ' says: ' .. who:talk())
end

-- interview them all.
for _, v in pairs(people) do
  interview(v)
end
