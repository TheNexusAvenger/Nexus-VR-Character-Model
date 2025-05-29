--Wraps the Nexus VR Character Model main module for loading.
--When required with an id, the main module's source isn't
--included, which makes the client see an empty script.
--!strict

local REQUIRED_LIBRARIES = {
    Enigma = "enigma",
    NexusAppendage = "nexus-appendage",
    NexusBufferedReplication = "nexus-buffered-replication",
    NexusButton = "nexus-button",
    NexusInstance = "nexus-instance",
    NexusVRCore = "nexus-vr-core",
}



--Copy the dependencies if it is a Wally package.
--This is meant to provide backward compatibility with the expected final module location.
local SourcePackages = script.Parent
if SourcePackages then
    local TargetPackages = script:WaitForChild("NexusVRCharacterModel"):WaitForChild("Packages")
    if not TargetPackages:FindFirstChild("_Index") then
        local Index = Instance.new("Folder")
        Index.Name = "_Index"
        Index.Parent = TargetPackages
        
        for PackageName, WallyPackageName in REQUIRED_LIBRARIES do
            local SourceReference = SourcePackages:FindFirstChild(PackageName)
            local SourcePackage = SourcePackages:FindFirstChild(WallyPackageName, true)
            local TargetPackage = TargetPackages:FindFirstChild(PackageName)
            if SourceReference and SourcePackage and TargetPackage then
                SourceReference:Clone().Parent = TargetPackages
                SourcePackage.Parent:Clone().Parent = Index
                TargetPackage:Destroy()
            end
        end
    end
end



--Load the module.
return require(script:WaitForChild("NexusVRCharacterModel"))