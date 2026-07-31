local class = require('oops')
local PhysicsObject = require('PhysicsObject')

local Wall = class('Wall', PhysicsObject) {
  __init = function(self, world, x, y, w, h)
    self.__super:__init(world, x, y, w, h, 'static')
    self.color = { 0.3, 0.3, 0.4 }
    self.fixture:setRestitution(1)
    self.fixture:setFriction(0)
    self.fixture:setGroupIndex(-1) -- see Paddle: walls and paddle pass through each other
    self.fixture:setUserData(self)
  end,

  draw = function(self)
    local x, y = self.body:getPosition()
    love.graphics.setColor(self.color)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rectangle('fill', -self.width / 2, -self.height / 2, self.width, self.height)
    love.graphics.pop()
  end,

  __class = {
    createBounds = function(cls, world, screenW, screenH)
      local thickness = 30
      return {
        cls(world, screenW / 2, -thickness / 2, screenW, thickness), -- top
        cls(world, -thickness / 2, screenH / 2, thickness, screenH), -- left
        cls(world, screenW + thickness / 2, screenH / 2, thickness, screenH), -- right
      }
    end,
  },
}

return Wall
