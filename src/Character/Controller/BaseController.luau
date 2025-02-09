 --Base class for controlling the local character.
--!strict

local THUMBSTICK_INPUT_START_RADIUS = 0.6
local THUMBSTICK_INPUT_RELEASE_RADIUS = 0.4
local THUMBSTICK_SNAP_ROTATION_ANGLE = math.rad(30) --Roblox's snap rotation is 30 degrees.
local THUMBSTICK_SMOOTH_LOCOMOTION_DEADZONE = 0.2
local THUMBSTICK_MANUAL_SMOOTH_ROTATION_RATE = math.rad(360) --May or may not be accurate for Roblox's player scripts.
local BLUR_TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quad)
local USER_CFRAME_TO_THUMBSTICK = {
    [Enum.UserCFrame.LeftHand] = Enum.KeyCode.Thumbstick1,
    [Enum.UserCFrame.RightHand] = Enum.KeyCode.Thumbstick2,
}

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local VRService = game:GetService("VRService")

local NexusVRCharacterModel = script.Parent.Parent.Parent
local NexusVRCharacterModelApi = require(NexusVRCharacterModel).Api
local Character = require(NexusVRCharacterModel:WaitForChild("Character"))
local CameraService = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("CameraService")).GetInstance()
local CharacterService = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("CharacterService")).GetInstance()
local Settings = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("Settings")).GetInstance()
local VRInputService = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("VRInputService")).GetInstance()

local BaseController = {}
BaseController.__index = BaseController

export type BaseController = {
    Active: boolean,
    ActionsToLock: {Enum.KeyCode},
    ActionsToUnbind: {Enum.KeyCode}?,
    Character: Character.Character?,
    Connections: {RBXScriptConnection}?,
    LastHeadCFrame: CFrame?,
    LastRotationUpdateTick: number?,
} & typeof(setmetatable({}, BaseController))



--[[
Returns the Y-axis angle of the given CFrame.
--]]
local function GetAngleToGlobalY(CF: CFrame): number
    return math.atan2(-CF.LookVector.X, -CF.LookVector.Z)
end

--[[
Creates a base controller object.
--]]
function BaseController.new(): BaseController
    return setmetatable({
        Active = false,
        ActionsToLock = {Enum.KeyCode.ButtonR3},
    }, BaseController) :: BaseController
end

--[[
Updates the character. Returns if it changed.
--]]
function BaseController.UpdateCharacterReference(self: BaseController): boolean
    local LastCharacter = self.Character
    self.Character = CharacterService:GetCharacter(Players.LocalPlayer)
    if not self.Character then
        return false
    end
    return LastCharacter ~= self.Character
end

--[[
Enables the controller.
--]]
function BaseController.Enable(self: BaseController): ()
    if not self.Connections then self.Connections = {} end
    self.Active = true

    --Bind the actions to sink inputs from the PlayerScripts.
    if not self.ActionsToUnbind then self.ActionsToUnbind = {} end
    for _, KeyCode in self.ActionsToLock do
        local ActionName = HttpService:GenerateGUID()
        ContextActionService:BindActionAtPriority(ActionName, function()
            return self.Active and Enum.ContextActionResult.Sink or Enum.ContextActionResult.Pass
        end, false, Enum.ContextActionPriority.High.Value, KeyCode)
        table.insert(self.ActionsToUnbind :: {Enum.KeyCode}, ActionName)
    end

    --Update the character and return if the character is nil.
    self:UpdateCharacterReference()
    if not self.Character then
        return
    end

    --Connect the eye level being set.
    local Connections = self.Connections :: {RBXScriptConnection}
    table.insert(Connections, VRInputService.EyeLevelSet:Connect(function()
        local LastHeadCFrame = self.LastHeadCFrame
        if LastHeadCFrame and LastHeadCFrame.Y > 0 then
            self.LastHeadCFrame = CFrame.new(0, -LastHeadCFrame.Y, 0) * LastHeadCFrame
        end
    end) :: any)

    --Connect the character entering a seat.
    table.insert(Connections, self.Character.Humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
        local SeatPart = self.Character:GetHumanoidSeatPart()
        if SeatPart then
            self:PlayBlur()
            VRInputService:Recenter()
        end
    end))

    --Disable auto rotate so that the default controls work.
    self.Character.Humanoid.AutoRotate = false
end

--[[
Disables the controller.
--]]
function BaseController.Disable(self: BaseController): ()
    self.Active = false
    self.Character = nil
    self.LastHeadCFrame = nil
    self.LastRotationUpdateTick = nil
    if self.Connections then
        for _, Connection in self.Connections do
            Connection:Disconnect()
        end
    end
    if self.ActionsToUnbind then
        for _, ActionName in self.ActionsToUnbind do
            ContextActionService:UnbindAction(ActionName)
        end
    end
    self.Connections = nil
end

--[[
Scales the local-space input CFrame based on
the height multiplier of the character.
--]]
function BaseController.ScaleInput(self: BaseController, InputCFrame: CFrame): CFrame
    --Return the original CFrame if there is no character.
    if not self.Character or not InputCFrame then
        return InputCFrame
    end

    --Return the modified CFrame.
    return CFrame.new(InputCFrame.Position * (self.Character:GetHumanoidScale("BodyHeightScale") - 1)) * InputCFrame
end

