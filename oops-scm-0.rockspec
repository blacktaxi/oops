-- This rockspec is only used for running tests.
package = "oops"
version = "scm-0"
source = {
  url = "git://github.com/blacktaxi/oops.git"
}

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
