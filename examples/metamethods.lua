local class = require('oops')

local Vector = class('Vector') {
  __init = function(self, x, y)
    self.x = x
    self.y = y
  end,

  __add = function(a, b)
    return a.__class(a.x + b.x, a.y + b.y)
  end,

  __eq = function(a, b)
    return a.x == b.x and a.y == b.y
  end,

  __tostring = function(self)
    return '(' .. self.x .. ', ' .. self.y .. ')'
  end,

  __len = function(self)
    return math.sqrt(self.x * self.x + self.y * self.y)
  end,

  __call = function(self, scalar)
    return self.__class(self.x * scalar, self.y * scalar)
  end,
}

local a = Vector(2, 3)
local b = Vector(4, 1)
local c = a + b -- uses __add
local d = a(2) -- scales vector
local equal = (a == b)

print('a + b =', c) --> (6, 4)
print('a == b?', equal) --> false
print('Length of a:', #a) --> 3.605...
print('a * 2 =', d) --> (4, 6)
