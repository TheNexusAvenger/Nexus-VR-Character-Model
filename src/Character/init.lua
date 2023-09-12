--[[
TheNexusAvenger

Manipulates a character model.
--]]
--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local NexusVRCharacterModel = script.Parent
local Head = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("Head"))
local Torso = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("Torso"))
local Appendage = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("Appendage"))
local FootPlanter = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("FootPlanter"))
local Settings = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("Settings")).GetInstance()
local NormalizeAssetId = require(NexusVRCharacterModel:WaitForChild("Util"):WaitForChild("NormalizeAssetId"))
local UpdateInputs = NexusVRCharacterModel:WaitForChild("UpdateInputs") :: RemoteEvent

local Character = {}
Character.__index = Character

export type Character = {
    new: (CharacterModel: Model) -> Character,

    UpdateFromInputs: (self: Character, HeadControllerCFrame: CFrame, LeftHandControllerCFrame: CFrame, RightHandControllerCFrame: CFrame) -> (),
}



--[[
Creates a character.
--]]
function Character.new(CharacterModel: Model): Character
    local self = {
        CharacterModel = CharacterModel,
        TweenComponents = true,
    }
    setmetatable(self, Character)

    --Determine if the arms can be disconnected.
    --Checking for the setting to be explicitly false is done in case the setting is undefined (default is true).
    local PreventArmDisconnection = false
    if Players.LocalPlayer and Players.LocalPlayer.Character == CharacterModel then
        local Setting = Settings:GetSetting("Appearance.LocalAllowArmDisconnection")
        if Setting == false then
            PreventArmDisconnection = true
        end
    else
        local Setting = Settings:GetSetting("Appearance.NonLocalAllowArmDisconnection")
        if Setting == false then
            PreventArmDisconnection = true
        end
    end

    --Store the body parts.
    self.Humanoid = CharacterModel:WaitForChild("Humanoid")
    self.Parts = {
        Head = CharacterModel:WaitForChild("Head"),
        UpperTorso = CharacterModel:WaitForChild("UpperTorso"),
        LowerTorso = CharacterModel:WaitForChild("LowerTorso"),
        HumanoidRootPart = CharacterModel:WaitForChild("HumanoidRootPart"),
        RightUpperArm = CharacterModel:WaitForChild("RightUpperArm"),
        RightLowerArm = CharacterModel:WaitForChild("RightLowerArm"),
        RightHand = CharacterModel:WaitForChild("RightHand"),
        LeftUpperArm = CharacterModel:WaitForChild("LeftUpperArm"),
        LeftLowerArm = CharacterModel:WaitForChild("LeftLowerArm"),
        LeftHand = CharacterModel:WaitForChild("LeftHand"),
        RightUpperLeg = CharacterModel:WaitForChild("RightUpperLeg"),
        RightLowerLeg = CharacterModel:WaitForChild("RightLowerLeg"),
        RightFoot = CharacterModel:WaitForChild("RightFoot"),
        LeftUpperLeg = CharacterModel:WaitForChild("LeftUpperLeg"),
        LeftLowerLeg = CharacterModel:WaitForChild("LeftLowerLeg"),
        LeftFoot = CharacterModel:WaitForChild("LeftFoot"),
    }
    self.Motors = {
        Neck = self.Parts.Head:WaitForChild("Neck"),
        Waist = self.Parts.UpperTorso:WaitForChild("Waist"),
        Root = self.Parts.LowerTorso:WaitForChild("Root"),
        RightShoulder = self.Parts.RightUpperArm:WaitForChild("RightShoulder"),
        RightElbow = self.Parts.RightLowerArm:WaitForChild("RightElbow"),
        RightWrist = self.Parts.RightHand:WaitForChild("RightWrist"),
        LeftShoulder = self.Parts.LeftUpperArm:WaitForChild("LeftShoulder"),
        LeftElbow = self.Parts.LeftLowerArm:WaitForChild("LeftElbow"),
        LeftWrist = self.Parts.LeftHand:WaitForChild("LeftWrist"),
        RightHip = self.Parts.RightUpperLeg:WaitForChild("RightHip"),
        RightKnee = self.Parts.RightLowerLeg:WaitForChild("RightKnee"),
        RightAnkle = self.Parts.RightFoot:WaitForChild("RightAnkle"),
        LeftHip = self.Parts.LeftUpperLeg:WaitForChild("LeftHip"),
        LeftKnee = self.Parts.LeftLowerLeg:WaitForChild("LeftKnee"),
        LeftAnkle = self.Parts.LeftFoot:WaitForChild("LeftAnkle"),
    }
    self.Attachments = {
        Head = {
            NeckRigAttachment = self.Parts.Head:WaitForChild("NeckRigAttachment"),
        },
        UpperTorso = {
            NeckRigAttachment = self.Parts.UpperTorso:WaitForChild("NeckRigAttachment"),
            LeftShoulderRigAttachment = self.Parts.UpperTorso:WaitForChild("LeftShoulderRigAttachment"),
            RightShoulderRigAttachment = self.Parts.UpperTorso:WaitForChild("RightShoulderRigAttachment"),
            WaistRigAttachment = self.Parts.UpperTorso:WaitForChild("WaistRigAttachment"),
        },
        LowerTorso = {
            WaistRigAttachment = self.Parts.LowerTorso:WaitForChild("WaistRigAttachment"),
            LeftHipRigAttachment = self.Parts.LowerTorso:WaitForChild("LeftHipRigAttachment"),
            RightHipRigAttachment = self.Parts.LowerTorso:WaitForChild("RightHipRigAttachment"),
            RootRigAttachment = self.Parts.LowerTorso:WaitForChild("RootRigAttachment"),
        },
        HumanoidRootPart = {
            RootRigAttachment = self.Parts.HumanoidRootPart:WaitForChild("RootRigAttachment"),
        },
        RightUpperArm = {
            RightShoulderRigAttachment = self.Parts.RightUpperArm:WaitForChild("RightShoulderRigAttachment"),
            RightElbowRigAttachment = self.Parts.RightUpperArm:WaitForChild("RightElbowRigAttachment"),
        },
        RightLowerArm = {
            RightElbowRigAttachment = self.Parts.RightLowerArm:WaitForChild("RightElbowRigAttachment"),
            RightWristRigAttachment = self.Parts.RightLowerArm:WaitForChild("RightWristRigAttachment"),
        },
        RightHand = {
            RightWristRigAttachment = self.Parts.RightHand:WaitForChild("RightWristRigAttachment"),
        },
        LeftUpperArm = {
            LeftShoulderRigAttachment = self.Parts.LeftUpperArm:WaitForChild("LeftShoulderRigAttachment"),
            LeftElbowRigAttachment = self.Parts.LeftUpperArm:WaitForChild("LeftElbowRigAttachment"),
        },
        LeftLowerArm = {
            LeftElbowRigAttachment = self.Parts.LeftLowerArm:WaitForChild("LeftElbowRigAttachment"),
            LeftWristRigAttachment = self.Parts.LeftLowerArm:WaitForChild("LeftWristRigAttachment"),
        },
        LeftHand = {
            LeftWristRigAttachment = self.Parts.LeftHand:WaitForChild("LeftWristRigAttachment"),
        },
        RightUpperLeg = {
            RightHipRigAttachment = self.Parts.RightUpperLeg:WaitForChild("RightHipRigAttachment"),
            RightKneeRigAttachment = self.Parts.RightUpperLeg:WaitForChild("RightKneeRigAttachment"),
        },
        RightLowerLeg = {
            RightKneeRigAttachment = self.Parts.RightLowerLeg:WaitForChild("RightKneeRigAttachment"),
            RightAnkleRigAttachment = self.Parts.RightLowerLeg:WaitForChild("RightAnkleRigAttachment"),
        },
        RightFoot = {
            RightAnkleRigAttachment = self.Parts.RightFoot:WaitForChild("RightAnkleRigAttachment"),
            RightFootAttachment = self.Parts.RightFoot:FindFirstChild("RightFootAttachment"),
        },
        LeftUpperLeg = {
            LeftHipRigAttachment = self.Parts.LeftUpperLeg:WaitForChild("LeftHipRigAttachment"),
            LeftKneeRigAttachment = self.Parts.LeftUpperLeg:WaitForChild("LeftKneeRigAttachment"),
        },
        LeftLowerLeg = {
            LeftKneeRigAttachment = self.Parts.LeftLowerLeg:WaitForChild("LeftKneeRigAttachment"),
            LeftAnkleRigAttachment = self.Parts.LeftLowerLeg:WaitForChild("LeftAnkleRigAttachment"),
        },
        LeftFoot = {
            LeftAnkleRigAttachment = self.Parts.LeftFoot:WaitForChild("LeftAnkleRigAttachment"),
            LeftFootAttachment = self.Parts.LeftFoot:FindFirstChild("LeftFootAttachment"),
        },
    }
    self.ScaleValues = {
        BodyDepthScale = self.Humanoid:WaitForChild("BodyDepthScale"),
        BodyWidthScale = self.Humanoid:WaitForChild("BodyWidthScale"),
        BodyHeightScale = self.Humanoid:WaitForChild("BodyHeightScale"),
        HeadScale = self.Humanoid:WaitForChild("HeadScale"),
    }
    self.MoodAnimationIds = {}

    --Add the missing attachments that not all rigs have.
    if not self.Attachments.RightFoot.RightFootAttachment then
        local NewAttachment = Instance.new("Attachment")
        NewAttachment.Position = Vector3.new(0, -(self.Parts.RightFoot :: BasePart).Size.Y / 2, 0)
        NewAttachment.Name = "RightFootAttachment"

        local OriginalPositionValue = Instance.new("Vector3Value")
        OriginalPositionValue.Name = "OriginalPosition"
        OriginalPositionValue.Value = NewAttachment.Position
        OriginalPositionValue.Parent = NewAttachment
        NewAttachment.Parent = self.Parts.RightFoot
        self.Attachments.RightFoot.RightFootAttachment = NewAttachment
    end
    if not self.Attachments.LeftFoot.LeftFootAttachment then
        local NewAttachment = Instance.new("Attachment")
        NewAttachment.Position = Vector3.new(0, -(self.Parts.LeftFoot :: BasePart).Size.Y / 2, 0)
        NewAttachment.Name = "LeftFootAttachment"

        local OriginalPositionValue = Instance.new("Vector3Value")
        OriginalPositionValue.Name = "OriginalPosition"
        OriginalPositionValue.Value = NewAttachment.Position
        OriginalPositionValue.Parent = NewAttachment
        NewAttachment.Parent = self.Parts.LeftFoot
        self.Attachments.LeftFoot.LeftFootAttachment = NewAttachment
    end

    --Store the limbs.
    self.Head = Head.new(self.Parts.Head :: BasePart)
    self.Torso = Torso.new(self.Parts.LowerTorso :: BasePart, self.Parts.UpperTorso :: BasePart)
    self.LeftArm = Appendage.new(CharacterModel:WaitForChild("LeftUpperArm") :: BasePart, CharacterModel:WaitForChild("LeftLowerArm") :: BasePart, CharacterModel:WaitForChild("LeftHand") :: BasePart, "LeftShoulderRigAttachment", "LeftElbowRigAttachment", "LeftWristRigAttachment", "LeftGripAttachment", PreventArmDisconnection)
    self.RightArm = Appendage.new(CharacterModel:WaitForChild("RightUpperArm") :: BasePart, CharacterModel:WaitForChild("RightLowerArm") :: BasePart, CharacterModel:WaitForChild("RightHand") :: BasePart, "RightShoulderRigAttachment", "RightElbowRigAttachment", "RightWristRigAttachment", "RightGripAttachment", PreventArmDisconnection)
    self.LeftLeg = Appendage.new(CharacterModel:WaitForChild("LeftUpperLeg") :: BasePart, CharacterModel:WaitForChild("LeftLowerLeg") :: BasePart, CharacterModel:WaitForChild("LeftFoot") :: BasePart, "LeftHipRigAttachment", "LeftKneeRigAttachment", "LeftAnkleRigAttachment", "LeftFootAttachment", true)
    self.LeftLeg.InvertBendDirection = true
    self.RightLeg = Appendage.new(CharacterModel:WaitForChild("RightUpperLeg") :: BasePart, CharacterModel:WaitForChild("RightLowerLeg") :: BasePart, CharacterModel:WaitForChild("RightFoot") :: BasePart, "RightHipRigAttachment", "RightKneeRigAttachment", "RightAnkleRigAttachment", "RightFootAttachment", true)
    self.RightLeg.InvertBendDirection = true
    self.FootPlanter = FootPlanter:CreateSolver(CharacterModel:WaitForChild("LowerTorso"), self.ScaleValues.BodyHeightScale)

    --Stop the character animations.
    local Animator = self.Humanoid:FindFirstChild("Animator") :: Animator
    if Animator then
        if Players.LocalPlayer and Players.LocalPlayer.Character == CharacterModel then
            --Remove the animation script and store the mood animations.
            local AnimateScript = CharacterModel:WaitForChild("Animate")
            local MoodValue = AnimateScript:FindFirstChild("mood") :: Instance
            if MoodValue then
                for _, Animation in MoodValue:GetChildren() do
                    if not Animation:IsA("Animation") then continue end
                    self.MoodAnimationIds[NormalizeAssetId((Animation :: Animation).AnimationId)] = true
                end
            end
            AnimateScript:Destroy()

            --Stop the animations.
            for _, Track in Animator:GetPlayingAnimationTracks() do
                if self:IsAnimationTrackAllowed(Track) then continue end
                Track:AdjustWeight(0, 0)
                Track:Stop(0)
            end
            Animator.AnimationPlayed:Connect(function(Track)
                if self:IsAnimationTrackAllowed(Track) then return end
                Track:AdjustWeight(0, 0)
                Track:Stop(0)
            end)
        else
            Animator:Destroy()
        end
    end
    self.Humanoid.ChildAdded:Connect(function(NewAnimator)
        if NewAnimator:IsA("Animator") then
            if Players.LocalPlayer and Players.LocalPlayer.Character == CharacterModel then
                for _, Track in NewAnimator:GetPlayingAnimationTracks() do
                    if self:IsAnimationTrackAllowed(Track) then continue end
                    Track:AdjustWeight(0, 0)
                    Track:Stop(0)
                end
                NewAnimator.AnimationPlayed:Connect(function(Track)
                    if self:IsAnimationTrackAllowed(Track) then return end
                    Track:AdjustWeight(0, 0)
                    Track:Stop(0)
                end)
            else
                NewAnimator:Destroy()
            end
        end
    end)

    --Set up replication at 30hz.
    if Players.LocalPlayer and Players.LocalPlayer.Character == CharacterModel then
        task.spawn(function()
            while (self.Humanoid :: Humanoid).Health > 0 do
                --Send the new CFrames if the CFrames changed.
                if (self :: any).LastReplicationCFrames ~= (self :: any).ReplicationCFrames then
                    (self :: any).LastReplicationCFrames = (self :: any).ReplicationCFrames
                    UpdateInputs:FireServer(unpack((self :: any).ReplicationCFrames))
                end

                --Wait 1/30th of a second to send the next set of CFrames.
                task.wait(1 / 30)
            end
        end)
    end
    
    return (self :: any) :: Character
