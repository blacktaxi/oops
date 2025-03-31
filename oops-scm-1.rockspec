-- This rockspec is only used for running tests.
rockspec_format = "1.0"
package = "oops"
version = "scm-1"
source = {
  url = "git://github.com/blacktaxi/oops.git"
}

description = {
  license = "BSD"
}

dependencies = {
  "lua >= 5.1",
  "busted >= 2.0.0",
  "luacheck",
  "mobdebug",
  "moses",
  "inspect"
}

build = {
  type = "builtin",
  modules = {
    oops = "lib/oops.lua"
  }
}
