-- This rockspec is only used for running tests.
package = "oops"
version = "scm-0"

dependencies = {
   "lua >= 5.1",
   "inspect",
   "moses",
   "telescope"
}

build = {
  type = "builtin",
  modules = {
    oops = "lib/oops.lua"
  }
}
