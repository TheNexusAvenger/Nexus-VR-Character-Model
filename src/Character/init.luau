--Manipulates a character model.
--!strict

local SMOOTHING_DURATION_SECONDS = 1 / 30

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VRService = game:GetService("VRService")

local NexusVRCharacterModel = script.Parent
local Head = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("Head"))
local Torso = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("Torso"))
local AppendageLegacy = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("Appendage"))
local FootPlanter = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("FootPlanter"))
local EnigmaService = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("EnigmaService")).GetInstance()
local Settings = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("Settings")).GetInstance()
local VRInputService = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("VRInputService")).GetInstance()
local NexusAppendage = require(NexusVRCharacterModel:WaitForChild("Packages"):WaitForChild("NexusAppendage"))
local UpdateInputs = NexusVRCharacterModel:WaitForChild("UpdateInputs") :: UnreliableRemoteEvent

local Appendage = NexusAppendage.Appendage

local Character = {}
Character.__index = Character

export type Character = {
    CharacterModel: Model,
    Humanoid: Humanoid,
    Head: Head.Head,
    Torso: Torso.Torso,
    LeftArm: NexusAppendage.Appendage,
    RightArm: NexusAppendage.Appendage,
    LeftLeg: NexusAppendage.Appendage,
    RightLeg: NexusAppendage.Appendage,
    FootPlanter: any,
    CurrentWalkspeed: number,
    TweenComponents: boolean,
    UseIKControl: boolean,
    PreventArmDisconnection: boolean,
    Parts: {[string]: BasePart},
    Motors: {[string]: Motor6D},
    Attachments: {[string]: {[string]: Attachment}},
    CurrentMotor6DTransforms: {[Motor6D]: CFrame},
    LastMotor6DTransforms: {[Motor6D]: CFrame},
    LastRefreshTime: number,
    ReplicationCFrames: {[string]: CFrame}?,
    LastReplicationCFrames: {[string]: CFrame}?,
    ReplicationTrackerData: {[string]: CFrame}?,
    LastReplicationTrackerData: {[string]: CFrame}?,
    AppearanceChangedConnection: RBXScriptConnection?,
} & typeof(setmetatable({}, Character))



--[[
Creates a character.
--]]
function Character.new(CharacterModel: Model): Character
    local self = setmetatable({
        CharacterModel = CharacterModel,
        TweenComponents = (CharacterModel ~= Players.LocalPlayer.Character),
        UseIKControl = Settings:GetSetting("Extra.TEMPORARY_UseIKControl"),
    }, Character) :: Character

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
    self.Humanoid = CharacterModel:WaitForChild("Humanoid") :: Humanoid
    self.CurrentWalkspeed = 0
    self.Humanoid.Running:Connect(function(WalkSpeed)
        if VRService.AvatarGestures and VRInputService:GetThumbstickPosition(Enum.KeyCode.Thumbstick1).Magnitude < 0.2 then
            WalkSpeed = 0
        end
        self.CurrentWalkspeed = WalkSpeed
    end)

    --Set up the character parts.
    self.PreventArmDisconnection = PreventArmDisconnection
    self:SetUpVRParts()

    --Set up a connection for Character Appearance changes.
    self.AppearanceChangedConnection = nil :: RBXScriptConnection?
    self:SetUpAppearanceChanged()

    self.CurrentMotor6DTransforms = {}
    self.LastMotor6DTransforms = {}
    self.LastRefreshTime = tick()

    --Set up replication at 30hz.
    if Players.LocalPlayer and Players.LocalPlayer.Character == CharacterModel then
        task.spawn(function()
            while (self.Humanoid :: Humanoid).Health > 0 do
                --Send the new CFrames if the CFrames changed.
                local ReplicationCFrames = self.ReplicationCFrames
                local ReplicationTrackerData = self.ReplicationTrackerData
                if ReplicationCFrames and self.LastReplicationCFrames ~= ReplicationCFrames and self.LastReplicationTrackerData ~= ReplicationTrackerData then
                    self.LastReplicationCFrames = ReplicationCFrames
                    self.LastReplicationTrackerData = ReplicationTrackerData
                    local NewTrackerData = {
                        UpdateTime = tick(),
                        CurrentWalkspeed = self.CurrentWalkspeed,
                        LeftFootCFrame = ReplicationTrackerData and ReplicationTrackerData.LeftFoot,
                        RightFootCFrame = ReplicationTrackerData and ReplicationTrackerData.RightFoot,
                    }
                    if not VRService.AvatarGestures then
                        NewTrackerData.HeadCFrame = ReplicationCFrames.HeadCFrame
                        NewTrackerData.LeftHandCFrame = ReplicationCFrames.LeftHandCFrame
                        NewTrackerData.RightHandCFrame = ReplicationCFrames.RightHandCFrame
                    end
                    UpdateInputs:FireServer(NewTrackerData)
                end

                --Wait 1/30th of a second to send the next set of CFrames.
                task.wait(1 / 30)
            end
        end)
    end

    return self
