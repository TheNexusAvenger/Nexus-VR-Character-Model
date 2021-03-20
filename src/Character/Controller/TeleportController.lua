 --[[
TheNexusAvenger

Local character controller using teleporting.
--]]

local THUMBSTICK_INPUT_START_RADIUS = 0.6
local THUMBSTICK_INPUT_RELEASE_RADIUS = 0.4
local THUMBSTICK_MANUAL_ROTATION_ANGLE = math.rad(22.5)



local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local NexusVRCharacterModel = require(script.Parent.Parent.Parent)
local BaseController = NexusVRCharacterModel:GetInstance("Character.Controller.BaseController")
local ArcWithBeacon = NexusVRCharacterModel:GetInstance("Character.Controller.Visual.ArcWithBeacon")
local VRInputService = NexusVRCharacterModel:GetInstance("State.VRInputService")

local TeleportController = BaseController:Extend()
TeleportController:SetClassName("TeleportController")



--[[
Enables the controller.
--]]
function TeleportController:Enable()
    self.super:Enable()

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

    --Connect requesting jumping.
    --ButtonA does not work with IsButtonDown.
    self.ButtonADown = false
    table.insert(self.Connections,UserInputService.InputBegan:Connect(function(Input,Processsed)
        if Processsed then return end
        if Input.KeyCode == Enum.KeyCode.ButtonA then
            self.ButtonADown = true
        end
    end))
    table.insert(self.Connections,UserInputService.InputEnded:Connect(function(Input)
        if Input.KeyCode == Enum.KeyCode.ButtonA then
            self.ButtonADown = false
        end
    end))
end

--[[
Disables the controller.
--]]
function TeleportController:Disable()
    self.super:Disable()

    --Destroy the arcs.
    self.LeftArc:Destroy()
    self.RightArc:Destroy()
end

