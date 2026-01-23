--- Lightweight class-based OOP for Lua with concise syntax and local classes.
-- @module oops
-- @release 0.2
-- @author Serhii Yavnyi <blacktaxi@gmail.com>
-- @license BSD

---@module "oops"
---@class OopsModule
---@field isclass fun(x: any): boolean
---@field isobject fun(x: any): boolean
---@field isinstanceof fun(obj: any, cls: any): boolean
---@field class fun(parent: OopsClass): fun(def: table): OopsClass
---@overload fun(name: string): fun(def: table): OopsClass
---@overload fun(name: string, parent: OopsClass): fun(def: table): OopsClass
---@overload fun(def: table): OopsClass
---@operator call: fun(parent: OopsClass): fun(def: table): OopsClass
---@overload fun(name: string): fun(def: table): OopsClass
---@overload fun(name: string, parent: OopsClass): fun(def: table): OopsClass
---@overload fun(def: table): OopsClass

---@generic T: OopsInstance
---@class OopsInstance<T>
---@field __super? T
---@field __class OopsClass<T>
---@field __init? fun(self: T, ...: any)

---@generic T: OopsInstance
---@class OopsClass<T>
---@field __classdef table
---@field __create fun(self: OopsClass<T>): T
---@field __name string
---@field __parent? OopsClass<any>
---@operator call: fun(...: any): T

--- Checks whether a value is a class created by `oops`.
---@param x any # The value to check.
---@return boolean # True if x is a class created by `oops`
local isclass = function(x)
  return type(x) == 'table' and type(x.__classdef) == 'table'
end

--- Checks whether a value is an instance of a class.
---@param x any # The value to check.
---@return boolean # True if x is an object created by a class
local isobject = function(x)
  return type(x) == 'table' and isclass(x.__class)
end

--- Checks whether an object is an instance of a given class or one of its ancestors.
--
-- Usage:
-- ```lua
-- local A = class { }
-- local a = A()
-- assert(isinstanceof(a, A))
-- ```
--
---@param obj table # The object to test.
---@param cls table # The class to check against.
---@return boolean # True if obj is an instance of cls or its ancestor
local function isinstanceof(obj, cls)
  return isobject(obj)
    and isclass(cls)
    and (obj.__class == cls or (obj.__super ~= nil and isinstanceof(obj.__super, cls)))
end

-- Known metamethods to copy from classdef
---@type table<string, boolean>
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

---@private
---@param name? string # Optional class name.
---@param parentclass? OopsClass # Optional parent class.
---@param classdef? table # Class definition table.
---@return OopsClass
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
-- -- Basic class definition:
-- local C = class { __init = function(self) ... end }
-- local Named = class("Named") { ... }
-- local Sub = class(BaseClass) { ... }
-- local Derived = class("Derived", BaseClass) { ... }
--
-- -- Multi-table merge (mixin-style composition):
-- local Player = class(Mixin1, Mixin2, { ... })
--
-- -- Combining parent/name with mixins (curried form):
-- local Enemy = class(BaseClass)(Mixin1, Mixin2, { ... })
-- local Boss = class("Boss", BaseClass)(Mixin1, Mixin2, { ... })
-- ```
--
---@overload fun(def: table): OopsClass
---@overload fun(name: string): fun(def: table): OopsClass
---@overload fun(parent: OopsClass): fun(def: table): OopsClass
---@overload fun(name: string, parent: OopsClass): fun(def: table): OopsClass
---@overload fun(...: table): OopsClass
local class = function(...)
  local arg_count = select('#', ...)

  if arg_count == 0 then
    error('Expected at least 1 argument')
  end

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
      error('Invalid argument type. Expected class name or classdef, got: ' .. type(a))
    end
  elseif arg_count == 2 then
    local a, b = ...

    -- Check if this is the curried pattern: class("Name", Parent) { ... }
    -- vs the new multi-table merge pattern
    if (type(a) == 'string' or a == nil) and (isclass(b) or b == nil) then
      -- class("Name", Parent) { ... } - curried pattern
      return function(classdef)
        return new_class_internal(a, b, classdef)
      end
    end

    -- Otherwise, fall through to multi-table merge
  end

  -- Multi-table merge mode (arg_count >= 2)
  -- All arguments must be tables - no name/parent parsing
  -- Use curried form class(Parent)(Mixin1, {def}) for inheritance + mixins
  local merged = {}
  for i = 1, arg_count do
    local t = select(i, ...)
    if type(t) ~= 'table' then
      error('Expected table at argument ' .. i .. ', got ' .. type(t))
    end
    -- Merge this table into the result (later tables override earlier ones)
    for k, v in pairs(t) do
      merged[k] = v
    end
  end

  return new_class_internal(nil, nil, merged)
end

---@type OopsModule
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
