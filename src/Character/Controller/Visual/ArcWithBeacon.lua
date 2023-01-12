--[[
TheNexusAvenger

Extension of the arc to add a beacon.
--]]
--!strict

local Arc = require(script.Parent:WaitForChild("Arc"))
local Beacon = require(script.Parent:WaitForChild("Beacon"))

local ArcWithBeacon = {}
ArcWithBeacon.__index = ArcWithBeacon
setmetatable(ArcWithBeacon, Arc)

export type ArcWithBeacon = {
    new: () -> (ArcWithBeacon),
} & Arc.Arc



--[[
Creates an arc.
--]]
function ArcWithBeacon.new(): ArcWithBeacon
    local self = Arc.new() :: any
    setmetatable(self, ArcWithBeacon)
    self.Beacon = Beacon.new()
    self:Hide()
    return self :: ArcWithBeacon
end

--[[
Updates the arc. Returns the part and
position that were hit.
--]]
function ArcWithBeacon:Update(StartCFrame: CFrame): (BasePart?, Vector3?)
    --Update the arc.
    local HitPart, HitPosition = Arc.Update(self, StartCFrame)

    --Update the beacon.
    local Beacon = (self :: any).Beacon :: Beacon.Beacon
    if HitPart then
        Beacon:Update(CFrame.new(HitPosition :: Vector3) * CFrame.new(0, 0.001, 0), HitPart)
    else
        Beacon:Hide()
    end

    --Return the arc's returns.
    return HitPart, HitPosition
end

--[[
Hides the arc.
--]]
function ArcWithBeacon:Hide(): ()
    Arc.Hide(self);
    (self :: any).Beacon:Hide()
end

--[[
Destroys the arc.
--]]
function ArcWithBeacon:Destroy(): ()
    Arc.Destroy(self);
    (self :: any).Beacon:Destroy()
end



return (ArcWithBeacon :: any) :: ArcWithBeacon