local class = require('oops')

-- Smallest possible class.
local Creature = class {}

-- Inherits from Creature, adds name via constructor
local Human = class(Creature) {
  __init = function(self, name)
    self.name = name
  end,
}

-- Abstract base class for "talking" creatures
local TalkingCreature = class(Human) {
  talk = function()
    error('Not implemented')
  end,
}

-- Scientist overrides talk
local Scientist = class(TalkingCreature) {
  __init = function(self, name, discovery)
    -- calling superclass constructor
    self.__super:__init(name)
    self.discovery = discovery
  end,

  -- overriding inherited method
  talk = function(self)
    return "It's a scientific fact that " .. self.discovery .. '.'
  end,
}

-- Kitten talks in adorable gibberish
local Kitten = class(TalkingCreature) {
  talk = function(self)
    return 'Miao!'
  end,
}

-- Storyteller interviews another talking creature
local Storyteller = class(TalkingCreature) {
  __init = function(self, name, companion)
    self.__super:__init(name)
    self.companion = companion
  end,

  talk = function(self)
    return 'I once heard from ' .. self.companion.name .. ': "' .. self.companion:talk() .. '"'
  end,
}

-- Collection of polymorphic characters
local characters = {
  Scientist('John von Neumann', 'quantum entanglement is real'),
  Kitten('Murzyk Vasyliovych'),
  Storyteller(
    'Aesop',
    -- anonymous class instantiation
    (class(TalkingCreature) {
      talk = function(self)
        return 'Even the smallest voice can tell the biggest truth.'
      end,
    })('The Tiny Owl')
  ),
}

-- Interview helper
local function interview(who)
  print(who.name .. ' says: ' .. who:talk())
end

-- Run the polymorphic demo
for _, c in ipairs(characters) do
  interview(c)
end
