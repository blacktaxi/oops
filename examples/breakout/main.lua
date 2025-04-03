package.path = 'src/?.lua;' .. package.path

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
    if not b.destroyed then
      return false
    end
  end
  return true
end

function love.load()
  love.window.setMode(800, 600)
  love.window.setTitle('Breakout with Physics + OOP')

  world = love.physics.newWorld(0, 0, true)
  world:setGravity(0, 500)

  -- Load class modules (we’ll define these soon)
  PhysicsObject = require('PhysicsObject')
  Paddle = require('Paddle')
  Ball = require('Ball')
  Brick = require('Brick')
  Wall = require('Wall')

  -- Create world elements
  objects.paddle = Paddle(world, 400, 580)
  objects.ball = Ball(world, objects, 400, 550)
  objects.walls = Wall:createBounds(world, 800, 600)
  objects.bricks = Brick:createGrid(world, 10, 5, 80, 30)

  game.started = false

  world:setCallbacks(function(a, b, contact)
    local objA = a:getUserData()
    local objB = b:getUserData()

    -- Brick destruction
    for _, pair in ipairs {
      { objA, objB },
      { objB, objA },
    } do
      local hitter, target = pair[1], pair[2]
      -- print('collided', hitter, target)
      if target and target.__class.__name == 'Brick' then
        target:destroy()
      end

      if hitter.__class.__name == 'Ball' and target.__class.__name == 'Paddle' then
        local vx, vy = hitter.body:getLinearVelocity()
        hitter.body:setLinearVelocity(vx, vy - 150) -- give it a small boost
      end
    end
  end)
end

function love.update(dt)
  world:update(dt)

  if objects.paddle then
    objects.paddle:update(dt)
  end

  if objects.ball then
    objects.ball:update(dt)
  end

  for _, brick in ipairs(objects.bricks) do
    brick:update(dt)
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
