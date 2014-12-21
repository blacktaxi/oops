--- OOP library for Lua with terse syntax.
-- @release 0.1
-- @class module
-- @name 'oops'
-- @author Sergey Yavnyi <blacktaxi@gmail.com>

--- 'Is a class' check.
local isclass = function (x)
  return type(x) == 'table' and type(x.__classdef) == 'table'
end

--- 'Is an object' check.
local isobject = function (x)
  return type(x) == 'table' and isclass(x.__class)
end

--- 'Is an instance of' check.
-- @param x Object that is tested for being an instance of class.
-- @param cls A class that the object is tested against.
-- @return Returns `true` if `obj` is an immediate instance of `cls` or one of it's ancestors.
local function isinstanceof(obj, cls)
  return isobject(obj) and isclass(cls) and 
    (obj.__class == cls or (obj.__super and isinstanceof(obj.__super, cls)))
end

--- Creates a class table.
-- @param name Class name.
-- @param parentclass Parent class. Optional.
-- @param classef Class definition table.
local new_class_internal = function (name, parentclass, classdef)
  -- typecheck arguments
  assert(
    (type(name) == 'nil' or type(name) == 'string')
    and (type(parentclass) == 'nil' or isclass(parentclass))
    and (type(classdef) == 'nil' or type(classdef) == 'table'),
    "Invalid arguments"
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

      local instanceid = tostring(instance)
      local tostringfn = function ()
        return '<object of ' .. tostring(cls) .. ': ' .. instanceid .. '>'
      end

      -- attributes not present in this instance will be
      -- indexed from parent class instance
      return super and setmetatable(instance, { __index = super, __tostring = tostringfn })
             or setmetatable(instance, { __tostring = tostringfn })
    end,
  }

  -- Assign class name.
  cls.__name = name or (tostring(cls))

  return setmetatable(cls, {
    --- User constructor.
    __call = function(cls, ...)
      local i = cls:__create()

      -- call init method, if any
      if i.__init then
        i:__init(...)
      end

      return i
    end,

    __tostring = function()
      return '<class: ' .. cls.__name .. '>'
    end
  })
end

--- Defines a new class.
-- @usage anon_class = class { <classdef>... }
-- @usage Class = class("Class") { <classdef>... }
-- @usage anon_class = class(ParentClass) { <classdef>... }
-- @usage anon_class = class(nil, ParentClass) { <classdef>... }
-- @usage Class = class("Class", ParentClass) { <classdef>... }
local class = function(...)
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
        return new_class_internal(nil, a, classdef)
      end
    elseif type(a) == 'table' then
      -- class { ... }
      return new_class_internal(nil, nil, a)
    elseif type(a) == 'string' or type(a) == nil then
      -- class("Name") { ... }
      -- class(nil) { ... }
      return function (classdef)
        return new_class_internal(a, nil, classdef)
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
      return new_class_internal(name, parent, classdef)
    end
  else
    error('Expected 1 or 2 arguments, got ' .. arg_count)
  end
end

local MODULE = {
  class = class,
  isclass = isclass,
  isobject = isobject,
  isinstanceof = isinstanceof,
}

-- Add a shortcut for defining classes.
setmetatable(MODULE, {
  __call = function(_, ...) return class(...) end
})

return MODULE
