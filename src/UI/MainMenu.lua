--[[
TheNexusAvenger

Main menu for Nexus VR Character Model.
--]]
--!strict

local MENU_OPEN_TIME_REQUIREMENT = 1
local MENU_OPEN_TIME = 0.25



local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local NexusVRCharacterModel = script.Parent.Parent
local Settings = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("Settings")).GetInstance()
local VRInputService = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("VRInputService")).GetInstance()
local ApiBaseView = require(NexusVRCharacterModel:WaitForChild("UI"):WaitForChild("View"):WaitForChild("ApiBaseView"))
local ChatView = require(NexusVRCharacterModel:WaitForChild("UI"):WaitForChild("View"):WaitForChild("ChatView"))
local SettingsView = require(NexusVRCharacterModel:WaitForChild("UI"):WaitForChild("View"):WaitForChild("SettingsView"))
local TextButtonFactory = require(NexusVRCharacterModel:WaitForChild("NexusButton"):WaitForChild("Factory"):WaitForChild("TextButtonFactory")).CreateDefault(Color3.fromRGB(0, 170, 255))
TextButtonFactory:SetDefault("Theme", "RoundedCorners")
local NexusVRCore = require(ReplicatedStorage:WaitForChild("NexusVRCore")) :: any
local ScreenGui = NexusVRCore:GetResource("Container.ScreenGui")

local MainMenu = {}
MainMenu.__index = MainMenu
local StaticInstance = nil



--[[
Creates the main menu.
--]]
function MainMenu.new(): any
    local self = {}
    setmetatable(self, MainMenu)

    --Set up the ScreenGui.
    local MainMenuScreenGui = ScreenGui.new()
    MainMenuScreenGui.ResetOnSpawn = false
    MainMenuScreenGui.Enabled = false
    MainMenuScreenGui.CanvasSize = Vector2.new(500, 600)
    MainMenuScreenGui.FieldOfView = 0
    MainMenuScreenGui.Easing = 0.25
    self.ScreenGui = MainMenuScreenGui

    --Create the parent frame, display text, and toggle buttons.
    local ViewAdornFrame = Instance.new("Frame")
    ViewAdornFrame.BackgroundTransparency = 1
    ViewAdornFrame.Size = UDim2.new(0, 500, 0, 500)
    ViewAdornFrame.Parent = MainMenuScreenGui:GetContainer()
    self.ViewAdornFrame = ViewAdornFrame

    local LeftButton, LeftText = TextButtonFactory:Create()
    LeftButton.Size = UDim2.new(0, 80, 0, 80)
    LeftButton.Position = UDim2.new(0, 10, 0, 510)
    LeftButton.Parent = MainMenuScreenGui:GetContainer()
    LeftText.Text = "<"
    self.LeftButton = LeftButton

    local RightButton, RightText = TextButtonFactory:Create()
    RightButton.Size = UDim2.new(0, 80, 0, 80)
    RightButton.Position = UDim2.new(0, 410, 0, 510)
    RightButton.Parent = MainMenuScreenGui:GetContainer()
    RightText.Text = ">"
    self.RightButton = RightButton

    local ViewTextLabel = Instance.new("TextLabel")
    ViewTextLabel.BackgroundTransparency = 1
    ViewTextLabel.Size = UDim2.new(0, 300, 0, 60)
    ViewTextLabel.Position = UDim2.new(0, 100, 0, 520)
    ViewTextLabel.Font = Enum.Font.SourceSansBold
    ViewTextLabel.TextScaled = true
    ViewTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ViewTextLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    ViewTextLabel.TextStrokeTransparency = 0
    ViewTextLabel.Parent = MainMenuScreenGui:GetContainer()
    self.ViewTextLabel = ViewTextLabel

    --Set up the default views.
    self.CurrentView = 1
    self.Views = {}
    (SettingsView :: any).new(self:CreateView("Settings"));
    (ChatView :: any).new(self:CreateView("Chat"))
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
    MainMenuScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    return self
