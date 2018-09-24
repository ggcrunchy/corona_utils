--- This module provides some features for using entities.

--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- [ MIT license: http://www.opensource.org/licenses/mit-license.php ]
--

-- Standard library imports --
local assert = assert
local getmetatable = getmetatable
local rawequal = rawequal
local remove = table.remove
local setmetatable = setmetatable

-- Modules --
local collect = require("tektite_core.array.collect")
local component = require("tektite_core.component")
local meta = require("tektite_core.table.meta")

-- Corona globals --
local display = display

-- Exports --
local M = {}

--
--
--

local Entity = {}

Entity.__index = Entity

local EventCache = {}

--- DOCME
function Entity:SendMessage (what, ...)
    local event = remove(EventCache) or { args = {} }

    event.n, event.name, event.result = collect.CollectArgsInto(event.args, ...), what

    local args, n = event.args, event.n -- n.b. saved in case modified

    self:dispatchEvent(event)

    for i = n, 1, -1 do
        args[i] = nil
    end

    event.args = args

    EventCache[#EventCache + 1] = event

    return event.result
end

local function Finalize (event)
    component.RemoveAll(event.target)
end

local DisplayObjectMT = meta.Weak("k")

local function IsDisplayObject (object)
    local mt = getmetatable(object)

    if DisplayObjectMT[mt] then
        return true
    else
        local stage = display.getCurrentStage()

        repeat
            object = object.parent -- TODO: snapshots, etc.

            if rawequal(object, stage) then
                DisplayObjectMT[mt] = true

                return true
            end
        until not object

        return false
    end
end

local Methods = meta.Weak("k")

--- DOCME
function M.Make (object, methods)
    assert(Methods[methods], "Expected result from entity.NewMethods()")

    if IsDisplayObject(object) then
        object:addEventListener("finalize", Finalize)
    end

    meta.Augment(object, methods)

    return object
end

--- DOCME
function M.NewMethods (parent)
    assert(parent == nil or Methods[parent], "Expected parent from previous call to entity.NewMethods()")

    local mt = parent and { __index = parent } or Entity
    local methods = setmetatable({}, mt)

    Methods[methods] = true

    return methods
end

--
Entity.AddComponent = component.AddToObject
Entity.CanAddComponent = component.CanAddToObject
Entity.GetComponentList = component.GetListForObject
Entity.GetInterfaceList = component.GetInterfacesForObject
Entity.HasComponent = component.FoundInObject
Entity.Implements = component.ImplementedByObject
Entity.LockComponent = component.LockInObject
Entity.RemoveAllComponents = component.RemoveAllFromObject
Entity.RemoveComponent = component.RemoveFromObject

return M