--[[
Updates the provided 'Store' table with the state of its
Thumbstick (Enum.KeyCode.ThumbstickX) field. Returns the
direction state, radius state, and overall state change.
--]]
function BaseController.GetJoystickState(self: BaseController, Store: any): (string, string, string)
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
function BaseController.PlayBlur(self: BaseController): ()
    local SnapTeleportBlur = Settings:GetSetting("Movement.SnapTeleportBlur")
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
function BaseController.UpdateCharacter(self: BaseController): ()
    --Return if the character is nil.
    local CharacterChanged = self:UpdateCharacterReference()
    if not self.Character then
        return
    end
    if CharacterChanged then
        self:Enable()
    end

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

    --Update the camera.
    if self.Character.Parts.HumanoidRootPart:IsDescendantOf(Workspace) and self.Character.Humanoid.Health > 0 then
        --Update the camera based on the character.
        --Done based on the HumanoidRootPart instead of the Head because of Motors not updating the same frame, leading to a delay.
        local HumanoidRootPartCFrame = self.Character.Parts.HumanoidRootPart.CFrame
        local LowerTorsoCFrame = HumanoidRootPartCFrame * self.Character.Attachments.HumanoidRootPart.RootRigAttachment.CFrame * self.Character.Motors.Root.Transform * self.Character.Attachments.LowerTorso.RootRigAttachment.CFrame:Inverse()
        local UpperTorsoCFrame = LowerTorsoCFrame * self.Character.Attachments.LowerTorso.WaistRigAttachment.CFrame * self.Character.Motors.Waist.Transform * self.Character.Attachments.UpperTorso.WaistRigAttachment.CFrame:Inverse()
        local HeadCFrame = UpperTorsoCFrame * self.Character.Attachments.UpperTorso.NeckRigAttachment.CFrame * self.Character.Motors.Neck.Transform * self.Character.Attachments.Head.NeckRigAttachment.CFrame:Inverse()
        CameraService:UpdateCamera(HeadCFrame * self.Character.Head:GetEyesOffset())
        self.LastHeadCFrame = VRHeadCFrame
    elseif not Workspace.CurrentCamera.HeadLocked then
        --Update the camera based on the last CFrame if the motors can't update (not in Workspace).
        local CurrentCameraCFrame = Workspace.CurrentCamera:GetRenderCFrame()
        local LastHeadCFrame = self.LastHeadCFrame or CFrame.new()
        local HeadCFrame = self:ScaleInput(VRInputService:GetVRInputs()[Enum.UserCFrame.Head])
        CameraService:UpdateCamera(CurrentCameraCFrame * LastHeadCFrame:Inverse() * HeadCFrame)
        self.LastHeadCFrame = HeadCFrame
    end
end

--[[
Performs snap or smooth rotating based on the thumbstick input.
--]]
function BaseController.UpdateRotating(self: BaseController, Hand: Enum.UserCFrame, Direction: string, StateChange: string): ()
    if VRService.AvatarGestures then
        self.LastRotationUpdateTick = nil
        return
    end
    if not self.Character or self.Character.Humanoid.Sit then
        self.LastRotationUpdateTick = nil
        return
    end
    if Direction ~= "Left" and Direction ~= "Right" then
        self.LastRotationUpdateTick = nil
        return
    end

    --Return if the input is inactive.
    if NexusVRCharacterModelApi.Controller and not NexusVRCharacterModelApi.Controller:IsControllerInputEnabled(Hand) then
        return
    end

    --Rotate the character.
    local HumanoidRootPart = self.Character.Parts.HumanoidRootPart
    if UserSettings():GetService("UserGameSettings").VRSmoothRotationEnabled then
        --Smoothly rotate the character.
        local InputPosition = VRInputService:GetThumbstickPosition(USER_CFRAME_TO_THUMBSTICK[Hand])
        if math.abs(InputPosition.X) >= THUMBSTICK_SMOOTH_LOCOMOTION_DEADZONE then
            local LastRotationUpdateTick = self.LastRotationUpdateTick or tick()
            local CurrentRotationUpdateTick = tick()
            local RotationUpdateDeltaTime = (CurrentRotationUpdateTick - LastRotationUpdateTick)
            HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position) * CFrame.Angles(0, -InputPosition.X * THUMBSTICK_MANUAL_SMOOTH_ROTATION_RATE * RotationUpdateDeltaTime, 0) * (CFrame.new(-HumanoidRootPart.Position) * HumanoidRootPart.CFrame)
            self.LastRotationUpdateTick = CurrentRotationUpdateTick
        else
            self.LastRotationUpdateTick = nil
        end
    else
        --Snap rotate the character.
        if StateChange == "Extended" then
            if Direction == "Left" then
                --Turn the player to the left.
                self:PlayBlur()
                HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position) * CFrame.Angles(0, THUMBSTICK_SNAP_ROTATION_ANGLE, 0) * (CFrame.new(-HumanoidRootPart.Position) * HumanoidRootPart.CFrame)
            elseif Direction == "Right" then
                --Turn the player to the right.
                self:PlayBlur()
                HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position) * CFrame.Angles(0, -THUMBSTICK_SNAP_ROTATION_ANGLE, 0) * (CFrame.new(-HumanoidRootPart.Position) * HumanoidRootPart.CFrame)
            end
        end
    end
end



return BaseController