end

--[[
Returns if an animation track is allowed to be played.
--]]
function Character:IsAnimationTrackAllowed(Track: AnimationTrack): boolean
    if not Track.Animation then return false end
    if self.MoodAnimationIds[NormalizeAssetId((Track.Animation :: Animation).AnimationId)] then return true end
    return false
end

--[[
Returns the SeatPart of the humanoid.
SeatPart is not replicated to new players, which results in
strange movements of character.
https://devforum.roblox.com/t/seat-occupant-and-humanoid-seatpart-not-replicating-to-new-players-to-a-server/261545
--]]
function Character:GetHumanoidSeatPart(): BasePart?
    --Return nil if the Humanoid is not sitting.
    if not self.Humanoid.Sit then
        return nil
    end

    --Return if the seat part is defined.
    if self.Humanoid.SeatPart then
        return self.Humanoid.SeatPart
    end

    --Iterated through the connected parts and return if a seat exists.
    --While SeatPart may not be set, a SeatWeld does exist.
    for _, ConnectedPart in self.Parts.HumanoidRootPart:GetConnectedParts() do
        if ConnectedPart:IsA("Seat") or ConnectedPart:IsA("VehicleSeat") then
            return ConnectedPart
        end
    end
    return nil
end
--[[
Sets a property. The property will either be
set instantly or tweened depending on how
it is configured.
--]]
function Character:SetCFrameProperty(Object: Instance, PropertyName: string, PropertyValue: any): ()
    if self.TweenComponents then
        TweenService:Create(
            Object,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                [PropertyName] = PropertyValue,
            }
        ):Play()
    else
        (Object :: any)[PropertyName] = PropertyValue
    end
