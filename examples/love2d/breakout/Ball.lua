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
    -- Pairs with the paddle's 0.5 for a mixed friction of exactly 0.5. Walls and
    -- bricks stay at 0, so sqrt(a*b) keeps them frictionless: spin is only ever
    -- exchanged with the paddle.
    self.fixture:setFriction(0.5)
    self.fixture:setUserData(self)

    self.body:setBullet(true) -- prevent tunneling
    self.body:setLinearDamping(0) -- no drag
    self.body:setAngularDamping(0)

    -- Speed floor for when gravity alone doesn't demand more, and a ceiling so
    -- that a hard paddle swat can't run away with it.
    self.speed = 450
    self.maxSpeed = 1150
    -- How fast the ball should still be at the top of the field. Gravity makes it
    -- slowest exactly where the bricks are, so this, not the launch speed, is what
    -- governs the pace of the part of the game you actually watch.
    self.apexSpeed = 480
    self.headroom = 1.05 -- margin on top of merely clearing the climb
    self.maxLaunchAngle = math.rad(45) -- widest launch that still reaches a brick

    -- The ball must always be able to climb back to the ceiling, so that height
    -- is what the energy calculations below are measured against.
    self.apexY = self.shape:getRadius()
  end,

  -- The speed^2 that climbing to apexY costs, straight out of 1/2 v^2 = g*h.
  -- Read from the world's own gravity, so retuning gravity retunes this too.
  climbCost = function(self)
    local _, gravity = self.body:getWorld():getGravity()

    return 2 * gravity * math.max(0, self.body:getY() - self.apexY)
  end,

  -- Upward speed needed to just barely clear that climb.
  climbSpeed = function(self)
    return math.sqrt(self:climbCost()) * self.headroom
  end,

  -- Total speed needed along (dx, dy), against two separate requirements.
  speedFor = function(self, dx, dy)
    local cost = self:climbCost()

    -- Pace. Gravity bills the ball for height and nothing else, so at the top it
    -- still has sqrt(s^2 - 2gh) whatever its heading -- making this term entirely
    -- direction-free. Without it the ball merely arrives at the brick field,
    -- crawling, which is the one place it wants to be lively.
    local needed = math.sqrt(self.apexSpeed * self.apexSpeed + cost)

    -- Reach. Only the upward share of the heading buys height, so a shallow shot
    -- needs proportionally more speed to make the same climb. This is the term
    -- that matters once lean and friction start angling the returns over.
    local len = math.sqrt(dx * dx + dy * dy)
    local upward = len > 0 and -dy / len or 1

    if upward > 0 then
      needed = math.max(needed, math.sqrt(cost) * self.headroom / upward)
    end

    return clamp(needed, self.speed, self.maxSpeed)
  end,

  -- How much of the paddle's motion the ball leaves with, solved so that a
  -- full-speed sweep lands exactly on maxLaunchAngle. Deriving it beats picking a
  -- constant: it depends on the paddle's top speed, its lean and the ball's own
  -- speed, so any of those three moving used to silently push the top of the
  -- sweep range past the cone, where it clamped and went dead.
  carryFactor = function(self, base)
    local paddle = self.objects.paddle
    local widest = math.cos(paddle.maxLean) * math.tan(self.maxLaunchAngle)

    return math.max(0, base * (widest - math.sin(paddle.maxLean)) / paddle.speed)
  end,

  launch = function(self)
    if not self.launched then
      self.launched = true

      -- Fire along the paddle's face, so leaning aims the shot...
      local paddle = self.objects.paddle
      local nx, ny = paddle:surfaceNormal()
      -- Only used to mix the normal against the carried velocity in sensible
      -- proportion; the shot's actual speed comes from the direction that falls
      -- out of it, below.
      local base = self:climbSpeed()

      -- ...plus the paddle's own sideways motion, since the ball is riding it
      -- and leaves carrying it. Velocity leads where lean lags: lean is a spring
      -- driven by velocity, so it takes a couple of tenths of a second to build,
      -- while the velocity is there the instant you move. Sweeping and launching
      -- therefore steers the shot immediately, rather than only after a sustained
      -- run-up long enough for the lean to catch up.
      local pvx = paddle.body:getLinearVelocity()
      local dx = nx * base + pvx * self:carryFactor(base)
      local dy = ny * base

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

      -- Sweep steers the shot; the speed is then whatever that heading needs to
      -- still make the climb, so a flatter launch is a faster one.
      local speed = self:speedFor(dx, dy)
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
      -- Held means fully controlled, spin included. The clearance above means
      -- nothing is actually touching the ball, so there is no friction to arrest
      -- the spin it arrived with and it would keep turning on the paddle forever.
      self.body:setAngularVelocity(0)
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
    local needed = self:speedFor(vx, vy)

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
    local radius = self.shape:getRadius()

    love.graphics.setColor(1, 0.5, 0.5)
    love.graphics.circle('fill', x, y, radius)

    -- Spin carries over between hits and reverses the next one's deflection, so
    -- it has to be legible. Without a marker the ball's rotation is invisible and
    -- the english it produces just looks like the ball misbehaving.
    local angle = self.body:getAngle()
    love.graphics.setColor(0.5, 0.15, 0.15)
    love.graphics.setLineWidth(2)
    love.graphics.line(x, y, x + math.cos(angle) * radius, y + math.sin(angle) * radius)
    love.graphics.setLineWidth(1)
  end,
}

return Ball
