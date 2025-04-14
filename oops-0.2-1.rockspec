rockspec_format = "1.0"
package = "oops"
version = "0.2-1"
source = {
  url = "git://github.com/blacktaxi/oops.git",
  tag = "v0.2",
}

description = {
  summary = "Lightweight class-based OOP with concise syntax and local class support.",

  detailed = [[
    Oops is a lightweight object-oriented programming (OOP) library for Lua,
    offering class-based inheritance and a clean, expressive syntax.

    It supports:
    - Concise inline class definitions
    - Anonymous and local classes
    - Single inheritance with superclass member access
    - Class fields/methods
    - Metamethods with inheritance

    Oops is fast and minimal — the simplest class is just a table with an initializer.
    It's designed to be easy to use, easy to extend, and suitable for both scripting
    and larger projects.
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
    oops = "src/oops.lua"
  }
}
