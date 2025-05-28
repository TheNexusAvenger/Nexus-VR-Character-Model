--View for the Enigma library.
--!strict

local SUPPORTED_PROTOCOL_VERSIONS = {
    ["1"] = true,
    ["2"] = true,
}

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VRService = game:GetService("VRService")

local NexusVRCharacterModel = script.Parent.Parent.Parent
local Enigma = require(NexusVRCharacterModel:WaitForChild("Packages"):WaitForChild("Enigma"))
local NexusButton = require(NexusVRCharacterModel:WaitForChild("Packages"):WaitForChild("NexusButton"))
local CharacterService = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("CharacterService")).GetInstance()
local EnigmaService = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("EnigmaService")).GetInstance()
local Settings = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("Settings")).GetInstance()
local BaseApiView = require(NexusVRCharacterModel:WaitForChild("UI"):WaitForChild("View"):WaitForChild("ApiBaseView"))

local TextButtonFactory = NexusButton.TextButtonFactory.CreateDefault(Color3.fromRGB(0, 170, 255))
TextButtonFactory:SetDefault("Theme", "RoundedCorners")

local EnigmaView = {}
EnigmaView.__index = EnigmaView

export type EnigmaView = {
    EnigmaText: TextLabel,
    ShowTrackersButton: NexusButton.NexusInstanceNexusButton?,
    DebugTrackersVisible: boolean?,
    CalibrateButton: NexusButton.NexusInstanceNexusButton?,
} & typeof(setmetatable({}, EnigmaView))



--[[
Returns text with rich text color.
--]]
local function AddColor(Text: string, R: number, G: number, B: number): string
    return `<font color="rgb({R},{G},{B})">{Text}</font>`
end

--[[
Creates the Enigma view.
--]]
function EnigmaView.new(View: BaseApiView.NexusInstanceApiBaseView, Menu: any): EnigmaView
    View:AddBackground()

    --Create the view.
    local Container = View:GetContainer()
    local EnigmaText = Instance.new("TextLabel")
    EnigmaText.BackgroundTransparency = 1
    EnigmaText.Size = UDim2.new(0.9, 0, 0.6, 0)
    EnigmaText.Position = UDim2.new(0.05, 0, 0.075, 0)
    EnigmaText.Font = Enum.Font.SourceSansBold
    EnigmaText.Text = ""
    EnigmaText.RichText = true
    EnigmaText.TextWrapped = true
    EnigmaText.TextColor3 = Color3.fromRGB(255, 255, 255)
    EnigmaText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    EnigmaText.TextStrokeTransparency = 0
    EnigmaText.TextSize = 28
    EnigmaText.TextYAlignment = Enum.TextYAlignment.Top
    EnigmaText.Parent = Container

    --Create the object.
    local self = setmetatable({
        EnigmaText = EnigmaText,
    }, EnigmaView) :: EnigmaView

    --Return the object early if Enigma is not enabled.
    if Settings:GetSetting("Extra.EnigmaEnabled") == false then
        EnigmaText.Text = "This game has disabled Enigma."
        return self
    end

    local ShowTrackersButton, ShowTrackersText = TextButtonFactory:Create()
    ShowTrackersButton.Size = UDim2.new(0.5, 0, 0.075, 0)
    ShowTrackersButton.Position = UDim2.new(0.25, 0, 0.775, 0)
    ShowTrackersButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
    ShowTrackersButton.Parent = Container
    ShowTrackersText.Text = " Show Trackers "
    self.ShowTrackersButton = ShowTrackersButton

    self.DebugTrackersVisible = false
    local DB = true
    ShowTrackersButton.MouseButton1Down:Connect(function()
        if not DB then return end
        DB = false
        self.DebugTrackersVisible = not self.DebugTrackersVisible
        if self.DebugTrackersVisible then
            task.spawn(function()
                self:ShowDebugTrackers()
            end)
        end
        ShowTrackersText.Text = (self.DebugTrackersVisible and " Hide Trackers" or " Show Trackers ")
        task.wait()
        DB = true
    end)

    local CalibrateButton, CalibrateText = TextButtonFactory:Create()
    CalibrateButton.Size = UDim2.new(0.5, 0, 0.075, 0)
    CalibrateButton.Position = UDim2.new(0.25, 0, 0.875, 0)
    CalibrateButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
    CalibrateButton.Parent = Container
    CalibrateText.Text = " Calibrate Trackers "
    self.CalibrateButton = CalibrateButton

    CalibrateButton.MouseButton1Down:Connect(function()
        if not DB then return end
        DB = false
        local Character = CharacterService:GetCharacter(Players.LocalPlayer)
        if Character then
            EnigmaService:Calibrate(Character)
        end
        task.wait()
        DB = true
    end)

    --Update the text in the background.
    self:UpdateText()
    task.spawn(function()
        while true do
            self:UpdateText()
            task.wait(0.1)
        end
    end)

    --Present the view if an uncalibratedd input becomes visible.
    task.spawn(function()
        local UncalibratedInputsPrompted = {
            LeftFoot = false,
            RightFoot = false,
        }
        while true do
            --Determine if there are unprompted inputs.
            local AllInputsCalibrated = true
            local InputsToPrompt = {}
            for InputName, Prompted in UncalibratedInputsPrompted do
                if Prompted then continue end
                if not Prompted then
                    AllInputsCalibrated = false
                end
                if not Enigma.Enabled or not Enigma:GetUserCFrameEnabled(InputName :: any) then continue end
                if EnigmaService.Offsets[InputName] then continue end
                table.insert(InputsToPrompt, InputName)
            end
            for _, InputName in InputsToPrompt do
                UncalibratedInputsPrompted[InputName] = true
            end

            --Show the view.
            if #InputsToPrompt > 0 then
                Menu:UpdateVisibleView(View.Name)
                Menu:Toggle(true)
                self:UpdateText()
            end

            --Break the loop if all inputs are prompted.
            if AllInputsCalibrated then break end
            task.wait()
        end
    end)

    --Return the object.
    return self
