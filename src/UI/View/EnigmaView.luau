--View for the Enigma library.
--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local NexusVRCharacterModel = script.Parent.Parent.Parent
local Enigma = require(NexusVRCharacterModel:WaitForChild("Enigma"))
local NexusInstance = require(NexusVRCharacterModel:WaitForChild("NexusInstance"):WaitForChild("NexusInstance"))
local CharacterService = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("CharacterService")).GetInstance()
local EnigmaService = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("EnigmaService")).GetInstance()
local Settings = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("Settings")).GetInstance()

local TextButtonFactory = require(NexusVRCharacterModel:WaitForChild("NexusButton"):WaitForChild("Factory"):WaitForChild("TextButtonFactory")).CreateDefault(Color3.fromRGB(0, 170, 255))
TextButtonFactory:SetDefault("Theme", "RoundedCorners")

local EnigmaView = NexusInstance:Extend()
EnigmaView:SetClassName("EnigmaView")



--[[
Creates the Enigma view.
--]]
function EnigmaView:__new(View: any, Menu: any): ()
    NexusInstance.__new(self)
    View:AddBackground()

    --Create the calibrate view.
    local Container = View:GetContainer()
    local EnigmaText = Instance.new("TextLabel")
    EnigmaText.BackgroundTransparency = 1
    EnigmaText.Size = UDim2.new(0.8, 0, 0.5, 0)
    EnigmaText.Position = UDim2.new(0.1, 0, 0.1, 0)
    EnigmaText.Font = Enum.Font.SourceSansBold
    EnigmaText.Text = ""
    EnigmaText.TextScaled = true
    EnigmaText.TextColor3 = Color3.fromRGB(255, 255, 255)
    EnigmaText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    EnigmaText.TextStrokeTransparency = 0
    EnigmaText.Parent = Container
    self.EnigmaText = EnigmaText
    if Settings:GetSetting("Extra.EnigmaEnabled") == false then
        EnigmaText.Text = "This game has disabled Enigma (Beta)."
        return
    end
    self:UpdateText()

    task.spawn(function()
        while true do
            self:UpdateText()
            task.wait(0.1)
        end
    end)

    local CalibrateButton, CalibrateText = TextButtonFactory:Create()
    CalibrateButton.Size = UDim2.new(0.4, 0, 0.075, 0)
    CalibrateButton.Position = UDim2.new(0.3, 0, 0.875, 0)
    CalibrateButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
    CalibrateButton.Parent = Container
    CalibrateText.Text = " Calibrate Trackers "

    CalibrateButton.MouseButton1Down:Connect(function()
        local Character = CharacterService:GetCharacter(Players.LocalPlayer)
        if not Character then return end
        EnigmaService:Calibrate(Character)
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
end

--[[
Updates the Enigma text.
--]]
function EnigmaView:UpdateText(): ()
    local Text = "⚠️ Enigma is in a beta, and requires a desktop application. There may be issues.\n"

    --Add the tracker information.
    if Enigma.Enabled and Enigma:GetUserCFrameEnabled("LeftFoot") then
        if EnigmaService.Offsets.LeftFoot then
            Text = `{Text}\nLeft Foot Tracker: Active`
        else
            Text = `{Text}\nLeft Foot Tracker: Requires Calibration`
        end
    else
        Text = `{Text}\nLeft Foot Tracker: Inactive`
    end
    if Enigma.Enabled and Enigma:GetUserCFrameEnabled("RightFoot") then
        if EnigmaService.Offsets.RightFoot then
            Text = `{Text}\nRight Foot Tracker: Active`
        else
            Text = `{Text}\nRight Foot Tracker: Requires Calibration`
        end
    else
        Text = `{Text}\nRight Foot Tracker: Inactive`
    end

    --Add the data transfer status.
    local FocusedTextBox = UserInputService:GetFocusedTextBox()
    if FocusedTextBox then
        if FocusedTextBox.Parent and FocusedTextBox.Parent.Name == "EnigmaTextBoxInput" then
            Text = `{Text}\nData transfer: Active`
        else
            Text = `{Text}\nData transfer: Invalid`
        end
    else
        Text = `{Text}\nData transfer: Inactive`
    end

    --Set the text.
    Text = `{Text}\n\nTo calibrate, stand up straight with your head level and facing forward with your feet next to each other pointing forward.`
    self.EnigmaText.Text = Text
end



return EnigmaView