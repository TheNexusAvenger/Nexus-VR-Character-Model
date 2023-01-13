--[[
TheNexusAvenger

Manages controlling the local characters.
--]]
--!strict

local NexusVRCharacterModel = require(script.Parent.Parent)
local BaseController = NexusVRCharacterModel:GetResource("Character.Controller.BaseController")
local TeleportController = NexusVRCharacterModel:GetResource("Character.Controller.TeleportController")
local SmoothLocomotionController = NexusVRCharacterModel:GetResource("Character.Controller.SmoothLocomotionController")

local ControlService = {}
ControlService.__index = ControlService
local StaticInstance = nil

export type ControlService = {
    new: () -> (ControlService),
    GetInstance: () -> (ControlService),

    RegisterController: (self: ControlService, Name: string, Controller: ControllerInterface) -> (),
    SetActiveController: (self: ControlService, Name: string) -> (),
    UpdateCharacter: (self: ControlService) -> (),
}

export type ControllerInterface = {
    Disable: (self: ControllerInterface) -> (),
    Enable: (self: ControllerInterface) -> (),
    UpdateCharacter: (self: ControllerInterface) -> (),
}



--[[
Creates a control service.
--]]
function ControlService.new(): ControlService
    --Create the object.
    local self = {
        RegisteredControllers = {},
    }
    setmetatable(self, ControlService)

    --Register the default controllers.
    self:RegisterController("None", BaseController.new())
    self:RegisterController("Teleport", TeleportController.new())
    self:RegisterController("SmoothLocomotion", SmoothLocomotionController.new())

    --Return the object.
    return (self :: any) :: ControlService
end

--[[
Returns a singleton instance of the character service.
--]]
function ControlService.GetInstance(): ControlService
    if not StaticInstance then
        StaticInstance = ControlService.new()
    end
    return StaticInstance
end

--[[
Registers a controller.
--]]
function ControlService:RegisterController(Name: string, Controller: any): ()
    self.RegisteredControllers[Name] = Controller
end

--[[
Sets the active controller.
--]]
function ControlService:SetActiveController(Name: string): ()
    --Return if the controller didn't change.
    if self.ActiveController == Name then return end
    self.ActiveController = Name

    --Disable the current controller.
    if self.CurrentController then
        self.CurrentController:Disable()
    end

    --Enable the new controller.
    self.CurrentController = self.RegisteredControllers[Name]
    if self.CurrentController then
        self.CurrentController:Enable()
    elseif Name ~= nil then
        warn("Nexus VR Character Model controller \""..tostring(Name).."\" is not registered.")
    end
end

--[[
Updates the local character.
--]]
function ControlService:UpdateCharacter()
    if self.CurrentController then
        self.CurrentController:UpdateCharacter()
    end
end



return (ControlService :: any) :: ControlService