end

--[[
Updates the Enigma text.
--]]
function EnigmaView.UpdateText(self: EnigmaView): ()
    --Add the tracker information.
    local Text = ""
    local HasLeftFoot, HasRightFoot = Enigma.Enabled and Enigma:GetUserCFrameEnabled("LeftFoot"), Enigma.Enabled and Enigma:GetUserCFrameEnabled("RightFoot")
    if HasLeftFoot then
        if EnigmaService.Offsets.LeftFoot then
            Text = `{Text}Left Foot Tracker: {AddColor("Active", 0, 200, 0)}`
        else
            Text = `{Text}Left Foot Tracker: {AddColor("Requires Calibration", 200, 150, 0)}`
        end
    else
        Text = `{Text}Left Foot Tracker: {AddColor("Inactive", 200, 0, 0)}`
    end
    if HasRightFoot then
        if EnigmaService.Offsets.RightFoot then
            Text = `{Text}\nRight Foot Tracker: {AddColor("Active", 0, 200, 0)}`
        else
            Text = `{Text}\nRight Foot Tracker: {AddColor("Requires Calibration", 200, 150, 0)}`
        end
    else
        Text = `{Text}\nRight Foot Tracker: {AddColor("Inactive", 200, 0, 0)}`
    end

    --Add the data transfer status.
    if Enigma:IsActive() then
        local FocusedTextBox = UserInputService:GetFocusedTextBox()
        if not FocusedTextBox or (FocusedTextBox.Parent and FocusedTextBox.Parent.Name == "EnigmaTextBoxInput") then
            Text = `{Text}\nData transfer: {AddColor("Active", 0, 200, 0)}`
            if Enigma.Input then
                local EnigmaVersion = string.split(Enigma.Input:GetCurrentText(), "|")[1]
                if SUPPORTED_PROTOCOL_VERSIONS[EnigmaVersion] then
                    Text = `{Text}\n\nProtocol version: {EnigmaVersion}`
                else
                    Text = `{Text}\n\nProtocol version: {AddColor(`{EnigmaVersion} (Unsupported)`, 200, 150, 0)}`
                end
            end
        else
            Text = `{Text}\nData transfer: {AddColor("Inactive", 200, 0, 0)}`
        end
        if not HasLeftFoot and not HasRightFoot and Enigma:GetUserCFrameEnabled("None") then
            Text = `{Text}\n\n⚠️ Trackers are detected, but the role in SteamVR is "None". They need to have assigned roles through the SteamVR menu.`
        else
            Text = `{Text}\n\nTo calibrate, stand up straight with your head level and facing forward with your feet next to each other pointing forward.`
        end
        if self.ShowTrackersButton then
            self.ShowTrackersButton.Visible = true
        end
        if self.CalibrateButton then
            self.CalibrateButton.Visible = true
        end
    else
        Text = `{Text}\nData transfer: {AddColor("Inactive", 200, 150, 0)}`
        Text = `{Text}\n\n⚠️ Enigma requires a desktop application. There may be experience-specific issues when Enigma is active.`
        if self.ShowTrackersButton then
            self.ShowTrackersButton.Visible = false
        end
        if self.CalibrateButton then
            self.CalibrateButton.Visible = false
        end
    end

    --Set the text.
    self.EnigmaText.Text = Text
