 --[[
TheNexusAvenger

Base class for controlling the local character.
--]]

local THUMBSTICK_DEADZONE_RADIUS = 0.2



local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local NexusVRCharacterModel = require(script.Parent.Parent.Parent)
local NexusObject = NexusVRCharacterModel:GetResource("NexusInstance.NexusObject")
local CameraService = NexusVRCharacterModel:GetInstance("State.CameraService")
local CharacterService = NexusVRCharacterModel:GetInstance("State.CharacterService")
local VRInputService = NexusVRCharacterModel:GetInstance("State.VRInputService")

local BaseController = NexusObject:Extend()
BaseController:SetClassName("BaseController")



--[[
Returns the Y-axis angle of the given CFrame.
--]]
local function GetAngleToGlobalY(CF)
    return math.atan2(-CF.LookVector.X,-CF.LookVector.Z)
end

--[[
Returns the Y-axis angle of the given CFrame relative
to another CFrame.
--]]
local function GetAngleToRelativeY(CF,Relative)
    return GetAngleToGlobalY(Relative:Inverse() * CF)
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
    if not self.Connections then self.Connections = {} end

    --Update the character and return if the character is nil.
    self:UpdateCharacterReference()
    if not self.Character then
        return
    end

    --Connect the eye level being set.
    table.insert(self.Connections,VRInputService.EyeLevelSet:Connect(function()
        if self.LastHeadCFrame.Y > 0 then
            self.LastHeadCFrame = CFrame.new(0,-self.LastHeadCFrame.Y,0) * self.LastHeadCFrame
        end
    end))

    --Connect the character entering a seat.
    table.insert(self.Connections,self.Character.Humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
        local SeatPart = self.Character:GetHumanoidSeatPart()
        if SeatPart and self.LastHeadCFrame then
            --Set the next angle Y to use for the character during the next update.
            self.OverrideBaseAngleY = GetAngleToGlobalY(SeatPart.CFrame)
        end
    end))

    --Disable auto rotate so that the default controls work.
    self.Character.Humanoid.AutoRotate = false

    --Disable the controls.
    --Done in a loop to ensure changed controllers are disabled.
    coroutine.wrap(function()
        local ControlModule = require(Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
        local Character = self.Character
        while self.Character == Character and Character.Humanoid.Health > 0 do
            if ControlModule.activeController and ControlModule.activeController.enabled then
                ControlModule:Disable()
            end
            wait()
        end
    end)()
end

--[[
Disables the controller.
--]]
function BaseController:Disable()
    self.Character = nil
    self.LastHeadCFrame = nil
    for _,Connection in pairs(self.Connections) do
        Connection:Disconnect()
    end
    self.Connections = nil
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
function BaseController:UpdateCharacter()
    --Return if the character is nil.
    local CharacterChanged = self:UpdateCharacterReference()
    if not self.Character then
        return
    end
    if CharacterChanged then
        self.object:Enable()
    end
    self.Character.TweenComponents = false

    --Get the VR inputs.
    local VRInputs = VRInputService:GetVRInputs()
    local VRHeadCFrame = self:ScaleInput(VRInputs[Enum.UserCFrame.Head])
    local VRLeftHandCFrame,VRRightHandCFrame = self:ScaleInput(VRInputs[Enum.UserCFrame.LeftHand]),self:ScaleInput(VRInputs[Enum.UserCFrame.RightHand])

    --Offset the character by the change in the head input.
    if self.LastHeadCFrame then
        --Determine the XZ rotation of the seat, if any.
        local SeatPart = self.Character:GetHumanoidSeatPart()
        local SeatRotationXZ = CFrame.new()
        if SeatPart then
            local SeatCFrame = SeatPart.CFrame
            SeatRotationXZ = (CFrame.new(SeatCFrame.Position) * CFrame.Angles(0,math.atan2(-SeatCFrame.LookVector.X,-SeatCFrame.LookVector.Z),0)):Inverse() * SeatCFrame
        end

        --Get the eye CFrame of the current character, except the Y offset from the HumanoidRootPart.
        --The Y position will be added absolutely since doing it relatively will result in floating or short characters.
        local HumanoidRootPartCFrame = self.Character.Parts.HumanoidRootPart.CFrame
        local LowerTorsoCFrame = HumanoidRootPartCFrame * self.Character.Attachments.HumanoidRootPart.RootRigAttachment.CFrame * CFrame.new(0,-self.Character.Motors.Root.Transform.Position.Y,0) * self.Character.Motors.Root.Transform * self.Character.Attachments.LowerTorso.RootRigAttachment.CFrame:Inverse()
        local UpperTorsoCFrame = LowerTorsoCFrame * self.Character.Attachments.LowerTorso.WaistRigAttachment.CFrame * self.Character.Motors.Waist.Transform * self.Character.Attachments.UpperTorso.WaistRigAttachment.CFrame:Inverse()
        local HeadCFrame = UpperTorsoCFrame * self.Character.Attachments.UpperTorso.NeckRigAttachment.CFrame * self.Character.Motors.Neck.Transform * self.Character.Attachments.Head.NeckRigAttachment.CFrame:Inverse()
        local EyesOffset = self.Character.Head:GetEyesOffset()
        local CharacterEyeCFrame = HeadCFrame * EyesOffset

        --Determine the input components.
        local InputDelta = self.LastHeadCFrame:Inverse() * VRHeadCFrame
        if VRHeadCFrame.UpVector.Y < 0 then
            InputDelta = CFrame.Angles(0,math.pi,0) * InputDelta
        end
        local HeadRotationXZ = (CFrame.new(VRHeadCFrame.Position) * CFrame.Angles(0,math.atan2(-VRHeadCFrame.LookVector.X,-VRHeadCFrame.LookVector.Z),0)):Inverse() * VRHeadCFrame
        local LastHeadAngleY = GetAngleToGlobalY(self.LastHeadCFrame)
        local HeadAngleY = GetAngleToGlobalY(VRHeadCFrame)
        local HeightOffset = CFrame.new(0,(CFrame.new(0,EyesOffset.Y,0) * (VRHeadCFrame * EyesOffset:Inverse())).Y,0)

        --Offset the character eyes for the current input.
        local CurrentCharacterAngleY = GetAngleToRelativeY(CharacterEyeCFrame,SeatRotationXZ)
        if self.OverrideBaseAngleY then
            CurrentCharacterAngleY = self.OverrideBaseAngleY
            self.OverrideBaseAngleY = nil
        end
        local RotationY = CFrame.Angles(0,CurrentCharacterAngleY + (HeadAngleY - LastHeadAngleY),0)
        local NewCharacterEyePosition = (CFrame.new((SeatRotationXZ * RotationY * CFrame.new(InputDelta.X,0,InputDelta.Z).Position)) * CharacterEyeCFrame).Position
        local NewCharacterEyeCFrame = CFrame.new(NewCharacterEyePosition) * RotationY * HeadRotationXZ --TODO: SeatRotationXZ is not applied (existing method didn't work as expected).

        --Update the character.
        local HeadToLeftHandCFrame = VRHeadCFrame:Inverse() * VRLeftHandCFrame
        local HeadToRightHandCFrame = VRHeadCFrame:Inverse() * VRRightHandCFrame
        self.Character:UpdateFromInputs(NewCharacterEyeCFrame,NewCharacterEyeCFrame * HeadToLeftHandCFrame,NewCharacterEyeCFrame * HeadToRightHandCFrame,HeightOffset) --TODO: Remove extra parameter when seat rotation is properly used.
    end
    self.LastHeadCFrame = VRHeadCFrame

    --Update the camera.
    if self.Character.Parts.HumanoidRootPart:IsDescendantOf(Workspace) and self.Character.Humanoid.Health > 0 then
        --Update the camera based on the character.
        --Done based on the HumanoidRootPart instead of the Head because of Motors not updating the same frame, leading to a delay.
        local HumanoidRootPartCFrame = self.Character.Parts.HumanoidRootPart.CFrame
        local LowerTorsoCFrame = HumanoidRootPartCFrame * self.Character.Attachments.HumanoidRootPart.RootRigAttachment.CFrame * self.Character.Motors.Root.Transform * self.Character.Attachments.LowerTorso.RootRigAttachment.CFrame:Inverse()
        local UpperTorsoCFrame = LowerTorsoCFrame * self.Character.Attachments.LowerTorso.WaistRigAttachment.CFrame * self.Character.Motors.Waist.Transform * self.Character.Attachments.UpperTorso.WaistRigAttachment.CFrame:Inverse()
        local HeadCFrame = UpperTorsoCFrame * self.Character.Attachments.UpperTorso.NeckRigAttachment.CFrame * self.Character.Motors.Neck.Transform * self.Character.Attachments.Head.NeckRigAttachment.CFrame:Inverse()
        CameraService:UpdateCamera(HeadCFrame * self.Character.Head:GetEyesOffset())
    else
        --Update the camera based on the last CFrame if the motors can't update (not in Workspace).
        local CurrentCameraCFrame = Workspace.CurrentCamera.CFrame
        local LastHeadCFrame = self.LastHeadCFrame or CFrame.new()
        local HeadCFrame = self:ScaleInput(VRInputService:GetVRInputs()[Enum.UserCFrame.Head])
        Workspace.CurrentCamera.CFrame = CurrentCameraCFrame * LastHeadCFrame:Inverse() * HeadCFrame
        self.LastHeadCFrame = HeadCFrame
    end
end

--[[
Updates the values of the vehicle seat.
--]]
function BaseController:UpdateVehicleSeat()
    --Get the vehicle seat.
    local SeatPart = self.Character:GetHumanoidSeatPart()
    if not SeatPart or not SeatPart:IsA("VehicleSeat") then
        return
    end

    --Get the direction.
    local ThumbstickPosition = VRInputService:GetThumbstickPosition(Enum.KeyCode.Thumbstick1)
    if ThumbstickPosition.Magnitude < THUMBSTICK_DEADZONE_RADIUS then
        ThumbstickPosition = Vector3.new(0,0,0)
    end
    local ForwardDirection = (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0) + (UserInputService:IsKeyDown(Enum.KeyCode.S) and -1 or 0) + ThumbstickPosition.Y
    local SideDirection = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) + (UserInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0) + ThumbstickPosition.X

    --Update the throttle and steering.
    SeatPart.ThrottleFloat = ForwardDirection
    SeatPart.SteerFloat = SideDirection
end



return BaseController