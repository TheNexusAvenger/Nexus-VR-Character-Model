--[[
TheNexusAvenger

Default camera that follows the character.
--]]

--Workaround for Roblox's CoreGuis relying on HeadLocked.
--https://devforum.roblox.com/t/coregui-vr-components-rely-on-headlocked-being-true/100460
local USE_HEAD_LOCKED_WORKAROUND = true



local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local VRService = game:GetService("VRService")

local NexusVRCharacterModel = require(script.Parent.Parent.Parent)
local NexusObject = NexusVRCharacterModel:GetResource("NexusInstance.NexusObject")
local Settings = NexusVRCharacterModel:GetInstance("State.Settings")

local DefaultCamera = NexusObject:Extend()
DefaultCamera:SetClassName("DefaultCamera")



--[[
Enables the camera.
--]]
function DefaultCamera:Enable()
    self.TransparencyEvents = {}
    if Players.LocalPlayer.Character then
        --Connect children being added.
        local Transparency = Settings:GetSetting("Appearance.LocalCharacterTransparency")
        table.insert(self.TransparencyEvents,Players.LocalPlayer.Character.DescendantAdded:Connect(function(Part)
            if Part:IsA("BasePart") then
                if Part.Parent:IsA("Accoutrement") then
                    Part.LocalTransparencyModifier = 1
                elseif not Part.Parent:IsA("Tool") then
                    Part.LocalTransparencyModifier = Transparency
                end
            end
        end))
        for _,Part in pairs(Players.LocalPlayer.Character:GetDescendants()) do
            if Part:IsA("BasePart") then
                if Part.Parent:IsA("Accoutrement") then
                    Part.LocalTransparencyModifier = 1
                elseif not Part.Parent:IsA("Tool") then
                    Part.LocalTransparencyModifier = Transparency
                end
            end
        end
    end

    --Connect the character and local transparency changing.
    table.insert(self.TransparencyEvents,Players.LocalPlayer:GetPropertyChangedSignal("Character"):Connect(function()
        self:Disable()
        self:Enable()
    end))
    table.insert(self.TransparencyEvents,Settings:GetSettingsChangedSignal("Appearance.LocalCharacterTransparency"):Connect(function()
        self:Disable()
        self:Enable()
    end))
end

--[[
Disables the camera.
--]]
function DefaultCamera:Disable()
    --Disconnect the character events.
    if self.TransparencyEvents then
        for _,Event in pairs(self.TransparencyEvents) do
            Event:Disconnect()
        end
        self.TransparencyEvents = {}
    end

    --Reset the local transparency modifiers.
    if Players.LocalPlayer.Character then
        for _,Part in pairs(Players.LocalPlayer.Character:GetDescendants()) do
            if Part:IsA("BasePart") then
                Part.LocalTransparencyModifier = 0
            end
        end
    end
end

--[[
Updates the camera.
--]]
function DefaultCamera:UpdateCamera(HeadsetCFrameWorld)
    Workspace.CurrentCamera.CameraType = "Scriptable"
    if USE_HEAD_LOCKED_WORKAROUND then
        Workspace.CurrentCamera.HeadLocked = true
        Workspace.CurrentCamera.CFrame = HeadsetCFrameWorld * VRService:GetUserCFrame(Enum.UserCFrame.Head):Inverse()
    else
        Workspace.CurrentCamera.HeadLocked = false
        Workspace.CurrentCamera.CFrame = HeadsetCFrameWorld
    end
end



return DefaultCamera