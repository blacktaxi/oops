local class = require('oops')
local PhysicsObject = require('PhysicsObject')

local Paddle = class('Paddle', PhysicsObject) {
  __init = function(self, world, x, y)
    -- 100x20 paddle, kinematic body
    self.__super:__init(world, x, y, 100, 20, 'kinematic')
    self.speed = 700

    self.fixture:setRestitution(1)
    self.fixture:setFriction(0)
    self.fixture:setUserData(self)
  end,

  update = function(self, dt)
    local vx = 0
    if love.keyboard.isDown('left') or love.keyboard.isDown('a') then
      vx = -self.speed
    elseif love.keyboard.isDown('right') or love.keyboard.isDown('d') then
      vx = self.speed
    end

    self.body:setLinearVelocity(vx, 0)

    -- Clamp to window edges
    local x = self.body:getX()
    local hw = self.width / 2
    local windowWidth = love.graphics.getWidth()

    if x - hw < 0 then
      self.body:setX(hw)
      self.body:setLinearVelocity(0, 0)
    elseif x + hw > windowWidth then
      self.body:setX(windowWidth - hw)
      self.body:setLinearVelocity(0, 0)
    end
  end,
}

return Paddle
