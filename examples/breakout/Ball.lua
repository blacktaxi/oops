local class = require('oops')
local PhysicsObject = require('PhysicsObject')

local Ball = class('Ball', PhysicsObject) {
  __init = function(self, world, objects, x, y)
    self.__super:__init(world, x, y, 12, 12, 'dynamic')
    self.launched = false
    self.speed = 700
    self.objects = objects

    self.shape = love.physics.newCircleShape(12)
    self.fixture = love.physics.newFixture(self.body, self.shape)
    self.fixture:setRestitution(1)
    self.fixture:setDensity(1)
    self.fixture:setUserData(self)

    self.body:setBullet(true) -- prevent tunneling
    self.body:setLinearDamping(0) -- no drag
    self.body:setAngularDamping(0)
  end,

  launch = function(self)
    if not self.launched then
      self.launched = true
      local angle = -math.pi / 4 + love.math.random() * (math.pi / 2)
      local dx = math.cos(angle) * self.speed * 0.3
      local dy = math.sin(angle) * self.speed * 0.1
      self.body:setLinearVelocity(dx, dy - self.speed * (1 + 0.5 * love.math.random()))
    end
  end,

  update = function(self, dt)
    if not self.launched then
      local px = self.objects.paddle.body:getX()
      local py = self.objects.paddle.body:getY()
      self.body:setPosition(px, py - 20)
      self.body:setLinearVelocity(0, 0)
    end
  end,

  draw = function(self)
    local x, y = self.body:getPosition()
    love.graphics.setColor(1, 0.5, 0.5)
    love.graphics.circle('fill', x, y, self.shape:getRadius())
  end,
}

return Ball
