--[[
TheNexusAvenger

Manages toggling the default cursor.
Workaround for: https://github.com/TheNexusAvenger/Nexus-VR-Character-Model/issues/10
--]]
--!strict

local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local DefaultCursorService = {}
DefaultCursorService.__index = DefaultCursorService

export type DefaultCursorService = {
    new: () -> (DefaultCursorService),

    SetCursorState: (self: DefaultCursorService, OptionName: string) -> (),
}



--[[
Creates a default cursor service.
--]]
function DefaultCursorService.new(): DefaultCursorService
    --Create the object.
    local self = {}
    setmetatable(self, DefaultCursorService)

    --Register the default values.
    self.CursorOptionsList = {"Detect", "Enabled", "Disabled"}
    self.CursorOptions = {
        Detect = function()
            --Enable the pointer.
            StarterGui:SetCore("VRLaserPointerMode", "Pointer")

            --Wait until the next frame to register the BindToRenderStep. Otherwise, the order is
            RunService.Stepped:Wait()

            --Enable the workaround for moving the pointer when the cursor isn't active.
            --It must be Last + 1 because the Core Script uses Last.
            RunService:BindToRenderStep("NexusVRCharacterModel_MoveCursorWorkaround", Enum.RenderPriority.Last.Value + 1, function()
                local Camera = Workspace.CurrentCamera
                local VRCoreEffectParts = Camera:FindFirstChild("VRCoreEffectParts")
                if VRCoreEffectParts then
                    local LaserPointerOrigin = VRCoreEffectParts:FindFirstChild("LaserPointerOrigin")
                    local Cursor = VRCoreEffectParts:FindFirstChild("Cursor")
                    if LaserPointerOrigin and Cursor then
                        local CursorSurfaceGui = Cursor:FindFirstChild("CursorSurfaceGui")
                        if CursorSurfaceGui and not CursorSurfaceGui.Enabled then
                            LaserPointerOrigin.CFrame = CFrame.new(0, math.huge, 0)
                        end
                    end
                end
            end)
        end,
        Enabled = function()
            StarterGui:SetCore("VRLaserPointerMode", "Pointer")
        end,
        Disabled = function()
            StarterGui:SetCore("VRLaserPointerMode", "Disabled")
        end,
    }
    self.CursorDisabledOptions = {
        Detect = function()
            RunService:UnbindFromRenderStep("NexusVRCharacterModel_MoveCursorWorkaround")
        end,
    }

    --Return the object.
    return (self :: any) :: DefaultCursorService
end

--[[
Sets the cursor state.
--]]
function DefaultCursorService:SetCursorState(OptionName: string): ()
    if self.CurrentCursorState == OptionName then return end
    if self.CurrentCursorState and self.CursorDisabledOptions[self.CurrentCursorState] then
        self.CursorDisabledOptions[self.CurrentCursorState]()
    end
    self.CurrentCursorState = OptionName
    task.spawn(self.CursorOptions[OptionName])
end



return DefaultCursorService