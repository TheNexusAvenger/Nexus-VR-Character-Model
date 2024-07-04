--[[
TheNexusAvenger

Manipulates a character model.
--]]
--!strict

local SMOOTHING_DURATION_SECONDS = 1 / 30

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local NexusVRCharacterModel = script.Parent
local Head = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("Head"))
local Torso = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("Torso"))
local AppendageLegacy = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("Appendage"))
local Appendage = require(NexusVRCharacterModel:WaitForChild("NexusAppendage"):WaitForChild("Appendage"))
local FootPlanter = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("FootPlanter"))
local EnigmaService = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("EnigmaService")).GetInstance()
local Settings = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("Settings")).GetInstance()
local UpdateInputs = NexusVRCharacterModel:WaitForChild("UpdateInputs") :: UnreliableRemoteEvent

local Character = {}
Character.__index = Character

export type Character = {
    new: (CharacterModel: Model) -> Character,

    GetHumanoidScale: (self: Character, ScaleName: string) -> (number),
    RefreshCharacter: (self: Character) -> (),
    UpdateFromInputs: (self: Character, HeadControllerCFrame: CFrame, LeftHandControllerCFrame: CFrame, RightHandControllerCFrame: CFrame) -> (),
}



--[[
Creates a character.
--]]
function Character.new(CharacterModel: Model): Character
    local self = {
        CharacterModel = CharacterModel,
        TweenComponents = (CharacterModel ~= Players.LocalPlayer.Character),
        UseIKControl = Settings:GetSetting("Extra.TEMPORARY_UseIKControl"),
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

    --Set up the character parts.
    self.PreventArmDisconnection = PreventArmDisconnection
    self:SetUpVRParts()

    --Set up a connection for Character Appearance changes.
    self.AppearanceChangedConnection = nil :: RBXScriptConnection?
    self:SetUpAppearanceChanged()

    self.MoodAnimationIds = {}
    self.CurrentMotor6DTransforms = {}
    self.LastMotor6DTransforms = {}
    self.LastRefreshTime = tick()

    --Set up replication at 30hz.
    if Players.LocalPlayer and Players.LocalPlayer.Character == CharacterModel then
        task.spawn(function()
            while (self.Humanoid :: Humanoid).Health > 0 do
                --Send the new CFrames if the CFrames changed.
                local ReplicationCFrames = (self :: any).ReplicationCFrames :: {CFrame}
                if (self :: any).LastReplicationCFrames ~= ReplicationCFrames then
                    (self :: any).LastReplicationCFrames = ReplicationCFrames
                    local ReplicationTrackerData = (self :: any).ReplicationTrackerData :: {[string]: CFrame}?
                    UpdateInputs:FireServer(ReplicationCFrames[1], ReplicationCFrames[2], ReplicationCFrames[3], tick(), ReplicationTrackerData)
                end

                --Wait 1/30th of a second to send the next set of CFrames.
                task.wait(1 / 30)
            end
        end)
    end

    return (self :: any) :: Character
end

--[[
Set up Character Parts for VR.
This is also used, to refresh character parts.
--]]
function Character:SetUpVRParts()
    local CharacterModel = self.CharacterModel
    local PreventArmDisconnection = self.PreventArmDisconnection

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
    if self.UseIKControl then
        self.LeftArm = Appendage.FromPreset("LeftArm", CharacterModel, not PreventArmDisconnection, self.TweenComponents and 0.1 or 0)
        self.RightArm = Appendage.FromPreset("RightArm", CharacterModel, not PreventArmDisconnection, self.TweenComponents and 0.1 or 0)
        self.LeftLeg = Appendage.FromPreset("LeftLeg", CharacterModel, false, self.TweenComponents and 0.1 or 0)
        self.RightLeg = Appendage.FromPreset("RightLeg", CharacterModel, false, self.TweenComponents and 0.1 or 0)
    else
        self.LeftArm = AppendageLegacy.new(CharacterModel:WaitForChild("LeftUpperArm") :: BasePart, CharacterModel:WaitForChild("LeftLowerArm") :: BasePart, CharacterModel:WaitForChild("LeftHand") :: BasePart, "LeftShoulderRigAttachment", "LeftElbowRigAttachment", "LeftWristRigAttachment", "LeftGripAttachment", PreventArmDisconnection)
        self.RightArm = AppendageLegacy.new(CharacterModel:WaitForChild("RightUpperArm") :: BasePart, CharacterModel:WaitForChild("RightLowerArm") :: BasePart, CharacterModel:WaitForChild("RightHand") :: BasePart, "RightShoulderRigAttachment", "RightElbowRigAttachment", "RightWristRigAttachment", "RightGripAttachment", PreventArmDisconnection)
        self.LeftLeg = AppendageLegacy.new(CharacterModel:WaitForChild("LeftUpperLeg") :: BasePart, CharacterModel:WaitForChild("LeftLowerLeg") :: BasePart, CharacterModel:WaitForChild("LeftFoot") :: BasePart, "LeftHipRigAttachment", "LeftKneeRigAttachment", "LeftAnkleRigAttachment", "LeftFootAttachment", true)
        self.LeftLeg.InvertBendDirection = true
        self.RightLeg = AppendageLegacy.new(CharacterModel:WaitForChild("RightUpperLeg") :: BasePart, CharacterModel:WaitForChild("RightLowerLeg") :: BasePart, CharacterModel:WaitForChild("RightFoot") :: BasePart, "RightHipRigAttachment", "RightKneeRigAttachment", "RightAnkleRigAttachment", "RightFootAttachment", true)
        self.RightLeg.InvertBendDirection = true
    end
    self.FootPlanter = FootPlanter:CreateSolver(CharacterModel:WaitForChild("LowerTorso"), self.Humanoid:FindFirstChild("BodyHeightScale"))
end

--[[
This sets up a connection that fires when HumanoidDescription is added
under a Humanoid, to listen for appearance changes to refresh the character parts.
--]]
function Character:SetUpAppearanceChanged()
    local CharacterModel = self.CharacterModel

    local Humanoid = CharacterModel:WaitForChild("Humanoid") :: Humanoid

    if not Humanoid then
        warn(`[NexusVRAppearanceFix] Humanoid was not found for {CharacterModel}`)
        return
    end

    --Reset connection if it already exists
    if self.AppearanceChangedConnection then
        self.AppearanceChangedConnection:Disconnect()
        self.AppearanceChangedConnection = nil
    end

    self.AppearanceChangedConnection = Humanoid.ChildAdded:Connect(function(Child)
        --If a new HumanoidDescription appeared, then something changed on the avatar.
        --We should re-ensure that everything is still connected to NexusVR.
        if Child:IsA("HumanoidDescription") then
            --Refresh character parts
            self:SetUpVRParts()
        end
    end)    
end

--[[
Returns the scale value of the humanoid, or the default value.
--]]
function Character:GetHumanoidScale(ScaleName: string): number
    local Value = self.Humanoid:FindFirstChild(ScaleName) :: NumberValue
    if Value then
        return Value.Value
    end
    return (ScaleName == "BodyTypeScale" and 0 or 1)
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
    if self.TweenComponents and PropertyName ~= "Transform" then
        TweenService:Create(
            Object,
            TweenInfo.new(SMOOTHING_DURATION_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                [PropertyName] = PropertyValue,
            }
        ):Play()
    else
        (Object :: any)[PropertyName] = PropertyValue
    end
    if PropertyName == "Transform" then
        self.CurrentMotor6DTransforms[Object] = PropertyValue
    end
end

--[[
Sets the transform of a motor.
--]]
function Character:SetTransform(MotorName: string, AttachmentName: string, StartLimbName: string, EndLimbName: string, StartCFrame: CFrame, EndCFrame: CFrame): ()
    self:SetCFrameProperty(self.Motors[MotorName], "Transform", (StartCFrame * self.Attachments[StartLimbName][AttachmentName].CFrame):Inverse() * (EndCFrame * self.Attachments[EndLimbName][AttachmentName].CFrame))
end

--[[
Refreshes the Motor6D Transforms.
Intended to be run for the local character after Stepped to override the animations.
--]]
function Character:RefreshCharacter(): ()
    if self.TweenComponents then
        local CurrentRefreshTime = tick()
        local SmoothRatio = math.min((CurrentRefreshTime - self.LastRefreshTime) / SMOOTHING_DURATION_SECONDS, 1)
        for Motor6D, Transform in self.CurrentMotor6DTransforms do
            local LastTransform = self.LastMotor6DTransforms[Motor6D]
            if LastTransform then
                Motor6D.Transform = LastTransform:Lerp(Transform, SmoothRatio)
            else
                Motor6D.Transform = Transform
            end
        end
    else
        for Motor6D, Transform in self.CurrentMotor6DTransforms do
            Motor6D.Transform = Transform
        end
    end
end

--[[
Updates the character from the inputs.
--]]
function Character:UpdateFromInputs(HeadControllerCFrame: CFrame, LeftHandControllerCFrame: CFrame, RightHandControllerCFrame: CFrame, TrackerData: {[string]: CFrame}?): ()
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

    --Store the current Motor6D transforms.
    for Motor6D, _ in self.CurrentMotor6DTransforms do
        self.LastMotor6DTransforms[Motor6D] = Motor6D.Transform
    end
    self.LastRefreshTime = tick()

    --Get the CFrames.
    local HeadCFrame = self.Head:GetHeadCFrame(HeadControllerCFrame)
    local NeckCFrame = self.Head:GetNeckCFrame(HeadControllerCFrame)
    local LowerTorsoCFrame: CFrame, UpperTorsoCFrame = self.Torso:GetTorsoCFrames(NeckCFrame)
    local JointCFrames = self.Torso:GetAppendageJointCFrames(LowerTorsoCFrame, UpperTorsoCFrame)

    --Get the tracker CFrames from Enigma and fallback feet CFrames.
    local IsLocalCharacter = (Players.LocalPlayer and Players.LocalPlayer.Character == self.CharacterModel)
    local LeftFoot: CFrame, RightFoot: CFrame = self.FootPlanter:GetFeetCFrames()
    if TrackerData and TrackerData.LeftFoot then
        LeftFoot = TrackerData.LeftFoot
    else
        LeftFoot = LeftFoot * CFrame.Angles(0, math.pi, 0)
    end
    if TrackerData and TrackerData.RightFoot then
        RightFoot = TrackerData.RightFoot
    else
        RightFoot = RightFoot * CFrame.Angles(0, math.pi, 0)
    end
    if IsLocalCharacter then
        local NewTrackerCFrames = EnigmaService:GetCFrames(self)
        if NewTrackerCFrames.LeftFoot then
            LeftFoot = NewTrackerCFrames.LeftFoot
        end
        if NewTrackerCFrames.RightFoot then
            RightFoot = NewTrackerCFrames.RightFoot
        end
        self.ReplicationTrackerData = {
            LeftFoot = NewTrackerCFrames.LeftFoot,
            RightFoot = NewTrackerCFrames.RightFoot,
        }
    end

    --Set the character CFrames.
    --HumanoidRootParts must always face up. This makes the math more complicated.
    --Setting the CFrame directly to something not facing directly up will result in the physics
    --attempting to correct that within the next frame, causing the character to appear to move.
    local TargetHumanoidRootPartCFrame = LowerTorsoCFrame * self.Attachments.LowerTorso.RootRigAttachment.CFrame * self.Attachments.HumanoidRootPart.RootRigAttachment.CFrame:Inverse()
    local ActualHumanoidRootPartCFrame: CFrame = self.Parts.HumanoidRootPart.CFrame
    local HumanoidRootPartHeightDifference = ActualHumanoidRootPartCFrame.Y - TargetHumanoidRootPartCFrame.Y
    local NewTargetHumanoidRootPartCFrame = CFrame.new(TargetHumanoidRootPartCFrame.Position) * CFrame.Angles(0, math.atan2(TargetHumanoidRootPartCFrame.LookVector.X, TargetHumanoidRootPartCFrame.LookVector.Z) + math.pi, 0)
    self:SetCFrameProperty(self.Parts.HumanoidRootPart, "CFrame", CFrame.new(0, HumanoidRootPartHeightDifference, 0) * NewTargetHumanoidRootPartCFrame)
    self:SetCFrameProperty(self.Motors.Root, "Transform", CFrame.new(0, -HumanoidRootPartHeightDifference, 0) * (NewTargetHumanoidRootPartCFrame * self.Attachments.HumanoidRootPart.RootRigAttachment.CFrame):Inverse() * LowerTorsoCFrame * self.Attachments.LowerTorso.RootRigAttachment.CFrame)
    self:SetTransform("Neck", "NeckRigAttachment", "UpperTorso", "Head", UpperTorsoCFrame, HeadCFrame)
    self:SetTransform("Waist", "WaistRigAttachment", "LowerTorso", "UpperTorso", LowerTorsoCFrame, UpperTorsoCFrame)
    if self.UseIKControl then
        self.LeftArm:MoveToWorld(LeftHandControllerCFrame)
        self.RightArm:MoveToWorld(RightHandControllerCFrame)
        self.LeftLeg:MoveToWorld(LeftFoot)
        self.RightLeg:MoveToWorld(RightFoot)
        self.LeftLeg:Enable()
        self.RightLeg:Enable()
    else
        local LeftUpperArmCFrame, LeftLowerArmCFrame, LeftHandCFrame = self.LeftArm:GetAppendageCFrames(JointCFrames["LeftShoulder"], LeftHandControllerCFrame)
        local RightUpperArmCFrame, RightLowerArmCFrame, RightHandCFrame = self.RightArm:GetAppendageCFrames(JointCFrames["RightShoulder"], RightHandControllerCFrame)
        local LeftUpperLegCFrame, LeftLowerLegCFrame, LeftFootCFrame = self.LeftLeg:GetAppendageCFrames(JointCFrames["LeftHip"], LeftFoot)
        local RightUpperLegCFrame, RightLowerLegCFrame, RightFootCFrame = self.RightLeg:GetAppendageCFrames(JointCFrames["RightHip"], RightFoot)
        self:SetTransform("RightHip", "RightHipRigAttachment", "LowerTorso", "RightUpperLeg", LowerTorsoCFrame, RightUpperLegCFrame)
        self:SetTransform("RightKnee", "RightKneeRigAttachment", "RightUpperLeg", "RightLowerLeg", RightUpperLegCFrame, RightLowerLegCFrame)
        self:SetTransform("RightAnkle", "RightAnkleRigAttachment", "RightLowerLeg", "RightFoot", RightLowerLegCFrame, RightFootCFrame)
        self:SetTransform("LeftHip", "LeftHipRigAttachment", "LowerTorso", "LeftUpperLeg", LowerTorsoCFrame, LeftUpperLegCFrame)
        self:SetTransform("LeftKnee", "LeftKneeRigAttachment", "LeftUpperLeg", "LeftLowerLeg", LeftUpperLegCFrame, LeftLowerLegCFrame)
        self:SetTransform("LeftAnkle", "LeftAnkleRigAttachment", "LeftLowerLeg", "LeftFoot", LeftLowerLegCFrame, LeftFootCFrame)
        self:SetTransform("RightShoulder", "RightShoulderRigAttachment", "UpperTorso", "RightUpperArm", UpperTorsoCFrame, RightUpperArmCFrame)
        self:SetTransform("RightElbow", "RightElbowRigAttachment", "RightUpperArm", "RightLowerArm", RightUpperArmCFrame, RightLowerArmCFrame)
        self:SetTransform("RightWrist", "RightWristRigAttachment", "RightLowerArm", "RightHand", RightLowerArmCFrame, RightHandCFrame)
        self:SetTransform("LeftShoulder", "LeftShoulderRigAttachment", "UpperTorso", "LeftUpperArm", UpperTorsoCFrame, LeftUpperArmCFrame)
        self:SetTransform("LeftElbow", "LeftElbowRigAttachment", "LeftUpperArm", "LeftLowerArm", LeftUpperArmCFrame, LeftLowerArmCFrame)
        self:SetTransform("LeftWrist", "LeftWristRigAttachment", "LeftLowerArm", "LeftHand", LeftLowerArmCFrame, LeftHandCFrame)
    end

    --Replicate the changes to the server.
    if IsLocalCharacter then
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
    local EyesOffset = self.Head:GetEyesOffset()
    local HeightOffset = CFrame.new(0, (CFrame.new(0, EyesOffset.Y, 0) * (HeadControllerCFrame * EyesOffset:Inverse())).Y, 0)

    --Set the head, toros, and arm CFrames.
    self:SetCFrameProperty(self.Motors.Root, "Transform", HeightOffset * CFrame.new(0, -LowerTorsoCFrame.Y, 0) * LowerTorsoCFrame)
    self:SetTransform("Neck", "NeckRigAttachment", "UpperTorso", "Head", UpperTorsoCFrame, HeadCFrame)
    self:SetTransform("Waist", "WaistRigAttachment", "LowerTorso", "UpperTorso", LowerTorsoCFrame, UpperTorsoCFrame)
    if self.UseIKControl then
        local HeadWorldSpaceCFrame = (self.Parts.Head.CFrame :: CFrame) * EyesOffset
        self.LeftArm:MoveToWorld(HeadWorldSpaceCFrame * HeadControllerCFrame:Inverse() * LeftHandControllerCFrame)
        self.RightArm:MoveToWorld(HeadWorldSpaceCFrame * HeadControllerCFrame:Inverse() * RightHandControllerCFrame)
        self.LeftLeg:Disable()
        self.RightLeg:Disable()
    else
        local LeftUpperArmCFrame, LeftLowerArmCFrame, LeftHandCFrame = self.LeftArm:GetAppendageCFrames(JointCFrames["LeftShoulder"], LeftHandControllerCFrame)
        local RightUpperArmCFrame, RightLowerArmCFrame, RightHandCFrame = self.RightArm:GetAppendageCFrames(JointCFrames["RightShoulder"], RightHandControllerCFrame)
        self:SetTransform("RightShoulder", "RightShoulderRigAttachment", "UpperTorso", "RightUpperArm", UpperTorsoCFrame, RightUpperArmCFrame)
        self:SetTransform("RightElbow", "RightElbowRigAttachment", "RightUpperArm", "RightLowerArm", RightUpperArmCFrame, RightLowerArmCFrame)
        self:SetTransform("RightWrist", "RightWristRigAttachment", "RightLowerArm", "RightHand", RightLowerArmCFrame, RightHandCFrame)
        self:SetTransform("LeftShoulder", "LeftShoulderRigAttachment", "UpperTorso", "LeftUpperArm", UpperTorsoCFrame, LeftUpperArmCFrame)
        self:SetTransform("LeftElbow", "LeftElbowRigAttachment", "LeftUpperArm", "LeftLowerArm", LeftUpperArmCFrame, LeftLowerArmCFrame)
        self:SetTransform("LeftWrist", "LeftWristRigAttachment", "LeftLowerArm", "LeftHand", LeftLowerArmCFrame, LeftHandCFrame)
    end

    --Reset the leg transforms to allow for animations.
    self.CurrentMotor6DTransforms[self.Motors.RightHip] = nil
    self.CurrentMotor6DTransforms[self.Motors.LeftHip] = nil
    self.CurrentMotor6DTransforms[self.Motors.RightKnee] = nil
    self.CurrentMotor6DTransforms[self.Motors.LeftKnee] = nil
    self.CurrentMotor6DTransforms[self.Motors.RightAnkle] = nil
    self.CurrentMotor6DTransforms[self.Motors.LeftAnkle] = nil

    --Replicate the changes to the server.
    if Players.LocalPlayer and Players.LocalPlayer.Character == self.CharacterModel then
        self.ReplicationCFrames = {HeadControllerCFrame, LeftHandControllerCFrame, RightHandControllerCFrame}
    end
end



return (Character :: any) :: Character