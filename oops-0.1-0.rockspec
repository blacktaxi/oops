package = "oops"
version = "0.1-0"
source = {
  url = "git://github.com/blacktaxi/oops.git",
  tag = "v0.1",
}

description = {
  summary = "OOP with concise syntax and local classes.",
  detailed = [[
    Oops is an OOP library for Lua with class-based inheritance.
    It supports ad-hoc class definition with very concise syntax and single
    inheritance.
    It is also rather performant and the most basic class is nothing more
    than a table with initializer.
  ]],
  homepage = "https://github.com/blacktaxi/oops",
  license = "BSD",
}

dependencies = {
  "lua >= 5.1",
}

build = {
  type = "builtin",
  modules = {
    oops = "lib/oops.lua"
  }
}
