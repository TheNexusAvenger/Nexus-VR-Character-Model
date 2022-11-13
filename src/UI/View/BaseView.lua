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
function BaseView:__new(): nil
    self:InitializeSuper("Frame")
    self.BackgroundTransparency = 1
    self.Size = UDim2.new(1, 0, 1, 0)
    self.SizeConstraint = Enum.SizeConstraint.RelativeXX
    warn("BaseView is deprecated and will be removed on April 15th, 2023.\n\tMore information: https://github.com/TheNexusAvenger/Nexus-VR-Core/blob/master/docs/custom-pointing-deprecation.md")
end



return BaseView