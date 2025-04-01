local class = require('oops')

-- Base Pet class
local Pet = class {
  __init = function(self, name, owner)
    self.name = name
    self.owner = owner
    self.__class:register(self)
  end,

  speak = function(self)
    print(self.name .. ' makes a noise.')
  end,

  __class = {
    registry = {},
    count = 0,

    register = function(cls, pet)
      table.insert(cls.registry, pet)
      cls.count = cls.count + 1
    end,

    report = function(cls)
      print(cls.count .. ' ' .. cls.__name .. '(s) adopted.')
      for _, pet in ipairs(cls.registry) do
        print('- ' .. pet.name .. ' (owner: ' .. pet.owner .. ')')
      end
    end,
  },
}

-- Dog subclass
local Dog = class('Dog', Pet) {
  __class = {
    -- since object fields are shared by reference, we're creating a separate registry
    -- table in the subclass
    registry = {},

    -- but not the count!
  },

  speak = function(self)
    print(self.name .. ' says: Woof!')
  end,
}

-- Cat subclass
local Cat = class('Cat', Pet) {
  __class = {
    registry = {},
  },

  speak = function(self)
    print(self.name .. ' says: Meow.')
  end,
}

-- Parrot subclass
local Parrot = class('Parrot', Pet) {
  __class = {
    registry = {},
  },

  speak = function(self)
    print(self.name .. ' says: Shiver me timbers!')
  end,
}

-- Adopt some pets!
local a = Dog('Rex', 'Alice')
local b = Cat('Murzyk Vasyliovych', 'Svyryd Opanasovych')
local c = Parrot('Pirate', 'Charlie')

a:speak()
b:speak()
c:speak()

print('\nAdoption Registry:')
Dog:report()
Cat:report()
Parrot:report()
