--[[
TheNexusAvenger

Base class for a view.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NexusVRCore = require(ReplicatedStorage:WaitForChild("NexusVRCore"))
local NexusWrappedInstance = NexusVRCore:GetResource("NexusWrappedInstance")

local BaseView = NexusWrappedInstance:Extend()
BaseView:SetClassName("BaseView")



--[[
Creates the base view.
--]]
function BaseView:__new()
    self:InitializeSuper("Frame")
    self.BackgroundTransparency = 1
    self.Size = UDim2.new(1,0,1,0)
    self.SizeConstraint = Enum.SizeConstraint.RelativeXX
end



return BaseView