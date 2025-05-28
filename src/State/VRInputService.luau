--Manages VR inputs. This normalizes the inputs from
--the headsets as the Y position of the inputs is arbitrary,
--meaning it can be the floor, eye level, or random.
--!strict

local NexusVRCharacterModel = script.Parent.Parent
local NexusInstance = require(NexusVRCharacterModel:WaitForChild("Packages"):WaitForChild("NexusInstance"))

local TypedEvent = NexusInstance.TypedEvent

local VRInputService = {}
VRInputService.__index = VRInputService
local StaticInstance = nil

export type VRInputService = {
    RecenterOffset: CFrame,
    ManualNormalHeadLevel: number?,
    HighestHeadHeight: number?,
    ThumbstickValues: {[Enum.KeyCode]: Vector3},
    VRService: VRService,
    UserInputService: UserInputService,
    Recentered: NexusInstance.TypedEvent<>,
    EyeLevelSet: NexusInstance.TypedEvent<>,
} & typeof(setmetatable({}, VRInputService))



--[[
Creates a settings object.
--]]
function VRInputService.new(VRService: VRService?, UserInputService: UserInputService?): VRInputService
    --Create the object.
    local self = setmetatable({
        RecenterOffset = CFrame.identity,
        ThumbstickValues = {
            [Enum.KeyCode.Thumbstick1] = Vector3.zero,
            [Enum.KeyCode.Thumbstick2] = Vector3.zero,
        },
        VRService = VRService or game:GetService("VRService"),
        UserInputService = UserInputService or game:GetService("UserInputService"),
        Recentered = TypedEvent.new(),
        EyeLevelSet = TypedEvent.new(),
    }, VRInputService) :: VRInputService

    --Connect updating the thumbsticks.
    self.UserInputService.InputEnded:Connect(function(Input)
        if self.ThumbstickValues[Input.KeyCode] then
            self.ThumbstickValues[Input.KeyCode] = Vector3.zero
        end
    end)
    self.UserInputService.InputChanged:Connect(function(Input)
        if self.ThumbstickValues[Input.KeyCode] then
            self.ThumbstickValues[Input.KeyCode] = Input.Position
        end
    end)

    --Return the object.
    return self
end

--[[
Returns a singleton instance of the VR input service.
--]]
function VRInputService.GetInstance(): VRInputService
    if not StaticInstance then
        StaticInstance = VRInputService.new()
    end
    return StaticInstance
end

--[[
Returns the VR inputs to use. The inputs are normalized
so that 0 is the head height.
--]]
function VRInputService.GetVRInputs(self: VRInputService): {[Enum.UserCFrame]: CFrame}
    --Get the head input.
    local VRInputs = {
        [Enum.UserCFrame.Head] = self.VRService:GetUserCFrame(Enum.UserCFrame.Head),
    } :: {[Enum.UserCFrame]: CFrame}

    --Get the hand inputs.
    if self.VRService:GetUserCFrameEnabled(Enum.UserCFrame.LeftHand) then
        VRInputs[Enum.UserCFrame.LeftHand] = self.VRService:GetUserCFrame(Enum.UserCFrame.LeftHand)
    else
        VRInputs[Enum.UserCFrame.LeftHand] = VRInputs[Enum.UserCFrame.Head] * CFrame.new(-1, -2.5, 0.5)
    end
    if self.VRService:GetUserCFrameEnabled(Enum.UserCFrame.RightHand) then
        VRInputs[Enum.UserCFrame.RightHand] = self.VRService:GetUserCFrame(Enum.UserCFrame.RightHand)
    else
        VRInputs[Enum.UserCFrame.RightHand] = VRInputs[Enum.UserCFrame.Head] * CFrame.new(1, -2.5, 0.5)
    end

    --Determine the height offset.
    local HeightOffset = 0
    if self.ManualNormalHeadLevel then
        --Adjust to normalize the height around the set value.
        HeightOffset = -self.ManualNormalHeadLevel
    else
        --Adjust to normalize the height around the highest value.
        --The head CFrame is moved back 0.5 studs for when the headset suddenly goes up (like putting on and taking off).
        local CurrentVRHeadHeight = (VRInputs[Enum.UserCFrame.Head] * CFrame.new(0, 0, 0.5)).Y
        if not self.HighestHeadHeight or CurrentVRHeadHeight > self.HighestHeadHeight then
            self.HighestHeadHeight = CurrentVRHeadHeight
        end
        HeightOffset = -self.HighestHeadHeight :: number
    end

    --Normalize the CFrame heights.
    --A list of enums is used instead of VRInputs because modifying a table stops pairs().
    for _, InputEnum in {Enum.UserCFrame.Head, Enum.UserCFrame.LeftHand, Enum.UserCFrame.RightHand} do
        VRInputs[InputEnum] = CFrame.new(0, HeightOffset, 0) * self.RecenterOffset * VRInputs[InputEnum]
    end

    --Return the CFrames.
    return VRInputs
end

--[[
Recenters the service.
Does not alter the Y axis.
--]]
function VRInputService.Recenter(self: VRInputService): ()
    local HeadCFrame = self.VRService:GetUserCFrame(Enum.UserCFrame.Head)
    self.RecenterOffset = CFrame.Angles(0, -math.atan2(-HeadCFrame.LookVector.X, -HeadCFrame.LookVector.Z), 0) * CFrame.new(-HeadCFrame.X, 0, -HeadCFrame.Z)
    self.Recentered:Fire()
end

--[[
Sets the eye level.
--]]
function VRInputService.SetEyeLevel(self: VRInputService): ()
    self.ManualNormalHeadLevel = self.VRService:GetUserCFrame(Enum.UserCFrame.Head).Y
    self.EyeLevelSet:Fire()
end

--[[
Returns the current value for a thumbstick.
--]]
function VRInputService.GetThumbstickPosition(self: VRInputService, Thumbsick: Enum.KeyCode): Vector3
    return self.ThumbstickValues[Thumbsick] or Vector3.zero
end



return VRInputService