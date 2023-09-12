--[[
TheNexusAvenger

Tests the NormalizeAssetId function.
--]]
--!strict

local NexusVRCharacterModel = game:GetService("ServerScriptService"):WaitForChild("NexusVRCharacterModelLoader"):WaitForChild("MainModule"):WaitForChild("NexusVRCharacterModel")
local NormalizeAssetId = require(NexusVRCharacterModel:WaitForChild("Util"):WaitForChild("NormalizeAssetId"))

return function()
    describe("The normalize asset id function", function()
        it("should normalize rbxassetid://", function()
            expect(NormalizeAssetId("rbxassetid://12345")).to.equal("rbxassetid://12345")
        end)

        it("should normalize https://www.roblox.com/asset?id=", function()
            expect(NormalizeAssetId("https://www.roblox.com/asset?id=12345")).to.equal("rbxassetid://12345")
        end)

        it("should leave other rbxasset:// untouched", function()
            expect(NormalizeAssetId("rbxasset://TestAsset")).to.equal("rbxasset://TestAsset")
            expect(NormalizeAssetId("rbxasset://TestAsset2")).to.equal("rbxasset://TestAsset2")
        end)

        it("should leave other strings untouched", function()
            expect(NormalizeAssetId("TestAsset")).to.equal("TestAsset")
        end)
    end)
end