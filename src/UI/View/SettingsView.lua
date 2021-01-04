--[[
TheNexusAvenger

View for the user settings.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NexusVRCharacterModel = require(script.Parent.Parent.Parent)
local CameraService = NexusVRCharacterModel:GetInstance("State.CameraService")
local ControlService = NexusVRCharacterModel:GetInstance("State.ControlService")
local Settings = NexusVRCharacterModel:GetInstance("State.Settings")
local VRInputService = NexusVRCharacterModel:GetInstance("State.VRInputService")
local BaseView = NexusVRCharacterModel:GetResource("UI.View.BaseView")
local TextButtonFactory = NexusVRCharacterModel:GetResource("NexusButton.Factory.TextButtonFactory").CreateDefault(Color3.new(0,170/255,255/255))
local NexusVRCore = require(ReplicatedStorage:WaitForChild("NexusVRCore"))
local NexusWrappedInstance = NexusVRCore:GetResource("NexusWrappedInstance")

local SettingsView = BaseView:Extend()
SettingsView:SetClassName("SettingsView")



--[[
Creates the settings view.
--]]
function SettingsView:__new()
    self:InitializeSuper()

    --Create the header.
    local HeaderLogo = NexusWrappedInstance.new("ImageLabel")
    HeaderLogo.BackgroundTransparency = 1
    HeaderLogo.Size = UDim2.new(0.4,0,0.4,0)
    HeaderLogo.Position = UDim2.new(0.3,0,-0.1,0)
    HeaderLogo.Image = "http://www.roblox.com/asset/?id=1499731139"
    HeaderLogo.Parent = self

    local NameText = NexusWrappedInstance.new("TextLabel")
    NameText.BackgroundTransparency = 1
    NameText.Size = UDim2.new(0.8,0,0.1,0)
    NameText.Position = UDim2.new(0.1,0,0.2,0)
    NameText.Font = Enum.Font.SciFi
    NameText.Text = "Nexus VR Character Model"
    NameText.TextScaled = true
    NameText.TextColor3 = Color3.new(1,1,1)
    NameText.TextStrokeColor3 = Color3.new(0,0,0)
    NameText.TextStrokeTransparency = 0
    NameText.Parent = self

    --Create the settings.
    local CameraSettingFrame = NexusWrappedInstance.new("Frame")
    CameraSettingFrame.BackgroundTransparency = 1
    CameraSettingFrame.Size = UDim2.new(0.8,0,0.125,0)
    CameraSettingFrame.Position = UDim2.new(0.1,0,0.325,0)
    CameraSettingFrame.Parent = self
    self:PopulateSettingsFrame(CameraSettingFrame,"View","Camera.EnabledCameraOptions",function()
        return CameraService.ActiveCamera
    end,function(NewValue)
        CameraService:SetActiveCamera(NewValue)
    end)

    local MovementSettingFrame = NexusWrappedInstance.new("Frame")
    MovementSettingFrame.BackgroundTransparency = 1
    MovementSettingFrame.Size = UDim2.new(0.8,0,0.125,0)
    MovementSettingFrame.Position = UDim2.new(0.1,0,0.5,0)
    MovementSettingFrame.Parent = self
    self:PopulateSettingsFrame(MovementSettingFrame,"Control","Movement.EnabledMovementMethods",function()
        return ControlService.ActiveController
    end,function(NewValue)
        ControlService:SetActiveController(NewValue)
    end)

    --Create the callibration settings.
    local RecenterButton,RecenterText = TextButtonFactory:Create()
    RecenterButton.Size = UDim2.new(0.4,0,0.075,0)
    RecenterButton.Position = UDim2.new(0.075,0,0.8,0)
    RecenterButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
    RecenterButton.Parent = self
    RecenterText.Text = "Recenter"

    RecenterButton.MouseButton1Click:Connect(function()
        VRInputService:Recenter()
    end)

    local SetEyeLevelButton,SetEyeLevelText = TextButtonFactory:Create()
    SetEyeLevelButton.Size = UDim2.new(0.4,0,0.075,0)
    SetEyeLevelButton.Position = UDim2.new(0.525,0,0.8,0)
    SetEyeLevelButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
    SetEyeLevelButton.Parent = self
    SetEyeLevelText.Text = " Set Eye Level "

    SetEyeLevelButton.MouseButton1Click:Connect(function()
        VRInputService:SetEyeLevel()
    end)
end

--[[
Popuulates a setting frame.
--]]
function SettingsView:PopulateSettingsFrame(ContainerFrame,HeaderName,OptionsSetting,GetValueFunction,SetValueFunction)
    --Create the frames.
    local LeftButton,LeftText = TextButtonFactory:Create()
    LeftButton.Size = UDim2.new(1,0,1,0)
    LeftButton.Position = UDim2.new(0,0,0,0)
    LeftButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
    LeftButton.Parent = ContainerFrame
    LeftText.Text = "<"

    local RightButton,RightText = TextButtonFactory:Create()
    RightButton.AnchorPoint = Vector2.new(1,0)
    RightButton.Size = UDim2.new(1,0,1,0)
    RightButton.Position = UDim2.new(1,0,0,0)
    RightButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
    RightButton.Parent = ContainerFrame
    RightText.Text = ">"

    local OptionHeaderText = NexusWrappedInstance.new("TextLabel")
    OptionHeaderText.BackgroundTransparency = 1
    OptionHeaderText.Size = UDim2.new(0.8,0,0.4,0)
    OptionHeaderText.Position = UDim2.new(0.1,0,0,0)
    OptionHeaderText.Font = Enum.Font.SciFi
    OptionHeaderText.Text = HeaderName
    OptionHeaderText.TextScaled = true
    OptionHeaderText.TextColor3 = Color3.new(1,1,1)
    OptionHeaderText.TextStrokeColor3 = Color3.new(0,0,0)
    OptionHeaderText.TextStrokeTransparency = 0
    OptionHeaderText.Parent = ContainerFrame

    local OptionText = NexusWrappedInstance.new("TextLabel")
    OptionText.BackgroundTransparency = 1
    OptionText.Size = UDim2.new(0.6,0,0.7,0)
    OptionText.Position = UDim2.new(0.2,0,0.3,0)
    OptionText.Font = Enum.Font.SciFi
    OptionText.TextScaled = true
    OptionText.TextColor3 = Color3.new(1,1,1)
    OptionText.TextStrokeColor3 = Color3.new(0,0,0)
    OptionText.TextStrokeTransparency = 0
    OptionText.Parent = ContainerFrame

    --[[
    Updates the settings.
    --]]
    local function UpdateSettings(Increment)
        --Get the current value id.
        local InitialValueName = GetValueFunction()
        local CurrentValue = 1
        local Options = Settings:GetSetting(OptionsSetting) or {}
        for i,Option in pairs(Options) do
            if Option == InitialValueName then
                CurrentValue = i
                break
            end
        end

        --Increment the value.
        if Increment and Increment ~= 0 then
            CurrentValue = CurrentValue + Increment
            if CurrentValue <= 0 then
                CurrentValue = #Options
            end
            if CurrentValue > #Options then
                CurrentValue = 1
            end
        end

        --Update the button visibility.
        LeftButton.Visible = (#Options > 1)
        RightButton.Visible = (#Options > 1)

        --Update the display text.
        OptionText.Text = Options[CurrentValue] or "(N/A)"
       
        --Set the new value.
        if Increment and Increment ~= 0 and Options[CurrentValue] then
            SetValueFunction(Options[CurrentValue])
        end
    end

    --Connect the events.
    Settings:GetSettingsChangedSignal(OptionsSetting):Connect(UpdateSettings)
    LeftButton.MouseButton1Click:Connect(function()
        UpdateSettings(-1)
    end)
    RightButton.MouseButton1Click:Connect(function()
        UpdateSettings(1)
    end)

    --Update the initial settings.
    UpdateSettings()
end



return SettingsView