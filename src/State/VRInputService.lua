--[[
TheNexusAvenger

Manages VR inputs. This normalizes the inputs from
the headsets as the Y position of the inputs is arbitrary,
meaning it can be the floor, eye level, or random.
--]]

local NexusVRCharacterModel = require(script.Parent.Parent)
local NexusObject = NexusVRCharacterModel:GetResource("NexusInstance.NexusObject")

local VRInputService = NexusObject:Extend()
VRInputService:SetClassName("VRInputService")



--[[
Creates a settings object.
--]]
function VRInputService:__new(VRService)
    self:InitializeSuper()
    self.VRService = VRService or game:GetService("VRService")
end

--[[
Returns the VR inputs to use. The inputs are normalized
so that 0 is the head height.
--]]
function VRInputService:GetVRInputs()
    --Get the head input.
    local VRInputs = {
        [Enum.UserCFrame.Head] = self.VRService:GetUserCFrame(Enum.UserCFrame.Head),
    }

    --Get the hand inputs.
    if self.VRService:GetUserCFrameEnabled(Enum.UserCFrame.LeftHand) then
        VRInputs[Enum.UserCFrame.LeftHand] = self.VRService:GetUserCFrame(Enum.UserCFrame.LeftHand)
    else
        VRInputs[Enum.UserCFrame.LeftHand] = VRInputs[Enum.UserCFrame.Head] * CFrame.new(-1,-2.5,0.5)
    end
    if self.VRService:GetUserCFrameEnabled(Enum.UserCFrame.RightHand) then
        VRInputs[Enum.UserCFrame.RightHand] = self.VRService:GetUserCFrame(Enum.UserCFrame.RightHand)
    else
        VRInputs[Enum.UserCFrame.RightHand] = VRInputs[Enum.UserCFrame.Head] * CFrame.new(1,-2.5,0.5)
    end

    --Adjust the normalize height.
    --The head CFrame is moved back 0.5 studs for when the headset suddenly goes up (like putting on and taking off).
    local CurrentVRHeadHeight = (VRInputs[Enum.UserCFrame.Head] * CFrame.new(0,0,0.5)).Y
    if not self.HighestHeadHeight or CurrentVRHeadHeight > self.HighestHeadHeight then
        self.HighestHeadHeight = CurrentVRHeadHeight
    end

    --Normalize the CFrame heights.
    --A list of enums is used instead of VRInputs because modifying a table stops pairs().
    for _,InputEnum in pairs({Enum.UserCFrame.Head,Enum.UserCFrame.LeftHand,Enum.UserCFrame.RightHand}) do
        VRInputs[InputEnum] = CFrame.new(0,-self.HighestHeadHeight,0) * VRInputs[InputEnum]
    end

    --Return the CFrames.
    return VRInputs
end



return VRInputService