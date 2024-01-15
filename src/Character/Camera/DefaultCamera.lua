--[[
TheNexusAvenger

Default camera that follows the character.
--]]
--!strict

local BUMP_DEFAULT_TRANSPARENCY_WORKAROUND = true
local HIDDEN_ACCESSORIES = {
    [Enum.AccessoryType.Hat] = true;
    [Enum.AccessoryType.Hair] = true;
    [Enum.AccessoryType.Face] = true;
    [Enum.AccessoryType.Eyebrow] = true;
    [Enum.AccessoryType.Eyelash] = true;
}

local Players = game:GetService("Players")

local NexusVRCharacterModel = script.Parent.Parent.Parent
local CommonCamera = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("Camera"):WaitForChild("CommonCamera"))
local Settings = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("Settings")).GetInstance()

local DefaultCamera = {}
DefaultCamera.__index = DefaultCamera
setmetatable(DefaultCamera, CommonCamera)



--[[
Returns true if the provided part should be hidden in first person.
--]]
function DefaultCamera.ShouldHidePart(Part: BasePart): boolean
    local Parent: Instance? = Part.Parent
    if Parent then
        if Parent:IsA("Accessory") then
            local AccessoryType = Parent.AccessoryType
            return HIDDEN_ACCESSORIES[AccessoryType] or false
        elseif Parent:IsA("Model") then
            return false
        else
            return not Parent:IsA("Tool")
        end
    end

    if Part:FindFirstChildWhichIsA("WrapLayer") then
        return false
    end

    return true
end

--[[
Creates a default camera object.
--]]
function DefaultCamera.new(): any
    return setmetatable(CommonCamera.new(), DefaultCamera)
end

--[[
Enables the camera.
--]]
function DefaultCamera:Enable(): ()
    self.TransparencyEvents = {}
    if Players.LocalPlayer.Character then
        --Connect children being added.
        local Transparency = Settings:GetSetting("Appearance.LocalCharacterTransparency")
        if BUMP_DEFAULT_TRANSPARENCY_WORKAROUND then
            if Transparency == 0.5 then
                Transparency = 0.501
            elseif Transparency < 0.5 then
                warn("Values of <0.5 with Appearance.LocalCharacterTransparency are currently known to cause black screen issues. This will hopefully be resolved by Roblox in a future update: https://devforum.roblox.com/t/vr-screen-becomes-black-due-to-non-transparent-character/2215099")
            end
        end
        table.insert(self.TransparencyEvents, Players.LocalPlayer.Character.DescendantAdded:Connect(function(Part)
            if Part:IsA("BasePart") then
                local PartTransparency = Transparency
                if Part:FindFirstAncestorOfClass("Tool") then
                    PartTransparency = 0
                elseif DefaultCamera.ShouldHidePart(Part) then
                    PartTransparency = 1
                end

                Part.LocalTransparencyModifier = PartTransparency
                table.insert(self.TransparencyEvents, Part:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
                    Part.LocalTransparencyModifier = PartTransparency
                end))
            end
        end))
        for _, Part in Players.LocalPlayer.Character:GetDescendants() do
            if Part:IsA("BasePart") then
                local PartTransparency = Transparency
                if Part:FindFirstAncestorOfClass("Tool") then
                    PartTransparency = 0
                elseif DefaultCamera.ShouldHidePart(Part) then
                    PartTransparency = 1
                end
                
                Part.LocalTransparencyModifier = PartTransparency
                table.insert(self.TransparencyEvents, Part:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
                    Part.LocalTransparencyModifier = PartTransparency
                end))
            end
        end
    end

    --Connect the character and local transparency changing.
    table.insert(self.TransparencyEvents, Players.LocalPlayer:GetPropertyChangedSignal("Character"):Connect(function()
        self:Disable()
        self:Enable()
    end))
    table.insert(self.TransparencyEvents, Settings:GetSettingsChangedSignal("Appearance.LocalCharacterTransparency"):Connect(function()
        self:Disable()
        self:Enable()
    end))
end

--[[
Disables the camera.
--]]
function DefaultCamera:Disable(): ()
    --Disconnect the character events.
    if self.TransparencyEvents then
        for _, Event in self.TransparencyEvents do
            Event:Disconnect()
        end
        self.TransparencyEvents = {}
    end

    --Reset the local transparency modifiers.
    if Players.LocalPlayer.Character then
        for _, Part in Players.LocalPlayer.Character:GetDescendants() do
            if Part:IsA("BasePart") then
                Part.LocalTransparencyModifier = 0
            end
        end
    end
end

--[[
Updates the camera.
--]]
function DefaultCamera:UpdateCamera(HeadsetCFrameWorld: CFrame): ()
    self:SetCFrame(HeadsetCFrameWorld)
end



return DefaultCamera