end

--[[
Set up Character Parts for VR.
This is also used, to refresh character parts.
--]]
function Character.SetUpVRParts(self: Character): ()
    local CharacterModel = self.CharacterModel
    local PreventArmDisconnection = self.PreventArmDisconnection

    self.Parts = {
        Head = CharacterModel:WaitForChild("Head") :: BasePart,
        UpperTorso = CharacterModel:WaitForChild("UpperTorso") :: BasePart,
        LowerTorso = CharacterModel:WaitForChild("LowerTorso") :: BasePart,
        HumanoidRootPart = CharacterModel:WaitForChild("HumanoidRootPart") :: BasePart,
        RightUpperArm = CharacterModel:WaitForChild("RightUpperArm") :: BasePart,
        RightLowerArm = CharacterModel:WaitForChild("RightLowerArm") :: BasePart,
        RightHand = CharacterModel:WaitForChild("RightHand") :: BasePart,
        LeftUpperArm = CharacterModel:WaitForChild("LeftUpperArm") :: BasePart,
        LeftLowerArm = CharacterModel:WaitForChild("LeftLowerArm") :: BasePart,
        LeftHand = CharacterModel:WaitForChild("LeftHand") :: BasePart,
        RightUpperLeg = CharacterModel:WaitForChild("RightUpperLeg") :: BasePart,
        RightLowerLeg = CharacterModel:WaitForChild("RightLowerLeg") :: BasePart,
        RightFoot = CharacterModel:WaitForChild("RightFoot") :: BasePart,
        LeftUpperLeg = CharacterModel:WaitForChild("LeftUpperLeg") :: BasePart,
        LeftLowerLeg = CharacterModel:WaitForChild("LeftLowerLeg") :: BasePart,
        LeftFoot = CharacterModel:WaitForChild("LeftFoot") :: BasePart,
    }
    self.Motors = {
        Neck = self.Parts.Head:WaitForChild("Neck") :: Motor6D,
        Waist = self.Parts.UpperTorso:WaitForChild("Waist") :: Motor6D,
        Root = self.Parts.LowerTorso:WaitForChild("Root") :: Motor6D,
        RightShoulder = self.Parts.RightUpperArm:WaitForChild("RightShoulder") :: Motor6D,
        RightElbow = self.Parts.RightLowerArm:WaitForChild("RightElbow") :: Motor6D,
        RightWrist = self.Parts.RightHand:WaitForChild("RightWrist") :: Motor6D,
        LeftShoulder = self.Parts.LeftUpperArm:WaitForChild("LeftShoulder") :: Motor6D,
        LeftElbow = self.Parts.LeftLowerArm:WaitForChild("LeftElbow") :: Motor6D,
        LeftWrist = self.Parts.LeftHand:WaitForChild("LeftWrist") :: Motor6D,
        RightHip = self.Parts.RightUpperLeg:WaitForChild("RightHip") :: Motor6D,
        RightKnee = self.Parts.RightLowerLeg:WaitForChild("RightKnee") :: Motor6D,
        RightAnkle = self.Parts.RightFoot:WaitForChild("RightAnkle") :: Motor6D,
        LeftHip = self.Parts.LeftUpperLeg:WaitForChild("LeftHip") :: Motor6D,
        LeftKnee = self.Parts.LeftLowerLeg:WaitForChild("LeftKnee") :: Motor6D,
        LeftAnkle = self.Parts.LeftFoot:WaitForChild("LeftAnkle") :: Motor6D,
    }
    self.Attachments = {
        Head = {
            NeckRigAttachment = self.Parts.Head:WaitForChild("NeckRigAttachment") :: Attachment,
        },
        UpperTorso = {
            NeckRigAttachment = self.Parts.UpperTorso:WaitForChild("NeckRigAttachment") :: Attachment,
            LeftShoulderRigAttachment = self.Parts.UpperTorso:WaitForChild("LeftShoulderRigAttachment") :: Attachment,
            RightShoulderRigAttachment = self.Parts.UpperTorso:WaitForChild("RightShoulderRigAttachment") :: Attachment,
            WaistRigAttachment = self.Parts.UpperTorso:WaitForChild("WaistRigAttachment") :: Attachment,
        },
        LowerTorso = {
            WaistRigAttachment = self.Parts.LowerTorso:WaitForChild("WaistRigAttachment") :: Attachment,
            LeftHipRigAttachment = self.Parts.LowerTorso:WaitForChild("LeftHipRigAttachment") :: Attachment,
            RightHipRigAttachment = self.Parts.LowerTorso:WaitForChild("RightHipRigAttachment") :: Attachment,
            RootRigAttachment = self.Parts.LowerTorso:WaitForChild("RootRigAttachment") :: Attachment,
        },
        HumanoidRootPart = {
            RootRigAttachment = self.Parts.HumanoidRootPart:WaitForChild("RootRigAttachment") :: Attachment,
        },
        RightUpperArm = {
            RightShoulderRigAttachment = self.Parts.RightUpperArm:WaitForChild("RightShoulderRigAttachment") :: Attachment,
            RightElbowRigAttachment = self.Parts.RightUpperArm:WaitForChild("RightElbowRigAttachment") :: Attachment,
        },
        RightLowerArm = {
            RightElbowRigAttachment = self.Parts.RightLowerArm:WaitForChild("RightElbowRigAttachment") :: Attachment,
            RightWristRigAttachment = self.Parts.RightLowerArm:WaitForChild("RightWristRigAttachment") :: Attachment,
        },
        RightHand = {
            RightWristRigAttachment = self.Parts.RightHand:WaitForChild("RightWristRigAttachment") :: Attachment,
        },
        LeftUpperArm = {
            LeftShoulderRigAttachment = self.Parts.LeftUpperArm:WaitForChild("LeftShoulderRigAttachment") :: Attachment,
            LeftElbowRigAttachment = self.Parts.LeftUpperArm:WaitForChild("LeftElbowRigAttachment") :: Attachment,
        },
        LeftLowerArm = {
            LeftElbowRigAttachment = self.Parts.LeftLowerArm:WaitForChild("LeftElbowRigAttachment") :: Attachment,
            LeftWristRigAttachment = self.Parts.LeftLowerArm:WaitForChild("LeftWristRigAttachment") :: Attachment,
        },
        LeftHand = {
            LeftWristRigAttachment = self.Parts.LeftHand:WaitForChild("LeftWristRigAttachment") :: Attachment,
        },
        RightUpperLeg = {
            RightHipRigAttachment = self.Parts.RightUpperLeg:WaitForChild("RightHipRigAttachment") :: Attachment,
            RightKneeRigAttachment = self.Parts.RightUpperLeg:WaitForChild("RightKneeRigAttachment") :: Attachment,
        },
        RightLowerLeg = {
            RightKneeRigAttachment = self.Parts.RightLowerLeg:WaitForChild("RightKneeRigAttachment") :: Attachment,
            RightAnkleRigAttachment = self.Parts.RightLowerLeg:WaitForChild("RightAnkleRigAttachment") :: Attachment,
        },
        RightFoot = {
            RightAnkleRigAttachment = self.Parts.RightFoot:WaitForChild("RightAnkleRigAttachment") :: Attachment,
            RightFootAttachment = self.Parts.RightFoot:FindFirstChild("RightFootAttachment") :: Attachment,
        },
        LeftUpperLeg = {
            LeftHipRigAttachment = self.Parts.LeftUpperLeg:WaitForChild("LeftHipRigAttachment") :: Attachment,
            LeftKneeRigAttachment = self.Parts.LeftUpperLeg:WaitForChild("LeftKneeRigAttachment") :: Attachment,
        },
        LeftLowerLeg = {
            LeftKneeRigAttachment = self.Parts.LeftLowerLeg:WaitForChild("LeftKneeRigAttachment") :: Attachment,
            LeftAnkleRigAttachment = self.Parts.LeftLowerLeg:WaitForChild("LeftAnkleRigAttachment") :: Attachment,
        },
        LeftFoot = {
            LeftAnkleRigAttachment = self.Parts.LeftFoot:WaitForChild("LeftAnkleRigAttachment") :: Attachment,
            LeftFootAttachment = self.Parts.LeftFoot:FindFirstChild("LeftFootAttachment") :: Attachment,
        },
    }

    --Force IKControl when AnimationConstraints is active.
    if not self.Motors.Neck:IsA("Motor6D") then
        self.UseIKControl = true
    end

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
        local LeftArm = AppendageLegacy.new(CharacterModel:WaitForChild("LeftUpperArm") :: BasePart, CharacterModel:WaitForChild("LeftLowerArm") :: BasePart, CharacterModel:WaitForChild("LeftHand") :: BasePart, "LeftShoulderRigAttachment", "LeftElbowRigAttachment", "LeftWristRigAttachment", "LeftGripAttachment", PreventArmDisconnection)
        local RightArm = AppendageLegacy.new(CharacterModel:WaitForChild("RightUpperArm") :: BasePart, CharacterModel:WaitForChild("RightLowerArm") :: BasePart, CharacterModel:WaitForChild("RightHand") :: BasePart, "RightShoulderRigAttachment", "RightElbowRigAttachment", "RightWristRigAttachment", "RightGripAttachment", PreventArmDisconnection)
        local LeftLeg = AppendageLegacy.new(CharacterModel:WaitForChild("LeftUpperLeg") :: BasePart, CharacterModel:WaitForChild("LeftLowerLeg") :: BasePart, CharacterModel:WaitForChild("LeftFoot") :: BasePart, "LeftHipRigAttachment", "LeftKneeRigAttachment", "LeftAnkleRigAttachment", "LeftFootAttachment", true)
        LeftLeg.InvertBendDirection = true
        local RightLeg = AppendageLegacy.new(CharacterModel:WaitForChild("RightUpperLeg") :: BasePart, CharacterModel:WaitForChild("RightLowerLeg") :: BasePart, CharacterModel:WaitForChild("RightFoot") :: BasePart, "RightHipRigAttachment", "RightKneeRigAttachment", "RightAnkleRigAttachment", "RightFootAttachment", true)
        RightLeg.InvertBendDirection = true
        self.LeftArm = LeftArm :: any
        self.RightArm = RightArm :: any
        self.LeftLeg = LeftLeg :: any
        self.RightLeg = RightLeg :: any
    end
    self.FootPlanter = FootPlanter:CreateSolver(CharacterModel:WaitForChild("LowerTorso"), self.Humanoid:FindFirstChild("BodyHeightScale"))
