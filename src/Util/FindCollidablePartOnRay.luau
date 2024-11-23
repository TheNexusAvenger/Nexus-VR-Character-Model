--Helper function that ray casts to find a collidable part.
--!strict

local Workspace = game:GetService("Workspace")

return function(StartPosition: Vector3, Direction: Vector3, IgnoreList: Instance | {Instance}?, CollisionGroup: string?): (BasePart?, Vector3)
    --Convert the collision group.
    if typeof(CollisionGroup) == "Instance" and CollisionGroup:IsA("BasePart") then
        CollisionGroup = CollisionGroup.CollisionGroup
    end

    --Create the parameters.
    local RaycastParameters = RaycastParams.new()
    RaycastParameters.FilterType = Enum.RaycastFilterType.Exclude
    RaycastParameters.FilterDescendantsInstances = {Workspace.CurrentCamera}
    if IgnoreList then
        RaycastParameters:AddToFilter(IgnoreList)
    end
    RaycastParameters.IgnoreWater = true
    if CollisionGroup then
        RaycastParameters.CollisionGroup = CollisionGroup
    end

    while true do
        --Raycast and try again if the hit part isn't collidable.
        local RaycastResult = Workspace:Raycast(StartPosition, Direction, RaycastParameters)
        if not RaycastResult then
            return nil, StartPosition + Direction
        end
        local HitPart,EndPosition = RaycastResult.Instance, RaycastResult.Position
        if HitPart and not HitPart.CanCollide and (not HitPart:IsA("Seat") or not HitPart:IsA("VehicleSeat") or HitPart.Disabled) then
            RaycastParameters:AddToFilter(HitPart)
            continue
        end

        --Return the hit result.
        return HitPart, EndPosition
    end
end