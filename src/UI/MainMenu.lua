--[[
TheNexusAvenger

Main menu for Nexus VR Character Model.
--]]

local MENU_OPEN_TIME_REQUIREMENT = 1
local MENU_OPEN_TIME = 0.25



local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local NexusVRCharacterModel = require(script.Parent.Parent)
local VRInputService = NexusVRCharacterModel:GetInstance("State.VRInputService")
local ChatView = NexusVRCharacterModel:GetResource("UI.View.ChatView")
local SettingsView = NexusVRCharacterModel:GetResource("UI.View.SettingsView")
local TextButtonFactory = NexusVRCharacterModel:GetResource("NexusButton.Factory.TextButtonFactory").CreateDefault(Color3.new(0,170/255,255/255))
local NexusVRCore = require(ReplicatedStorage:WaitForChild("NexusVRCore"))
local ScreenGui = NexusVRCore:GetResource("Container.ScreenGui")
local NexusWrappedInstance = NexusVRCore:GetResource("NexusWrappedInstance")

local MainMenu = ScreenGui:Extend()
MainMenu:SetClassName("MainMenu")



--[[
Creates the main menu.
--]]
function MainMenu:__new()
    self:InitializeSuper()

    --Set up the ScreenGui.
    self.ResetOnSpawn = false
    self.Enabled = false
    self.CanvasSize = Vector2.new(500,600)
    self.FieldOfView = 0
    self.Easing = 0.25

    --Disable replication to the wrapped instance.
    self:DisableChangeReplication("ViewAdornFrame")
    self:DisableChangeReplication("LeftButton")
    self:DisableChangeReplication("RightButton")
    self:DisableChangeReplication("ViewTextLabel")
    self:DisableChangeReplication("CurrentView")
    self:DisableChangeReplication("Views")

    --Create the parent frame, display text, and toggle buttons.
    local ViewAdornFrame = NexusWrappedInstance.new("Frame")
    ViewAdornFrame.BackgroundTransparency = 1
    ViewAdornFrame.Size = UDim2.new(0,500,0,500)
    ViewAdornFrame.Parent = self
    self.ViewAdornFrame = ViewAdornFrame

    local LeftButton,LeftText = TextButtonFactory:Create()
    LeftButton.Size = UDim2.new(0,80,0,80)
    LeftButton.Position = UDim2.new(0,10,0,510)
    LeftButton.Parent = self
    LeftText.Text = "<"
    self.LeftButton = LeftButton

    local RightButton,RightText = TextButtonFactory:Create()
    RightButton.Size = UDim2.new(0,80,0,80)
    RightButton.Position = UDim2.new(0,410,0,510)
    RightButton.Parent = self
    RightText.Text = ">"
    self.RightButton = RightButton

    local ViewTextLabel = NexusWrappedInstance.new("TextLabel")
    ViewTextLabel.BackgroundTransparency = 1
    ViewTextLabel.Size = UDim2.new(0,300,0,60)
    ViewTextLabel.Position = UDim2.new(0,100,0,520)
    ViewTextLabel.Font = Enum.Font.SciFi
    ViewTextLabel.TextScaled = true
    ViewTextLabel.TextColor3 = Color3.new(1,1,1)
    ViewTextLabel.TextStrokeColor3 = Color3.new(0,0,0)
    ViewTextLabel.TextStrokeTransparency = 0
    ViewTextLabel.Parent = self
    self.ViewTextLabel = ViewTextLabel

    --Set up the default views.
    self.CurrentView = 1
    self.Views = {}
    self:RegisterView("Settings",SettingsView.new())
    self:RegisterView("Chat",ChatView.new())
    self:UpdateVisibleView()

    --Connect changing views.
    LeftButton.MouseButton1Click:Connect(function()
        --De-increment the current view.
        self.CurrentView = self.CurrentView - 1
        if self.CurrentView == 0 then
            self.CurrentView = #self.Views
        end

        --Update the views.
        self:UpdateVisibleView()
    end)
    RightButton.MouseButton1Click:Connect(function()
        --Increment the current view.
        self.CurrentView = self.CurrentView + 1
        if self.CurrentView > #self.Views then
            self.CurrentView = 1
        end

        --Update the views.
        self:UpdateVisibleView()
    end)

    --Parent the menu.
    self.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

