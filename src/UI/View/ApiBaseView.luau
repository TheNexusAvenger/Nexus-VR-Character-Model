--Base view for the menu intended to be used with the API.
--!strict

local GuiService = game:GetService("GuiService")

local NexusVRCharacterModel = script.Parent.Parent.Parent
local NexusInstance = require(NexusVRCharacterModel:WaitForChild("Packages"):WaitForChild("NexusInstance"))

local ApiBaseView = {}
ApiBaseView.__index = ApiBaseView

export type ApiBaseView = {
    Name: string,
    Visible: boolean,
    Destroyed: NexusInstance.TypedEvent<>,
    Frame: Frame,
} & typeof(setmetatable({}, ApiBaseView))
export type NexusInstanceApiBaseView = NexusInstance.NexusInstance<ApiBaseView>



--[[
Creates the view.
--]]
function ApiBaseView.__new(self: NexusInstanceApiBaseView, InitialName: string): ()
    self.Name = InitialName
    self.Destroyed = self:CreateEvent()

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
function ApiBaseView.GetContainer(self: NexusInstanceApiBaseView): Frame
    return self.Frame
end

--[[
Adds the background of the frame.
--]]
function ApiBaseView.AddBackground(self: NexusInstanceApiBaseView): ()
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
function ApiBaseView.Destroy(self: NexusInstanceApiBaseView): ()
    self.Destroyed:Fire()
    self.Frame:Destroy()
end



return NexusInstance.ToInstance(ApiBaseView) :: NexusInstance.NexusInstanceClass<typeof(ApiBaseView), (InitialName: string) -> (NexusInstanceApiBaseView)>