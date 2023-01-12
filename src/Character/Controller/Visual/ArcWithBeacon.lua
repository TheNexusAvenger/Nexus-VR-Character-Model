--[[
TheNexusAvenger

Extension of the arc to add a beacon.
--]]

local NexusVRCharacterModel = require(script.Parent.Parent.Parent.Parent)
local Arc = NexusVRCharacterModel:GetResource("Character.Controller.Visual.Arc")
local Beacon = NexusVRCharacterModel:GetResource("Character.Controller.Visual.Beacon")

local ArcWithBeacon = Arc:Extend()
ArcWithBeacon:SetClassName("ArcWithBeacon")



--[[
Creates an arc.
--]]
function ArcWithBeacon:__new(): nil
    Arc.__new(self)
    self.BeamParts = {}
    self.Beacon = Beacon.new()
    self:Hide()
end

--[[
Updates the arc. Returns the part and
position that were hit.
--]]
function ArcWithBeacon:Update(StartCFrame: CFrame): nil
    --Update the arc.
    local HitPart, HitPosition = Arc:Update(self, StartCFrame)

    --Update the beacon.
    if HitPart then
        self.Beacon:Update(CFrame.new(HitPosition) * CFrame.new(0, 0.001, 0), HitPart)
    else
        self.Beacon:Hide()
    end

    --Return the arc's returns.
    return HitPart, HitPosition
end

--[[
Hides the arc.
--]]
function ArcWithBeacon:Hide(): nil
    Arc:Hide(self)
    self.Beacon:Hide()
end

--[[
Destroys the arc.
--]]
function ArcWithBeacon:Destroy(): nil
    Arc:Destroy(self)
    self.Beacon:Destroy()
end



return ArcWithBeacon