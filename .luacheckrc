std = 'lua54'

globals = {
  -- allow test frameworks or engine globals
  'describe',
  'it',
  'assert', -- for busted
  'jit',
}

ignore = {
  -- "211", -- unused local variable
  -- "212", -- unused argument
}

read_globals = {
  -- "vim", -- if writing for Neovim
}

-- Optional: disable warnings in tests
files['tests/.*%.lua$'] = {
  ignore = {
    '111', -- global variable
    '112', -- unused global
  },
}