end

--[[
Sets the transform of a motor.
--]]
function Character:SetTransform(MotorName: string, AttachmentName: string, StartLimbName: string, EndLimbName: string, StartCFrame: CFrame, EndCFrame: CFrame): ()
    self:SetCFrameProperty(self.Motors[MotorName], "Transform", (StartCFrame * self.Attachments[StartLimbName][AttachmentName].CFrame):Inverse() * (EndCFrame * self.Attachments[EndLimbName][AttachmentName].CFrame))
end

--[[
Updates the character from the inputs.
--]]
function Character:UpdateFromInputs(HeadControllerCFrame: CFrame, LeftHandControllerCFrame: CFrame, RightHandControllerCFrame: CFrame): ()
    --Return if the humanoid is dead.
    if self.Humanoid.Health <= 0 then
        return
    end

    --Call the other method if there is a SeatPart.
    --The math below is not used while in seats due to assumptions made while standing.
    --The CFrames will already be in local space from the replication.
    local SeatPart = self:GetHumanoidSeatPart()
    if SeatPart then
        self:UpdateFromInputsSeated(HeadControllerCFrame, LeftHandControllerCFrame, RightHandControllerCFrame)
        return
    end

    --Get the CFrames.
    local HeadCFrame = self.Head:GetHeadCFrame(HeadControllerCFrame)
    local NeckCFrame = self.Head:GetNeckCFrame(HeadControllerCFrame)
	local LowerTorsoCFrame: CFrame, UpperTorsoCFrame = self.Torso:GetTorsoCFrames(NeckCFrame)
	local JointCFrames = self.Torso:GetAppendageJointCFrames(LowerTorsoCFrame, UpperTorsoCFrame)
	local LeftUpperArmCFrame, LeftLowerArmCFrame, LeftHandCFrame = self.LeftArm:GetAppendageCFrames(JointCFrames["LeftShoulder"], LeftHandControllerCFrame)
	local RightUpperArmCFrame, RightLowerArmCFrame, RightHandCFrame = self.RightArm:GetAppendageCFrames(JointCFrames["RightShoulder"], RightHandControllerCFrame)

    --Set the character CFrames.
    --HumanoidRootParts must always face up. This makes the math more complicated.
    --Setting the CFrame directly to something not facing directly up will result in the physics
    --attempting to correct that within the next frame, causing the character to appear to move.
    local LeftFoot: CFrame, RightFoot: CFrame = self.FootPlanter:GetFeetCFrames()
    local LeftUpperLegCFrame, LeftLowerLegCFrame, LeftFootCFrame = self.LeftLeg:GetAppendageCFrames(JointCFrames["LeftHip"], LeftFoot * CFrame.Angles(0, math.pi, 0))
    local RightUpperLegCFrame, RightLowerLegCFrame, RightFootCFrame = self.RightLeg:GetAppendageCFrames(JointCFrames["RightHip"], RightFoot * CFrame.Angles(0, math.pi, 0))
    local TargetHumanoidRootPartCFrame = LowerTorsoCFrame * self.Attachments.LowerTorso.RootRigAttachment.CFrame * self.Attachments.HumanoidRootPart.RootRigAttachment.CFrame:Inverse()
    local ActualHumanoidRootPartCFrame: CFrame = self.Parts.HumanoidRootPart.CFrame
    local HumanoidRootPartHeightDifference = ActualHumanoidRootPartCFrame.Y - TargetHumanoidRootPartCFrame.Y
    local NewTargetHumanoidRootPartCFrame = CFrame.new(TargetHumanoidRootPartCFrame.Position)
    self:SetCFrameProperty(self.Parts.HumanoidRootPart, "CFrame", CFrame.new(0, HumanoidRootPartHeightDifference, 0) * NewTargetHumanoidRootPartCFrame)
    self:SetCFrameProperty(self.Motors.Root, "Transform", CFrame.new(0, -HumanoidRootPartHeightDifference, 0) * (NewTargetHumanoidRootPartCFrame * self.Attachments.HumanoidRootPart.RootRigAttachment.CFrame):Inverse() * LowerTorsoCFrame * self.Attachments.LowerTorso.RootRigAttachment.CFrame)
    self:SetTransform("RightHip", "RightHipRigAttachment", "LowerTorso", "RightUpperLeg", LowerTorsoCFrame, RightUpperLegCFrame)
    self:SetTransform("RightKnee", "RightKneeRigAttachment", "RightUpperLeg", "RightLowerLeg", RightUpperLegCFrame, RightLowerLegCFrame)
    self:SetTransform("RightAnkle", "RightAnkleRigAttachment", "RightLowerLeg", "RightFoot", RightLowerLegCFrame, RightFootCFrame)
    self:SetTransform("LeftHip", "LeftHipRigAttachment", "LowerTorso", "LeftUpperLeg", LowerTorsoCFrame, LeftUpperLegCFrame)
    self:SetTransform("LeftKnee", "LeftKneeRigAttachment", "LeftUpperLeg", "LeftLowerLeg", LeftUpperLegCFrame, LeftLowerLegCFrame)
    self:SetTransform("LeftAnkle", "LeftAnkleRigAttachment", "LeftLowerLeg", "LeftFoot", LeftLowerLegCFrame, LeftFootCFrame)
    self:SetTransform("Neck", "NeckRigAttachment", "UpperTorso", "Head", UpperTorsoCFrame, HeadCFrame)
    self:SetTransform("Waist", "WaistRigAttachment", "LowerTorso", "UpperTorso", LowerTorsoCFrame, UpperTorsoCFrame)
    self:SetTransform("RightShoulder", "RightShoulderRigAttachment", "UpperTorso", "RightUpperArm", UpperTorsoCFrame, RightUpperArmCFrame)
    self:SetTransform("RightElbow", "RightElbowRigAttachment", "RightUpperArm", "RightLowerArm", RightUpperArmCFrame, RightLowerArmCFrame)
    self:SetTransform("RightWrist", "RightWristRigAttachment", "RightLowerArm", "RightHand", RightLowerArmCFrame, RightHandCFrame)
    self:SetTransform("LeftShoulder", "LeftShoulderRigAttachment", "UpperTorso", "LeftUpperArm", UpperTorsoCFrame, LeftUpperArmCFrame)
    self:SetTransform("LeftElbow", "LeftElbowRigAttachment", "LeftUpperArm", "LeftLowerArm", LeftUpperArmCFrame, LeftLowerArmCFrame)
    self:SetTransform("LeftWrist", "LeftWristRigAttachment", "LeftLowerArm", "LeftHand", LeftLowerArmCFrame, LeftHandCFrame)

    --Replicate the changes to the server.
    if Players.LocalPlayer and Players.LocalPlayer.Character == self.CharacterModel then
        self.ReplicationCFrames = {HeadControllerCFrame, LeftHandControllerCFrame, RightHandControllerCFrame}
    end
