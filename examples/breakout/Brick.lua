local class = require('oops')
local PhysicsObject = require('PhysicsObject')

local Brick = class('Brick', PhysicsObject) {
  __init = function(self, world, x, y, w, h)
    self.__super:__init(world, x, y, w, h, 'static')
    self.destroyed = false
    self.destroying = false
    self.color = { love.math.random(), love.math.random(), love.math.random() }

    self.fixture:setRestitution(1)
    self.fixture:setFriction(0)
    self.fixture:setUserData(self)
  end,

  destroy = function(self)
    if not self.destroyed and not self.destroyed then
      self.destroying = true
    end
  end,

  update = function(self)
    if not self.destroyed and self.destroying then
      self.body:setType('dynamic')
      self.body:applyAngularImpulse(love.math.random(-1000, 1000))
      self.fixture:setRestitution(0.2)
      self.falling = true
      self.destroyed = true
    end
  end,

  draw = function(self)
    local x, y = self.body:getPosition()
    local angle = self.body:getAngle()

    if self.falling then
      self.color = { 0.3, 0.3, 0.3 }
    end

    love.graphics.setColor(self.color)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(angle)
    love.graphics.rectangle('fill', -self.width / 2, -self.height / 2, self.width, self.height)
    love.graphics.pop()
  end,

  __class = {
    createGrid = function(cls, world, cols, rows, brickWidth, brickHeight)
      local bricks = {}
      local padding = 10
      local offsetX = (love.graphics.getWidth() - (cols * (brickWidth + padding))) / 2
      local offsetY = 50

      for row = 1, rows do
        for col = 1, cols - 2 do
          local x = offsetX + col * (brickWidth + padding) + brickWidth / 2
          local y = offsetY + row * (brickHeight + padding) + brickHeight / 2
          table.insert(bricks, cls(world, x, y, brickWidth, brickHeight))
        end
      end

      return bricks
    end,
  },
}

return Brick
