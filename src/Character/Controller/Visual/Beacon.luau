--Visual indicator for the end of aiming.
--!strict

local BEACON_SPEED_MULTIPLIER = 2

local Workspace = game:GetService("Workspace")

local Beacon = {}
Beacon.__index = Beacon

export type Beacon = {
    Sphere: Part,
    ConstantRing: ImageHandleAdornment,
    MovingRing: ImageHandleAdornment,
} & typeof(setmetatable({}, Beacon))



--[[
Creates a beacon.
--]]
function Beacon.new(): Beacon
    --Create the object.
    local self = {}
    setmetatable(self, Beacon)

    --Create the parts.
    local Sphere = Instance.new("Part")
    Sphere.Transparency = 1
    Sphere.Material = Enum.Material.Neon
    Sphere.Anchored = true
    Sphere.CanCollide = false
    Sphere.CanQuery = false
    Sphere.Size = Vector3.new(0.5, 0.5, 0.5)
    Sphere.Shape = Enum.PartType.Ball
    Sphere.Parent = Workspace.CurrentCamera

    local ConstantRing = Instance.new("ImageHandleAdornment")
    ConstantRing.Adornee = Sphere
    ConstantRing.Size = Vector2.new(2, 2)
    ConstantRing.Image = "rbxasset://textures/ui/VR/VRPointerDiscBlue.png"
    ConstantRing.Visible = false
    ConstantRing.Parent = Sphere

    local MovingRing = Instance.new("ImageHandleAdornment")
    MovingRing.Adornee = Sphere
    MovingRing.Size = Vector2.new(2, 2)
    MovingRing.Image = "rbxasset://textures/ui/VR/VRPointerDiscBlue.png"
    MovingRing.Visible = false
    MovingRing.Parent = Sphere

    --Return the object.
    return setmetatable({
        Sphere = Sphere,
        ConstantRing = ConstantRing,
        MovingRing = MovingRing,
    }, Beacon) :: Beacon
end

--[[
Updates the beacon at a given CFrame.
--]]
function Beacon.Update(self: Beacon, CenterCFrame: CFrame, HoverPart: BasePart): ()
    --Calculate the size for the current time.
    local Height = 0.4 + (-math.cos(tick() * 2 * BEACON_SPEED_MULTIPLIER) / 8)
    local BeaconSize = 2 * ((tick() * BEACON_SPEED_MULTIPLIER) % math.pi) / math.pi

    --Update the size and position of the beacon.
    self.Sphere.CFrame = CenterCFrame * CFrame.new(0, Height, 0)
    self.ConstantRing.CFrame = CFrame.new(0, -Height, 0) * CFrame.Angles(math.pi / 2, 0, 0)
    self.MovingRing.CFrame = CFrame.new(0, -Height, 0) * CFrame.Angles(math.pi / 2, 0, 0)
    self.MovingRing.Transparency = BeaconSize / 2
    self.MovingRing.Size = Vector2.new(BeaconSize, BeaconSize)

    --Update the beacon color.
    local BeaconColor = Color3.fromRGB(0, 170, 0)
    if HoverPart then
        local VRBeaconColor = HoverPart:FindFirstChild("VRBeaconColor") :: Color3Value
        if VRBeaconColor then
            BeaconColor = VRBeaconColor.Value
        elseif (HoverPart:IsA("Seat") or HoverPart:IsA("VehicleSeat")) and not HoverPart.Disabled then
            BeaconColor = Color3.fromRGB(0, 170, 255)
        end
    end
    self.Sphere.Color = BeaconColor

    --Show the beacon.
    self.Sphere.Transparency = 0
    self.ConstantRing.Visible = true
    self.MovingRing.Visible = true
end

--[[
Hides the beacon.
--]]
function Beacon.Hide(self: Beacon): ()
    --Hide the beacon.
    self.Sphere.Transparency = 1
    self.ConstantRing.Visible = false
    self.MovingRing.Visible = false
end

--[[
Destroys the beacon.
--]]
function Beacon.Destroy(self: Beacon): ()
    self.Sphere:Destroy()
end



return Beacon