 --[[
TheNexusAvenger

Base class for controlling the local character.
--]]
--!strict

local THUMBSTICK_INPUT_START_RADIUS = 0.6
local THUMBSTICK_INPUT_RELEASE_RADIUS = 0.4
local BLUR_TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quad)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local NexusVRCharacterModel = script.Parent.Parent.Parent
local CameraService = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("CameraService")).GetInstance()
local CharacterService = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("CharacterService")).GetInstance()
local Settings = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("Settings")).GetInstance()
local VRInputService = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("VRInputService")).GetInstance()

local BaseController = {}
BaseController.__index = BaseController



--[[
Creates a base controller object.
--]]
function BaseController.new(): any
    return setmetatable({}, BaseController)
end

--[[
Updates the character. Returns if it changed.
--]]
function BaseController:UpdateCharacterReference(): boolean
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
function BaseController:Enable(): ()
    if not self.Connections then self.Connections = {} end

    --Update the character and return if the character is nil.
    self:UpdateCharacterReference()
    if not self.Character then
        return
    end

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
end

--[[
Disables the controller.
--]]
function BaseController:Disable(): ()
    self.Character = nil
    self.LastRotationUpdateTick = nil
    for _, Connection in self.Connections do
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
function BaseController:PlayBlur(): ()
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
function BaseController:UpdateCharacter(): ()
    --Return if the character is nil.
    local CharacterChanged = self:UpdateCharacterReference()
    if not self.Character then
        return
    end
    if CharacterChanged then
        self:Enable()
    end

    --Update the camera.
    --TODO: Currently unsure how to handle the camera because the Head is no longer a source of truth for the camera.
    --TODO: CameraService:UpdateCamera()
end



return BaseController