-- https://github.com/ImagicTheCat/Luaoop
-- MIT license (see LICENSE or src/Luaoop.lua)
--[[
MIT License
local Xtype=require("Xtype")

Copyright (c) 2017 ImagicTheCat

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

local Xtype=require("xtype")

local lua51=string.find(_VERSION, "5.1")
local getmetatable, setmetatable, newproxy=getmetatable, setmetatable, newproxy

local function error_arg(index, expected)
  error("bad argument #"..index.." ("..expected.." expected)")
end

local Luaoop={}

-- class type
local class_mt={Xtype="Xtype"}
local class=setmetatable(Xtype.create("class", "Xtype"), class_mt)

local function check_class(v, index)
  if not Xtype.is(v, class) then error_arg(index, "class") end
end

local function instance_tostring(self)
  local xt=Xtype.get(self)
  local mt=getmetatable(self)
  mt.__tostring=nil
  local str=string.gsub(tostring(self), "table:", ""..Xtype.name(xt).."", 1)
  mt.__tostring=instance_tostring
  return str
end

-- Build the class inheritance (not the instance inheritance).
local function class_build_inheritance(classdef)
  local build={}
  for i=#classdef.Xtype_stack,1,-1 do -- least specific, descending order
    local base=classdef.Xtype_stack[i]
    if Xtype.is(base, class) then
      -- inherit base class fields
      for k,v in pairs(base) do
        if k ~= "luaoop" and not k:find("^Xtype_") then build[k]=v end
      end
    end
  end
  return build
end

-- Build/re-build the class (class and instance inheritance).
-- Will add the luaoop field to the class.
--
-- classdef: class
local function class_build(classdef)
  check_class(classdef, 1)
  -- init luaoop table
  local luaoop=classdef.luaoop
  if not luaoop then luaoop={}; classdef.luaoop=luaoop end
  -- build
  --- inheritance
  ---- class build
  local build=class_build_inheritance(classdef)
  ---- instance build
  local instance_build={}
  for k,v in pairs(build) do -- inherit class build, everything but special fields
    if not k:find("^__") then instance_build[k]=v end
  end
  for k,v in pairs(classdef) do -- inherit class, everything but special fields
    if k ~= "luaoop" and not k:find("^Xtype_") and not k:find("^__") then
      instance_build[k]=v
    end
  end
  --- setup class inheritance
  getmetatable(classdef).__index=build
  --- init instance metatable
  if not luaoop.meta then
    luaoop.meta={
      Xtype=classdef,
      -- binary operators
      __add=Xtype.op.add,
      __sub=Xtype.op.sub,
      __mul=Xtype.op.mul,
      __div=Xtype.op.div,
      __mod=Xtype.op.mod,
      __pow=Xtype.op.pow,
      __concat=Xtype.op.concat,
      __eq=Xtype.op.eq,
      __lt=Xtype.op.lt,
      __le=Xtype.op.le,
      __idiv=Xtype.op.idiv,
      __band=Xtype.op.band,
      __bor=Xtype.op.bor,
      __bxor=Xtype.op.bxor,
      __shl=Xtype.op.shl,
      __shr=Xtype.op.shr
    }
  end
  --- update instance metatable
  luaoop.meta.__index=instance_build
  luaoop.meta.__call=classdef.__call
  luaoop.meta.__gc=classdef.__destruct
  luaoop.meta.__tostring=classdef.__tostring or instance_tostring
  luaoop.meta.__unm=classdef.__unm
  luaoop.meta.__len=classdef.__len
  luaoop.meta.__bnot=classdef.__bnot
end

-- Build the class if not already built.
-- return luaoop table
local function class_prebuild(classdef)
  if not classdef.luaoop then class_build(classdef) end
  return classdef.luaoop
end

local function proxy_gc(self)
  local mt=getmetatable(self)
  mt.destructor(mt.instance)
end

-- Create instance.
-- Will build the class if not already built.
--
-- classdef: class
-- ...: constructor arguments
-- return created instance
local function class_instantiate(classdef, ...)
  local luaoop=class_prebuild(classdef)
  -- create instance
  local instance=setmetatable({}, luaoop.meta)
  -- setup destructor (Lua 5.1)
  if lua51 then
    local destructor=classdef.__destruct
    if destructor then
      local proxy=newproxy(true)
      local mt=getmetatable(proxy)
      mt.__gc=proxy_gc
      mt.destructor=destructor
      mt.instance=instance
      instance.__proxy_gc=proxy
    end
  end
  -- construct
  local constructor=classdef.__construct
  if constructor then constructor(instance, ...) end
  return instance
end

-- Create a new class.
-- Base types can be classes or other Xtypes.
--
-- name: human-readable string (doesn't have to be unique)
-- ...: base types, ordered by descending proximity, to the least specific type
-- return created class (an Xtype)
local function class_new(name, ...)
  local xt=Xtype.create(name, ...)
  -- default print "class<type>: 0x..."
  local tostring_const=string.gsub(tostring(xt), "Xtype", "class", 1)
  return setmetatable(xt, {
    Xtype=class,
    __index=class_build_inheritance(xt),
    __call=class_instantiate,
    __tostring=function() return tostring_const end
  })
end

-- Get the class metatable applied to the instances.
-- Will build the class if not already built; useful to apply class behaviour
-- to a custom table.
--
-- classdef: class
-- return metatable
local function class_meta(classdef)
  return class_prebuild(classdef).meta
end

class.new=class_new
class.meta=class_meta
class.instantiate=class_instantiate
class.build=class_build
class_mt.__call=function(t, ...) return class_new(...) end

-- Namespaces.
Luaoop.class=class

return Luaoop
