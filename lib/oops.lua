--- Oops is a class-based inheritance OOP library for Lua with controlled 
-- class scope (local and anonymous classes) and succinct syntax.
-- @release 0.1
-- @class module
-- @module 'oops'
-- @author Sergey Yavnyi

--- Creates a class table.
-- @param name Class name.
-- @param parentclass Parent class. Optional.
-- @param classef Class definition table.
local new_class = function (name, parentclass, classdef)
  -- print("defining class "..name.." with parent "..tostring(parentclass).." and def "..tostring(classdef))

  local cls = {
    __parent__ = parentclass,
    __name__ = name,
    -- "inherit" class definition from parent class
    __classdef__ = setmetatable(classdef, {__index = parentclass.__classdef__}),

    --- Instance constructor.
    create = function(cls)
      -- print(cls.__name__..":create()", cls.__parent__)
      
      -- call superclass constructor
      local super = cls.__parent__:create()

      -- create instance object and initialize it with
      -- class-defined attributes
      local instance = {}
      for k, v in pairs(cls.__classdef__) do
        instance[k] = v
      end

      -- add these "special" attributes after classdefs
      -- in case the definition contains attrs with the
      -- same names.
      -- TODO in such case, it is probably better to 
      -- either raise an error or ignore this completely.
      instance.super = super
      instance.__class__ = cls

      -- attributes not present in this instance will be
      -- indexed from parent class instance
      setmetatable(instance, {__index = super})

      return instance
    end,

    --- Convenience constructor that also calls the init method.
    new = function(cls, ...)
      local i = cls:create()

      -- call init method, if any
      if i.init then
        i:init(...)
      end

      return i
    end
  }

  return cls
end

--- The root class. TODO this is probably redundant, can optimize object 
-- creation by removing a call to root_class:create() and instead move this 
-- code in the new_class function.
local root_class = {
  __classdef__ = {},
  __parent__ = nil,
  __name__ = "<root>",

  create = function(cls)
    -- print(cls.__name__..":create()")

    return {
      __class__ = cls,
      super = nil
    }
  end
}

--- Defines a new class.
-- @usage Name = class("Name")(ParentClass) { <classdef>... }
class = function(name)
  return function(parent)
    return function(classdef)
      return new_class(
        name or "<anonymous>",
        parent or root_class,
        classdef or {}
      )
    end
  end
end

--- Abstract method placeholder.
abstract_method = function(self, ...)
  error("Abstract method call: inst of "..self.__class__.__name__.." with args", ...)
end

return {
  class = class,
  abstract_method = abstract_method
}