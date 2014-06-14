#!/bin/sh
luarocks make oops-scm-0.rockspec
tsc -f test/*.lua