end

--[[
Returns a singleton instance of the character service.
--]]
function MainMenu.GetInstance(): any
    if not StaticInstance then
        StaticInstance = MainMenu.new()
    end
    return StaticInstance
end

--[[
Sets up opening based on the controllers
being rotated upwards.
--]]
function MainMenu:SetUpOpening(): ()
    --Create the animation parts.
    local LeftAdornPart = Instance.new("Part")
    LeftAdornPart.Transparency = 1
    LeftAdornPart.Size = Vector3.new()
    LeftAdornPart.Anchored = true
    LeftAdornPart.CanCollide = false
    LeftAdornPart.Parent = Workspace.CurrentCamera

    local LeftAdorn = Instance.new("BoxHandleAdornment")
    LeftAdorn.Color3 = Color3.fromRGB(0, 170, 255)
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
    RightAdorn.Color3 = Color3.fromRGB(0, 170 , 255)
    RightAdorn.AlwaysOnTop = true
    RightAdorn.ZIndex = 0
    RightAdorn.Adornee = RightAdornPart
    RightAdorn.Parent = RightAdornPart

    local LeftMenuToggleHintAdornPart = Instance.new("Part")
    LeftMenuToggleHintAdornPart.Transparency = 1
    LeftMenuToggleHintAdornPart.Size = Vector3.new(1,1,0)
    LeftMenuToggleHintAdornPart.Anchored = true
    LeftMenuToggleHintAdornPart.CanCollide = false
    LeftMenuToggleHintAdornPart.Parent = Workspace.CurrentCamera

    local RightMenuToggleHintAdornPart = Instance.new("Part")
    RightMenuToggleHintAdornPart.Transparency = 1
    RightMenuToggleHintAdornPart.Size = Vector3.new(1,1,0)
    RightMenuToggleHintAdornPart.Anchored = true
    RightMenuToggleHintAdornPart.CanCollide = false
    RightMenuToggleHintAdornPart.Parent = Workspace.CurrentCamera

    local LeftMenuToggleHintGuiFront = Instance.new("SurfaceGui")
    LeftMenuToggleHintGuiFront.Active = false
    LeftMenuToggleHintGuiFront.Face = Enum.NormalId.Front
    LeftMenuToggleHintGuiFront.CanvasSize = Vector2.new(500,500)
    LeftMenuToggleHintGuiFront.LightInfluence = 0
    LeftMenuToggleHintGuiFront.AlwaysOnTop = true
    LeftMenuToggleHintGuiFront.Adornee = LeftMenuToggleHintAdornPart
    LeftMenuToggleHintGuiFront.Parent = LeftMenuToggleHintAdornPart

    local LeftMenuToggleHintFrontArrow = Instance.new("ImageLabel")
    LeftMenuToggleHintFrontArrow.ImageTransparency = 1
    LeftMenuToggleHintFrontArrow.BackgroundTransparency = 1
    LeftMenuToggleHintFrontArrow.Rotation = 180
    LeftMenuToggleHintFrontArrow.Size = UDim2.new(1,0,1,0)
    LeftMenuToggleHintFrontArrow.Image = "rbxassetid://6537091378"
    LeftMenuToggleHintFrontArrow.ImageRectSize = Vector2.new(512,512)
    LeftMenuToggleHintFrontArrow.ImageRectOffset = Vector2.new(0,0)
    LeftMenuToggleHintFrontArrow.Parent = LeftMenuToggleHintGuiFront

    local LeftMenuToggleHintFrontText = Instance.new("ImageLabel")
    LeftMenuToggleHintFrontText.ImageTransparency = 1
    LeftMenuToggleHintFrontText.BackgroundTransparency = 1
    LeftMenuToggleHintFrontText.Size = UDim2.new(1,0,1,0)
    LeftMenuToggleHintFrontText.ZIndex = 2
    LeftMenuToggleHintFrontText.Image = "rbxassetid://6537091378"
    LeftMenuToggleHintFrontText.ImageRectSize = Vector2.new(512,512)
    LeftMenuToggleHintFrontText.ImageRectOffset = Vector2.new(0,512)
    LeftMenuToggleHintFrontText.Parent = LeftMenuToggleHintGuiFront

    local LeftMenuToggleHintGuiBack = Instance.new("SurfaceGui")
    LeftMenuToggleHintGuiBack.Active = false
    LeftMenuToggleHintGuiBack.Face = Enum.NormalId.Back
    LeftMenuToggleHintGuiBack.CanvasSize = Vector2.new(500,500)
    LeftMenuToggleHintGuiBack.LightInfluence = 0
    LeftMenuToggleHintGuiBack.AlwaysOnTop = true
    LeftMenuToggleHintGuiBack.Adornee = LeftMenuToggleHintAdornPart
    LeftMenuToggleHintGuiBack.Parent = LeftMenuToggleHintAdornPart

    local LeftMenuToggleHintBackArrow = Instance.new("ImageLabel")
    LeftMenuToggleHintBackArrow.ImageTransparency = 1
    LeftMenuToggleHintBackArrow.BackgroundTransparency = 1
    LeftMenuToggleHintBackArrow.Size = UDim2.new(1,0,1,0)
    LeftMenuToggleHintBackArrow.Image = "rbxassetid://6537091378"
    LeftMenuToggleHintBackArrow.ImageRectSize = Vector2.new(512,512)
    LeftMenuToggleHintBackArrow.ImageRectOffset = Vector2.new(512,0)
    LeftMenuToggleHintBackArrow.Parent = LeftMenuToggleHintGuiBack

    local LeftMenuToggleHintBackText = Instance.new("ImageLabel")
    LeftMenuToggleHintBackText.ImageTransparency = 1
    LeftMenuToggleHintBackText.BackgroundTransparency = 1
    LeftMenuToggleHintBackText.Size = UDim2.new(1,0,1,0)
    LeftMenuToggleHintBackText.ZIndex = 2
    LeftMenuToggleHintBackText.Image = "rbxassetid://6537091378"
    LeftMenuToggleHintBackText.ImageRectSize = Vector2.new(512,512)
    LeftMenuToggleHintBackText.ImageRectOffset = Vector2.new(0,512)
    LeftMenuToggleHintBackText.Parent = LeftMenuToggleHintGuiBack

    local RightMenuToggleHintGuiFront = Instance.new("SurfaceGui")
    RightMenuToggleHintGuiFront.Active = false
    RightMenuToggleHintGuiFront.Face = Enum.NormalId.Front
    RightMenuToggleHintGuiFront.CanvasSize = Vector2.new(500,500)
    RightMenuToggleHintGuiFront.LightInfluence = 0
    RightMenuToggleHintGuiFront.AlwaysOnTop = true
    RightMenuToggleHintGuiFront.Adornee = RightMenuToggleHintAdornPart
    RightMenuToggleHintGuiFront.Parent = RightMenuToggleHintAdornPart

    local RightMenuToggleHintFrontArrow = Instance.new("ImageLabel")
    RightMenuToggleHintFrontArrow.ImageTransparency = 1
    RightMenuToggleHintFrontArrow.BackgroundTransparency = 1
    RightMenuToggleHintFrontArrow.Size = UDim2.new(1,0,1,0)
    RightMenuToggleHintFrontArrow.Image = "rbxassetid://6537091378"
    RightMenuToggleHintFrontArrow.ImageRectSize = Vector2.new(512,512)
    RightMenuToggleHintFrontArrow.ImageRectOffset = Vector2.new(512,0)
    RightMenuToggleHintFrontArrow.Parent = RightMenuToggleHintGuiFront

    local RightMenuToggleHintFrontText = Instance.new("ImageLabel")
    RightMenuToggleHintFrontText.ImageTransparency = 1
    RightMenuToggleHintFrontText.BackgroundTransparency = 1
    RightMenuToggleHintFrontText.Size = UDim2.new(1,0,1,0)
    RightMenuToggleHintFrontText.ZIndex = 2
    RightMenuToggleHintFrontText.Image = "rbxassetid://6537091378"
    RightMenuToggleHintFrontText.ImageRectSize = Vector2.new(512,512)
    RightMenuToggleHintFrontText.ImageRectOffset = Vector2.new(0,512)
    RightMenuToggleHintFrontText.Parent = RightMenuToggleHintGuiFront

    local RightMenuToggleHintGuiBack = Instance.new("SurfaceGui")
    RightMenuToggleHintGuiBack.Active = false
    RightMenuToggleHintGuiBack.Face = Enum.NormalId.Back
    RightMenuToggleHintGuiBack.CanvasSize = Vector2.new(500,500)
    RightMenuToggleHintGuiBack.LightInfluence = 0
    RightMenuToggleHintGuiBack.AlwaysOnTop = true
    RightMenuToggleHintGuiBack.Adornee = RightMenuToggleHintAdornPart
    RightMenuToggleHintGuiBack.Parent = RightMenuToggleHintAdornPart

    local RightMenuToggleHintBackArrow = Instance.new("ImageLabel")
    RightMenuToggleHintBackArrow.ImageTransparency = 1
    RightMenuToggleHintBackArrow.BackgroundTransparency = 1
    RightMenuToggleHintBackArrow.Size = UDim2.new(1,0,1,0)
    RightMenuToggleHintBackArrow.Image = "rbxassetid://6537091378"
    RightMenuToggleHintBackArrow.ImageRectSize = Vector2.new(512,512)
    RightMenuToggleHintBackArrow.ImageRectOffset = Vector2.new(0,0)
    RightMenuToggleHintBackArrow.Parent = RightMenuToggleHintGuiBack

    local RightMenuToggleHintBackText = Instance.new("ImageLabel")
    RightMenuToggleHintBackText.BackgroundTransparency = 1
    RightMenuToggleHintBackText.Rotation = 180
    RightMenuToggleHintBackText.ImageTransparency = 1
    RightMenuToggleHintBackText.Size = UDim2.new(1,0,1,0)
    RightMenuToggleHintBackText.ZIndex = 2
    RightMenuToggleHintBackText.Image = "rbxassetid://6537091378"
    RightMenuToggleHintBackText.ImageRectSize = Vector2.new(512,512)
    RightMenuToggleHintBackText.ImageRectOffset = Vector2.new(0,512)
    RightMenuToggleHintBackText.Parent = RightMenuToggleHintGuiBack

    --Connect hiding the hints when the setting changes.
    Settings:GetSettingsChangedSignal("Menu.MenuToggleGestureActive"):Connect(function()
        --Determine if the gesture is active.
        local MenuToggleGestureActive = Settings:GetSetting("Menu.MenuToggleGestureActive")
        if MenuToggleGestureActive == nil then
            MenuToggleGestureActive = true
        end

        --Update the visibility of the hints.
        LeftMenuToggleHintGuiFront.Enabled = MenuToggleGestureActive
        LeftMenuToggleHintGuiBack.Enabled = MenuToggleGestureActive
        RightMenuToggleHintGuiFront.Enabled = MenuToggleGestureActive
        RightMenuToggleHintGuiBack.Enabled = MenuToggleGestureActive
    end)


    --Start checking for the controllers to be upside down.
    --Done in a task since this function is non-yielding.
    local BothControllersUpStartTime
    local MenuToggleReached = false
    task.spawn(function()
        while true do
            --Determine if the gesture is active.
            local MenuToggleGestureActive = Settings:GetSetting("Menu.MenuToggleGestureActive")
            if MenuToggleGestureActive == nil then
                MenuToggleGestureActive = true
            end

            --Get the inputs and determine if the hands are both upside down and pointing forward.
            local VRInputs = VRInputService:GetVRInputs()
            local LeftHandCFrameRelative, RightHandCFrameRelative = VRInputs[Enum.UserCFrame.Head]:Inverse() * VRInputs[Enum.UserCFrame.LeftHand], VRInputs[Enum.UserCFrame.Head]:Inverse() * VRInputs[Enum.UserCFrame.RightHand]
            local LeftHandFacingUp, RightHandFacingUp = LeftHandCFrameRelative.UpVector.Y < 0, RightHandCFrameRelative.UpVector.Y < 0
            local LeftHandFacingForward, RightHandFacingForward = LeftHandCFrameRelative.LookVector.Z < 0, RightHandCFrameRelative.LookVector.Z < 0
            local LeftHandUp, RightHandUp = LeftHandFacingUp and LeftHandFacingForward, RightHandFacingUp and RightHandFacingForward
            local BothHandsUp = MenuToggleGestureActive and LeftHandUp and RightHandUp
            if BothHandsUp then
                BothControllersUpStartTime = BothControllersUpStartTime or tick()
            else
                BothControllersUpStartTime = nil :: any
                MenuToggleReached = false
            end

            --Update the adorn part CFrames.
            local CameraCenterCFrame = Workspace.CurrentCamera:GetRenderCFrame() * VRInputs[Enum.UserCFrame.Head]:Inverse()
            LeftAdornPart.CFrame = CameraCenterCFrame * VRInputs[Enum.UserCFrame.LeftHand] * CFrame.new(0, -0.25, 0.25)
            RightAdornPart.CFrame = CameraCenterCFrame * VRInputs[Enum.UserCFrame.RightHand] * CFrame.new(0, -0.25, 0.25)
            LeftMenuToggleHintAdornPart.CFrame = CameraCenterCFrame * VRInputs[Enum.UserCFrame.LeftHand]
            RightMenuToggleHintAdornPart.CFrame = CameraCenterCFrame * VRInputs[Enum.UserCFrame.RightHand]

            --Update the progress bars.
            if BothControllersUpStartTime and not MenuToggleReached then
                local DeltaTimePercent = (tick() - BothControllersUpStartTime) / MENU_OPEN_TIME_REQUIREMENT
                LeftAdorn.Size = Vector3.new(0.1, 0, 0.25 * DeltaTimePercent)
                RightAdorn.Size = Vector3.new(0.1, 0, 0.25 * DeltaTimePercent)
                LeftAdorn.Visible = true
                RightAdorn.Visible = true

                --Toggle the menu if the time threshold was reached.
                if DeltaTimePercent >= 1 then
                    MenuToggleReached = true
                    task.spawn(function()
                        self:Toggle()
                    end)
                end
            else
                LeftAdorn.Visible = false
                RightAdorn.Visible = false
            end

            --[[
            Updates the given hint parts.
            --]]
            local function UpdateHintParts(Visible,Part,FrontArrow,BackArrow,FrontText,BackText)
                local TweenData = TweenInfo.new(0.25)
                TweenService:Create(Part,TweenData,{
                    Size = Visible and Vector3.new(1, 1, 0) or Vector3.new(1.5, 1.5, 0)
                }):Play()
                TweenService:Create(FrontArrow,TweenData,{
                    ImageTransparency = Visible and 0 or 1
                }):Play()
                TweenService:Create(BackArrow,TweenData,{
                    ImageTransparency = Visible and 0 or 1
                }):Play()
                TweenService:Create(FrontText,TweenData,{
                    ImageTransparency = Visible and 0 or 1
                }):Play()
                TweenService:Create(BackText,TweenData,{
                    ImageTransparency = Visible and 0 or 1
                }):Play()
            end

            --Update the hints.
            local LeftHandHintVisible, RightHandHintVisible = self.ScreenGui.Enabled and not LeftHandUp, self.ScreenGui.Enabled and not RightHandUp
            if self.LeftHandHintVisible ~= LeftHandHintVisible then
                self.LeftHandHintVisible = LeftHandHintVisible
                UpdateHintParts(LeftHandHintVisible, LeftMenuToggleHintAdornPart, LeftMenuToggleHintFrontArrow, LeftMenuToggleHintBackArrow, LeftMenuToggleHintFrontText, LeftMenuToggleHintBackText)
            end
            if self.RightHandHintVisible ~= RightHandHintVisible then
                self.RightHandHintVisible = RightHandHintVisible
                UpdateHintParts(RightHandHintVisible, RightMenuToggleHintAdornPart, RightMenuToggleHintFrontArrow, RightMenuToggleHintBackArrow, RightMenuToggleHintFrontText, RightMenuToggleHintBackText)
            end
            local Rotation = (tick() * 10) % 360
            LeftMenuToggleHintFrontArrow.Rotation = Rotation
            LeftMenuToggleHintBackArrow.Rotation = -Rotation
            RightMenuToggleHintFrontArrow.Rotation = -Rotation
            RightMenuToggleHintBackArrow.Rotation = Rotation

            --Wait to poll again.
            RunService.RenderStepped:Wait()
        end
    end)