end

--[[
Updates the character from the inputs while seated.
The CFrames are in the local space instead of global space
since the seat maintains the global space.
--]]
function Character:UpdateFromInputsSeated(HeadControllerCFrame: CFrame, LeftHandControllerCFrame: CFrame, RightHandControllerCFrame: CFrame): ()
    --Return if the humanoid is dead.
    if self.Humanoid.Health <= 0 then
        return
    end

    --Get the CFrames.
    local HeadCFrame = self.Head:GetHeadCFrame(HeadControllerCFrame)
    local NeckCFrame = self.Head:GetNeckCFrame(HeadControllerCFrame,0)
	local LowerTorsoCFrame, UpperTorsoCFrame = self.Torso:GetTorsoCFrames(NeckCFrame)
	local JointCFrames = self.Torso:GetAppendageJointCFrames(LowerTorsoCFrame,UpperTorsoCFrame)
	local LeftUpperArmCFrame, LeftLowerArmCFrame, LeftHandCFrame = self.LeftArm:GetAppendageCFrames(JointCFrames["LeftShoulder"], LeftHandControllerCFrame)
	local RightUpperArmCFrame, RightLowerArmCFrame, RightHandCFrame = self.RightArm:GetAppendageCFrames(JointCFrames["RightShoulder"], RightHandControllerCFrame)
    local EyesOffset = self.Head:GetEyesOffset()
    local HeightOffset = CFrame.new(0, (CFrame.new(0, EyesOffset.Y, 0) * (HeadControllerCFrame * EyesOffset:Inverse())).Y, 0)

    --Set the head, toros, and arm CFrames.
    self:SetCFrameProperty(self.Motors.Root, "Transform", HeightOffset * CFrame.new(0, -LowerTorsoCFrame.Y, 0) * LowerTorsoCFrame)
    self:SetTransform("Neck", "NeckRigAttachment", "UpperTorso", "Head", UpperTorsoCFrame, HeadCFrame)
    self:SetTransform("Waist", "WaistRigAttachment", "LowerTorso", "UpperTorso", LowerTorsoCFrame, UpperTorsoCFrame)
    self:SetTransform("RightShoulder", "RightShoulderRigAttachment", "UpperTorso", "RightUpperArm", UpperTorsoCFrame, RightUpperArmCFrame)
    self:SetTransform("RightElbow", "RightElbowRigAttachment", "RightUpperArm", "RightLowerArm", RightUpperArmCFrame, RightLowerArmCFrame)
    self:SetTransform("RightWrist", "RightWristRigAttachment", "RightLowerArm", "RightHand", RightLowerArmCFrame, RightHandCFrame)
    self:SetTransform("LeftShoulder", "LeftShoulderRigAttachment", "UpperTorso", "LeftUpperArm", UpperTorsoCFrame, LeftUpperArmCFrame)
    self:SetTransform("LeftElbow", "LeftElbowRigAttachment", "LeftUpperArm", "LeftLowerArm", LeftUpperArmCFrame, LeftLowerArmCFrame)
    self:SetTransform("LeftWrist", "LeftWristRigAttachment", "LeftLowerArm", "LeftHand", LeftLowerArmCFrame, LeftHandCFrame)

    --Set the legs to be sitting.
    self.Motors.RightHip.Transform = CFrame.Angles(math.pi / 2, 0, math.rad(5))
    self.Motors.LeftHip.Transform = CFrame.Angles(math.pi / 2, 0, math.rad(-5))
    self.Motors.RightKnee.Transform = CFrame.Angles(math.rad(-10), 0, 0)
    self.Motors.LeftKnee.Transform = CFrame.Angles(math.rad(-10), 0, 0)
    self.Motors.RightAnkle.Transform = CFrame.Angles(0, 0, 0)
    self.Motors.LeftAnkle.Transform = CFrame.Angles(0, 0, 0)

    --Replicate the changes to the server.
    if Players.LocalPlayer and Players.LocalPlayer.Character == self.CharacterModel then
        self.ReplicationCFrames = {HeadControllerCFrame, LeftHandControllerCFrame, RightHandControllerCFrame}
    end
end



return (Character :: any) :: Character