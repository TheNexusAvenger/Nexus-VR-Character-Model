--[[
TheNexusAvenger

Displays a message if R6 is used.
--]]

local MESSAGE_OPEN_TIME = 0.25



local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local NexusVRCharacterModel = require(script.Parent.Parent)
local TextButtonFactory = NexusVRCharacterModel:GetResource("NexusButton.Factory.TextButtonFactory").CreateDefault(Color3.new(0,170/255,255/255))
local NexusVRCore = require(ReplicatedStorage:WaitForChild("NexusVRCore"))
local ScreenGui = NexusVRCore:GetResource("Container.ScreenGui")
local NexusWrappedInstance = NexusVRCore:GetResource("NexusWrappedInstance")

local R6Message = ScreenGui:Extend()
R6Message:SetClassName("R6Message")



--[[
Creates the R6 message.
--]]
function R6Message:__new()
    self:InitializeSuper()

    --Set up the ScreenGui.
    self.ResetOnSpawn = false
    self.Enabled = false
    self.CanvasSize = Vector2.new(500,500)
    self.FieldOfView = 0
    self.Easing = 0.25

    --Create the logo and message.
    local Logo = NexusWrappedInstance.new("ImageLabel")
    Logo.BackgroundTransparency = 1
    Logo.Size = UDim2.new(0.4,0,0.4,0)
    Logo.Position = UDim2.new(0.3,0,-0.1,0)
    Logo.Image = "http://www.roblox.com/asset/?id=1499731139"
    Logo.Parent = self

    local UpperText = NexusWrappedInstance.new("TextLabel")
    UpperText.BackgroundTransparency = 1
    UpperText.Size = UDim2.new(0.8,0,0.1,0)
    UpperText.Position = UDim2.new(0.1,0,0.25,0)
    UpperText.Font = Enum.Font.SciFi
    UpperText.Text = "R6 Not Supported"
    UpperText.TextScaled = true
    UpperText.TextColor3 = Color3.new(1,1,1)
    UpperText.TextStrokeColor3 = Color3.new(0,0,0)
    UpperText.TextStrokeTransparency = 0
    UpperText.Parent = self

    local LowerText = NexusWrappedInstance.new("TextLabel")
    LowerText.BackgroundTransparency = 1
    LowerText.Size = UDim2.new(0.8,0,0.25,0)
    LowerText.Position = UDim2.new(0.1,0,0.4,0)
    LowerText.Font = Enum.Font.SciFi
    LowerText.Text = "Nexus VR Character Model does not support using R6. Use R15 instead."
    LowerText.TextScaled = true
    LowerText.TextColor3 = Color3.new(1,1,1)
    LowerText.TextStrokeColor3 = Color3.new(0,0,0)
    LowerText.TextStrokeTransparency = 0
    LowerText.Parent = self

    --Create and connect the close button.
    local CloseButton,CloseText = TextButtonFactory:Create()
    CloseButton.Size = UDim2.new(0.3,0,0.1,0)
    CloseButton.Position = UDim2.new(0.35,0,0.7,0)
    CloseButton.Parent = self
    CloseText.Text = "Ok"

    CloseButton.MouseButton1Click:Connect(function()
        self:SetOpen(false)
        self:Destroy()
    end)

    --Parent the message.
    self.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

--[[
Sets the window open or closed.
--]]
function R6Message:SetOpen(Open)
    --Determine the start and end values.
    local StartFieldOfView,EndFieldOfView = (Open and 0 or math.rad(40)),(Open and math.rad(40) or 0)

    --Show the message if it isn't visible.
    if Open then
        self.Enabled = true
    end

    --Tween the field of view.
    local StartTime = tick()
    while tick() - StartTime < MESSAGE_OPEN_TIME do
        local Delta = (tick() - StartTime)/MESSAGE_OPEN_TIME
        Delta = (math.sin((Delta - 0.5) * math.pi)/2) + 0.5
        self.FieldOfView = StartFieldOfView + ((EndFieldOfView - StartFieldOfView) * Delta)
        RunService.RenderStepped:Wait()
    end

    --Hide thhe message if it is closed.
    if EndFieldOfView == 0 then
        self.Enabled = false
    end
end

--[[
Opens the message.
--]]
function R6Message:Open()
    self:SetOpen(true)
end



return R6Message