--[[
Updates the local character. Must also update the camara.
--]]
function TeleportController:UpdateCharacter()
    --Update the base character.
    self.super:UpdateCharacter()
    if not self.Character then
        return
    end

    --Get the VR inputs.
    local VRInputs = VRInputService:GetVRInputs()
    for _,InputEnum in pairs({Enum.UserCFrame.Head,Enum.UserCFrame.LeftHand,Enum.UserCFrame.RightHand}) do
        VRInputs[InputEnum] = self:ScaleInput(VRInputs[InputEnum])
    end

    --Update the arcs.
    local SeatPart = self.Character:GetHumanoidSeatPart()
    for _,ArcData in pairs(self.ArcControls) do
        --Reset the left arc if the player is in a vehicle seat.
        if ArcData.Thumbstick == Enum.KeyCode.Thumbstick1 and SeatPart and SeatPart:IsA("VehicleSeat") then
            ArcData.Arc:Hide()
            continue
        end

        --Fetch the input and calculate the radius and angle.
        local InputPosition = VRInputService:GetThumbstickPosition(ArcData.Thumbstick)
        local InputRadius = ((InputPosition.X ^ 2) + (InputPosition.Y ^ 2)) ^ 0.5
        local InputAngle = math.atan2(InputPosition.X,InputPosition.Y)

        --Determine the state.
        local DirectionState,RadiusState
        if InputAngle >= math.rad(-135) and InputAngle <= math.rad(-45) then
            DirectionState = "Left"
        elseif InputAngle >= math.rad(-45) and InputAngle <= math.rad(45) then
            DirectionState = "Forward"
        elseif InputAngle >= math.rad(45) and InputAngle <= math.rad(135) then
            DirectionState = "Right"
        end
        if InputRadius >= THUMBSTICK_INPUT_START_RADIUS then
            RadiusState = "Extended"
        elseif InputRadius <= THUMBSTICK_INPUT_RELEASE_RADIUS then
            RadiusState = "Released"
        else
            RadiusState = "InBetween"
        end

        --Update the stored state.
        local StateChange
        if ArcData.DirectionState == nil then
            if RadiusState == "Released" then
                ArcData.DirectionState = DirectionState
                ArcData.RadiusState = RadiusState
            end
        else
            if ArcData.DirectionState ~= DirectionState then
                ArcData.DirectionState = nil
                ArcData.RadiusState = nil
                StateChange = "Cancel"
            elseif (ArcData.RadiusState == nil or ArcData.RadiusState == "Released") and RadiusState == "Extended" then
                ArcData.RadiusState = RadiusState
                StateChange = "Extended"
            elseif (RadiusState == nil or RadiusState == "Released") and ArcData.RadiusState == "Extended" then
                ArcData.RadiusState = RadiusState
                StateChange = "Released"
            end
        end

        --Update from the state.
        local HumanoidRootPart = self.Character.Parts.HumanoidRootPart
        if StateChange == "Extended" then
            if not self.Character.Humanoid.Sit then
                if ArcData.DirectionState == "Left" then
                    --Turn the player to the left.
                    HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position) * CFrame.Angles(0,THUMBSTICK_MANUAL_ROTATION_ANGLE,0) * (CFrame.new(-HumanoidRootPart.Position) * HumanoidRootPart.CFrame)
                elseif ArcData.DirectionState == "Right" then
                    --Turn the player to the right.
                    HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position) * CFrame.Angles(0,-THUMBSTICK_MANUAL_ROTATION_ANGLE,0) * (CFrame.new(-HumanoidRootPart.Position) * HumanoidRootPart.CFrame)
                end
            end
        elseif StateChange == "Released" then
            ArcData.Arc:Hide()
            if ArcData.DirectionState == "Forward" then
                --Teleport the player.
                if ArcData.LastHitPart and ArcData.LastHitPosition then
                    --Unsit the player.
                    --The teleport event is set to ignored since the CFrame will be different when the player gets out of the seat.
                    local WasSitting = false
                    if SeatPart then
                        WasSitting = true
                        self.IgnoreNextExternalTeleport = true
                        self.Character.Humanoid.Sit = false
                    end

                    if (ArcData.LastHitPart:IsA("Seat") or ArcData.LastHitPart:IsA("VehicleSeat")) and not ArcData.LastHitPart.Occupant and not ArcData.LastHitPart.Disabled then
                        --Sit in the seat.
                        --Waiting is done if the player was in an existing seat because the player no longer sitting will prevent sitting.
                        if WasSitting then
                            coroutine.wrap(function()
                                while self.Character.Humanoid.SeatPart do wait() end
                                ArcData.LastHitPart:Sit(self.Character.Humanoid)
                            end)()
                        else
                            ArcData.LastHitPart:Sit(self.Character.Humanoid)
                        end
                    else
                        --Teleport the player.
                        --Waiting is done if the player was in an existing seat because the player will teleport the seat.
                        if WasSitting then
                            coroutine.wrap(function()
                                while self.Character.Humanoid.SeatPart do wait() end
                                HumanoidRootPart.CFrame = CFrame.new(ArcData.LastHitPosition) * CFrame.new(0,4.5 * self.Character.ScaleValues.BodyHeightScale.Value,0) * (CFrame.new(-HumanoidRootPart.Position) * HumanoidRootPart.CFrame)
                            end)()
                        else
                            HumanoidRootPart.CFrame = CFrame.new(ArcData.LastHitPosition) * CFrame.new(0,4.5 * self.Character.ScaleValues.BodyHeightScale.Value,0) * (CFrame.new(-HumanoidRootPart.Position) * HumanoidRootPart.CFrame)
                        end
                    end
                end
            end
        elseif StateChange == "Cancel" then
            ArcData.Arc:Hide()
        elseif ArcData.DirectionState == "Forward" and ArcData.RadiusState == "Extended" then
            ArcData.LastHitPart,ArcData.LastHitPosition = ArcData.Arc:Update(Workspace.CurrentCamera:GetRenderCFrame() * VRInputs[Enum.UserCFrame.Head]:Inverse() * VRInputs[ArcData.UserCFrame])
        end
    end

    --Update the vehicle seat.
    self:UpdateVehicleSeat()

    --Jump the player.
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) or self.ButtonADown then
        self.Character.Humanoid.Jump = true
    end
end



return TeleportController