--[[
TheNexusAvenger

Manages the local camera.
--]]
--!strict

local NexusVRCharacterModel = script.Parent.Parent
local CommonCamera = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("Camera"):WaitForChild("CommonCamera"))
local DefaultCamera = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("Camera"):WaitForChild("DefaultCamera"))
local ThirdPersonTrackCamera = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("Camera"):WaitForChild("ThirdPersonTrackCamera"))

local CameraService = {}
CameraService.__index = CameraService
local StaticInstance = nil

export type CameraService = {
    new: () -> (CameraService),
    GetInstance: () -> (CameraService),

    ActiveCamera: string,
    RegisterCamera: (self: CameraService, Name: string, Camera: CameraInterface) -> (),
    SetActiveCamera: (self: CameraService, Name: string) -> (),
    UpdateCamera: (self: CameraService, HeadsetCFrameWorld: CFrame) -> (),
}

export type CameraInterface = {
    Enable: (self: CameraInterface) -> (),
    Disable: (self: CameraInterface) -> (),
    UpdateCamera: (self: CameraInterface, HeadsetCFrameWorld: CFrame) -> (),
}



--[[
Creates a camera service.
--]]
function CameraService.new(): CameraService
    --Create the object.
    local self = {
        RegisteredCameras = {},
    }
    setmetatable(self, CameraService)

    --Register the default controllers.
    self:RegisterCamera("Default", DefaultCamera.new())
    self:RegisterCamera("ThirdPersonTrack", ThirdPersonTrackCamera.new())
    self:RegisterCamera("Disabled", CommonCamera.new())

    --Return the object.
    return (self :: any) :: CameraService
end

--[[
Returns a singleton instance of the camera service.
--]]
function CameraService.GetInstance(): CameraService
    if not StaticInstance then
        StaticInstance = CameraService.new()
    end
    return StaticInstance
end

--[[
Registers a camera.
--]]
function CameraService:RegisterCamera(Name: string, Camera: CameraInterface): ()
    self.RegisteredCameras[Name] = Camera
end

--[[
Sets the active camera.
--]]
function CameraService:SetActiveCamera(Name: string): ()
    --Return if the camera didn't change.
    if self.ActiveCamera == Name then return end
    self.ActiveCamera = Name

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
function CameraService:UpdateCamera(HeadsetCFrameWorld: CFrame): ()
    if self.CurrentCamera then
        self.CurrentCamera:UpdateCamera(HeadsetCFrameWorld)
    end
end



return (CameraService :: any) :: CameraService