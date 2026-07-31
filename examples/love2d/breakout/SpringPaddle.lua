local class = require('oops')

local SpringPaddle = class('SpringPaddle') {
  __init = function(self, world, x, y, width, height)
    self.world = world
    self.width = width
    self.height = height

    self.anchor = love.physics.newBody(world, x, y, 'dynamic')
    self.anchor:setMass(100) -- high mass = stays mostly still
    self.anchor:setLinearDamping(1)
    self.anchor:setAngularDamping(1)
    self.anchor:setGravityScale(0) -- Prevent the anchor from being affected by gravity

    -- Dynamic paddle body
    self.body = love.physics.newBody(world, x, y, 'dynamic')
    self.shape = love.physics.newRectangleShape(width, height)
    self.fixture = love.physics.newFixture(self.body, self.shape, 1)

    self.body:setFixedRotation(false)
    self.body:setMass(10)
    self.body:setLinearDamping(2)
    self.body:setAngularDamping(3)
    self.body:setGravityScale(0)

    -- Spring-like distance joint
    self.joint = love.physics.newDistanceJoint(
      self.anchor,
      self.body,
      self.anchor:getX(),
      self.anchor:getY(),
      self.body:getX(),
      self.body:getY(),
      false
    )
    self.joint:setDampingRatio(0.7)
    self.joint:setFrequency(5)
  end,

  update = function(self, dt)
    local force = 150000
    if love.keyboard.isDown('left') or love.keyboard.isDown('a') then
      self.anchor:applyForce(-force, 0)
    elseif love.keyboard.isDown('right') or love.keyboard.isDown('d') then
      self.anchor:applyForce(force, 0)
    end
  end,

  draw = function(self)
    local x, y = self.body:getPosition()
    local angle = self.body:getAngle()

    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(angle)
    love.graphics.setColor(0.8, 0.8, 1.0)
    love.graphics.rectangle('fill', -self.width / 2, -self.height / 2, self.width, self.height)
    love.graphics.pop()

    local x, y = self.anchor:getPosition()
    local angle = self.anchor:getAngle()

    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(angle)
    love.graphics.setColor(1.0, 0, 0)
    love.graphics.rectangle('line', -self.width / 2, -self.height / 2, self.width, self.height)
    love.graphics.pop()
  end,
}

return SpringPaddle
