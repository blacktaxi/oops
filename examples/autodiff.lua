local class = require('oops')

local Add, Mul, Pow

-- Base class for all nodes in the computation graph
local Node = class('Node') {
  __init = function(self)
    self.inputs = {}
    self.grad = 0
    self.value = nil
  end,

  forward = function(self)
    error('Not implemented')
  end,

  backward = function(self, grad_output)
    error('Not implemented')
  end,

  -- Reset gradients before backward pass
  zero_grad = function(self, visited)
    visited = visited or {}
    if visited[self] then
      return
    end
    visited[self] = true
    self.grad = 0
    for _, input in ipairs(self.inputs) do
      input:zero_grad(visited)
    end
  end,

  -- Kick off reverse-mode autodiff
  backward_all = function(self, grad_output)
    self:zero_grad()
    self:backward(grad_output or 1)
  end,

  __tostring = function(self)
    return '<' .. self.__class.__name .. '>'
  end,

  -- Operator overloading
  __add = function(a, b)
    return Add(a, b)
  end,

  __mul = function(a, b)
    return Mul(a, b)
  end,

  __pow = function(a, b)
    return Pow(a, b)
  end,
}

-- Constants
local Const = class('Const', Node) {
  __init = function(self, val)
    self.__super:__init()
    self.value = val
  end,

  forward = function(self)
    return self.value
  end,

  backward = function(self, grad_output)
    -- Constant has no gradient
  end,

  __tostring = function(self)
    return tostring(self.value)
  end,
}

-- Variables
local Var = class('Var', Node) {
  __init = function(self, val)
    self.__super:__init()
    self.value = val
  end,

  forward = function(self)
    return self.value
  end,

  backward = function(self, grad_output)
    self.grad = self.grad + grad_output
  end,

  __tostring = function(self)
    return 'Var(' .. tostring(self.value) .. ')'
  end,
}

-- Addition
Add = class('Add', Node) {
  __init = function(self, a, b)
    self.__super:__init()
    self.a = a
    self.b = b
    self.inputs = { a, b }
  end,

  forward = function(self)
    self.value = self.a:forward() + self.b:forward()
    return self.value
  end,

  backward = function(self, grad_output)
    self.a:backward(grad_output)
    self.b:backward(grad_output)
  end,

  __tostring = function(self)
    return '(' .. tostring(self.a) .. ' + ' .. tostring(self.b) .. ')'
  end,
}

-- Multiplication
Mul = class('Mul', Node) {
  __init = function(self, a, b)
    self.__super:__init()
    self.a = a
    self.b = b
    self.inputs = { a, b }
  end,

  forward = function(self)
    self.a_val = self.a:forward()
    self.b_val = self.b:forward()
    self.value = self.a_val * self.b_val
    return self.value
  end,

  backward = function(self, grad_output)
    self.a:backward(grad_output * self.b_val)
    self.b:backward(grad_output * self.a_val)
  end,

  __tostring = function(self)
    return '(' .. tostring(self.a) .. ' * ' .. tostring(self.b) .. ')'
  end,
}

-- Power
Pow = class('Pow', Node) {
  __init = function(self, base, exp)
    self.__super:__init()
    self.base = base
    self.exp = exp
    self.inputs = { base, exp }
  end,

  forward = function(self)
    self.base_val = self.base:forward()
    self.exp_val = self.exp:forward()
    self.value = self.base_val ^ self.exp_val
    return self.value
  end,

  backward = function(self, grad_output)
    local b, e = self.base_val, self.exp_val
    local logb = math.log(b)

    self.base:backward(grad_output * e * (b ^ (e - 1)))
    self.exp:backward(grad_output * self.value * logb)
  end,

  __tostring = function(self)
    return '(' .. tostring(self.base) .. ' ^ ' .. tostring(self.exp) .. ')'
  end,
}

-- Sample usage:
local x = Var(3)
local y = Var(5)
local z = x * x + x * y + Const(7)

print('Expression:', z)
print('Forward:', z:forward()) -- should print 31

z:backward_all()

print('dz/dx =', x.grad) -- should be 2x + y = 6 + 5 = 11
print('dz/dy =', y.grad) -- should be x = 3
