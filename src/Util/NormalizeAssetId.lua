--[[
TheNexusAvenger

Normalizes an asset id.
--]]
--!strict

return function(AssetId: string): string
    --Return if an rbxasset:// URL is being used.
    if string.find(AssetId, "rbxasset:") then
        return AssetId
    end
    
    --Normalize the URL if a number is found.
    local Id = string.match(AssetId, "(%d+)")
    if Id and string.find(AssetId, "://") then
        return "rbxassetid://"..tostring(Id)
    end

    --Return the original URL.
    return AssetId
end