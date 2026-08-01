local class = require('oops')
local PhysicsObject = require('PhysicsObject')
local Piece = require('Piece')

-- A brick soaks up impact energy and passes through two thresholds: at fallAt it
-- comes loose and drops, at breakAt it comes apart into debris. Kinds differ only
-- in where those two thresholds sit, which covers everything from glass that
-- shatters on contact to stone that needs working at.
local Brick = class('Brick', PhysicsObject) {
  __init = function(self, world, objects, x, y, width, height, kind, nominalImpulse)
    self.__super:__init(world, x, y, width, height, 'static')

    self.objects = objects
    self.kind = kind
    self.state = 'intact'
    self.energy = 0

    -- Damage is priced in nominal hits. Energy goes as the square of impulse
    -- (E = p^2 / 2m), so crediting impulse^2 against the ball's square-on impulse
    -- makes a threshold of 1.0 mean exactly one such strike, and makes a faster
    -- strike worth quadratically more rather than merely counting contacts. It
    -- also means a brick resting its weight on another deposits ~0.0003 of a hit
    -- per step, so static loads can never grind a brick apart.
    self.hitScale = 1 / (nominalImpulse * nominalImpulse)

    self.fixture:setRestitution(1)
    self.fixture:setFriction(0)
    self.fixture:setUserData(self)
  end,

  -- Called from postSolve, so it may only accumulate. Box2D forbids creating or
  -- destroying bodies inside a callback, so the thresholds are acted on in
  -- update() instead, which runs outside the world step.
  absorb = function(self, impulse)
    if self.state ~= 'shattered' then
      self.energy = self.energy + impulse * impulse * self.hitScale
    end
  end,

  cleared = function(self)
    return self.state ~= 'intact'
  end,

  update = function(self)
    if self.state == 'shattered' then
      return
    end

    -- Checked in this order so that one big enough hit skips straight past the
    -- falling stage and takes the brick apart where it stands.
    if self.energy >= self.kind.breakAt then
      self:shatter()
    elseif self.state == 'intact' and self.energy >= self.kind.fallAt then
      self:dislodge()
    end
  end,

  dislodge = function(self)
    self.state = 'falling'
    self.body:setType('dynamic')
    self.body:applyAngularImpulse(love.math.random(-1000, 1000))
    self.fixture:setRestitution(0.2)
  end,

  shatter = function(self)
    local world = self.body:getWorld()
    local shards = self.kind.shards or { 3, 2 }
    local cols, rows = shards[1], shards[2]
    local pieceWidth, pieceHeight = self.width / cols, self.height / rows

    for col = 0, cols - 1 do
      for row = 0, rows - 1 do
        local localX = -self.width / 2 + pieceWidth * (col + 0.5)
        local localY = -self.height / 2 + pieceHeight * (row + 0.5)

        table.insert(
          self.objects.pieces,
          Piece(world, self, localX, localY, pieceWidth, pieceHeight)
        )
      end
    end

    -- Pieces read the brick's transform, so the body only goes once they exist.
    self.state = 'shattered'
    self.body:destroy()
  end,

  draw = function(self)
    if self.state == 'shattered' then
      return
    end

    local x, y = self.body:getPosition()
    local color = self.kind.color
    -- Darken with accumulated damage, so a brick's remaining life is readable
    -- before it comes apart rather than only in hindsight.
    local wear = math.min(self.energy / self.kind.breakAt, 1)
    local shade = 1 - wear * 0.55

    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(self.body:getAngle())

    love.graphics.setColor(color[1] * shade, color[2] * shade, color[3] * shade)
    love.graphics.rectangle('fill', -self.width / 2, -self.height / 2, self.width, self.height)

    if self.kind.explosive then
      love.graphics.setColor(1, 0.9, 0.35)
      love.graphics.rectangle(
        'line',
        -self.width / 2 + 3,
        -self.height / 2 + 3,
        self.width - 6,
        self.height - 6
      )
    end

    love.graphics.pop()
  end,

  __class = {
    -- Thresholds are in nominal ball hits. Note that a dislodged brick usually
    -- falls out of play before it can soak up more, so breakAt mostly decides
    -- what happens on one hard strike, or in the collisions on the way down.
    kinds = {
      -- Shatters on contact: breakAt is reached before it can ever come loose.
      { name = 'glass', fallAt = 0.5, breakAt = 0.5, color = { 0.55, 0.8, 0.95 }, weight = 22 },
      -- Roughly how every brick behaved before: one touch and it drops.
      { name = 'plain', fallAt = 0.7, breakAt = 2.2, color = { 0.85, 0.45, 0.4 }, weight = 38 },
      -- Needs working at before it will budge at all.
      { name = 'stone', fallAt = 2.4, breakAt = 5.5, color = { 0.45, 0.45, 0.55 }, weight = 30 },
      -- Uncommon, and its debris stays solid -- see Piece. Splits into fewer,
      -- heavier chunks than the others and throws them hard enough to knock its
      -- neighbours loose, which is what makes it worth aiming at.
      {
        name = 'volatile',
        fallAt = 1.0,
        breakAt = 1.6,
        color = { 1.0, 0.7, 0.2 },
        weight = 10,
        explosive = true,
        shards = { 2, 2 }, -- twice the mass per piece of an ordinary break
        blast = 480, -- px/s, thrown radially; see Piece
      },
    },

    randomKind = function(cls)
      local total = 0
      for _, kind in ipairs(cls.kinds) do
        total = total + kind.weight
      end

      local roll = love.math.random() * total
      for _, kind in ipairs(cls.kinds) do
        roll = roll - kind.weight
        if roll <= 0 then
          return kind
        end
      end

      return cls.kinds[1]
    end,

    createGrid = function(cls, world, objects, cols, rows, brickWidth, brickHeight)
      local bricks = {}
      local padding = 10
      local offsetX = (love.graphics.getWidth() - (cols * (brickWidth + padding))) / 2
      local offsetY = 50
      -- Bricks price their damage against the ball, so it has to exist already.
      local nominalImpulse = objects.ball:nominalImpulse()

      for row = 1, rows do
        for col = 1, cols - 2 do
          local x = offsetX + col * (brickWidth + padding) + brickWidth / 2
          local y = offsetY + row * (brickHeight + padding) + brickHeight / 2

          table.insert(
            bricks,
            cls(world, objects, x, y, brickWidth, brickHeight, cls:randomKind(), nominalImpulse)
          )
        end
      end

      return bricks
    end,
  },
}

return Brick
