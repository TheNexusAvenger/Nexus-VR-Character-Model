--[[
TheNexusAvenger

Manages toggling the default cursor.
Workaround for: https://github.com/TheNexusAvenger/Nexus-VR-Character-Model/issues/10
--]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local NexusVRCharacterModel = require(script.Parent.Parent)
local NexusVRCore = require(ReplicatedStorage:WaitForChild("NexusVRCore"))
local NexusObject = NexusVRCharacterModel:GetResource("NexusInstance.NexusObject")
local VRPart = NexusVRCore:GetResource("Interaction.VRPart")
local VRInputService = NexusVRCharacterModel:GetInstance("State.VRInputService")

local DefaultCursorService = NexusObject:Extend()
DefaultCursorService:SetClassName("DefaultCursorService")



--[[
Creates a default cursor service.
--]]
function DefaultCursorService:__new()
    self:InitializeSuper()

    --Register the default values.
    self.CursorOptionsList = {"Detect", "Enabled", "Disabled"}
    self.CursorOptions = {
        Detect = function()
            --Continuously update the pointer.
            while self.CurrentCursorState == "Detect" do
                --Determine if the UserGui is visible and being pointed at.
                --Roblox only uses the right hand, so only the right hand is checked.
                --TODO: Doesn't detect other UIs, such as BillboardGuis.
                local PointingAtUserGui = false
                local Camera = Workspace.CurrentCamera
                local VRCorePanelParts = Camera:FindFirstChild("VRCorePanelParts")
                if VRCorePanelParts then
                    local UserGui = VRCorePanelParts:FindFirstChild("UserGui")
                    if UserGui then
                        local VRCFrames = VRInputService:GetVRInputs()
                        local RightHandCFrame = Camera:GetRenderCFrame() * VRCFrames[Enum.UserCFrame.Head]:Inverse() * VRCFrames[Enum.UserCFrame.RightHand]
                        local UserGuiVRPart = VRPart.GetInstance(UserGui)
                        local RaycastPointX, RaycastPointY, _ = UserGuiVRPart:Raycast(RightHandCFrame, Enum.NormalId.Front)
                        if RaycastPointX >= 0 and RaycastPointX <= 1 and RaycastPointY >= 0 and RaycastPointY <= 1 then
                            PointingAtUserGui = true
                        end
                    end
                end

                --Update the pointer.
                pcall(function()
                    StarterGui:SetCore("VRLaserPointerMode", PointingAtUserGui and "Pointer" or "Disabled")
                end)

                --Wait to update again.
                task.wait()
            end
        end,
        Enabled = function()
            StarterGui:SetCore("VRLaserPointerMode", "Pointer")
        end,
        Disabled = function()
            StarterGui:SetCore("VRLaserPointerMode", "Disabled")
        end,
    }
end

--[[
Sets the cursor state.
--]]
function DefaultCursorService:SetCursorState(OptionName: string): nil
    if self.CurrentCursorState == OptionName then return end
    self.CurrentCursorState = OptionName
    task.spawn(self.CursorOptions[OptionName])
end



return DefaultCursorService