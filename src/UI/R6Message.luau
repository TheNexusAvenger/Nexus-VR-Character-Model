--Displays a message if R6 is used.
--!strict

local MESSAGE_OPEN_TIME = 0.25

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local NexusVRCharacterModel = script.Parent.Parent
local NexusButton = require(NexusVRCharacterModel:WaitForChild("Packages"):WaitForChild("NexusButton"))
local NexusVRCore = require(NexusVRCharacterModel:WaitForChild("Packages"):WaitForChild("NexusVRCore"))

local TextButtonFactory = NexusButton.TextButtonFactory.CreateDefault(Color3.fromRGB(0, 170, 255))
TextButtonFactory:SetDefault("Theme", "RoundedCorners")
local ScreenGui3D = NexusVRCore.ScreenGui3D

local R6Message = {}
R6Message.__index = R6Message

export type R6Message = {
    ScreenGui: any,
} & typeof(setmetatable({}, R6Message))



--[[
Creates the R6 message.
--]]
function R6Message.new(): R6Message
    --Set up the ScreenGui.
    local MessageScreenGui = ScreenGui3D.new()
    MessageScreenGui.ResetOnSpawn = false
    MessageScreenGui.Enabled = false
    MessageScreenGui.CanvasSize = Vector2.new(500, 500)
    MessageScreenGui.FieldOfView = 0
    MessageScreenGui.Easing = 0.25

    --Create the object.
    local self = setmetatable({
        ScreenGui = MessageScreenGui,
    }, R6Message) :: R6Message

    --Create the logo and message.
    local Logo = Instance.new("ImageLabel")
    Logo.BackgroundTransparency = 1
    Logo.Size = UDim2.new(0.4, 0, 0.4, 0)
    Logo.Position = UDim2.new(0.3, 0, -0.1, 0)
    Logo.Image = "http://www.roblox.com/asset/?id=1499731139"
    Logo.Parent = MessageScreenGui:GetContainer()

    local UpperText = Instance.new("TextLabel")
    UpperText.BackgroundTransparency = 1
    UpperText.Size = UDim2.new(0.8, 0, 0.1, 0)
    UpperText.Position = UDim2.new(0.1, 0, 0.25, 0)
    UpperText.Font = Enum.Font.SourceSansBold
    UpperText.Text = "R6 Not Supported"
    UpperText.TextScaled = true
    UpperText.TextColor3 = Color3.fromRGB(255, 255, 255)
    UpperText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    UpperText.TextStrokeTransparency = 0
    UpperText.Parent = MessageScreenGui:GetContainer()

    local LowerText = Instance.new("TextLabel")
    LowerText.BackgroundTransparency = 1
    LowerText.Size = UDim2.new(0.8, 0, 0.25, 0)
    LowerText.Position = UDim2.new(0.1, 0, 0.4, 0)
    LowerText.Font = Enum.Font.SourceSansBold
    LowerText.Text = "Nexus VR Character Model does not support using R6. Use R15 instead."
    LowerText.TextScaled = true
    LowerText.TextColor3 = Color3.fromRGB(255, 255, 255)
    LowerText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    LowerText.TextStrokeTransparency = 0
    LowerText.Parent = MessageScreenGui:GetContainer()

    --Create and connect the close button.
    local CloseButton, CloseText = TextButtonFactory:Create()
    CloseButton.Size = UDim2.new(0.3, 0, 0.1, 0)
    CloseButton.Position = UDim2.new(0.35, 0, 0.7, 0)
    CloseButton.Parent = MessageScreenGui:GetContainer()
    CloseText.Text = "Ok"

    CloseButton.MouseButton1Down:Connect(function()
        self:SetOpen(false)
        MessageScreenGui:Destroy()
    end)

    --Parent the message.
    MessageScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    return self
end

--[[
Sets the window open or closed.
--]]
function R6Message.SetOpen(self: R6Message, Open: boolean): ()
    --Determine the start and end values.
    local StartFieldOfView, EndFieldOfView = (Open and 0 or math.rad(40)), (Open and math.rad(40) or 0)

    --Show the message if it isn't visible.
    if Open then
        self.ScreenGui.Enabled = true
    end

    --Tween the field of view.
    local StartTime = tick()
    while tick() - StartTime < MESSAGE_OPEN_TIME do
        local Delta = (tick() - StartTime) / MESSAGE_OPEN_TIME
        Delta = (math.sin((Delta - 0.5) * math.pi) / 2) + 0.5
        self.ScreenGui.FieldOfView = StartFieldOfView + ((EndFieldOfView - StartFieldOfView) * Delta)
        RunService.RenderStepped:Wait()
    end

    --Hide thhe message if it is closed.
    if EndFieldOfView == 0 then
        self.ScreenGui.Enabled = false
    end
end

--[[
Opens the message.
--]]
function R6Message.Open(self: R6Message): ()
    self:SetOpen(true)
end



return R6Message