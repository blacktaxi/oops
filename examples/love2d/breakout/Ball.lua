local class = require('oops')
local PhysicsObject = require('PhysicsObject')

local function clamp(v, lo, hi)
  return math.max(lo, math.min(hi, v))
end

local Ball = class('Ball', PhysicsObject) {
  __init = function(self, world, objects, x, y)
    self.__super:__init(world, x, y, 12, 12, 'dynamic')
    self.launched = false
    self.returned = false
    self.objects = objects

    -- PhysicsObject hands us a rectangle fixture; the ball is a circle. Swap it
    -- out rather than leaving both attached, or the ball carries two fixtures'
    -- worth of mass.
    self.fixture:destroy()
    self.shape = love.physics.newCircleShape(12)
    self.fixture = love.physics.newFixture(self.body, self.shape, 1)
    self.fixture:setRestitution(1)
    self.fixture:setUserData(self)

    self.body:setBullet(true) -- prevent tunneling
    self.body:setLinearDamping(0) -- no drag
    self.body:setAngularDamping(0)

    -- Speed floor for when gravity alone doesn't demand more, and a ceiling so
    -- that a hard paddle swat can't run away with it.
    self.speed = 700
    self.maxSpeed = 1200
    self.headroom = 1.08 -- arrive at the top with a little speed still in hand
    self.maxLaunchAngle = math.rad(45) -- widest launch that still reaches a brick
    -- How much of the paddle's motion the ball leaves with. Tuned so a full-speed
    -- sweep lands right on maxLaunchAngle: any higher and the top of the input
    -- range would clamp to the same shot, wasting it.
    self.carry = 0.5

    -- The ball must always be able to climb back to the ceiling, so that height
    -- is what the energy calculations below are measured against.
    self.apexY = self.shape:getRadius()
  end,

  -- Speed needed here to just coast up to apexY, straight out of 1/2 v^2 = g*h.
  -- Derived from the world's own gravity, so retuning gravity retunes this too.
  climbSpeed = function(self)
    local _, gravity = self.body:getWorld():getGravity()
    local climb = math.max(0, self.body:getY() - self.apexY)

    return math.max(self.speed, math.sqrt(2 * gravity * climb) * self.headroom)
  end,

  launch = function(self)
    if not self.launched then
      self.launched = true

      -- Fire along the paddle's face, so leaning aims the shot...
      local paddle = self.objects.paddle
      local nx, ny = paddle:surfaceNormal()
      local speed = self:climbSpeed()

      -- ...plus the paddle's own sideways motion, since the ball is riding it
      -- and leaves carrying it. Velocity leads where lean lags: lean is a spring
      -- driven by velocity, so it takes a couple of tenths of a second to build,
      -- while the velocity is there the instant you move. Sweeping and launching
      -- therefore steers the shot immediately, rather than only after a sustained
      -- run-up long enough for the lean to catch up.
      local pvx = paddle.body:getLinearVelocity()
      local dx = nx * speed + pvx * self.carry
      local dy = ny * speed

      -- Jitter only keeps a flat, stationary paddle from firing perfectly
      -- vertically, which would bounce straight back down forever.
      local jitter = (love.math.random() * 2 - 1) * math.rad(2)
      dx, dy =
        dx * math.cos(jitter) - dy * math.sin(jitter),
        dx * math.sin(jitter) + dy * math.cos(jitter)

      -- Hold the shot inside a cone around vertical. A full-speed sweep would
      -- otherwise fire flat enough that the ball can't climb to even the lowest
      -- brick row, making a deliberate launch feel like a misfire.
      local widest = -dy * math.tan(self.maxLaunchAngle)
      dx = clamp(dx, -widest, widest)

      -- Renormalise: the sweep steers the shot, it doesn't add energy to it, so
      -- the climbSpeed guarantee survives however hard you were moving.
      local len = math.sqrt(dx * dx + dy * dy)

      self.body:setLinearVelocity(dx / len * speed, dy / len * speed)
    end
  end,

  update = function(self, dt)
    if not self.launched then
      -- Ride the paddle's face so the ball follows it as it leans.
      local paddle = self.objects.paddle
      local px, py = paddle.body:getPosition()
      local nx, ny = paddle:surfaceNormal()
      -- +1 for clearance: resting flush would generate a contact and jitter the
      -- paddle's rail spring while the ball is still held.
      local gap = paddle.height / 2 + self.shape:getRadius() + 1

      self.body:setPosition(px + nx * gap, py + ny * gap)
      self.body:setLinearVelocity(0, 0)
      self.returned = false
      return
    end

    if self.returned then
      self.returned = false
      self:restoreEnergy()
    end

    self:capSpeed()
  end,

  -- The paddle returns the ball with at least enough energy to climb back to the
  -- top of the playfield. This is a floor rather than a per-bounce gain, so it
  -- cannot compound: an already-fast ball is left completely alone.
  restoreEnergy = function(self)
    local vx, vy = self.body:getLinearVelocity()
    local speed = math.sqrt(vx * vx + vy * vy)
    local needed = self:climbSpeed()

    if speed > 0 and speed < needed then
      self.body:setLinearVelocity(vx * needed / speed, vy * needed / speed)
    end
  end,

  -- Backstop for energy the swinging paddle adds on a well-timed hit.
  capSpeed = function(self)
    local vx, vy = self.body:getLinearVelocity()
    local speed = math.sqrt(vx * vx + vy * vy)

    if speed > self.maxSpeed then
      self.body:setLinearVelocity(vx * self.maxSpeed / speed, vy * self.maxSpeed / speed)
    end
  end,

  draw = function(self)
    local x, y = self.body:getPosition()
    love.graphics.setColor(1, 0.5, 0.5)
    love.graphics.circle('fill', x, y, self.shape:getRadius())
  end,
}

return Ball
