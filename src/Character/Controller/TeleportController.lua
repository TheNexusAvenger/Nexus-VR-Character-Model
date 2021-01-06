 --[[
TheNexusAvenger

Local character controller using teleporting.
--]]

local THUMBSTICK_INPUT_START_RADIUS = 0.6
local THUMBSTICK_INPUT_RELEASE_RADIUS = 0.4
local THUMBSTICK_MANUAL_ROTATION_ANGLE = math.rad(22.5)



local NexusVRCharacterModel = require(script.Parent.Parent.Parent)
local BaseController = NexusVRCharacterModel:GetInstance("Character.Controller.BaseController")
local ArcWithBeacon = NexusVRCharacterModel:GetInstance("Character.Controller.Visual.ArcWithBeacon")
local CameraService = NexusVRCharacterModel:GetInstance("State.CameraService")
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
    --Update the world CFrame reference.
    self:UpdateReferenceWorldCFrame()
    if not self.Character then
        return
    end
    self.Character.TweenComponents = false

    --Get the VR inputs and convert them to world space.
    local VRInputs = VRInputService:GetVRInputs()

    --Update the arcs.
    for _,ArcData in pairs(self.ArcControls) do
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
        if StateChange == "Extended" then
            if not self.Character.Humanoid.Sit then
                if ArcData.DirectionState == "Left" then
                    --Turn the player to the left.
                    self.ReferenceWorldCFrame = self.ReferenceWorldCFrame * CFrame.Angles(0,THUMBSTICK_MANUAL_ROTATION_ANGLE,0)
                elseif ArcData.DirectionState == "Right" then
                    --Turn the player to the right.
                    self.ReferenceWorldCFrame = self.ReferenceWorldCFrame * CFrame.Angles(0,-THUMBSTICK_MANUAL_ROTATION_ANGLE,0)
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
                    if self.Character:GetHumanoidSeatPart() then
                        WasSitting = true
                        self.IgnoreNextExternalTeleport = true
                        self.Character.Humanoid.Sit = false
                    end

                    self.Character.Parts.HumanoidRootPart.Anchored = true
                    if ArcData.LastHitPart:IsA("Seat") and not ArcData.LastHitPart.Occupant then
                        --Sit in the seat.
                        --Waiting is done if the player was in an existing seat because the player no longer sitting will prevent sitting.
                        if WasSitting then
                            coroutine.wrap(function()
                                while self.Character.Humanoid.SeatPart do wait() end
                                self.Character.Parts.HumanoidRootPart.Anchored = false
                                ArcData.LastHitPart:Sit(self.Character.Humanoid)
                            end)()
                        else
                            self.Character.Parts.HumanoidRootPart.Anchored = true
                            ArcData.LastHitPart:Sit(self.Character.Humanoid)
                        end
                    else
                        --Teleport the player.
                        --Waiting is done if the player was in an existing seat because the player will teleport the seat.
                        if WasSitting then
                            coroutine.wrap(function()
                                while self.Character.Humanoid.SeatPart do wait() end
                                self.ReferenceWorldCFrame = CFrame.new(ArcData.LastHitPosition) * CFrame.new(0,4.5 * self.Character.ScaleValues.BodyHeightScale.Value,0) * (CFrame.new(-self.ReferenceWorldCFrame.Position) * self.ReferenceWorldCFrame)
                                self:UpdateReferenceWorldCFrame((CFrame.new(ArcData.LastHitPosition) * CFrame.new(0,2 * self.Character.ScaleValues.BodyHeightScale.Value,0)).Position)
                            end)()
                        else
                            self.ReferenceWorldCFrame = CFrame.new(ArcData.LastHitPosition) * CFrame.new(0,4.5 * self.Character.ScaleValues.BodyHeightScale.Value,0) * (CFrame.new(-self.ReferenceWorldCFrame.Position) * self.ReferenceWorldCFrame)
                            self:UpdateReferenceWorldCFrame((CFrame.new(ArcData.LastHitPosition) * CFrame.new(0,2 * self.Character.ScaleValues.BodyHeightScale.Value,0)).Position)
                        end
                    end
                end
            end
        elseif StateChange == "Cancel" then
            ArcData.Arc:Hide()
        elseif ArcData.DirectionState == "Forward" and ArcData.RadiusState == "Extended" then
            ArcData.LastHitPart,ArcData.LastHitPosition = ArcData.Arc:Update(self.ReferenceWorldCFrame * VRInputs[ArcData.UserCFrame])
        end
    end

    --Convert the VR inputs from local to world space.
    for _,InputEnum in pairs({Enum.UserCFrame.Head,Enum.UserCFrame.LeftHand,Enum.UserCFrame.RightHand}) do
        VRInputs[InputEnum] = self.ReferenceWorldCFrame * self:ScaleInput(VRInputs[InputEnum])
    end

    --Update the character.
    self.Character:UpdateFromInputs(VRInputs[Enum.UserCFrame.Head],VRInputs[Enum.UserCFrame.LeftHand],VRInputs[Enum.UserCFrame.RightHand])

    --Update the camera.
    CameraService:UpdateCamera(VRInputs[Enum.UserCFrame.Head])
end



return TeleportController