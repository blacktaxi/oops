package = "oops"
version = "scm-0"
source = {
   url = "git://github.com/blacktaxi/oops.git",
}

description = {
   summary = "Simple OOP with classes.",
   detailed = [[
      Oops is an OOP library for Lua with class-based inheritance.
   ]],
   license = "BSD"
}

dependencies = {
   "lua >= 5.1"
}

build = {
  type = "builtin",
  modules = {
    oops = "lib/oops.lua"
  }
}