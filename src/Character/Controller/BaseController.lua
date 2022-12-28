 --[[
TheNexusAvenger

Base class for controlling the local character.
--]]

local THUMBSTICK_INPUT_START_RADIUS = 0.6
local THUMBSTICK_INPUT_RELEASE_RADIUS = 0.4
local THUMBSTICK_DEADZONE_RADIUS = 0.2

local BLUR_TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quad)

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local NexusVRCharacterModel = require(script.Parent.Parent.Parent)
local NexusObject = NexusVRCharacterModel:GetResource("NexusInstance.NexusObject")
local CameraService = NexusVRCharacterModel:GetInstance("State.CameraService")
local CharacterService = NexusVRCharacterModel:GetInstance("State.CharacterService")
local VRInputService = NexusVRCharacterModel:GetInstance("State.VRInputService")
local Settings = NexusVRCharacterModel:GetInstance("State.Settings")

local BaseController = NexusObject:Extend()
BaseController:SetClassName("BaseController")



--[[
Returns the Y-axis angle of the given CFrame.
--]]
local function GetAngleToGlobalY(CF: CFrame): number
    return math.atan2(-CF.LookVector.X, -CF.LookVector.Z)
end



--[[
Updates the character. Returns if it changed.
--]]
function BaseController:UpdateCharacterReference(): boolean
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
function BaseController:Enable(): nil
    if not self.Connections then self.Connections = {} end

    --Update the character and return if the character is nil.
    self:UpdateCharacterReference()
    if not self.Character then
        return
    end

    --Connect the eye level being set.
    table.insert(self.Connections, VRInputService.EyeLevelSet:Connect(function()
        if self.LastHeadCFrame.Y > 0 then
            self.LastHeadCFrame = CFrame.new(0, -self.LastHeadCFrame.Y, 0) * self.LastHeadCFrame
        end
    end))

    --Connect the character entering a seat.
    table.insert(self.Connections, self.Character.Humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
        local SeatPart = self.Character:GetHumanoidSeatPart()
        if SeatPart then
            self:PlayBlur()
            VRInputService:Recenter()
        end
    end))

    --Disable auto rotate so that the default controls work.
    self.Character.Humanoid.AutoRotate = false

    --Disable the controls.
    --Done in a loop to ensure changed controllers are disabled.
    task.spawn(function()
        local ControlModule = require(Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
        local Character = self.Character
        while self.Character == Character and Character.Humanoid.Health > 0 do
            if ControlModule.activeController and ControlModule.activeController.enabled then
                ControlModule:Disable()
                ContextActionService:BindActivate(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonR2)
            end
            task.wait()
        end
    end)
end

--[[
Disables the controller.
--]]
function BaseController:Disable(): nil
    self.Character = nil
    self.LastHeadCFrame = nil
    for _, Connection in pairs(self.Connections) do
        Connection:Disconnect()
    end
    self.Connections = nil
end

--[[
Scales the local-space input CFrame based on
the height multiplier of the character.
--]]
function BaseController:ScaleInput(InputCFrame: CFrame): CFrame
    --Return the original CFrame if there is no character.
    if not self.Character then
        return InputCFrame
    end

    --Return the modified CFrame.
    return CFrame.new(InputCFrame.Position * (self.Character.ScaleValues.BodyHeightScale.Value - 1)) * InputCFrame
end

--[[
Updates the provided 'Store' table with the state of its
Thumbstick (Enum.KeyCode.ThumbstickX) field. Returns the
direction state, radius state, and overall state change.
--]]
function BaseController:GetJoystickState(Store: any): (string, string, string)
    local InputPosition = VRInputService:GetThumbstickPosition(Store.Thumbstick)
    local InputRadius = ((InputPosition.X ^ 2) + (InputPosition.Y ^ 2)) ^ 0.5
    local InputAngle = math.atan2(InputPosition.X, InputPosition.Y)

    local DirectionState, RadiusState
    if InputAngle >= math.rad(-135) and InputAngle <= math.rad(-45) then
        DirectionState = "Left"
    elseif InputAngle >= math.rad(-45) and InputAngle <= math.rad(45) then
        DirectionState = "Forward"
    elseif InputAngle >= math.rad(45) and InputAngle <= math.rad(135) then
        DirectionState = "Right"
    end
    if InputRadius >= THUMBSTICK_INPUT_START_RADIUS then
        RadiusState = "Extended"
    elseif InputRadius <= THUMBSTICK_INPUT_RELEASE_RADIUS then
        RadiusState = "Released"
    else
        RadiusState = "InBetween"
    end

    --Update the stored state.
    local StateChange = nil
    if RadiusState == "Released" then
        if Store.RadiusState == "Extended" then
            StateChange = "Released"
        end
        Store.RadiusState = "Released"
        Store.DirectionState = nil
    elseif RadiusState == "Extended" then
        if Store.RadiusState == nil or Store.RadiusState == "Released" then
            if Store.RadiusState ~= "Extended" then
                StateChange = "Extended"
            end
            Store.RadiusState = "Extended"
            Store.DirectionState = DirectionState
        elseif Store.DirectionState ~= DirectionState then
            if Store.RadiusState ~= "Cancelled" then
                StateChange = "Cancel"
            end
            Store.RadiusState = "Cancelled"
            Store.DirectionState = nil
        end
    end

    return DirectionState, RadiusState, StateChange
end

--[[
Plays a temporary blur effect to make
teleports and snap turns less jarring.
]]--
function BaseController:PlayBlur(): nil
    local SnapTeleportBlur = Settings:GetSetting("Movement.SnapTeleportBlur")
    warn(SnapTeleportBlur)
    SnapTeleportBlur = (if SnapTeleportBlur == nil then true else SnapTeleportBlur)

    if not SnapTeleportBlur then
        return
    end

    local Blur = Instance.new("BlurEffect")
    Blur.Parent = workspace.CurrentCamera
    Blur.Size = 56

    local BlurTween = TweenService:Create(Blur, BLUR_TWEEN_INFO, { Size = 0 })
    BlurTween:Play()

    BlurTween.Completed:Connect(function()
        Blur:Destroy()
    end)
end

--[[
Updates the reference world CFrame.
--]]
function BaseController:UpdateCharacter(): nil
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
    local VRLeftHandCFrame,VRRightHandCFrame = self:ScaleInput(VRInputs[Enum.UserCFrame.LeftHand]), self:ScaleInput(VRInputs[Enum.UserCFrame.RightHand])
    local HeadToLeftHandCFrame = VRHeadCFrame:Inverse() * VRLeftHandCFrame
    local HeadToRightHandCFrame = VRHeadCFrame:Inverse() * VRRightHandCFrame

    --Update the character.
    local SeatPart = self.Character:GetHumanoidSeatPart()
    if not SeatPart then
        --Offset the character by the change in the head input.
        if self.LastHeadCFrame then
            --Get the eye CFrame of the current character, except the Y offset from the HumanoidRootPart.
            --The Y position will be added absolutely since doing it relatively will result in floating or short characters.
            local HumanoidRootPartCFrame = self.Character.Parts.HumanoidRootPart.CFrame
            local LowerTorsoCFrame = HumanoidRootPartCFrame * self.Character.Attachments.HumanoidRootPart.RootRigAttachment.CFrame * CFrame.new(0, -self.Character.Motors.Root.Transform.Position.Y, 0) * self.Character.Motors.Root.Transform * self.Character.Attachments.LowerTorso.RootRigAttachment.CFrame:Inverse()
            local UpperTorsoCFrame = LowerTorsoCFrame * self.Character.Attachments.LowerTorso.WaistRigAttachment.CFrame * self.Character.Motors.Waist.Transform * self.Character.Attachments.UpperTorso.WaistRigAttachment.CFrame:Inverse()
            local HeadCFrame = UpperTorsoCFrame * self.Character.Attachments.UpperTorso.NeckRigAttachment.CFrame * self.Character.Motors.Neck.Transform * self.Character.Attachments.Head.NeckRigAttachment.CFrame:Inverse()
            local EyesOffset = self.Character.Head:GetEyesOffset()
            local CharacterEyeCFrame = HeadCFrame * EyesOffset

            --Determine the input components.
            local InputDelta = self.LastHeadCFrame:Inverse() * VRHeadCFrame
            if VRHeadCFrame.UpVector.Y < 0 then
                InputDelta = CFrame.Angles(0,math.pi,0) * InputDelta
            end
            local HeadRotationXZ = (CFrame.new(VRHeadCFrame.Position) * CFrame.Angles(0, math.atan2(-VRHeadCFrame.LookVector.X, -VRHeadCFrame.LookVector.Z), 0)):Inverse() * VRHeadCFrame
            local LastHeadAngleY = GetAngleToGlobalY(self.LastHeadCFrame)
            local HeadAngleY = GetAngleToGlobalY(VRHeadCFrame)
            local HeightOffset = CFrame.new(0, (CFrame.new(0, EyesOffset.Y, 0) * (VRHeadCFrame * EyesOffset:Inverse())).Y, 0)

            --Offset the character eyes for the current input.
            local CurrentCharacterAngleY = GetAngleToGlobalY(CharacterEyeCFrame)
            local RotationY = CFrame.Angles(0, CurrentCharacterAngleY + (HeadAngleY - LastHeadAngleY), 0)
            local NewCharacterEyePosition = (HeightOffset *  CFrame.new((RotationY * CFrame.new(InputDelta.X, 0, InputDelta.Z)).Position) * CharacterEyeCFrame).Position
            local NewCharacterEyeCFrame = CFrame.new(NewCharacterEyePosition) * RotationY * HeadRotationXZ

            --Update the character.
            self.Character:UpdateFromInputs(NewCharacterEyeCFrame, NewCharacterEyeCFrame * HeadToLeftHandCFrame,NewCharacterEyeCFrame * HeadToRightHandCFrame)
        end
    else
        --Set the absolute positions of the character.
        self.Character:UpdateFromInputsSeated(VRHeadCFrame, VRHeadCFrame * HeadToLeftHandCFrame,VRHeadCFrame * HeadToRightHandCFrame)
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
function BaseController:UpdateVehicleSeat(): nil
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