end

--[[
Shows debug trackers.
--]]
function EnigmaView.ShowDebugTrackers(self: EnigmaView): ()
    if not Enigma.Enabled then return end
    local TrackerParts, TrackerLabels = {}, {}
    local TrackersPartsFolder = Instance.new("Folder")
    TrackersPartsFolder.Name = "NexusVRCharacterModelEnigmaDebugTrackers"
    TrackersPartsFolder.Parent = Workspace.CurrentCamera

    while self.DebugTrackersVisible do
        --Get the visible trackers.
        local ActiveInputs = {}
        local TotalInputs = 0
        local OriginWorldCFrame = Workspace.CurrentCamera:GetRenderCFrame() * VRService:GetUserCFrame(Enum.UserCFrame.Head):Inverse()
        for _, UserCFrameName: Enigma.TrackerRole in Enigma.TrackerRoles do
            local TrackerIndex = 1
            while Enigma:GetUserCFrameEnabled(UserCFrameName, TrackerIndex) do
                local DisplayUserCFrame = (TrackerIndex == 1 and UserCFrameName or `{UserCFrameName} ({TrackerIndex})`)
                ActiveInputs[DisplayUserCFrame] = OriginWorldCFrame * Enigma:GetUserCFrame(UserCFrameName, TrackerIndex)
                TotalInputs += 1
                TrackerIndex += 1
            end
        end

        --Update the debug trackers.
        local CurrentInput = 1
        for InputName, InputCFrame in ActiveInputs do
            if not TrackerParts[CurrentInput] then
                local TrackerPart = Instance.new("Part")
                TrackerPart.BrickColor = BrickColor.new("Institutional white")
                TrackerPart.Material = Enum.Material.Neon
                TrackerPart.Anchored = true
                TrackerPart.CanCollide = false
                TrackerPart.CanTouch = false
                TrackerPart.CanQuery = false
                TrackerPart.Shape = Enum.PartType.Ball
                TrackerPart.Size = Vector3.new(0.2, 0.2, 0.2)
                TrackerPart.Parent = TrackersPartsFolder
                TrackerParts[CurrentInput] = TrackerPart

                local SphereHandleAdornment = Instance.new("SphereHandleAdornment")
                SphereHandleAdornment.Transparency = 0.5
                SphereHandleAdornment.AlwaysOnTop = true
                SphereHandleAdornment.Color3 = Color3.fromRGB(255, 255, 255)
                SphereHandleAdornment.ZIndex = 1
                SphereHandleAdornment.Radius = 0.1
                SphereHandleAdornment.Adornee = TrackerPart
                SphereHandleAdornment.Parent = TrackerPart

                local BillboardGui = Instance.new("BillboardGui")
                BillboardGui.AlwaysOnTop = true
                BillboardGui.Adornee = TrackerPart
                BillboardGui.Size = UDim2.new(2, 0, 0.4, 0)
                BillboardGui.StudsOffset = Vector3.new(0, 0.3 ,0)
                BillboardGui.Parent = TrackerPart

                local TrackerRoleText = Instance.new("TextLabel")
                TrackerRoleText.BackgroundTransparency = 1
                TrackerRoleText.Size = UDim2.new(1, 0, 1, 0)
                TrackerRoleText.TextScaled = true
                TrackerRoleText.TextColor3 = Color3.fromRGB(255, 255, 255)
                TrackerRoleText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                TrackerRoleText.TextStrokeTransparency = 0
                TrackerRoleText.Parent = BillboardGui
                TrackerLabels[CurrentInput] = TrackerRoleText
            end
            TrackerParts[CurrentInput].CFrame = InputCFrame
            TrackerLabels[CurrentInput].Text = InputName
            CurrentInput += 1
        end

        --Remove extra trackers.
        for i = #TrackerParts, TotalInputs + 1, -1 do
            TrackerParts[i]:Destroy()
            TrackerParts[i] = nil
            TrackerLabels[i]:Destroy()
            TrackerLabels[i] = nil
        end

        --Wait to refresh.
        RunService.RenderStepped:Wait()
    end

    --Clear the instances.
    TrackersPartsFolder:Destroy()
end



return EnigmaView