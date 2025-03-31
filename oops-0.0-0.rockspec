package = "oops"
version = "0.0-0"
source = {
	url = "git://github.com/blacktaxi/oops.git"
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
	type = "builtin"
}
