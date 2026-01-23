--- Example: Mixin-style composition using multi-table merge
-- Demonstrates how to compose reusable behaviors without inheritance

local class = require 'oops'

-- Define reusable behavior "mixins" as plain tables

-- Timer behavior - adds timer management to any class
local Timed = {
  add_timer = function(self, duration, callback)
    table.insert(self.timers, { time = duration, callback = callback })
  end,

  update_timers = function(self, dt)
    for i = #self.timers, 1, -1 do
      local timer = self.timers[i]
      timer.time = timer.time - dt
      if timer.time <= 0 then
        timer.callback()
        table.remove(self.timers, i)
      end
    end
  end,
}

-- Physics behavior - adds basic physics simulation
local PhysicsBody = {
  apply_force = function(self, fx, fy)
    self.vx = self.vx + fx
    self.vy = self.vy + fy
  end,

  update_physics = function(self, dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- Simple friction
    self.vx = self.vx * 0.98
    self.vy = self.vy * 0.98
  end,
}

-- Drawable behavior - adds rendering info
local Drawable = {
  set_color = function(self, r, g, b)
    self.color = { r = r, g = g, b = b }
  end,

  get_color_string = function(self)
    return string.format('RGB(%d, %d, %d)', self.color.r, self.color.g, self.color.b)
  end,
}

print('=== Mixin Composition Example ===\n')

-- Example 1: Compose multiple behaviors into a single class
print('Example 1: Player with timer, physics, and drawing')
print('---')

local Player = class(Timed, PhysicsBody, Drawable, {
  __init = function(self, x, y)
    self.x, self.y = x, y
    self.vx, self.vy = 0, 0
    self.timers = {}
    self:set_color(255, 0, 0)
    print('Player initialized at position (' .. x .. ', ' .. y .. ')')
  end,

  update = function(self, dt)
    self:update_timers(dt)
    self:update_physics(dt)
  end,

  info = function(self)
    return string.format(
      'Player at (%.1f, %.1f), velocity (%.1f, %.1f), %s',
      self.x,
      self.y,
      self.vx,
      self.vy,
      self:get_color_string()
    )
  end,
})

local player = Player(100, 100)
player:apply_force(10, 5)
player:add_timer(2, function()
  print('Timer expired!')
end)

print(player:info())
player:update(0.1)
print('After update:', player:info())

-- Example 2: Different class, different mixin combination
print('\nExample 2: Bullet with only timer and physics')
print('---')

local Bullet = class(Timed, PhysicsBody, {
  __init = function(self, x, y, vx, vy, lifetime)
    self.x, self.y = x, y
    self.vx, self.vy = vx, vy
    self.timers = {}
    self.alive = true

    -- Auto-destroy after lifetime
    self:add_timer(lifetime, function()
      self.alive = false
      print('Bullet destroyed after ' .. lifetime .. 's')
    end)

    print('Bullet created with velocity (' .. vx .. ', ' .. vy .. ')')
  end,

  update = function(self, dt)
    if self.alive then
      self:update_timers(dt)
      self:update_physics(dt)
    end
  end,
})

local bullet = Bullet(0, 0, 100, 50, 3)
print('Bullet position: (' .. bullet.x .. ', ' .. bullet.y .. ')')
bullet:update(0.5)
print('After 0.5s: (' .. string.format('%.1f', bullet.x) .. ', ' .. string.format('%.1f', bullet.y) .. ')')

-- Example 3: Inheritance + Mixins (curried form)
print('\nExample 3: Using inheritance with mixins (curried form)')
print('---')

local Entity = class {
  __init = function(self, name)
    self.name = name
    print('Entity "' .. name .. '" created')
  end,

  get_name = function(self)
    return self.name
  end,
}

-- Enemy inherits from Entity and mixes in physics
-- Note: use curried form class(Parent)(Mixin, {def})
local Enemy = class(Entity)(PhysicsBody, {
  __init = function(self, name, x, y)
    self.__super:__init(name)
    self.x, self.y = x, y
    self.vx, self.vy = 0, 0
  end,

  info = function(self)
    return string.format('%s at (%.1f, %.1f)', self:get_name(), self.x, self.y)
  end,
})

local enemy = Enemy('Goblin', 50, 50)
print(enemy:info())
enemy:apply_force(5, 0)
enemy:update_physics(1)
print('After movement:', enemy:info())

-- Example 4: Named class with mixins (curried form)
print('\nExample 4: Named class with multiple mixins (curried form)')
print('---')

local PowerUp = class('PowerUp')(Timed, PhysicsBody, {
  __init = function(self, x, y, power)
    self.x, self.y = x, y
    self.vx, self.vy = 0, 0
    self.power = power
    self.timers = {}
    self.active = true

    -- Expire after 5 seconds
    self:add_timer(5, function()
      self.active = false
      print('PowerUp expired')
    end)
  end,
})

print('Class name: ' .. PowerUp.__name)
local powerup = PowerUp(10, 10, 'speed')
print('PowerUp active: ' .. tostring(powerup.active))

-- Example 5: Method override precedence (last table wins)
print('\nExample 5: Method override with multiple mixins')
print('---')

local MixinA = {
  greet = function()
    return 'Hello from A'
  end,
}

local MixinB = {
  greet = function()
    return 'Hello from B'
  end,
}

-- MixinB's greet() will be used (last wins)
local ClassAB = class(MixinA, MixinB, {})
print('With A then B: ' .. ClassAB():greet())

-- MixinA's greet() will be used (last wins)
local ClassBA = class(MixinB, MixinA, {})
print('With B then A: ' .. ClassBA():greet())

-- Class definition's greet() will be used (last wins)
local ClassCustom = class(MixinA, MixinB, {
  greet = function()
    return 'Hello from custom'
  end,
})
print('With custom override: ' .. ClassCustom():greet())

print('\n=== Summary ===')
print('Multi-table merge allows mixin-style composition:')
print('- Define reusable behaviors as plain tables')
print('- Compose classes from multiple mixins: class(Mixin1, Mixin2, {def})')
print('- Use curried form for inheritance + mixins:')
print('  - class(Parent)(Mixin1, {def})')
print('  - class("Name")(Mixin1, {def})')
print('  - class("Name", Parent)(Mixin1, {def})')
print('- Later tables override earlier ones on name collision')
print('- Zero runtime overhead - merging happens at class definition time')
