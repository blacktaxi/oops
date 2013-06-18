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

  local classdef = classdef or {}

  local cls = {
    __parent = parentclass,
    -- "inherit" class definition from parent class
    __classdef = 
      parentclass and setmetatable(classdef, { __index = parentclass.__classdef })
      or classdef,

    --- Instance constructor.
    __create = function(cls)
      -- call superclass constructor
      local super = parentclass and cls.__parent:__create() or nil

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
      return super and setmetatable(instance, { __index = super }) or instance
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
-- @usage anon_class = class { <classdef>... }
-- @usage Class = class("Class") { <classdef>... }
-- @usage anon_class = class(ParentClass) { <classdef>... }
-- @usage anon_class = class(nil, ParentClass) { <classdef>... }
-- @usage Class = class("Class", ParentClass) { <classdef>... }
class = function(...)
  local arg_count = select('#', ...)
  if arg_count == 1 then
    -- class(ParentClass) { ... }
    -- class("Name") { ... }
    -- class(nil) { ... }
    -- class { ... }
    local a = ...

    if (isclass(a)) then
      -- class(ParentClass) { ... }
      return function (classdef)
        return new_class(nil, a, classdef)
      end
    elseif type(a) == 'table' then
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
  error('Abstract method call: inst of ' .. self.__class.__name .. ' with args', ...)
end

return {
  class = class,
  isclass = isclass,
  isobject = isobject,
  abstract_method = abstract_method
}