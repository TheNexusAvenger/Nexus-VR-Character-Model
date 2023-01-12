 --[[
TheNexusAvenger

Local character controller using teleporting.
--]]

local IGNORE_RIGHT_INPUT_FORWARD_ON_MENU_OPEN = true
local THUMBSTICK_MANUAL_ROTATION_ANGLE = math.rad(45)


local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local NexusVRCharacterModel = require(script.Parent.Parent.Parent)
local BaseController = NexusVRCharacterModel:GetResource("Character.Controller.BaseController")
local ArcWithBeacon = NexusVRCharacterModel:GetResource("Character.Controller.Visual.ArcWithBeacon")
local VRInputService = NexusVRCharacterModel:GetInstance("State.VRInputService")

local TeleportController = BaseController:Extend()
TeleportController:SetClassName("TeleportController")



--[[
Enables the controller.
--]]
function TeleportController:Enable(): nil
    BaseController.Enable(self)

    --Create the arcs.
    self.LeftArc = ArcWithBeacon.new()
    self.RightArc = ArcWithBeacon.new()
    self.ArcControls = {
        {
            Thumbstick = Enum.KeyCode.Thumbstick1,
            UserCFrame = Enum.UserCFrame.LeftHand,
            Arc = self.LeftArc,
        },
        {
            Thumbstick = Enum.KeyCode.Thumbstick2,
            UserCFrame = Enum.UserCFrame.RightHand,
            Arc = self.RightArc,
        },
    }

    --Connect requesting jumping.
    --ButtonA does not work with IsButtonDown.
    self.ButtonADown = false
    table.insert(self.Connections,UserInputService.InputBegan:Connect(function(Input, Processsed)
        if Processsed then return end
        if Input.KeyCode == Enum.KeyCode.ButtonA then
            self.ButtonADown = true
        end
    end))
    table.insert(self.Connections,UserInputService.InputEnded:Connect(function(Input)
        if Input.KeyCode == Enum.KeyCode.ButtonA then
            self.ButtonADown = false
        end
    end))
end

--[[
Disables the controller.
--]]
function TeleportController:Disable(): nil
    BaseController.Disable(self)

    --Destroy the arcs.
    self.LeftArc:Destroy()
    self.RightArc:Destroy()
end

