--[[
TheNexusAvenger

Helper function that ray casts to
find a collidable part.
--]]
--!strict

local Workspace = game:GetService("Workspace")



--[[
Ray casts to find a collidable part.
--]]
local function FindCollidablePartOnRay(StartPosition: Vector3, Direction: Vector3, IgnoreList: Instance | {Instance}?, CollisionGroup: string?): (BasePart?, Vector3)
    --Convert the collision group.
    if typeof(CollisionGroup) == "Instance" and CollisionGroup:IsA("BasePart") then
        CollisionGroup = CollisionGroup.CollisionGroup
    end

    --Create the ignore list.
    local Camera = Workspace.CurrentCamera
    local NewIgnoreList = {Camera}
    if typeof(IgnoreList) == "Instance" then
        table.insert(NewIgnoreList, IgnoreList)
    elseif typeof(IgnoreList) == "table" then
        for _, Entry in IgnoreList do
            if Entry ~= Camera then
                table.insert(NewIgnoreList, Entry)
            end
        end
    end

    --Create the parameters.
    local RaycastParameters = RaycastParams.new()
    RaycastParameters.FilterType = Enum.RaycastFilterType.Exclude
    RaycastParameters.FilterDescendantsInstances = NewIgnoreList
    RaycastParameters.IgnoreWater = true
    if CollisionGroup then
        RaycastParameters.CollisionGroup = CollisionGroup
    end

    --Raycast and continue if the hit part isn't collidable.
    local RaycastResult = Workspace:Raycast(StartPosition, Direction, RaycastParameters)
    if not RaycastResult then
        return nil, StartPosition + Direction
    end
    local HitPart,EndPosition = RaycastResult.Instance, RaycastResult.Position
    if HitPart and not HitPart.CanCollide and (not HitPart:IsA("Seat") or not HitPart:IsA("VehicleSeat") or HitPart.Disabled) then
        table.insert(NewIgnoreList, HitPart)
        return FindCollidablePartOnRay(EndPosition, Direction + (EndPosition - StartPosition), NewIgnoreList, CollisionGroup)
    end

    --Return the hit result.
    return HitPart, EndPosition
end



return FindCollidablePartOnRay