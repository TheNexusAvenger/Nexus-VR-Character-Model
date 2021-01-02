--[[
TheNexusAvenger

Manages the local camera.
--]]

local NexusVRCharacterModel = require(script.Parent.Parent)
local NexusObject = NexusVRCharacterModel:GetResource("NexusInstance.NexusObject")
local DefaultCamera = NexusVRCharacterModel:GetResource("Character.Camera.DefaultCamera")

local CameraService = NexusObject:Extend()
CameraService:SetClassName("CameraService")



--[[
Creates a camera service.
--]]
function CameraService:__new()
    self:InitializeSuper()

    --Register the default controllers.
    self.RegisteredCameras = {}
    self:RegisterCamera("Default",DefaultCamera.new())
end

--[[
Registers a camera.
--]]
function CameraService:RegisterCamera(Name,Camera)
    self.RegisteredCameras[Name] = Camera
end

--[[
Sets the active camera.
--]]
function CameraService:SetActiveCamera(Name)
    --Disable the current camera.
    if self.CurrentCamera then
        self.CurrentCamera:Disable()
    end

    --Enable the new camera.
    self.CurrentCamera = self.RegisteredCameras[Name]
    if self.CurrentCamera then
        self.CurrentCamera:Enable()
    elseif Name ~= nil then
        warn("Nexus VR Character Model camera \""..tostring(Name).."\" is not registered.")
    end
end

--[[
Updates the local camera.
--]]
function CameraService:UpdateCamera(HeadsetCFrameWorld)
    if self.CurrentCamera then
        self.CurrentCamera:UpdateCamera(HeadsetCFrameWorld)
    end
end



return CameraService