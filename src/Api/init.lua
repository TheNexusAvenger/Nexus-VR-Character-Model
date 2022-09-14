--[[
TheNexusAvenger

Main module for creating the usable API.
--]]

local RunService = game:GetService("RunService")



--[[
Creates a shim for interacted with a limited API for a module.
--]]
local function CreateShim(Source: {[string]: any}, FunctionNames: {string}): {[string]: any}
    local Shim = {}
    for _, FunctionName in FunctionNames do
        Shim[FunctionName] = Source[FunctionName]
    end
    return Shim
end



return function(NexusVRCharacterModel)
    --Return an empty API if the module was loaded on the server.
    if RunService:IsServer() then
        return {}
    end

    --Build the initial shims for the APIs.
    local CameraService = NexusVRCharacterModel:GetInstance("State.CameraService")
    local ControlService = NexusVRCharacterModel:GetInstance("State.ControlService")
    local Api = {
        Camera = CreateShim(CameraService, {"SetActiveCamera",}),
        Controller = CreateShim(ControlService, {"SetActiveController",}),
        Settings = CreateShim(NexusVRCharacterModel:GetInstance("State.Settings"), {"GetSetting", "SetSetting", "GetSettingsChangedSignal"}),
        Input = CreateShim(NexusVRCharacterModel:GetInstance("State.VRInputService"), {"Recenter", "SetEyeLevel", "Recentered", "EyeLevelSet",}),
        --TODO: Menu API
    }

    --Add the additional APIs.
    Api.Camera.GetActiveCamera = function()
        return CameraService.ActiveCamera
    end
    Api.Controller.GetActiveController = function()
        return ControlService.ActiveController
    end

    --Return the APIs.
    return Api
end