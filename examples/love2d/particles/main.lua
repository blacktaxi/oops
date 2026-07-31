-- LÖVE's package.path loader resolves against the process working directory, so
-- cover both ways of launching: from the repo root and from this game directory.
package.path = 'src/?.lua;../../../src/?.lua;' .. package.path

local class = require('oops')

local Particle = class('Particle') {
  __init = function(self, x, y, vx, vy, color, lifetime)
    self.x = x
    self.y = y
    self.vx = vx or love.math.random(-50, 50)
    self.vy = vy or love.math.random(-150, -50)
    self.color = color or { 1, 1, 1 }
    self.lifetime = lifetime or love.math.random(1, 2)
    self.age = 0
    self.radius = 3
  end,

  update = function(self, dt)
    self.age = self.age + dt
    self.vy = self.vy + 100 * dt
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
}

local Sparkle = class(Particle) {
  __init = function(self, x, y)
    self.__super:__init(
      x,
      y,
      love.math.random(-550, 550),
      love.math.random(-550, 550),
      { 1, 0.5, 0.1 }
    )

    self.radius = 5
  end,

  update = function(self, dt)
    self.__super:update(dt)
    self.vx = self.vx * (1 - 3 * dt)
    self.vy = self.vy * (1 - 3 * dt)
  end,
}

local ParticleSystem = class {
  __init = function(self)
    self.particles = {}
  end,

  add = function(self, particle)
    table.insert(self.particles, particle)
  end,

  update = function(self, dt)
    local alive = {}
    for _, p in ipairs(self.particles) do
      p:update(dt)
      if p:isAlive() then
        table.insert(alive, p)
      end
    end
    self.particles = alive
  end,

  draw = function(self)
    for _, p in ipairs(self.particles) do
      p:draw()
    end
  end,

  count = function(self)
    return #self.particles
  end,
}

local system = ParticleSystem()

local Emitter = {
  x = 0,
  y = 0,
  timer = 0,
  rate = 0.02,

  update = function(self, dt)
    self.x, self.y = love.mouse.getPosition()

    self.timer = self.timer + dt
    while self.timer > self.rate do
      self.timer = self.timer - self.rate

      local p
      if love.math.random() > 0.8 then
        p = Sparkle(self.x, self.y)
      else
        p = Particle(self.x, self.y)
      end

      system:add(p)
    end
  end,
}

function love.load()
  love.window.setMode(600, 400)
end

function love.update(dt)
  Emitter:update(dt)
  system:update(dt)
end

function love.draw()
  love.graphics.clear(0.05, 0.05, 0.1)
  system:draw()
  love.graphics.setColor(1, 1, 1)
  love.graphics.print('Particles: ' .. system:count(), 10, 10)
end
