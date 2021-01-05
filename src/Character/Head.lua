--[[
TheNexusAvenger

Stores information about the head of a character.
--]]

local NexusVRCharacterModel = require(script.Parent.Parent)
local Limb = NexusVRCharacterModel:GetResource("Character.Limb")
local Settings = NexusVRCharacterModel:GetInstance("State.Settings")

local Head = Limb:Extend()
Head:SetClassName("Head")



--[[
Creates a head.
--]]
function Head:__new(Head)
    self:InitializeSuper()

    --Store the parts.
    self.Head = Head
end

--[[
Returns the head CFrame for the
given VR input in global world space.
--]]
function Head:GetHeadCFrame(VRHeadCFrame)
    return VRHeadCFrame * (self:GetAttachmentCFrame(self.Head,"FaceFrontAttachment") * CFrame.new(0,self.Head.Size.Y/4,0)):inverse()
end

--[[
Returns the neck CFrame for the
given VR input in global world space.
--]]
function Head:GetNeckCFrame(VRHeadCFrame,OverrideSeatCFrame)
    --Get the base neck CFrame and angles.
    local BaseNeckCFrame = self:GetHeadCFrame(VRHeadCFrame) * self:GetAttachmentCFrame(self.Head,"NeckRigAttachment")
    local BaseNeckLookVector = BaseNeckCFrame.LookVector
    local BaseNeckLook,BaseNeckTilt = math.atan2(BaseNeckLookVector.X,BaseNeckLookVector.Z) + math.pi,math.asin(BaseNeckLookVector.Y)

    --Clamp the new neck tilt.
    local NewNeckTilt = 0
    local MaxNeckTilt = Settings:GetSetting("Appearance.MaxNeckTilt") or math.rad(60)
    if BaseNeckTilt > MaxNeckTilt then
        NewNeckTilt = BaseNeckTilt - MaxNeckTilt
    elseif BaseNeckTilt < -MaxNeckTilt then
        NewNeckTilt = BaseNeckTilt + MaxNeckTilt
    end

    --Clamp the neck rotation if it is turning.
    local MaxNeckRotation = Settings:GetSetting("Appearance.MaxNeckRotation") or math.rad(35)
    if self.LastNeckRotationGlobal then
        --Determine the minimum angle difference.
        --Modulus is not used as it guarentees a positive answer, not the minimum answer, which can be negative.
        local RotationDifference = (BaseNeckLook - self.LastNeckRotationGlobal)
        while RotationDifference > math.pi do RotationDifference = RotationDifference - (2 * math.pi) end
        while RotationDifference < -math.pi do RotationDifference = RotationDifference + (2 * math.pi) end

        --Set the angle based on if it is over the limit or not.
        --Ignore if there is no previous stored rotation or if the rotation is "big" (like teleporting).
        if math.abs(RotationDifference) < 1.5 * MaxNeckRotation then
            if RotationDifference > MaxNeckRotation then
                BaseNeckLook = BaseNeckLook - MaxNeckRotation
            elseif RotationDifference < -MaxNeckRotation then
                BaseNeckLook = BaseNeckLook + MaxNeckRotation
            else
                BaseNeckLook = self.LastNeckRotationGlobal
            end
        end
    end
    self.LastNeckRotationGlobal = BaseNeckLook
    
    --Return the new neck CFrame.
    if OverrideSeatCFrame then
        return CFrame.new(BaseNeckCFrame.Position) * CFrame.new(-OverrideSeatCFrame.Position) * OverrideSeatCFrame * CFrame.Angles(NewNeckTilt,0,0)
    end
    return CFrame.new(BaseNeckCFrame.Position) * CFrame.Angles(0,BaseNeckLook,0) * CFrame.Angles(NewNeckTilt,0,0)
end



return Head