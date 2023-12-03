--[[
TheNexusAvenger

Base view for the menu intended to be used with the API.
--]]
--!strict

local GuiService = game:GetService("GuiService")

local NexusVRCharacterModel = script.Parent.Parent.Parent
local NexusInstance = require(NexusVRCharacterModel:WaitForChild("NexusInstance"):WaitForChild("NexusInstance"))
local NexusEvent = require(NexusVRCharacterModel:WaitForChild("NexusInstance"):WaitForChild("Event"):WaitForChild("NexusEvent"))

local ApiBaseView = NexusInstance:Extend()
ApiBaseView:SetClassName("ApiBaseView")

export type ApiBaseView = {
    new: (InitialName: string) -> ApiBaseView,
    Extend: (self: ApiBaseView) -> ApiBaseView,

    Name: string,
    Visible: boolean,
    Destroyed: NexusEvent.NexusEvent<>,
    GetContainer: (self: ApiBaseView) -> (Frame),
    AddBackground: (self: ApiBaseView) -> (),
} & NexusInstance.NexusInstance



--[[
Creates the view.
--]]
function ApiBaseView:__new(InitialName: string): ()
    NexusInstance.__new(self)
    self.Name = InitialName
    self.Destroyed = NexusEvent.new()

    self.Frame = Instance.new("Frame")
    self.Frame.Name = tostring(self.Name)
    self.Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
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
Adds the background of the frame.
--]]
function ApiBaseView:AddBackground(): ()
    --Add the corner.
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0.05, 0)
    UICorner.Parent = self.Frame

    --Enable the transparency.
    self.Frame.BackgroundTransparency = 0.6 * GuiService.PreferredTransparency
    GuiService:GetPropertyChangedSignal("PreferredTransparency"):Connect(function()
        self.Frame.BackgroundTransparency = 0.6 * GuiService.PreferredTransparency
    end)
end

--[[
Destroys the view.
--]]
function ApiBaseView:Destroy(): ()
    ApiBaseView.Destroy(self)
    self.Destroyed:Fire()
    self.Destroyed:Disconnect()
end



return (ApiBaseView :: any) :: ApiBaseView