local class = require('oops')

local PhysicsObject = class('PhysicsObject') {
  __init = function(self, world, x, y, width, height, type)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.type = type or 'dynamic'

    self.body = love.physics.newBody(world, x, y, self.type)
    self.shape = love.physics.newRectangleShape(width, height)
    self.fixture = love.physics.newFixture(self.body, self.shape)
    self.fixture:setUserData(self)
  end,

  update = function(self, dt)
    -- override as needed
  end,

  draw = function(self)
    local x, y = self.body:getPosition()
    local angle = self.body:getAngle()
    love.graphics.setColor(1, 1, 1)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(angle)
    love.graphics.rectangle('fill', -self.width / 2, -self.height / 2, self.width, self.height)
    love.graphics.pop()
  end,
}

return PhysicsObject
