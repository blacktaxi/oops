--- Lightweight class-based OOP for Lua with concise syntax and local classes.
-- @module oops
-- @release 0.2
-- @author Serhii Yavnyi <blacktaxi@gmail.com>
-- @license BSD

--- Checks whether a value is a class created by `oops`.
-- @param x any: The value to check.
-- @return boolean: `true` if `x` is a class, `false` otherwise.
local isclass = function(x)
  return type(x) == 'table' and type(x.__classdef) == 'table'
end

--- Checks whether a value is an instance of a class.
-- @param x any: The value to check.
-- @return boolean: `true` if `x` is an object created via a class, `false` otherwise.
local isobject = function(x)
  return type(x) == 'table' and isclass(x.__class)
end

--- Checks whether an object is an instance of a given class or one of its ancestors.
-- @param obj table: The object to test.
-- @param cls table: The class to check against.
-- @return boolean: `true` if `obj` is an instance of `cls` or its parent, `false` otherwise.
-- @usage
-- local A = class { }
-- local a = A()
-- assert(isinstanceof(a, A))
local function isinstanceof(obj, cls)
  return isobject(obj)
    and isclass(cls)
    and (obj.__class == cls or (obj.__super ~= nil and isinstanceof(obj.__super, cls)))
end

-- Known metamethods to copy from classdef
local known_metamethods = {
  __add = true,
  __sub = true,
  __mul = true,
  __div = true,
  __mod = true,
  __pow = true,
  __unm = true,
  __len = true,
  __eq = true,
  __lt = true,
  __le = true,
  __pairs = true,
  __ipairs = true,
  __call = true,
  __tostring = true,
  __concat = true,
}

--- Internal: creates a new class.
-- @param name string|nil: Optional class name.
-- @param parentclass table|nil: Optional parent class.
-- @param classdef table: Table containing instance methods and special keys (e.g. `__init`, `__class`).
-- @return table: A new class.
local new_class_internal = function(name, parentclass, classdef)
  -- typecheck arguments
  assert(
    (type(name) == 'nil' or type(name) == 'string')
      and (type(parentclass) == 'nil' or isclass(parentclass))
      and (type(classdef) == 'nil' or type(classdef) == 'table'),
    'Invalid arguments'
  )

  classdef = classdef or {}

  -- extract and remove __class from classdef
  local class_fields = classdef.__class or {}
  classdef.__class = nil

  local class = {
    __parent = parentclass,
    -- "inherit" class definition from parent class
    __classdef = parentclass and setmetatable(classdef, { __index = parentclass.__classdef })
      or classdef,

    --- Instance constructor.
    __create = function(cls)
      -- call superclass constructor
      local super = parentclass and cls.__parent:__create() or nil

      -- this instance's metatable
      local meta = {
        -- attributes not present in this instance will be
        -- indexed from parent class instance
        __index = super or nil,
        __newindex = super or nil,
      }

      -- create instance object and initialize it with class-defined attributes
      -- also transfer metamethods to the instance's metatable
      local instance = {}
      for k, v in pairs(cls.__classdef) do
        if known_metamethods[k] then
          meta[k] = v
        else
          instance[k] = v
        end
      end

      -- copy metamethods from parent instance
      if super then
        for k, v in pairs(getmetatable(super)) do
          if known_metamethods[k] and not meta[k] then
            meta[k] = v
          end
        end
      end

      instance.__super = super
      instance.__class = cls

      -- provide __tostring impl if not defined by user
      if not meta.__tostring then
        meta.__tostring = function(_)
          return '<object of ' .. tostring(cls) .. ': ' .. tostring(meta) .. '>'
        end
      end

      return super and setmetatable(instance, meta) or setmetatable(instance, meta)
    end,
  }

  -- inherit class fields from parent if present
  local parent_index = parentclass and getmetatable(parentclass).__index

  if parent_index then
    class_fields = setmetatable(class_fields, {
      __index = parent_index,
    })
  end

  -- Assign class name.
  class.__name = name or (tostring(class))

  return setmetatable(class, {
    --- Class fields
    __index = class_fields,

    --- Constructor impl
    __call = function(cls, ...)
      local i = cls:__create()

      -- call init method, if any
      if i.__init then
        i:__init(...)
      end

      return i
    end,

    __tostring = function()
      return '<class: ' .. class.__name .. '>'
    end,
  })
end

--- Defines a new class with optional name and/or parent.
--
-- Usage patterns:
-- ```lua
-- local C = class { __init = function(self) ... end }
-- local Named = class("Named") { ... }
-- local Sub = class(BaseClass) { ... }
-- local Derived = class("Derived", BaseClass) { ... }
-- ```
--
-- @usage anon_class = class { <classdef>... }
-- @usage Class = class("Class") { <classdef>... }
-- @usage anon_class = class(ParentClass) { <classdef>... }
-- @usage anon_class = class(nil, ParentClass) { <classdef>... }
-- @usage Class = class("Class", ParentClass) { <classdef>... }
-- @param ... string|table|nil: Class name, parent class, or class definition.
-- @return function|table: Returns a function that accepts the class definition, or the class itself.
local class = function(...)
  local arg_count = select('#', ...)
  if arg_count == 1 then
    -- class(ParentClass) { ... }
    -- class("Name") { ... }
    -- class(nil) { ... }
    -- class { ... }
    local a = ...

    if isclass(a) then
      -- class(ParentClass) { ... }
      return function(classdef)
        return new_class_internal(nil, a, classdef)
      end
    elseif type(a) == 'table' then
      -- class { ... }
      return new_class_internal(nil, nil, a)
    elseif type(a) == 'string' or type(a) == nil then
      -- class("Name") { ... }
      -- class(nil) { ... }
      return function(classdef)
        return new_class_internal(a, nil, classdef)
      end
    else
      -- invalid arg
      error('Invalid argument type. Expected class name or classdef, got: ' .. a)
    end
  elseif arg_count == 2 then
    -- class("Name", Parent) { ... }
    -- class("Name", nil) { ... }
    -- class(nil, Parent) { ... }
    -- class(nil, nil) { ... }
    local name, parent = ...
    return function(classdef)
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

-- Allow shortcut: `local MyClass = require('oops')("Name") { ... }`
setmetatable(MODULE, {
  __call = function(_, ...)
    return class(...)
  end,
})

return MODULE
