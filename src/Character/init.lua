--[[
TheNexusAvenger

Manipulates a character model.
--]]
--!strict


local Players = game:GetService("Players")

local Character = {}
Character.__index = Character

export type Character = {
    new: (CharacterModel: Model) -> Character,

    GetHumanoidScale: (self: Character, ScaleName: string) -> (number),
    GetHumanoidSeatPart: (self: Character) -> (BasePart?),
}



--[[
Creates a character.
--]]
function Character.new(CharacterModel: Model): Character
    local self = {
        CharacterModel = CharacterModel,
        TweenComponents = (CharacterModel ~= Players.LocalPlayer.Character),
    }
    setmetatable(self, Character)

    --Store the body parts.
    self.Humanoid = CharacterModel:WaitForChild("Humanoid")

    --Set up the character parts.
    self:SetUpVRParts()

    --Set up a connection for Character Appearance changes.
    self.AppearanceChangedConnection = nil :: RBXScriptConnection?
    self:SetUpAppearanceChanged()

    return (self :: any) :: Character
end

--[[
Set up Character Parts for VR.
This is also used, to refresh character parts.
--]]
function Character:SetUpVRParts()
    local CharacterModel = self.CharacterModel

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



return (Character :: any) :: Character