--[[
Updates the local character. Must also update the camara.
--]]
function TeleportController:UpdateCharacter()
    --Update the base character.
    BaseController.UpdateCharacter(self)
    if not self.Character then
        return
    end

    --Get the VR inputs.
    local VRInputs = VRInputService:GetVRInputs()
    for _, InputEnum in pairs(Enum.UserCFrame:GetEnumItems()) do
        VRInputs[InputEnum] = self:ScaleInput(VRInputs[InputEnum])
    end

    --Update the arcs.
    local SeatPart = self.Character:GetHumanoidSeatPart()
    for _, ArcData in pairs(self.ArcControls) do
        --Reset the left arc if the player is in a vehicle seat.
        if ArcData.Thumbstick == Enum.KeyCode.Thumbstick1 and SeatPart and SeatPart:IsA("VehicleSeat") then
            ArcData.Arc:Hide()
            continue
        end

        --Update and fetch the current state.
        local InputActive = (not NexusVRCharacterModel.Api.Controller or NexusVRCharacterModel.Api.Controller:IsControllerInputEnabled(ArcData.UserCFrame))
        local DirectionState, RadiusState, StateChange = self:GetJoystickState(ArcData)
        if not InputActive then
            ArcData.Arc:Hide()
            ArcData.WaitForRelease = false
            ArcData.RadiusState = nil
            continue
        end

        --Cancel the input if it is forward facing, on the right hand, and the menu is visible.
        --This is an optimization for the Valve Index that has pressing the right thumbstick forward for opening the menu.
        --PositionLocked only appears when a user is pointing at the main user interface. This will not work if the player toggles
        --the Roblox UI but doesn't point at it. Ideally, there should be a way to know that this input opens the Roblox UI.
        if IGNORE_RIGHT_INPUT_FORWARD_ON_MENU_OPEN and not ArcData.WaitForRelease and DirectionState == "Forward" and ArcData.Thumbstick == Enum.KeyCode.Thumbstick2 then
            local VRCorePanelParts = Workspace.CurrentCamera:FindFirstChild("VRCorePanelParts")
            if VRCorePanelParts then
                local PositionLocked = VRCorePanelParts:FindFirstChild("PositionLocked")
                if PositionLocked and PositionLocked.Position.Magnitude > 0.001 then
                    ArcData.WaitForRelease = true
                end
            end
        end
        if ArcData.WaitForRelease then
            if RadiusState == "Released" then
                ArcData.WaitForRelease = false
            else
                StateChange = "Cancel"
                ArcData.RadiusState = nil
            end
        end

        --Update from the state.
        local HumanoidRootPart = self.Character.Parts.HumanoidRootPart
        if DirectionState ~= "Forward" or RadiusState == "Released" then
            ArcData.Arc:Hide()
        end
        if StateChange == "Extended" then
            if not self.Character.Humanoid.Sit then
                if DirectionState == "Left" then
                    --Turn the player to the left.
                    self:PlayBlur()
                    HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position) * CFrame.Angles(0, THUMBSTICK_MANUAL_ROTATION_ANGLE, 0) * (CFrame.new(-HumanoidRootPart.Position) * HumanoidRootPart.CFrame)
                elseif DirectionState == "Right" then
                    --Turn the player to the right.
                    self:PlayBlur()
                    HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position) * CFrame.Angles(0, -THUMBSTICK_MANUAL_ROTATION_ANGLE, 0) * (CFrame.new(-HumanoidRootPart.Position) * HumanoidRootPart.CFrame)
                end
            end
        elseif StateChange == "Released" then
            ArcData.Arc:Hide()
            if DirectionState == "Forward" then
                --Teleport the player.
                if ArcData.LastHitPart and ArcData.LastHitPosition then
                    --Unsit the player.
                    --The teleport event is set to ignored since the CFrame will be different when the player gets out of the seat.
                    local WasSitting = false
                    self:PlayBlur()

                    if SeatPart then
                        WasSitting = true
                        self.IgnoreNextExternalTeleport = true
                        self.Character.Humanoid.Sit = false
                    end

                    if (ArcData.LastHitPart:IsA("Seat") or ArcData.LastHitPart:IsA("VehicleSeat")) and not ArcData.LastHitPart.Occupant and not ArcData.LastHitPart.Disabled then
                        --Sit in the seat.
                        --Waiting is done if the player was in an existing seat because the player no longer sitting will prevent sitting.
                        if WasSitting then
                            task.spawn(function()
                                while self.Character.Humanoid.SeatPart do task.wait() end
                                ArcData.LastHitPart:Sit(self.Character.Humanoid)
                            end)
                        else
                            ArcData.LastHitPart:Sit(self.Character.Humanoid)
                        end
                    else
                        --Teleport the player.
                        --Waiting is done if the player was in an existing seat because the player will teleport the seat.
                        if WasSitting then
                            task.spawn(function()
                                while self.Character.Humanoid.SeatPart do task.wait() end
                                HumanoidRootPart.CFrame = CFrame.new(ArcData.LastHitPosition) * CFrame.new(0, 4.5 * self.Character.ScaleValues.BodyHeightScale.Value, 0) * (CFrame.new(-HumanoidRootPart.Position) * HumanoidRootPart.CFrame)
                            end)
                        else
                            HumanoidRootPart.CFrame = CFrame.new(ArcData.LastHitPosition) * CFrame.new(0, 4.5 * self.Character.ScaleValues.BodyHeightScale.Value, 0) * (CFrame.new(-HumanoidRootPart.Position) * HumanoidRootPart.CFrame)
                        end
                    end
                end
            end
        elseif StateChange == "Cancel" then
            ArcData.Arc:Hide()
        elseif DirectionState == "Forward" and RadiusState == "Extended" then
            ArcData.LastHitPart, ArcData.LastHitPosition = ArcData.Arc:Update(Workspace.CurrentCamera:GetRenderCFrame() * VRInputs[Enum.UserCFrame.Head]:Inverse() * VRInputs[ArcData.UserCFrame])
        end
    end

    --Update the vehicle seat.
    self:UpdateVehicleSeat()

    --Jump the player.
    if (not UserInputService:GetFocusedTextBox() and UserInputService:IsKeyDown(Enum.KeyCode.Space)) or self.ButtonADown then
        self.Character.Humanoid.Jump = true
    end
end



return TeleportController