--Local character controller using teleporting.
--!strict

local BaseController = require(script.Parent:WaitForChild("BaseController"))

local SmoothLocomotionController = {}
SmoothLocomotionController.__index = SmoothLocomotionController
setmetatable(SmoothLocomotionController, BaseController)

export type SmoothLocomotionController = {
    JoystickState: {[string]: Enum.KeyCode}?,
} & typeof(setmetatable({}, SmoothLocomotionController)) & BaseController.BaseController


--[[
Creates a smooth locomotion controller object.
--]]
function SmoothLocomotionController.new(): SmoothLocomotionController
    return setmetatable(BaseController.new(), SmoothLocomotionController) :: SmoothLocomotionController
end

--[[
Enables the controller.
--]]
function SmoothLocomotionController.Enable(self: SmoothLocomotionController): ()
    BaseController.Enable(self)
    self.JoystickState = {Thumbstick = Enum.KeyCode.Thumbstick2}
end

--[[
Disables the controller.
--]]
function SmoothLocomotionController.Disable(self: SmoothLocomotionController): ()
    BaseController.Disable(self)
    self.JoystickState = nil
end

--[[
Updates the local character. Must also update the camara.
--]]
function SmoothLocomotionController.UpdateCharacter(self: SmoothLocomotionController): ()
    --Update the base character.
    BaseController.UpdateCharacter(self)
    if not self.Character then
        return
    end

    --Rotate the character.
    local DirectionState, _, StateChange = self:GetJoystickState(self.JoystickState)
    self:UpdateRotating(Enum.UserCFrame.RightHand, DirectionState, StateChange)
end



return SmoothLocomotionController