end

--[[
This sets up a connection that fires when HumanoidDescription is added
under a Humanoid, to listen for appearance changes to refresh the character parts.
--]]
function Character.SetUpAppearanceChanged(self: Character): ()
    local CharacterModel = self.CharacterModel
    local Humanoid = CharacterModel:WaitForChild("Humanoid") :: Humanoid

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
function Character.GetHumanoidScale(self: Character, ScaleName: string): number
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
function Character.GetHumanoidSeatPart(self: Character): BasePart?
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
function Character.SetCFrameProperty(self: Character, Object: Instance, PropertyName: string, PropertyValue: any): ()
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
        self.CurrentMotor6DTransforms[Object :: Motor6D] = PropertyValue
    end
end

--[[
Sets the transform of a motor.
--]]
function Character.SetTransform(self: Character, MotorName: string, AttachmentName: string, StartLimbName: string, EndLimbName: string, StartCFrame: CFrame, EndCFrame: CFrame): ()
    self:SetCFrameProperty(self.Motors[MotorName], "Transform", (StartCFrame * self.Attachments[StartLimbName][AttachmentName].CFrame):Inverse() * (EndCFrame * self.Attachments[EndLimbName][AttachmentName].CFrame))
end

--[[
Refreshes the Motor6D Transforms.
Intended to be run for the local character after Stepped to override the animations.
--]]
function Character.RefreshCharacter(self: Character): ()
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
function Character.UpdateFromInputs(self: Character, HeadControllerCFrame: CFrame?, LeftHandControllerCFrame: CFrame?, RightHandControllerCFrame: CFrame?, CurrentWalkspeed: number?, TrackerData: {[string]: CFrame}?): ()
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
    local CurrentHeadControllerCFrame = HeadControllerCFrame or (self.Parts.Head.CFrame * self.Head:GetEyesOffset())
    local HeadCFrame = self.Head:GetHeadCFrame(CurrentHeadControllerCFrame)
    local NeckCFrame = self.Head:GetNeckCFrame(CurrentHeadControllerCFrame)
    local LowerTorsoCFrame: CFrame, UpperTorsoCFrame = self.Torso:GetTorsoCFrames(NeckCFrame)
    local JointCFrames = self.Torso:GetAppendageJointCFrames(LowerTorsoCFrame, UpperTorsoCFrame)

    --Get the tracker CFrames from Enigma and fallback feet CFrames.
    local IsLocalCharacter = (Players.LocalPlayer and Players.LocalPlayer.Character == self.CharacterModel)
    local LeftFoot: CFrame, RightFoot: CFrame = self.FootPlanter:GetFeetCFrames()
    local LeftFootTrackerActive, RightFootTrackerActive = false, false
    if TrackerData and TrackerData.LeftFoot then
        LeftFoot = TrackerData.LeftFoot
        LeftFootTrackerActive = true
    else
        LeftFoot = LeftFoot * CFrame.Angles(0, math.pi, 0)
    end
    if TrackerData and TrackerData.RightFoot then
        RightFoot = TrackerData.RightFoot
        RightFootTrackerActive = true
    else
        RightFoot = RightFoot * CFrame.Angles(0, math.pi, 0)
    end
    if IsLocalCharacter then
        local NewTrackerCFrames = EnigmaService:GetCFrames(self)
        if NewTrackerCFrames.LeftFoot then
            LeftFoot = NewTrackerCFrames.LeftFoot
            LeftFootTrackerActive = true
        end
        if NewTrackerCFrames.RightFoot then
            RightFoot = NewTrackerCFrames.RightFoot
            RightFootTrackerActive = true
        end
        self.ReplicationTrackerData = {
            LeftFoot = NewTrackerCFrames.LeftFoot,
            RightFoot = NewTrackerCFrames.RightFoot,
        } :: {[string]: CFrame}
    end

    --Set the character CFrames.
    --HumanoidRootParts must always face up. This makes the math more complicated.
    --Setting the CFrame directly to something not facing directly up will result in the physics
    --attempting to correct that within the next frame, causing the character to appear to move.
    local AvatarGesturesEnabled = VRService.AvatarGestures
    local IsWalking = ((CurrentWalkspeed or self.CurrentWalkspeed) > 0.1)
    local TargetHumanoidRootPartCFrame = LowerTorsoCFrame * self.Attachments.LowerTorso.RootRigAttachment.CFrame * self.Attachments.HumanoidRootPart.RootRigAttachment.CFrame:Inverse()
    local ActualHumanoidRootPartCFrame: CFrame = self.Parts.HumanoidRootPart.CFrame
    local HumanoidRootPartHeightDifference = ActualHumanoidRootPartCFrame.Y - TargetHumanoidRootPartCFrame.Y
    local NewTargetHumanoidRootPartCFrame = CFrame.new(TargetHumanoidRootPartCFrame.Position) * CFrame.Angles(0, math.atan2(TargetHumanoidRootPartCFrame.LookVector.X, TargetHumanoidRootPartCFrame.LookVector.Z) + math.pi, 0)
    if not AvatarGesturesEnabled then
        self:SetCFrameProperty(self.Parts.HumanoidRootPart, "CFrame", CFrame.new(0, HumanoidRootPartHeightDifference, 0) * NewTargetHumanoidRootPartCFrame)
        self:SetCFrameProperty(self.Motors.Root, "Transform", CFrame.new(0, -HumanoidRootPartHeightDifference, 0) * (NewTargetHumanoidRootPartCFrame * self.Attachments.HumanoidRootPart.RootRigAttachment.CFrame):Inverse() * LowerTorsoCFrame * self.Attachments.LowerTorso.RootRigAttachment.CFrame)
        self:SetTransform("Neck", "NeckRigAttachment", "UpperTorso", "Head", UpperTorsoCFrame, HeadCFrame)
        self:SetTransform("Waist", "WaistRigAttachment", "LowerTorso", "UpperTorso", LowerTorsoCFrame, UpperTorsoCFrame)
    end
    if self.UseIKControl then
        if not AvatarGesturesEnabled and LeftHandControllerCFrame and RightHandControllerCFrame then --CFrames aren't send with AvatarGestures. Checks included for typing.
            self.LeftArm:MoveToWorld(LeftHandControllerCFrame)
            self.RightArm:MoveToWorld(RightHandControllerCFrame)
        end
        if not IsWalking and (not AvatarGesturesEnabled or LeftFootTrackerActive) then
            self.LeftLeg:MoveToWorld(LeftFoot)
            self.LeftLeg:Enable()
        else
            self.LeftLeg:Disable()
        end
        if not IsWalking and (not AvatarGesturesEnabled or RightFootTrackerActive) then
            self.RightLeg:MoveToWorld(RightFoot)
            self.RightLeg:Enable()
        else
            self.RightLeg:Disable()
        end
    else
        if not AvatarGesturesEnabled then
            local LeftUpperArmCFrame, LeftLowerArmCFrame, LeftHandCFrame = (self.LeftArm :: any):GetAppendageCFrames(JointCFrames["LeftShoulder"], LeftHandControllerCFrame)
            local RightUpperArmCFrame, RightLowerArmCFrame, RightHandCFrame = (self.RightArm :: any):GetAppendageCFrames(JointCFrames["RightShoulder"], RightHandControllerCFrame)
            self:SetTransform("RightShoulder", "RightShoulderRigAttachment", "UpperTorso", "RightUpperArm", UpperTorsoCFrame, RightUpperArmCFrame)
            self:SetTransform("RightElbow", "RightElbowRigAttachment", "RightUpperArm", "RightLowerArm", RightUpperArmCFrame, RightLowerArmCFrame)
            self:SetTransform("RightWrist", "RightWristRigAttachment", "RightLowerArm", "RightHand", RightLowerArmCFrame, RightHandCFrame)
            self:SetTransform("LeftShoulder", "LeftShoulderRigAttachment", "UpperTorso", "LeftUpperArm", UpperTorsoCFrame, LeftUpperArmCFrame)
            self:SetTransform("LeftElbow", "LeftElbowRigAttachment", "LeftUpperArm", "LeftLowerArm", LeftUpperArmCFrame, LeftLowerArmCFrame)
            self:SetTransform("LeftWrist", "LeftWristRigAttachment", "LeftLowerArm", "LeftHand", LeftLowerArmCFrame, LeftHandCFrame)
        end
        if not IsWalking and (not AvatarGesturesEnabled or LeftFootTrackerActive) then
            local LeftUpperLegCFrame, LeftLowerLegCFrame, LeftFootCFrame = (self.LeftLeg :: any):GetAppendageCFrames(JointCFrames["LeftHip"], LeftFoot)
            self:SetTransform("LeftHip", "LeftHipRigAttachment", "LowerTorso", "LeftUpperLeg", LowerTorsoCFrame, LeftUpperLegCFrame)
            self:SetTransform("LeftKnee", "LeftKneeRigAttachment", "LeftUpperLeg", "LeftLowerLeg", LeftUpperLegCFrame, LeftLowerLegCFrame)
            self:SetTransform("LeftAnkle", "LeftAnkleRigAttachment", "LeftLowerLeg", "LeftFoot", LeftLowerLegCFrame, LeftFootCFrame)
        else
            self.CurrentMotor6DTransforms[self.Motors.LeftHip] = nil
            self.CurrentMotor6DTransforms[self.Motors.LeftKnee] = nil
            self.CurrentMotor6DTransforms[self.Motors.LeftAnkle] = nil
        end
        if not IsWalking and (not AvatarGesturesEnabled or RightFootTrackerActive) then
            local RightUpperLegCFrame, RightLowerLegCFrame, RightFootCFrame = (self.RightLeg :: any):GetAppendageCFrames(JointCFrames["RightHip"], RightFoot)
            self:SetTransform("RightHip", "RightHipRigAttachment", "LowerTorso", "RightUpperLeg", LowerTorsoCFrame, RightUpperLegCFrame)
            self:SetTransform("RightKnee", "RightKneeRigAttachment", "RightUpperLeg", "RightLowerLeg", RightUpperLegCFrame, RightLowerLegCFrame)
            self:SetTransform("RightAnkle", "RightAnkleRigAttachment", "RightLowerLeg", "RightFoot", RightLowerLegCFrame, RightFootCFrame)
        else
            self.CurrentMotor6DTransforms[self.Motors.RightHip] = nil
            self.CurrentMotor6DTransforms[self.Motors.RightKnee] = nil
            self.CurrentMotor6DTransforms[self.Motors.RightAnkle] = nil
        end
    end

    --Replicate the changes to the server.
    if IsLocalCharacter then
        self.ReplicationCFrames = {
            HeadCFrame = HeadControllerCFrame :: CFrame,
            LeftHandCFrame = LeftHandControllerCFrame :: CFrame,
            RightHandCFrame = RightHandControllerCFrame :: CFrame,
        }
    end