end

--[[
Toggles the menu being open.
--]]
function MainMenu:Toggle(): ()
    --Determine the start and end values.
    local StartFieldOfView, EndFieldOfView = (self.ScreenGui.Enabled and math.rad(40) or 0), (self.ScreenGui.Enabled and 0 or math.rad(40))

    --Show the menu if it isn't visible.
    if not self.ScreenGui.Enabled then
        self.ScreenGui.Enabled = true
    end

    --Tween the field of view.
    local StartTime = tick()
    while tick() - StartTime < MENU_OPEN_TIME do
        local Delta = (tick() - StartTime) / MENU_OPEN_TIME
        Delta = (math.sin((Delta - 0.5) * math.pi) / 2) + 0.5
        self.ScreenGui.FieldOfView = StartFieldOfView + ((EndFieldOfView - StartFieldOfView) * Delta)
        RunService.RenderStepped:Wait()
    end

    --Hide thhe menu if it is closed.
    if EndFieldOfView == 0 then
        self.ScreenGui.Enabled = false
    end
end

--[[
Registers a view.
--]]
function MainMenu:RegisterView(ViewName: string, ViewInstance: any): ()
    warn("MainMenu::RegisterView is deprecated and may be removed in the future. Use MainMenu::CreateView instead.")

    --Set up the view instance.
    ViewInstance.Visible = false
    ViewInstance.Name = ViewName
    ViewInstance.Parent = self.ViewAdornFrame

    --Store the view.
    table.insert(self.Views, ViewInstance)
end

--[[
Creates a menu view.
--]]
function MainMenu:CreateView(InitialViewName: string): any
    --Create and store the view.
    local View = ApiBaseView.new(InitialViewName)
    View.Frame.Parent = (self :: any).ViewAdornFrame
    table.insert(self.Views, View)

    --Connect the events.
    View:GetPropertyChangedSignal("Name"):Connect(function()
        self:UpdateVisibleView()
    end)
    View.Destroyed:Connect(function()
        for i = 1, #self.Views do
            if self.Views[i] == View then
                table.remove(self.Views, i)
                if self.CurrentView > i then
                    self.CurrentView += -1
                end
                break
            end
        end
        self:UpdateVisibleView()
    end)
    return View
end

--[[
Updates the visible view.
--]]
function MainMenu:UpdateVisibleView(): ()
    --Update the button visibility.
    self.LeftButton.Visible = (#self.Views > 1)
    self.RightButton.Visible = (#self.Views > 1)

    --Update the display text.
    self.ViewTextLabel.Text = self.Views[self.CurrentView].Name

    --Update the view visibilites.
    for i, View in self.Views do
        View.Visible = (i == self.CurrentView)
    end
end



return MainMenu