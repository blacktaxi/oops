-- LÖVE's package.path loader resolves against the process working directory, so
-- cover both ways of launching: from the repo root and from this game directory.
package.path = 'src/?.lua;../../../src/?.lua;' .. package.path
local class = require('oops')

-- Global physics world
local world

-- Game object manager
local objects = {}

-- Game state
local game = {
  lives = 300,
  started = false,
}

local function resetBall()
  objects.ball.body:setLinearVelocity(0, 0)
  objects.ball.body:setPosition(objects.paddle.body:getX(), 550)
  objects.ball.launched = false
end

local function checkVictory()
  for _, b in ipairs(objects.bricks) do
    if not b:cleared() then
      return false
    end
  end
  return true
end

function love.load()
  love.window.setMode(800, 600)
  love.window.setTitle('Breakout with Physics + OOP')

  world = love.physics.newWorld(0, 0, true)
  -- Gravity sets the ball's speed floor: it has to leave the paddle fast enough
  -- to climb back to the ceiling, so heavier gravity forces a faster ball. This
  -- is what spreads the ball's speed between the paddle line and the ceiling.
  -- Lighter gravity narrows that spread, which is what keeps the ball from
  -- crawling through the brick field; Ball.apexSpeed sets where the slow end of
  -- it lands.
  world:setGravity(0, 250)

  -- Load class modules (we’ll define these soon)
  local Paddle = require('Paddle')
  local Ball = require('Ball')
  local Brick = require('Brick')
  local Wall = require('Wall')
  local SpringPaddle = require('SpringPaddle')

  -- Create world elements
  -- objects.paddle = SpringPaddle(world, 400, 550, 120, 20)
  -- 555, not 580: leaning swings the low corner ~34px below centre, and a hit
  -- landing at full lean adds the recoil dip on top of that.
  objects.paddle = Paddle(world, 400, 555)
  objects.ball = Ball(world, objects, 400, 550)
  objects.walls = Wall:createBounds(world, 800, 600)
  objects.pieces = {}
  objects.bricks = Brick:createGrid(world, objects, 10, 5, 80, 30)

  game.started = false

  local function beginContact(a, b)
    local objA = a:getUserData()
    local objB = b:getUserData()

    for _, pair in ipairs {
      { objA, objB },
      { objB, objA },
    } do
      local hitter, target = pair[1], pair[2]

      -- Walls and bricks are perfectly elastic, so they need no help -- the ball
      -- keeps whatever energy it launched with. Only the paddle tops it back up,
      -- and Ball:restoreEnergy does that as a floor rather than a per-bounce
      -- multiplier, so returns cannot compound into a runaway.
      if
        hitter
        and class.isinstanceof(hitter, Ball)
        and target
        and class.isinstanceof(target, Paddle)
      then
        hitter.returned = true
      end
    end
  end

  -- Bricks take damage from the real contact impulse rather than from a hit
  -- count, which is why this hangs off postSolve: it is the only callback that
  -- runs after the solver and knows what the collision actually cost. Any impact
  -- counts, not just the ball's, so a falling brick can carry others down with it.
  local function postSolve(a, b, contact, normalImpulse1, tangentImpulse1, normalImpulse2)
    local impulse = normalImpulse1 + (normalImpulse2 or 0)
    local objA, objB = a:getUserData(), b:getUserData()

    if class.isinstanceof(objA, Brick) then
      objA:absorb(impulse)
    end

    if class.isinstanceof(objB, Brick) then
      objB:absorb(impulse)
    end
  end

  world:setCallbacks(beginContact, nil, nil, postSolve)
end

function love.update(dt)
  world:update(dt)

  if objects.paddle then
    objects.paddle:update(dt)
  end

  if objects.ball then
    objects.ball:update(dt)
  end

  -- Bricks cross their thresholds here rather than in the contact callback,
  -- because dislodging and shattering create and destroy bodies, which Box2D
  -- only permits outside the world step.
  for _, brick in ipairs(objects.bricks) do
    brick:update(dt)
  end

  -- Retire debris once it has left the field, or it accumulates for the whole game.
  for i = #objects.pieces, 1, -1 do
    local piece = objects.pieces[i]

    if piece.body:getY() > love.graphics.getHeight() + 60 then
      piece.body:destroy()
      table.remove(objects.pieces, i)
    end
  end

  -- Ball below screen
  if objects.ball.body:getY() > love.graphics.getHeight() + 30 then
    game.lives = game.lives - 1
    if game.lives > 0 then
      resetBall()
      game.started = false
    else
      game.over = true
    end
  end

  -- Victory check
  if not game.won and checkVictory() then
    game.won = true
  end
end

function love.draw()
  love.graphics.clear(0.1, 0.1, 0.15)

  -- Draw all game objects
  if objects.paddle then
    objects.paddle:draw()
  end

  if objects.ball then
    objects.ball:draw()
  end

  if objects.bricks then
    for _, b in ipairs(objects.bricks) do
      b:draw()
    end
  end

  if objects.pieces then
    for _, p in ipairs(objects.pieces) do
      p:draw()
    end
  end

  love.graphics.setColor(1, 1, 1)
  love.graphics.print('Lives: ' .. game.lives, 10, 10)

  if game.over then
    love.graphics.printf('Game Over!', 0, 280, 800, 'center')
  elseif game.won then
    love.graphics.printf('You Win!', 0, 280, 800, 'center')
  end
end

function love.keypressed(key)
  if key == 'space' then
    if not game.started then
      objects.ball:launch()
      game.started = true
    end
  end
end
