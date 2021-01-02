--[[
TheNexusAvenger

Manages controlling the local characters.
--]]

local NexusVRCharacterModel = require(script.Parent.Parent)
local NexusObject = NexusVRCharacterModel:GetResource("NexusInstance.NexusObject")
local TeleportController = NexusVRCharacterModel:GetResource("Character.Controller.TeleportController")

local ControlService = NexusObject:Extend()
ControlService:SetClassName("ControlService")



--[[
Creates a control service.
--]]
function ControlService:__new()
    self:InitializeSuper()

    --Register the default controllers.
    self.RegisteredControllers = {}
    self:RegisterController("Teleport",TeleportController.new())
end

--[[
Registers a controller.
--]]
function ControlService:RegisterController(Name,Controller)
    self.RegisteredControllers[Name] = Controller
end

--[[
Sets the active controller.
--]]
function ControlService:SetActiveController(Name)
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



return ControlService