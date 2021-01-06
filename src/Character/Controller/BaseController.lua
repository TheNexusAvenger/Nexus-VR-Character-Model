 --[[
TheNexusAvenger

Base class for controlling the local character.
--]]

local SEAT_COOLDOWN = 3



local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local NexusVRCharacterModel = require(script.Parent.Parent.Parent)
local NexusObject = NexusVRCharacterModel:GetResource("NexusInstance.NexusObject")
local CharacterService = NexusVRCharacterModel:GetInstance("State.CharacterService")
local Settings = NexusVRCharacterModel:GetInstance("State.Settings")
local VRInputService = NexusVRCharacterModel:GetInstance("State.VRInputService")
local FindCollidablePartOnRay = NexusVRCharacterModel:GetResource("Util.FindCollidablePartOnRay")

local BaseController = NexusObject:Extend()
BaseController:SetClassName("BaseController")



--[[
Updates the character. Returns if it changed.
--]]
function BaseController:UpdateCharacterReference()
    local LastCharacter = self.Character
    self.Character = CharacterService:GetCharacter(Players.LocalPlayer)
    if not self.Character then
        return
    end
    return LastCharacter ~= self.Character
end

--[[
Enables the controller.
--]]
function BaseController:Enable()
    self.VelocityY = 0

    --Update the character and return if the character is nil.
    self:UpdateCharacterReference()
    if not self.Character then
        return
    end

    --Update the reference world CFrame.
    local BaseReferenceCFrame = self.Character.Parts.Head.CFrame * VRInputService:GetVRInputs()[Enum.UserCFrame.Head]:Inverse()
    self.ReferenceWorldCFrame = CFrame.new(BaseReferenceCFrame.Position) * CFrame.Angles(0,math.atan2(-BaseReferenceCFrame.LookVector.X,-BaseReferenceCFrame.LookVector.Z),0)

    --Connect the character teleporting.
    self.Character.CharacterTeleported:Connect(function()
        if self.IgnoreNextExternalTeleport then self.IgnoreNextExternalTeleport = nil return end
        local HeadCFrame = self.Character.Parts.HumanoidRootPart.CFrame * self.Character.Attachments.HumanoidRootPart.RootRigAttachment.CFrame * self.Character.Attachments.LowerTorso.RootRigAttachment.CFrame:Inverse() * self.Character.Attachments.LowerTorso.WaistRigAttachment.CFrame * self.Character.Attachments.UpperTorso.WaistRigAttachment.CFrame * self.Character.Attachments.UpperTorso.NeckRigAttachment.CFrame * self.Character.Attachments.Head.NeckRigAttachment.CFrame
        local HeadsetCFrame = self:ScaleInput(VRInputService:GetVRInputs()[Enum.UserCFrame.Head])
        self.ReferenceWorldCFrame = HeadCFrame * CFrame.new(-HeadsetCFrame.X,0,-HeadsetCFrame.Z) * CFrame.Angles(0,-math.atan2(-HeadsetCFrame.LookVector.X,-HeadsetCFrame.LookVector.Z),0)
    end)

    --Connect the humanoid leaving the seat.
    self.Character.Humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
        if not self.Character:GetHumanoidSeatPart() then
            self.SeatCooldown = tick() + SEAT_COOLDOWN
        end
    end)
end

--[[
Disables the controller.
--]]
function BaseController:Disable()
    self.Character = nil
    self.ReferenceWorldCFrame = nil
    self.VelocityY = nil
end

--[[
Scales the local-space input CFrame based on
the height multiplier of the character.
--]]
function BaseController:ScaleInput(InputCFrame)
    --Return the original CFrame if there is no character.
    if not self.Character then
        return InputCFrame
    end

    --Return the modified CFrame.
    return CFrame.new(InputCFrame.Position * (self.Character.ScaleValues.BodyHeightScale.Value - 1)) * InputCFrame
end

