--[[
TheNexusAvenger

Base view for the menu intended to be used with the API.
--]]

local NexusVRCharacterModel = require(script.Parent.Parent.Parent)
local NexusInstance = NexusVRCharacterModel:GetResource("NexusInstance.NexusInstance")
local NexusEvent = NexusVRCharacterModel:GetResource("NexusInstance.Event.NexusEvent")

local ApiBaseView = NexusInstance:Extend()
ApiBaseView:SetClassName("ApiBaseView")



--[[
Creates the view.
--]]
function ApiBaseView:__new(InitialName: string): nil
    NexusInstance.__new(self)
    self.Name = InitialName
    self.Destroyed = NexusEvent.new()

    self.Frame = Instance.new("Frame")
    self.Frame.Name = tostring(self.Name)
    self.Frame.BackgroundTransparency = 1
    self.Frame.Size = UDim2.new(1, 0, 1, 0)
    self.Frame.Visible = false
    self.Frame.SizeConstraint = Enum.SizeConstraint.RelativeXX
    self:GetPropertyChangedSignal("Name"):Connect(function()
        self.Frame.Name = tostring(self.Name)
    end)
    self:GetPropertyChangedSignal("Visible"):Connect(function()
        self.Frame.Visible = self.Visible
    end)
end

--[[
Returns the containing frame.
--]]
function ApiBaseView:GetContainer(): Frame
    return self.Frame
end

--[[
Destroys the view.
--]]
function ApiBaseView:Destroy(): nil
    ApiBaseView.Destroy(self)
    self.Destroyed:Fire()
    self.Destroyed:Disconnect()
end



return ApiBaseView