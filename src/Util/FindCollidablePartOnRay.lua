--[[
TheNexusAvenger

Helper function that ray casts to
find a collidable part.
--]]

local Workspace = game:GetService("Workspace")



--[[
Ray casts to find a collidable part.
--]]
local function FindCollidablePartOnRay(StartPosition,Direction,IgnoreList)
    --Create the ignore list.
    local Camera = Workspace.CurrentCamera
    local NewIgnoreList = {Camera}
    if typeof(IgnoreList) == "Instance" then
        table.insert(NewIgnoreList,IgnoreList)
    elseif typeof(IgnoreList) == "table" then
        for _,Entry in pairs(IgnoreList) do
            if Entry ~= Camera then
                table.insert(NewIgnoreList,Entry)
            end
        end
    end

    --Create the parameters.
    local RaycastParameters = RaycastParams.new()
    RaycastParameters.FilterType = Enum.RaycastFilterType.Blacklist
    RaycastParameters.FilterDescendantsInstances = NewIgnoreList
    RaycastParameters.IgnoreWater = true

    --Raycast and continue if the hit part isn't collidable.
    local RaycastResult = Workspace:Raycast(StartPosition,Direction,RaycastParameters)
    if not RaycastResult then
        return nil,StartPosition + Direction
    end
    local HitPart,EndPosition = RaycastResult.Instance,RaycastResult.Position
    if HitPart and not HitPart.CanCollide then
        table.insert(NewIgnoreList,HitPart)
        return FindCollidablePartOnRay(EndPosition,Direction + (EndPosition - StartPosition),NewIgnoreList)
    end

    --Return the hit result.
    return HitPart,EndPosition
end

return FindCollidablePartOnRay