--[[
Updates the reference world CFrame.
--]]
function BaseController:UpdateReferenceWorldCFrame(OverrideRaycastStartPosition)
    --Return if the character is nil.
    local CharacterChanged = self:UpdateCharacterReference()
    if not self.Character then
        return
    end
    if CharacterChanged then
        self:Enable()
    end

    --Raycast from the torso down.
    local LowerTorsoCFrame = self.Character.Parts.LowerTorso.CFrame
    local LeftHipPosition,RightHipPosition = (LowerTorsoCFrame * self.Character.Attachments.LowerTorso.LeftHipRigAttachment.CFrame).Position,(LowerTorsoCFrame * self.Character.Attachments.LowerTorso.RightHipRigAttachment.CFrame).Position
    local RightHeight = (self.Character.Attachments.RightUpperLeg.RightHipRigAttachment.Position.Y - self.Character.Attachments.RightUpperLeg.RightKneeRigAttachment.Position.Y) + (self.Character.Attachments.RightLowerLeg.RightKneeRigAttachment.Position.Y - self.Character.Attachments.RightLowerLeg.RightAnkleRigAttachment.Position.Y) + (self.Character.Attachments.RightFoot.RightAnkleRigAttachment.Position.Y - self.Character.Attachments.RightFoot.RightFootAttachment.Position.Y)
    local LeftHeight = (self.Character.Attachments.LeftUpperLeg.LeftHipRigAttachment.Position.Y - self.Character.Attachments.LeftUpperLeg.LeftKneeRigAttachment.Position.Y) + (self.Character.Attachments.LeftLowerLeg.LeftKneeRigAttachment.Position.Y - self.Character.Attachments.LeftLowerLeg.LeftAnkleRigAttachment.Position.Y) + (self.Character.Attachments.LeftFoot.LeftAnkleRigAttachment.Position.Y - self.Character.Attachments.LeftFoot.LeftFootAttachment.Position.Y)
    local LeftHitPart,LeftHitPosition,RightHitPart,RightHitPosition
    if OverrideRaycastStartPosition then
        LeftHitPart,LeftHitPosition = FindCollidablePartOnRay(OverrideRaycastStartPosition,Vector3.new(0,-500,0),self.Character.CharacterModel)
        RightHitPart,RightHitPosition = LeftHitPart,LeftHitPosition
    else
        LeftHitPart,LeftHitPosition = FindCollidablePartOnRay(LeftHipPosition,Vector3.new(0,-500,0),self.Character.CharacterModel)
        RightHitPart,RightHitPosition = FindCollidablePartOnRay(RightHipPosition,Vector3.new(0,-500,0),self.Character.CharacterModel)
    end
    local CharacterHeightWithoutLegs = (self.Character.Attachments.LowerTorso.WaistRigAttachment.Position.Y - self.Character.Attachments.LowerTorso.RightHipRigAttachment.Position.Y) + (self.Character.Attachments.UpperTorso.NeckRigAttachment.Position.Y - self.Character.Attachments.UpperTorso.WaistRigAttachment.Position.Y) - self.Character.Attachments.Head.NeckRigAttachment.Position.Y
    local CharacterHeight = RightHeight + CharacterHeightWithoutLegs

    local SeatPart = self.Character:GetHumanoidSeatPart()
    if self.Character.Humanoid.Sit and SeatPart then
        --Store the headset CFrame.
        if not self.SeatInitialHeadsetCFrame then
            self.SeatInitialHeadsetCFrame = VRInputService:GetVRInputs()[Enum.UserCFrame.Head]
        end

        --Set the offeset based on the seat.
        local Seat = SeatPart
        self.ReferenceWorldCFrame = Seat.CFrame * CFrame.new(0,(Seat.Size.Y/2) + (self.Character.Parts.LowerTorso.Size.X/2) + CharacterHeightWithoutLegs,0) * CFrame.new(-self.SeatInitialHeadsetCFrame.Position) * CFrame.Angles(0,-math.atan2(-self.SeatInitialHeadsetCFrame.LookVector.X,-self.SeatInitialHeadsetCFrame.LookVector.Z),0)
    else
        --Unset the seat headset CFrame.
        if self.SeatInitialHeadsetCFrame then
            self.SeatInitialHeadsetCFrame = nil
        end

        --Determine the highest target position.
        local HitPart,HitPosition,LegHeight,HipPosition
        if LeftHitPosition.Y > RightHitPosition.Y then
            HitPart,HitPosition,LegHeight,HipPosition = LeftHitPart,LeftHitPosition,LeftHeight,LeftHipPosition
        else
            HitPart,HitPosition,LegHeight,HipPosition = RightHitPart,RightHitPosition,RightHeight,RightHipPosition
        end

        --Update the reference world position.
        local RayCastHeightDifference = HipPosition.Y - (HitPosition.Y + LegHeight)
        local ClampOffset = (CharacterHeight + HitPosition.Y) - self.ReferenceWorldCFrame.Y
        local AllowSit = false
        if Settings:GetSetting("Movement.UseFallingSimulation") then
            if RayCastHeightDifference > 0 then
                --Simulate falling.
                if self.LastPositionUpdate then
                    --Calculate the delta time.
                    local CurrentTime = tick()
                    local DeltaTime = self.LastPositionUpdate - CurrentTime
                    self.LastPositionUpdate = CurrentTime

                    --Update height.
                    local NewVelocity = self.VelocityY + (Workspace.Gravity * DeltaTime)
                    if self.ReferenceWorldCFrame.Y + NewVelocity > HitPosition.Y + CharacterHeight then
                        self.ReferenceWorldCFrame = CFrame.new(0,NewVelocity,0) * self.ReferenceWorldCFrame
                        self.VelocityY = NewVelocity
                    else
                        self.ReferenceWorldCFrame = CFrame.new(0,ClampOffset,0) * self.ReferenceWorldCFrame
                        self.VelocityY = 0
                        AllowSit = true
                    end
                else
                    --Set the last time for the next update.
                    self.LastPositionUpdate = tick()
                end
            else
                --Clamp the player to the hit part.
                self.ReferenceWorldCFrame = CFrame.new(0,ClampOffset,0) * self.ReferenceWorldCFrame
                self.VelocityY = 0
                AllowSit = true
            end
        else
            if HitPart then
                --Clamp the player to the hit part.
                self.ReferenceWorldCFrame = CFrame.new(0,ClampOffset,0) * self.ReferenceWorldCFrame
                AllowSit = true
            end
        end

        --Correct the rotation.
        self.ReferenceWorldCFrame = CFrame.new(self.ReferenceWorldCFrame.Position) * CFrame.Angles(0,math.atan2(-self.ReferenceWorldCFrame.LookVector.X,-self.ReferenceWorldCFrame.LookVector.Z),0)

        --Allow the player to sit if the hit part was a seat.
        if AllowSit and HitPart and tick() >= (self.SeatCooldown or 0) and HitPart:IsA("Seat") and not HitPart.Occupant then
            self.Character.Parts.HumanoidRootPart.Anchored = false
            HitPart:Sit(self.Character.Humanoid)
        end
    end
end

--[[
Updates the local character. Must also update the camara.
--]]
function BaseController:UpdateCharacter()
    error("Not implemented in base class")
end



return BaseController