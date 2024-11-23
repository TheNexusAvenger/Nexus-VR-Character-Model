--Manages the local camera.
--!strict

local NexusVRCharacterModel = script.Parent.Parent
local CommonCamera = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("Camera"):WaitForChild("CommonCamera"))
local DefaultCamera = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("Camera"):WaitForChild("DefaultCamera"))
local ThirdPersonTrackCamera = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("Camera"):WaitForChild("ThirdPersonTrackCamera"))

local CameraService = {}
CameraService.__index = CameraService
local StaticInstance = nil

export type CameraService = {
    ActiveCamera: string,
    CurrentCamera: CameraInterface?,
    RegisteredCameras: {[string]: CameraInterface},
} & typeof(setmetatable({}, CameraService))

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
    local self = setmetatable({
        RegisteredCameras = {},
    }, CameraService) :: CameraService

    --Register the default controllers.
    self:RegisterCamera("Default", DefaultCamera.new() :: any)
    self:RegisterCamera("ThirdPersonTrack", ThirdPersonTrackCamera.new() :: any)
    self:RegisterCamera("Disabled", CommonCamera.new() :: any)

    --Return the object.
    return self
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
function CameraService.RegisterCamera(self: CameraService, Name: string, Camera: CameraInterface): ()
    self.RegisteredCameras[Name] = Camera
end

--[[
Sets the active camera.
--]]
function CameraService.SetActiveCamera(self: CameraService, Name: string): ()
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
        warn(`Nexus VR Character Model camera \"{Name}\" is not registered.`)
    end
end

--[[
Updates the local camera.
--]]
function CameraService.UpdateCamera(self: CameraService,HeadsetCFrameWorld: CFrame): ()
    if self.CurrentCamera then
        self.CurrentCamera:UpdateCamera(HeadsetCFrameWorld)
    end
end



return CameraService