 --[[
TheNexusAvenger

Local character controller using teleporting.
--]]
--!strict

local BaseController = require(script.Parent:WaitForChild("BaseController"))

local SmoothLocomotionController = {}
SmoothLocomotionController.__index = SmoothLocomotionController
setmetatable(SmoothLocomotionController, BaseController)



--[[
Creates a smooth locomotion controller object.
--]]
function SmoothLocomotionController.new(): any
    return setmetatable(BaseController.new(), SmoothLocomotionController)
end

--[[
Enables the controller.
--]]
function SmoothLocomotionController:Enable(): ()
    BaseController.Enable(self)
    self.JoystickState = {Thumbstick = Enum.KeyCode.Thumbstick2}
end

--[[
Disables the controller.
--]]
function SmoothLocomotionController:Disable(): ()
    BaseController.Disable(self)
    self.JoystickState = nil
end

--[[
Updates the local character. Must also update the camara.
--]]
function SmoothLocomotionController:UpdateCharacter(): ()
    --Update the base character.
    BaseController.UpdateCharacter(self)
    if not self.Character then
        return
    end

    --Rotate the character.
    local DirectionState, _, StateChange = self:GetJoystickState(self.JoystickState)
    self:UpdateTurning(Enum.UserCFrame.RightHand, DirectionState, StateChange)
end



return SmoothLocomotionController