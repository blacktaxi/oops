local class = require('oops')

--- Base class for all characters
local Character = class {
  __init = function(self, name, max_hit_points)
    self.name = name
    self.max_hit_points = max_hit_points
    self.hit_points = max_hit_points
  end,

  receive_damage = function(self, amount, cause)
    if self.hit_points > 0 then
      self.hit_points = self.hit_points - amount
      print(
        ('%s takes %d damage from %s (HP: %d)'):format(self.name, amount, cause, self.hit_points)
      )

      if self.hit_points <= 0 then
        print(self.name .. ' has fallen.')
      end
    else
      print(self.name .. ' is already out of the fight.')
    end
  end,

  receive_healing = function(self, amount, cause)
    if self.hit_points > 0 then
      self.hit_points = math.min(self.hit_points + amount, self.max_hit_points)
      print(
        ('%s is healed by %s for %d HP (HP: %d)'):format(self.name, cause, amount, self.hit_points)
      )
    else
      print(self.name .. ' in unconscious and cannot be healed.')
    end
  end,

  is_alive = function(self)
    return self.hit_points > 0
  end,

  make_a_turn = function(self)
    error('Not implemented')
  end,
}

--- Mage: high damage, low health
local Mage = class(Character) {
  __init = function(self, name)
    self.__super:__init(name, 30)
  end,

  FIREBALL_DAMAGE = 20,

  cast_fireball = function(self, game, target)
    game:attack(self, target, 'fireball', self.FIREBALL_DAMAGE)
  end,

  make_a_turn = function(self, game, opponent)
    self:cast_fireball(game, opponent)
  end,
}

--- Healer: supports or smites
local Healer = class(Character) {
  __init = function(self, name)
    self.__super:__init(name, 50)
  end,

  SMITE_DAMAGE = 5,
  HEAL_AMOUNT = 35,

  cast_holy_light = function(self, game, target)
    if target == self then
      game:heal(self, target, 'holy light', self.HEAL_AMOUNT)
    else
      game:attack(self, target, 'holy light', self.SMITE_DAMAGE)
    end
  end,

  make_a_turn = function(self, game, opponent)
    if self.hit_points < 20 then
      -- Low health -- heal self
      self:cast_holy_light(game, self)
    else
      -- Occasionally speaks instead of attacking
      if math.random(1, 10) > 2 then
        self:cast_holy_light(game, opponent)
      else
        game:say(self, opponent.name .. ", turn to peace before it's too late!")
      end
    end
  end,
}

--- Ranger: tactical melee attacker
local Ranger = class(Character) {
  __init = function(self, name)
    self.__super:__init(name, 100)
  end,

  STRIKE_DAMAGE = 10,

  vicious_strike = function(self, game, target)
    game:attack(self, target, 'vicious strike', self.STRIKE_DAMAGE)
  end,

  make_a_turn = function(self, game, opponent)
    if self.hit_points <= self.STRIKE_DAMAGE then
      -- dramatic self-KO
      game:say(self, opponent.name .. ', you will not defeat ' .. self.name .. '!')
      self:vicious_strike(game, self)
    else
      self:vicious_strike(game, opponent)
    end
  end,
}

--- Game engine
local Game = class {
  __init = function(self, character1, character2)
    self.character1 = character1
    self.character2 = character2

    -- Interface for Character to interact with the game.
    -- Note the usage of anonymous class and it's instantiation in the
    -- same expression.
    self.game_interface = (class {
      attack = function(_, attacker, target, name, damage)
        print(attacker.name .. ' casts ' .. name .. '!')
        target:receive_damage(damage, attacker.name .. "'s " .. name)
      end,

      heal = function(_, healer, target, name, amount)
        print(healer.name .. ' casts ' .. name .. '!')
        target:receive_healing(amount, healer.name .. "'s " .. name)
      end,

      say = function(_, speaker, message)
        print(speaker.name .. ' says: ' .. message)
      end,
    })()
  end,

  character_turn = function(self, character, opponent)
    if character:is_alive() then
      character:make_a_turn(self.game_interface, opponent)
    else
      print(character.name .. ' is unable to act.')
    end
  end,

  game_turn = function(self)
    print('=== Turn ' .. self.current_turn .. ' ===')
    self:character_turn(self.character1, self.character2)
    self:character_turn(self.character2, self.character1)
    print() -- space after each turn
  end,

  game_is_over = function(self)
    return not (self.character1:is_alive() and self.character2:is_alive())
  end,

  winner = function(self)
    return self.character1:is_alive() and self.character1 or self.character2
  end,

  run_game = function(self)
    print('🏟️  Welcome to the Arena!')
    print(self.character1.name .. ' VS ' .. self.character2.name)
    print('🔥 FIGHT! 🔥\n')

    self.current_turn = 1
    while not self:game_is_over() do
      self:game_turn()
      self.current_turn = self.current_turn + 1
    end

    print('🏁 The match is over!')
    print('🏆 Winner: ' .. self:winner().name)
    print('----------------------------------------\n')
  end,
}

-- Run a few battles
Game(Mage('Circe'), Healer('Elowen')):run_game()
Game(Mage('Merlin'), Ranger('Ash')):run_game()
Game(Healer('Liora'), Ranger('Thorne')):run_game()
