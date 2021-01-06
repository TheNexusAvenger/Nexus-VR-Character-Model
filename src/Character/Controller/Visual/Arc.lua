--[[
TheNexusAvenger

Visual indicator aiming with an arc.
--]]

local MAX_SEGMENTS = 100
local SEGMENT_SEPARATION = 2
local BASE_POINTER_ANGLE = math.rad(60)
local POINTER_PARABOLA_HEIGHT_MULTIPLIER = -0.2



local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local NexusVRCharacterModel = require(script.Parent.Parent.Parent.Parent)
local NexusObject = NexusVRCharacterModel:GetResource("NexusInstance.NexusObject")
local FindCollidablePartOnRay = NexusVRCharacterModel:GetResource("Util.FindCollidablePartOnRay")

local Arc = NexusObject:Extend()
Arc:SetClassName("Arc")



--[[
Creates an arc.
--]]
function Arc:__new()
    self:InitializeSuper()
    self.BeamParts = {}
    self:Hide()
end

--[[
Updates the arc. Returns the part and
position that were hit.
--]]
function Arc:Update(StartCFrame)
    --Calculate the starting angle.
    local StartPosition = StartCFrame.Position
    local FaceAngle = math.atan2(-StartCFrame.LookVector.X,-StartCFrame.LookVector.Z)
    local StartAngle = math.asin(StartCFrame.LookVector.Y)
    StartAngle = StartAngle + (BASE_POINTER_ANGLE * ((math.pi/2) - math.abs(StartAngle))/(math.pi/2))
    
    --Calculate the start CFrame and start offset of the parabola.
    --The start is the where the derivative of POINTER_PARABOLA_HEIGHT_MULTIPLIER * x^2 is tan(StartAngle).
    local StartCF = CFrame.new(StartPosition) * CFrame.Angles(0,FaceAngle,0)
    local StartOffset = math.tan(StartAngle) / (POINTER_PARABOLA_HEIGHT_MULTIPLIER * 2)
    local StartValue = POINTER_PARABOLA_HEIGHT_MULTIPLIER * (StartOffset ^ 2)

    --Create the parts until the limit is reached.
    for i = 0,MAX_SEGMENTS - 1 do
        --Calculate the current and next position.
        local SegmentStartPosition = (StartCF * CFrame.new(0,POINTER_PARABOLA_HEIGHT_MULTIPLIER * ((i + StartOffset) ^ 2) - StartValue,-SEGMENT_SEPARATION * i)).Position
        local SegmentEndPosition = (StartCF * CFrame.new(0,POINTER_PARABOLA_HEIGHT_MULTIPLIER * ((i + 1 + StartOffset) ^ 2) - StartValue,-SEGMENT_SEPARATION * (i + 1))).Position

        --Create the parts if they don't exist.
        if not self.BeamParts[i] then
            self.BeamParts[i] = Instance.new("Part")
            self.BeamParts[i].Transparency = 1
            self.BeamParts[i].Size = Vector3.new(0,0,0)
            self.BeamParts[i].Anchored = true
            self.BeamParts[i].CanCollide = false
            self.BeamParts[i].Parent = Workspace.CurrentCamera

            local Attachment = Instance.new("Attachment")
            Attachment.Name = "BeamAttachment"
            Attachment.CFrame = CFrame.Angles(0,0,math.pi/2)
            Attachment.Parent = self.BeamParts[i]
        end
        if not self.BeamParts[i + 1] then
            --Create the part and attachment.
            self.BeamParts[i + 1] = Instance.new("Part")
            self.BeamParts[i + 1].Transparency = 1
            self.BeamParts[i + 1].Size = Vector3.new(0,0,0)
            self.BeamParts[i + 1].Anchored = true
            self.BeamParts[i + 1].CanCollide = false
            self.BeamParts[i + 1].Parent = Workspace.CurrentCamera

            local Attachment = Instance.new("Attachment")
            Attachment.Name = "BeamAttachment"
            Attachment.CFrame = CFrame.Angles(0,0,math.pi/2)
            Attachment.Parent = self.BeamParts[i + 1]

            --Create the beam.
            local Beam = Instance.new("Beam")
            Beam.Name = "Beam"
            Beam.Attachment0 = self.BeamParts[i].BeamAttachment
            Beam.Attachment1 = Attachment
            Beam.Segments = 1
            Beam.Width0 = 0.1
            Beam.Width1 = 0.1
            Beam.Parent = self.BeamParts[i + 1]
        end

        --Cast the ray to the end.
        --Return if an end was hit and make the arc blue.
        local HitPart,HitPosition = FindCollidablePartOnRay(SegmentStartPosition,SegmentEndPosition - SegmentStartPosition,Players.LocalPlayer and Players.LocalPlayer.Character)
        self.BeamParts[i].CFrame = CFrame.new(SegmentStartPosition) * CFrame.Angles(0,FaceAngle,0)
        self.BeamParts[i + 1].Beam.Enabled = true
        if HitPart then
            self.BeamParts[i + 1].CFrame = CFrame.new(HitPosition)
            for j = 0,i do
                self.BeamParts[j + 1].Beam.Color = ColorSequence.new(Color3.new(0,170/255,255/255))
            end
            for j = i + 1,#self.BeamParts - 1 do
                self.BeamParts[j + 1].Beam.Enabled = false
            end
            return HitPart,HitPosition
        else
            self.BeamParts[i + 1].CFrame = CFrame.new(SegmentEndPosition)
        end
    end

    --Set the beams to red.
    for i = 0,#self.BeamParts - 1 do
        self.BeamParts[i + 1].Beam.Color = ColorSequence.new(Color3.new(200/255,0,0))
    end
end

--[[
Hides the arc.
--]]
function Arc:Hide()
    for i = 0,#self.BeamParts - 1 do
        self.BeamParts[i + 1].Beam.Enabled = false
    end
end

--[[
Destroys the arc.
--]]
function Arc:Destroy()
    for _,BeamPart in pairs(self.BeamParts) do
        BeamPart:Destroy()
    end
    self.BeamParts = {}
end



return Arc