--[[
Sets up opening based on the controllers
being rotated upwards.
--]]
function MainMenu:SetUpOpening()
    --Create the animation parts.
    local LeftAdornPart = Instance.new("Part")
    LeftAdornPart.Transparency = 1
    LeftAdornPart.Size = Vector3.new()
    LeftAdornPart.Anchored = true
    LeftAdornPart.CanCollide = false
    LeftAdornPart.Parent = Workspace.CurrentCamera

    local LeftAdorn = Instance.new("BoxHandleAdornment")
    LeftAdorn.Color3 = Color3.new(0,170/255,255/255)
    LeftAdorn.AlwaysOnTop = true
    LeftAdorn.ZIndex = 0
    LeftAdorn.Adornee = LeftAdornPart
    LeftAdorn.Parent = LeftAdornPart

    local RightAdornPart = Instance.new("Part")
    RightAdornPart.Transparency = 1
    RightAdornPart.Size = Vector3.new()
    RightAdornPart.Anchored = true
    RightAdornPart.CanCollide = false
    RightAdornPart.Parent = Workspace.CurrentCamera

    local RightAdorn = Instance.new("BoxHandleAdornment")
    RightAdorn.Color3 = Color3.new(0,170/255,255/255)
    RightAdorn.AlwaysOnTop = true
    RightAdorn.ZIndex = 0
    RightAdorn.Adornee = RightAdornPart
    RightAdorn.Parent = RightAdornPart

    --Start checking for the controllers to be upside down.
    --Done in a coroutine since this function is non-yielding.
    local BothControllersUpStartTime
    local MenuToggleReached = false
    coroutine.wrap(function()
        while true do
            --Get the inputs and determine if the hands are both upside down and pointing forward.
            local VRInputs = VRInputService:GetVRInputs()
            local LeftHandCFrameRelative,RightHandCFrameRelative = VRInputs[Enum.UserCFrame.Head]:Inverse() * VRInputs[Enum.UserCFrame.LeftHand],VRInputs[Enum.UserCFrame.Head]:Inverse() * VRInputs[Enum.UserCFrame.RightHand]
            local LeftHandFacingUp,RightHandFacingUp = LeftHandCFrameRelative.UpVector.Y < 0,RightHandCFrameRelative.UpVector.Y < 0
            local LeftHandFacingForward,RightHandFacingForward = LeftHandCFrameRelative.LookVector.Z < 0,RightHandCFrameRelative.LookVector.Z < 0
            local BothHandsUp = LeftHandFacingUp and RightHandFacingUp and LeftHandFacingForward and RightHandFacingForward
            if BothHandsUp then
                BothControllersUpStartTime = BothControllersUpStartTime or tick()
            else
                BothControllersUpStartTime = nil
                MenuToggleReached = false
            end

            --Update the adorn part CFrames.
            local CameraCenterCFrame = Workspace.CurrentCamera:GetRenderCFrame() * VRInputs[Enum.UserCFrame.Head]:Inverse()
            LeftAdornPart.CFrame = CameraCenterCFrame * VRInputs[Enum.UserCFrame.LeftHand] * CFrame.new(0,-0.25,0.25)
            RightAdornPart.CFrame = CameraCenterCFrame * VRInputs[Enum.UserCFrame.RightHand] * CFrame.new(0,-0.25,0.25)

            --Update the progress bars.
            if BothControllersUpStartTime and not MenuToggleReached then
                local DeltaTimePercent = (tick() - BothControllersUpStartTime)/MENU_OPEN_TIME_REQUIREMENT
                LeftAdorn.Size = Vector3.new(0.1,0,0.25 * DeltaTimePercent)
                RightAdorn.Size = Vector3.new(0.1,0,0.25 * DeltaTimePercent)
                LeftAdorn.Visible = true
                RightAdorn.Visible = true

                --Toggle the menu if the time threshold was reached.
                if DeltaTimePercent >= 1 then
                    MenuToggleReached = true
                    self:Toggle()
                end
            else
                LeftAdorn.Visible = false
                RightAdorn.Visible = false
            end

            --Wait to poll again.
            wait()
        end
    end)()
end

--[[
Toggles the menu being open.
--]]
function MainMenu:Toggle()
    --Determine the start and end values.
    local StartFieldOfView,EndFieldOfView = (self.Enabled and math.rad(40) or 0),(self.Enabled and 0 or math.rad(40))

    --Show the menu if it isn't visible.
    if not self.Enabled then
        self.Enabled = true
    end

    --Tween the field of view.
    local StartTime = tick()
    while tick() - StartTime < MENU_OPEN_TIME do
        local Delta = (tick() - StartTime)/MENU_OPEN_TIME
        Delta = (math.sin((Delta - 0.5) * math.pi)/2) + 0.5
        self.FieldOfView = StartFieldOfView + ((EndFieldOfView - StartFieldOfView) * Delta)
        RunService.RenderStepped:Wait()
    end

    --Hide thhe menu if it is closed.
    if EndFieldOfView == 0 then
        self.Enabled = false
    end
end

--[[
Registers a view.
--]]
function MainMenu:RegisterView(ViewName,ViewInstance)
    --Set up the view instance.
    ViewInstance.Visible = false
    ViewInstance.Parent = self.ViewAdornFrame

    --Store the view.
    table.insert(self.Views,{
        Name = ViewName,
        View = ViewInstance,
    })
end

--[[
Updates the visible view.
--]]
function MainMenu:UpdateVisibleView()
    --Update the button visibility.
    self.LeftButton.Visible = (#self.Views > 1)
    self.RightButton.Visible = (#self.Views > 1)

    --Update the display text.
    self.ViewTextLabel.Text = self.Views[self.CurrentView].Name

    --Update the view visibilites.
    for i,View in pairs(self.Views) do
        View.View.Visible = (i == self.CurrentView)
    end
end



return MainMenu