end

--[[
Updates the character from the inputs while seated.
The CFrames are in the local space instead of global space
since the seat maintains the global space.
--]]
function Character.UpdateFromInputsSeated(self: Character, HeadControllerCFrame: CFrame?, LeftHandControllerCFrame: CFrame?, RightHandControllerCFrame: CFrame?): ()
    --Return if the humanoid is dead.
    if self.Humanoid.Health <= 0 then
        return
    end
    if VRService.AvatarGestures or not HeadControllerCFrame or not LeftHandControllerCFrame or not RightHandControllerCFrame then --CFrames aren't send with AvatarGestures. Checks included for typing.
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
        local LeftUpperArmCFrame, LeftLowerArmCFrame, LeftHandCFrame = (self.LeftArm:: any):GetAppendageCFrames(JointCFrames["LeftShoulder"], LeftHandControllerCFrame)
        local RightUpperArmCFrame, RightLowerArmCFrame, RightHandCFrame = (self.RightArm:: any):GetAppendageCFrames(JointCFrames["RightShoulder"], RightHandControllerCFrame)
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
        self.ReplicationCFrames = {
            HeadCFrame = HeadControllerCFrame,
            LeftHandCFrame = LeftHandControllerCFrame,
            RightHandCFrame = RightHandControllerCFrame,
        }
    end
end



return Character