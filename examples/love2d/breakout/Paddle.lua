local class = require('oops')
local PhysicsObject = require('PhysicsObject')

local function clamp(v, lo, hi)
  return math.max(lo, math.min(hi, v))
end

-- A spring is far easier to tune as "how fast does it wobble" plus "how quickly
-- does that wobble die out" than as raw stiffness/damping coefficients.
local function spring(hz, damping)
  local w = 2 * math.pi * hz
  return w * w, 2 * damping * w
end

local Paddle = class('Paddle', PhysicsObject) {
  __init = function(self, world, x, y)
    -- Dynamic, not kinematic. A kinematic body has infinite mass and ignores
    -- impulses, so the ball could never disturb it. Everything below is a force
    -- or a spring instead of a velocity assignment, which is what lets a ball
    -- impact fight the player's input rather than being overwritten by it.
    self.__super:__init(world, x, y, 100, 20, 'dynamic')

    self.restY = y

    -- Travel. Force-driven, so it winds up to speed instead of snapping to it.
    self.speed = 700 -- top speed, px/s
    self.thrust = 2800 -- acceleration ceiling, px/s^2
    self.grip = 9 -- how hard it chases the target speed

    -- Lean. A torque spring: ball impacts land in the same angular state the
    -- spring acts on, so a hit knocks the paddle off its lean and gets sprung
    -- back out. This is the part that rings after a hit.
    self.maxLean = math.rad(26)
    self.leanStiffness, self.leanDamping = spring(1.8, 0.45)

    -- Rail. Holds the paddle on its line, but as a spring rather than a hard pin
    -- so it can visibly dip under a hit and push back up.
    self.railStiffness, self.railDamping = spring(1.95, 0.5)

    self.body:setGravityScale(0)
    self.body:setSleepingAllowed(false) -- it must stay awake to receive forces

    -- Mass sets both the linear recoil and, through the shape, the moment of
    -- inertia. Go through density so Box2D derives the two consistently.
    -- This only governs how hard the ball disturbs the paddle, not how it
    -- steers: updateLean asks for an angular acceleration and scales it by the
    -- body's own inertia, so the steering feel stays put when you change this.
    self.mass = 16
    local meter = love.physics.getMeter()
    local area = (self.width / meter) * (self.height / meter)
    self.fixture:setDensity(self.mass / area)
    self.body:resetMassData()

    self.fixture:setRestitution(1)
    self.fixture:setFriction(0)
    -- Share a negative group with the walls so the two never collide: the paddle
    -- is bounded by clampToWindow below, and a leaning corner catching on a wall
    -- would otherwise spin it. The ball's group is 0, so it still hits both.
    self.fixture:setGroupIndex(-1)
    self.fixture:setUserData(self)
  end,

  -- Forces are integrated by the world step, so none of these need dt.
  update = function(self, dt)
    self:clampToWindow()
    self:drive()
    self:holdRail()
    self:updateLean()
  end,

  clampToWindow = function(self)
    local x = self.body:getX()
    local _, vy = self.body:getLinearVelocity()
    local hw = self.width / 2
    local windowWidth = love.graphics.getWidth()

    if x - hw < 0 then
      self.body:setX(hw)
      self.body:setLinearVelocity(0, vy)
    elseif x + hw > windowWidth then
      self.body:setX(windowWidth - hw)
      self.body:setLinearVelocity(0, vy)
    end
  end,

  drive = function(self)
    local dir = 0
    if love.keyboard.isDown('left') or love.keyboard.isDown('a') then
      dir = -1
    elseif love.keyboard.isDown('right') or love.keyboard.isDown('d') then
      dir = 1
    end

    -- Chase the target speed, but never harder than the thrust ceiling -- that
    -- ceiling is what you see as the wind-up.
    local vx = self.body:getLinearVelocity()
    local accel = clamp((dir * self.speed - vx) * self.grip, -self.thrust, self.thrust)

    self.body:applyForce(accel * self.body:getMass(), 0)
  end,

  holdRail = function(self)
    local _, vy = self.body:getLinearVelocity()
    local accel = self.railStiffness * (self.restY - self.body:getY()) - self.railDamping * vy

    self.body:applyForce(0, accel * self.body:getMass())
  end,

  updateLean = function(self)
    local vx = self.body:getLinearVelocity()
    local target = self.maxLean * clamp(vx / self.speed, -1, 1)

    -- Spring in angular acceleration, then convert to torque with the body's own
    -- inertia. That keeps the tuning independent of both the paddle's mass and
    -- the pixels-per-meter scale, since rad/s^2 reads the same in either unit.
    local accel = self.leanStiffness * (target - self.body:getAngle())
      - self.leanDamping * self.body:getAngularVelocity()

    self.body:applyTorque(accel * self.body:getInertia())
  end,
}

return Paddle
