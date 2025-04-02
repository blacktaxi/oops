package.path = 'src/?.lua;' .. package.path

local class = require('oops')

-- Base Particle class
local Particle
Particle = class('Particle') {
  __init = function(self, x, y)
    self.x = x
    self.y = y
    self.vx = love.math.random(-50, 50)
    self.vy = love.math.random(-150, -50)
    self.lifetime = love.math.random(1, 2)
    self.age = 0
    self.radius = 3
    self.color = { 1, 1, 1 }
    Particle:track(self)
  end,

  update = function(self, dt)
    self.age = self.age + dt
    self.vy = self.vy + 100 * dt -- gravity
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
  end,

  draw = function(self)
    love.graphics.setColor(self.color)
    love.graphics.circle('fill', self.x, self.y, self.radius)
  end,

  isAlive = function(self)
    return self.age < self.lifetime
  end,

  __tostring = function(self)
    return string.format('<Particle %.2f, %.2f>', self.x, self.y)
  end,

  __class = {
    active = {},

    track = function(cls, particle)
      table.insert(cls.active, particle)
    end,

    cleanup = function(cls)
      local next = {}
      for _, p in ipairs(cls.active) do
        if p:isAlive() then
          table.insert(next, p)
        end
      end
      cls.active = next
    end,

    updateAll = function(cls, dt)
      for _, p in ipairs(cls.active) do
        p:update(dt)
      end
      cls:cleanup()
    end,

    drawAll = function(cls)
      for _, p in ipairs(cls.active) do
        p:draw()
      end
    end,
  },
}

-- Optional sparkle variant
local Sparkle = class('Sparkle', Particle) {
  __init = function(self, x, y)
    self.__super:__init(x, y)
    self.radius = 5
    self.vx = love.math.random(-150, 150)
    self.vy = love.math.random(-250, -150)
    self.color = { love.math.random(), love.math.random(), love.math.random() }
  end,
}

-- Emitter (not strictly needed but illustrative)
local Emitter = class {
  __init = function(self, x, y)
    self.x = x
    self.y = y
    self.timer = 0
    self.rate = 0.02
  end,

  update = function(self, dt)
    self.timer = self.timer + dt
    while self.timer > self.rate do
      self.timer = self.timer - self.rate
      if love.math.random() > 5 then
        Particle(self.x, self.y)
      else
        Sparkle(self.x, self.y)
      end
    end
  end,
}

-- Global setup
local emitter

function love.load()
  print('LÖVE Lua version:', _VERSION)
  print('LuaJIT version:', jit and jit.version)
  print('package.path:\n', package.path)
  print('package.cpath:\n', package.cpath)
  love.window.setTitle('Particle Fountain - oops')
  love.window.setMode(600, 400)
  emitter = Emitter(300, 350)
end

function love.update(dt)
  emitter:update(dt)
  Particle:updateAll(dt)
end

function love.draw()
  love.graphics.clear(0.05, 0.05, 0.1)
  Particle:drawAll()
  love.graphics.setColor(1, 1, 1)
  love.graphics.print('Particles: ' .. tostring(#Particle.active), 10, 10)
end
