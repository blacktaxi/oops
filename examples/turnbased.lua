local class = require 'oops'

--- Base class for players.
local Creature = class {
  -- initialize attributes
  __init = function (self, name, max_hit_points)
    self.name = name
    self.max_hit_points = max_hit_points

    self.hit_points = max_hit_points
  end,

  -- suffer some damage
  receive_damage = function (self, amount, cause)
    if self.hit_points > 0 then
      self.hit_points = self.hit_points - amount

      print(self.name .. ' suffers ' .. amount .. ' damage from ' ..
          cause .. ', has ' .. self.hit_points .. ' hit points left.')

      if self.hit_points <= 0 then
        print(self.name .. ' dies.')
      end
    else
      print(self.name .. ' is dead.')
    end
  end,

  -- receive some healing
  receive_healing = function (self, amount, cause)
    if self.hit_points > 0 then
      self.hit_points = math.min(self.hit_points + amount, self.max_hit_points)
      print(self.name .. ' is healed for ' .. amount ..
          ' hit points by ' .. cause .. ' and now has ' ..
          self.hit_points .. ' hit points left.')
    else
      print(self.name .. ' is dead and can not be healed. Use resurrection!')
    end
  end,

  -- true if player is alive
  is_alive = function (self)
    return self.hit_points > 0
  end,

  -- called when a player is supposed to make a turn
  make_a_turn = abstract_method
}

--- A mage. Casts fireballs.
local Mage = class(Creature) {
  __init = function (self, name)
    self.__super:__init(name, 30)
  end,

  FIREBALL_DAMAGE = 20,

  cast_fireball = function (self, game, target)
    game:attack(self, target, 'fireball', self.FIREBALL_DAMAGE)
  end,

  make_a_turn = function (self, game, opponent)
    self:cast_fireball(game, opponent)
  end
}

--- Priest. Operates by the holy light. Tries to resolve conflicts
-- in a peaceful way.
local Priest = class(Creature) {
  __init = function (self, name)
    self.__super:__init(name, 50)
  end,

  HOLY_LIGHT_DAMAGE = 5,
  HOLY_LIGHT_HEALING = 35,

  -- holy light causes damage to enemies and heals friends
  cast_holy_light = function (self, game, target)
    if target == self then
      game:heal(self, target, 'holy light', self.HOLY_LIGHT_HEALING)
    else
      game:attack(self, target, 'holy light', self.HOLY_LIGHT_DAMAGE)
    end
  end,

  make_a_turn = function (self, game, opponent)
    -- injured?
    if self.hit_points < 20 then
      -- heal self
      self:cast_holy_light(game, self)
    else
      -- give enemy a chance to repent ...
      if math.random(1, 10) > 2 then
        -- they deserve it
        self:cast_holy_light(game, opponent)
      else
        -- chastise them
        game:say(self, opponent.name .. ', turn to God before it\'s too late and surrender!')
      end
    end
  end
}

--- A ninja. Trained by high monks of Shaolin and posesses a deadly
-- technique of kick in the balls. Can't stand to lose a battle.
local Ninja = class(Creature) {
  __init = function (self, name)
    self.__super:__init(name, 100)
  end,

  BALL_STRIKE_DAMAGE = 10,

  kick_in_the_balls = function (self, game, target)
    game:attack(self, target, 'vicious balls strike', self.BALL_STRIKE_DAMAGE)
  end,

  make_a_turn = function (self, game, opponent)
    -- injured?
    if self.hit_points <= self.BALL_STRIKE_DAMAGE then
      -- perform suicide
      self:kick_in_the_balls(game, self)
    else
      -- trample 'em
      self:kick_in_the_balls(game, opponent)
    end
  end
}

--- The arena.
local Game = class {
  __init = function (self, player1, player2)
    self.player1 = player1
    self.player2 = player2

    -- Create an interface for player to interact with the game.
    -- Note the usage of anonymous class and it's instantiation in the
    -- same expression.
    self.game_interface = (class {
      attack = function (self, player, target, attack_name, damage)
        print(player.name .. ' attacks.')
        target:receive_damage(damage, player.name .. '\'s ' .. attack_name)
      end,

      heal = function (self, player, target, spell_name, healing)
        print(player.name .. ' casts a healing spell.')
        target:receive_healing(healing, player.name .. '\'s ' .. spell_name)
      end,

      say = function (self, player, message)
        print(player.name .. ' says: ' .. message)
      end
    })()
  end,

  player_turn = function (self, player, opponent)
    if player:is_alive() then
      player:make_a_turn(self.game_interface, opponent)
    else
      print(player.name .. ' lies dead like a bag of stones.')
    end
  end,

  game_turn = function (self)
    print('Turn ' .. self.current_turn)
    self:player_turn(self.player1, self.player2)
    self:player_turn(self.player2, self.player1)
  end,

  game_is_over = function (self)
    return (not self.player1:is_alive()) or (not self.player2:is_alive())
  end,

  winner = function (self)
    return self.player1:is_alive() and self.player1 or
        self.player2:is_alive() and self.player2
  end,

  run_game = function (self)
    print('------------------------------------------------------')
    print('The battle is about to start! Tonight, at the arena...')
    print(self.player1.name)
    print('VS')
    print(self.player2.name)
    print('...')
    print('FIGHT!')
    print()

    self.current_turn = 1
    while not self:game_is_over() do
      self:game_turn()
      self.current_turn = self.current_turn + 1
    end

    print('The fight is over, and the winner is...')
    print(self:winner().name)
    print('GLORY TO THE VICTORIOUS!')
  end
}

--
local mage_vs_priest = Game(Mage('Saruman'), Priest('Pope Benedict XVI'))
local mage_vs_ninja = Game(Mage('Merlin'), Ninja('Satoshi Nakamoto'))
local priest_vs_ninja = Game(Priest('Pastor Sam'), Ninja('Tokugawa Yoshimune'))

--
mage_vs_priest:run_game()
mage_vs_ninja:run_game()
priest_vs_ninja:run_game()



