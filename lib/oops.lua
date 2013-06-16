--- Oops is a class-based inheritance OOP library for Lua with controlled 
-- class scope (local and anonymous classes) and succinct syntax.
-- @release 0.1
-- @class module
-- @module 'oops'
-- @author Sergey Yavnyi

isclass = function (x)
  return type(x) == 'table' and type(x.__classdef) == 'table'
end

isobject = function (x)
  return type(x) == 'table' and isclass(x.__class)
end

--- The root class. All classes inherit from the root class.
local root_class = {
  __classdef = {},
  __parent = nil,
  __name = "<root>",

  __create = function(cls)
    return {
      __class = cls,
      __super = nil
    }
  end
}

--- Creates a class table.
-- @param name Class name.
-- @param parentclass Parent class. Optional.
-- @param classef Class definition table.
local new_class = function (name, parentclass, classdef)
  -- typecheck arguments
  assert(
    (type(name) == 'nil' or type(name) == 'string')
    and (type(parentclass) == 'nil' or isclass(parentclass))
    and (type(classdef) == 'nil' or type(classdef) == 'table')
  )

  local parentclass = parentclass or root_class
  local classdef = classdef or {}

  local cls = {
    __parent = parentclass,
    -- "inherit" class definition from parent class
    __classdef = setmetatable(classdef, { __index = parentclass.__classdef }),

    --- Instance constructor.
    __create = function(cls)
      -- call superclass constructor
      local super = cls.__parent:__create()

      -- create instance object and initialize it with
      -- class-defined attributes
      local instance = {}
      for k, v in pairs(cls.__classdef) do
        instance[k] = v
      end

      instance.__super = super
      instance.__class = cls

      -- attributes not present in this instance will be
      -- indexed from parent class instance
      setmetatable(instance, { __index = super })

      return instance
    end,
  }

  -- Assign class name.
  cls.__name = name or ('<class@' .. tostring(cls) .. '>')

  return setmetatable(cls, {
    --- User constructor.
    __call = function(cls, ...)
      local i = cls:__create()

      -- call init method, if any
      if i.__init then
        i:__init(...)
      end

      return i
    end
  })
end

--- Defines a new class.
-- @usage Class = class("Class") { <classdef>... }
-- @usage Class = class("Class", ParentClass) { <classdef>... }
-- @usage anon_class = class { <classdef>... }
-- @usage anon_class = class(nil, ParentClass) { <classdef>... }
class = function(...)
  local arg_count = select('#', ...)
  if arg_count == 1 then
    -- class("Name") { ... }
    -- class(nil) { ... }
    -- class { ... }
    local a = ...

    if type(a) == 'table' and (not isclass(a)) then
      -- class { ... }
      return new_class(nil, nil, a)
    elseif type(a) == 'string' or type(a) == nil then
      -- class("Name") { ... }
      -- class(nil) { ... }
      return function (classdef)
        return new_class(a, nil, classdef)
      end
    else
      -- invalid arg
      error('Invalid argument type. Expected class name or classdef, got: ' .. (a))
    end
  elseif arg_count == 2 then
    -- class("Name", Parent) { ... }
    -- class("Name", nil) { ... }
    -- class(nil, Parent) { ... }
    -- class(nil, nil) { ... }
    local name, parent = ...
    return function (classdef)
      return new_class(name, parent, classdef)
    end
  else
    error('Expected 1 or 2 arguments, got ' .. arg_count)
  end
end

--- Abstract method placeholder.
abstract_method = function(self, ...)
  error('Abstract method call: inst of ' ..self.__class__.__name__.. ' with args', ...)
end

return {
  class = class,
  isclass = isclass,
  isobject = isobject,
  abstract_method = abstract_method
}