 --[[
TheNexusAvenger

Local character controller with no inputs.
--]]
--!strict

local BaseController = require(script.Parent:WaitForChild("BaseController"))

local EmptyController = {}
EmptyController.__index = EmptyController
setmetatable(EmptyController, BaseController)



--[[
Creates an empty controller object.
--]]
function EmptyController.new(): any
    local self = setmetatable(BaseController.new(), EmptyController)
    self.ActionsToLock = {Enum.KeyCode.Thumbstick1, Enum.KeyCode.Thumbstick2, Enum.KeyCode.ButtonR3, Enum.KeyCode.ButtonA}
    return self
end



return EmptyController