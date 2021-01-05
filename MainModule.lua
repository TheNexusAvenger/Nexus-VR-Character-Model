--[[
TheNexusAvenger

Wraps the Nexus VR Character Model main module for loading.
When required with an id, the main module's source isn't
included, which makes the client see an empty script.
--]]

return require(script:WaitForChild("NexusVRCharacterModel"))