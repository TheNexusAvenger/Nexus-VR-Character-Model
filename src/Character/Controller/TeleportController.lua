 --[[
TheNexusAvenger

Local character controller using teleporting.
--]]
--!strict

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local NexusVRCharacterModel = script.Parent.Parent.Parent
local NexusVRCharacterModelApi = require(NexusVRCharacterModel).Api
local BaseController = require(script.Parent:WaitForChild("BaseController"))
local ArcWithBeacon = require(script.Parent:WaitForChild("Visual"):WaitForChild("ArcWithBeacon"))
local VRInputService = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("VRInputService")).GetInstance()

local TeleportController = {}
TeleportController.__index = TeleportController
setmetatable(TeleportController, BaseController)



--[[
Creates a teleport controller object.
--]]
function TeleportController.new(): any
    return setmetatable(BaseController.new(), TeleportController)
end

--[[
Enables the controller.
--]]
function TeleportController:Enable(): ()
    BaseController.Enable(self)

    --Create the arcs.
    self.LeftArc = ArcWithBeacon.new()
    self.RightArc = ArcWithBeacon.new()
    self.ArcControls = {
        {
            Thumbstick = Enum.KeyCode.Thumbstick1,
            UserCFrame = Enum.UserCFrame.LeftHand,
            Arc = self.LeftArc,
        },
        {
            Thumbstick = Enum.KeyCode.Thumbstick2,
            UserCFrame = Enum.UserCFrame.RightHand,
            Arc = self.RightArc,
        },
    }
end

--[[
Disables the controller.
--]]
function TeleportController:Disable(): ()
    BaseController.Disable(self)

    --Destroy the arcs.
    self.LeftArc:Destroy()
    self.RightArc:Destroy()
end

--[[
Updates the local character. Must also update the camara.
--]]
function TeleportController:UpdateCharacter(): ()
    --Update the base character.
    BaseController.UpdateCharacter(self)
    if not self.Character then
        return
    end

    --Stop the player from moving.
    Players.LocalPlayer:Move(Vector3.new(0, 0, 0), true)

    --Get the VR inputs.
    local VRInputs = VRInputService:GetVRInputs()
    for _, InputEnum in Enum.UserCFrame:GetEnumItems() do
        VRInputs[InputEnum] = self:ScaleInput(VRInputs[InputEnum])
    end

    --Update the arcs.
    local SeatPart = self.Character:GetHumanoidSeatPart()
    for _, ArcData in self.ArcControls do
        --Reset the left arc if the player is in a vehicle seat.
        if ArcData.Thumbstick == Enum.KeyCode.Thumbstick1 and SeatPart and SeatPart:IsA("VehicleSeat") then
            ArcData.Arc:Hide()
            continue
        end

        --Update and fetch the current state.
        local InputActive = (not NexusVRCharacterModelApi.Controller or NexusVRCharacterModelApi.Controller:IsControllerInputEnabled(ArcData.UserCFrame))
        local DirectionState, RadiusState, StateChange = self:GetJoystickState(ArcData)
        if not InputActive then
            ArcData.Arc:Hide()
            ArcData.WaitForRelease = false
            ArcData.RadiusState = nil
            continue
        end

        --Update from the state.
        local HumanoidRootPart = self.Character.Parts.HumanoidRootPart
        if DirectionState ~= "Forward" or RadiusState == "Released" then
            ArcData.Arc:Hide()
        end
        if StateChange == "Extended" then
            self:UpdateTurning(ArcData.UserCFrame, DirectionState, StateChange)
        elseif StateChange == "Released" then
            ArcData.Arc:Hide()
            if DirectionState == "Forward" then
                --Teleport the player.
                if ArcData.LastHitPart and ArcData.LastHitPosition then
                    --Unsit the player.
                    --The teleport event is set to ignored since the CFrame will be different when the player gets out of the seat.
                    local WasSitting = false
                    self:PlayBlur()

                    if SeatPart then
                        WasSitting = true
                        self.IgnoreNextExternalTeleport = true
                        self.Character.Humanoid.Sit = false
                    end

                    if (ArcData.LastHitPart:IsA("Seat") or ArcData.LastHitPart:IsA("VehicleSeat")) and not ArcData.LastHitPart.Occupant and not ArcData.LastHitPart.Disabled then
                        --Sit in the seat.
                        --Waiting is done if the player was in an existing seat because the player no longer sitting will prevent sitting.
                        if WasSitting then
                            task.spawn(function()
                                while self.Character.Humanoid.SeatPart do task.wait() end
                                ArcData.LastHitPart:Sit(self.Character.Humanoid)
                            end)
                        else
                            ArcData.LastHitPart:Sit(self.Character.Humanoid)
                        end
                    else
                        --Teleport the player.
                        --Waiting is done if the player was in an existing seat because the player will teleport the seat.
                        if WasSitting then
                            task.spawn(function()
                                while self.Character.Humanoid.SeatPart do task.wait() end
                                HumanoidRootPart.CFrame = CFrame.new(ArcData.LastHitPosition) * CFrame.new(0, 4.5 * self.Character:GetHumanoidScale("BodyHeightScale"), 0) * (CFrame.new(-HumanoidRootPart.Position) * HumanoidRootPart.CFrame)
                            end)
                        else
                            HumanoidRootPart.CFrame = CFrame.new(ArcData.LastHitPosition) * CFrame.new(0, 4.5 * self.Character:GetHumanoidScale("BodyHeightScale"), 0) * (CFrame.new(-HumanoidRootPart.Position) * HumanoidRootPart.CFrame)
                        end
                    end
                end
            end
        elseif StateChange == "Cancel" then
            ArcData.Arc:Hide()
        elseif DirectionState == "Forward" and RadiusState == "Extended" then
            ArcData.LastHitPart, ArcData.LastHitPosition = ArcData.Arc:Update(Workspace.CurrentCamera:GetRenderCFrame() * VRInputs[Enum.UserCFrame.Head]:Inverse() * VRInputs[ArcData.UserCFrame])
        end
    end
end



return TeleportController