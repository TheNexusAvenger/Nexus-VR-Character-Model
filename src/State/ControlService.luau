--Manages controlling the local characters.
--!strict

local NexusVRCharacterModel = script.Parent.Parent
local BaseController = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("Controller"):WaitForChild("BaseController"))
local TeleportController = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("Controller"):WaitForChild("TeleportController"))
local SmoothLocomotionController = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("Controller"):WaitForChild("SmoothLocomotionController"))

local ControlService = {}
ControlService.__index = ControlService
local StaticInstance = nil

export type ControlService = {
    RegisteredControllers: {[string]: ControllerInterface},
    ActiveController: string,
    CurrentController: ControllerInterface?,
} & typeof(setmetatable({}, ControlService))

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
    local self = setmetatable({
        RegisteredControllers = {},
    }, ControlService) :: ControlService

    --Register the default controllers.
    local EmptyController = BaseController.new()
    EmptyController.ActionsToLock = {Enum.KeyCode.Thumbstick1, Enum.KeyCode.Thumbstick2, Enum.KeyCode.ButtonR3, Enum.KeyCode.ButtonA}
    self:RegisterController("None", EmptyController :: any)
    self:RegisterController("Teleport", TeleportController.new() :: any)
    self:RegisterController("SmoothLocomotion", SmoothLocomotionController.new() :: any)

    --Return the object.
    return self 
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
function ControlService.RegisterController(self: ControlService, Name: string, Controller: ControllerInterface): ()
    self.RegisteredControllers[Name] = Controller
end

--[[
Sets the active controller.
--]]
function ControlService.SetActiveController(self: ControlService, Name: string): ()
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
        warn(`Nexus VR Character Model controller \"{Name}\" is not registered.`)
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



return ControlService