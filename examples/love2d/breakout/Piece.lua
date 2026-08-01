local class = require('oops')
local PhysicsObject = require('PhysicsObject')

-- Debris from a shattered brick. Ordinary pieces fall through the scene without
-- disturbing it; pieces from a volatile brick stay solid and knock things around.
local Piece = class('Piece', PhysicsObject) {
  __init = function(self, world, brick, localX, localY, width, height)
    local x, y = brick.body:getWorldPoint(localX, localY)
    self.__super:__init(world, x, y, width, height, 'dynamic')

    self.kind = brick.kind
    self.body:setAngle(brick.body:getAngle())

    -- Carry the brick's own motion, then scatter, so the debris looks like it
    -- came off the thing that was just hit rather than spawning from nowhere.
    local vx, vy = brick.body:getLinearVelocity()

    if self.kind.blast then
      -- Thrown outward from the brick's centre rather than in a random
      -- direction. Radial debris actually arrives at the neighbouring bricks,
      -- which is the entire point of a volatile one -- scattered debris mostly
      -- misses, and a piece that misses does nothing at all.
      local spread = math.max(math.sqrt(localX * localX + localY * localY), 0.001)
      local speed = self.kind.blast * (0.75 + love.math.random() * 0.5)

      self.body:setLinearVelocity(
        vx + localX / spread * speed,
        vy + localY / spread * speed
      )
      self.body:setAngularVelocity(love.math.random(-25, 25))
    else
      self.body:setLinearVelocity(
        vx + love.math.random(-140, 140),
        vy + love.math.random(-180, 60)
      )
      self.body:setAngularVelocity(love.math.random(-14, 14))
    end

    if self.kind.explosive then
      self.fixture:setRestitution(0.35)
      self.fixture:setFriction(0.4)
    else
      -- A sensor is still simulated and still falls -- it just generates no
      -- collision response, which is exactly "passes through everything".
      self.fixture:setSensor(true)
    end

    self.fixture:setUserData(self)
  end,

  draw = function(self)
    local x, y = self.body:getPosition()
    local color = self.kind.color

    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(self.body:getAngle())
    love.graphics.setColor(color[1], color[2], color[3])
    love.graphics.rectangle('fill', -self.width / 2, -self.height / 2, self.width, self.height)
    love.graphics.pop()
  end,
}

return Piece
