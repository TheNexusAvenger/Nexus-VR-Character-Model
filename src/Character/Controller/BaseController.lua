 --[[
TheNexusAvenger

Base class for controlling the local character.
--]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local NexusVRCharacterModel = require(script.Parent.Parent.Parent)
local NexusObject = NexusVRCharacterModel:GetResource("NexusInstance.NexusObject")
local CharacterService = NexusVRCharacterModel:GetInstance("State.CharacterService")
local Settings = NexusVRCharacterModel:GetInstance("State.Settings")
local VRInputService = NexusVRCharacterModel:GetInstance("State.VRInputService")

local BaseController = NexusObject:Extend()
BaseController:SetClassName("BaseController")



--[[
Raycasts to a collidable part.
--]]
local function FindCollidablePartOnRay(Start,Direction,Ignore)
    --Raycast and continue if the hit part isn't collidable.
	local Hit,End = Workspace:FindPartOnRayWithIgnoreList(Ray.new(Start,Direction),{Workspace.CurrentCamera,Ignore})
	if Hit and not Hit.CanCollide then
		return FindCollidablePartOnRay(End + (Direction * 0.01),Direction - (Start - End),Ignore)
	end
    
    --Return the hit result.
	return Hit,End
end



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
    --Update the character and return if the character is nil.
    self:UpdateCharacterReference()
    if not self.Character then
        return
    end

    --Update the reference world CFrame.
    local BaseReferenceCFrame = self.Character.Parts.Head.CFrame * VRInputService:GetVRInputs()[Enum.UserCFrame.Head]:Inverse()
    self.ReferenceWorldCFrame = CFrame.new(BaseReferenceCFrame.Position) * CFrame.Angles(0,math.atan2(-BaseReferenceCFrame.LookVector.X,-BaseReferenceCFrame.LookVector.Z),0)
end

--[[
Disables the controller.
--]]
function BaseController:Disable()
    self.Character = nil
    self.ReferenceWorldCFrame = nil
end

--[[
Updates the reference world CFrame.
--]]
function BaseController:UpdateReferenceWorldCFrame()
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
    local LeftHipPosition,RightHipPosition = (LowerTorsoCFrame * self.Character.Attachments.LowerTorso.LeftHipRigAttachment.CFrame).Position,(LowerTorsoCFrame * LowerTorsoCFrame * self.Character.Attachments.LowerTorso.RightHipRigAttachment.CFrame).Position
    local RightHeight = (self.Character.Attachments.RightUpperLeg.RightHipRigAttachment.Position.Y - self.Character.Attachments.RightUpperLeg.RightKneeRigAttachment.Position.Y) + (self.Character.Attachments.RightLowerLeg.RightKneeRigAttachment.Position.Y - self.Character.Attachments.RightLowerLeg.RightAnkleRigAttachment.Position.Y) + (self.Character.Attachments.RightFoot.RightAnkleRigAttachment.Position.Y - self.Character.Attachments.RightFoot.RightFootAttachment.Position.Y)
    local LeftHeight = (self.Character.Attachments.LeftUpperLeg.LeftHipRigAttachment.Position.Y - self.Character.Attachments.LeftUpperLeg.LeftKneeRigAttachment.Position.Y) + (self.Character.Attachments.LeftLowerLeg.LeftKneeRigAttachment.Position.Y - self.Character.Attachments.LeftLowerLeg.LeftAnkleRigAttachment.Position.Y) + (self.Character.Attachments.LeftFoot.LeftAnkleRigAttachment.Position.Y - self.Character.Attachments.LeftFoot.LeftFootAttachment.Position.Y)
    local LeftHitPart,LeftHitPosition = FindCollidablePartOnRay(LeftHipPosition,Vector3.new(0,-500,0),self.Character.CharacterModel)
    local RightHitPart,RightHitPosition = FindCollidablePartOnRay(RightHipPosition,Vector3.new(0,-500,0),self.Character.CharacterModel)
    local CharacterHeight = RightHeight + (self.Character.Attachments.LowerTorso.WaistRigAttachment.Position.Y - self.Character.Attachments.LowerTorso.RightHipRigAttachment.Position.Y) + (self.Character.Attachments.UpperTorso.NeckRigAttachment.Position.Y - self.Character.Attachments.UpperTorso.WaistRigAttachment.Position.Y) - self.Character.Attachments.Head.NeckRigAttachment.Position.Y

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
    if Settings:GetSetting("Movement.UseFallingSimulation") then
        if RayCastHeightDifference > 0 then
            --Simulate falling.
            if self.LastPositionUpdate then
                --Calculate the delta time.
                local CurrentTime = tick()
                local DeltaTime = self.LastPositionUpdate - CurrentTime
                self.LastPositionUpdate = CurrentTime

                --Update height.
                local NewVelocity = self.Character.Parts.HumanoidRootPart.Velocity - Vector3.new(0,-Workspace.Gravity * DeltaTime,0)
                if self.ReferenceWorldCFrame.Y + NewVelocity.Y > HitPosition.Y + LegHeight then
                    self.ReferenceWorldCFrame = CFrame.new(0,ClampOffset,0) * self.ReferenceWorldCFrame
                    self.Character.Parts.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
                else
                    self.ReferenceWorldCFrame = CFrame.new(0,NewVelocity.Y,0) * self.ReferenceWorldCFrame
                    self.Character.Parts.HumanoidRootPart.Velocity = NewVelocity
                end
            end
        else
            --Clamp the player to the hit part.
            self.ReferenceWorldCFrame = CFrame.new(0,ClampOffset,0) * self.ReferenceWorldCFrame
        end
    else
        if HitPart then
            --Clamp the player to the hit part.
            self.ReferenceWorldCFrame = CFrame.new(0,ClampOffset,0) * self.ReferenceWorldCFrame
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