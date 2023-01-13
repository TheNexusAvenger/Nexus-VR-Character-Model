--[[
TheNexusAvenger

Tests the Appendage class.
--]]
--!strict
--$NexusUnitTestExtensions

local NexusVRCharacterModel = game:GetService("ServerScriptService"):WaitForChild("NexusVRCharacterModelLoader"):WaitForChild("MainModule"):WaitForChild("NexusVRCharacterModel")
local Appendage = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("Appendage"))

return function()
    describe("An appendage instance", function()
        it("should return the expected CFrames.", function()
            --Create the test appendages.
            local UpperLimb = Instance.new("Part")
            UpperLimb.Size = Vector3.new(1,1,1)
            local LowerLimb = Instance.new("Part")
            LowerLimb.Size = Vector3.new(1,1,1)
            local LimbEnd = Instance.new("Part")
            LimbEnd.Size = Vector3.new(1,1,1)

            local UpperLimbUpperAttachment = Instance.new("Attachment")
            UpperLimbUpperAttachment.Position = Vector3.new(-0.5,0.5,0)
            UpperLimbUpperAttachment.Name = "UpperLimbAttachment"
            UpperLimbUpperAttachment.Parent = UpperLimb

            local UpperLimbLowerAttachment = Instance.new("Attachment")
            UpperLimbLowerAttachment.Position = Vector3.new(0,-0.5,0)
            UpperLimbLowerAttachment.Name = "MiddleLimbAttachment"
            UpperLimbLowerAttachment.Parent = UpperLimb

            local LowerLimbUpperAttachment = Instance.new("Attachment")
            LowerLimbUpperAttachment.Position = Vector3.new(0,0.5,0)
            LowerLimbUpperAttachment.Name = "MiddleLimbAttachment"
            LowerLimbUpperAttachment.Parent = LowerLimb

            local LowerLimbLowerAttachment = Instance.new("Attachment")
            LowerLimbLowerAttachment.Position = Vector3.new(0,-0.5,0)
            LowerLimbLowerAttachment.Name = "LowerLimbAttachment"
            LowerLimbLowerAttachment.Parent = LowerLimb

            local LimbEndUpperAttachment = Instance.new("Attachment")
            LimbEndUpperAttachment.Position = Vector3.new(0,0.5,0)
            LimbEndUpperAttachment.Name = "LowerLimbAttachment"
            LimbEndUpperAttachment.Parent = LimbEnd

            local LimbEndLowerAttachment = Instance.new("Attachment")
            LimbEndLowerAttachment.Position = Vector3.new(0,-0.5,0)
            LimbEndLowerAttachment.Name = "LowerEndAttachment"
            LimbEndLowerAttachment.Parent = LimbEnd

            local TestAppendage1 = Appendage.new(UpperLimb, LowerLimb, LimbEnd,"UpperLimbAttachment","MiddleLimbAttachment","LowerLimbAttachment","LowerEndAttachment",true)
            local TestAppendage2 = Appendage.new(UpperLimb, LowerLimb, LimbEnd,"UpperLimbAttachment","MiddleLimbAttachment","LowerLimbAttachment","LowerEndAttachment",false)

            --Assert that an unextended arm is valid with prevent disconnection true.
            local UpperCFrame, LowerCFrame, EndCFrame = TestAppendage1:GetAppendageCFrames(CFrame.new(), CFrame.new(0, -2, 0))
            expect((UpperCFrame * CFrame.new(-0.5, 0.5, 0)).Position).to.be.near(Vector3.new(0, 0, 0), 0.001)
            expect((UpperCFrame * CFrame.new(0, -0.5, 0)).Position).to.be.near((LowerCFrame * CFrame.new(0, 0.5, 0)).Position, 0.001)
            expect((LowerCFrame * CFrame.new(0, -0.5, 0)).Position).to.be.near((EndCFrame * CFrame.new(0, 0.5, 0)).Position, 0.001)
            expect((EndCFrame * CFrame.new(0, -0.5,0)).Position).to.be.near(Vector3.new(0, -2, 0), 0.001)

            --Assert that an unextended arm is valid with prevent disconnection false.
            UpperCFrame, LowerCFrame, EndCFrame = TestAppendage2:GetAppendageCFrames(CFrame.new(), CFrame.new(0, -2, 0))
            expect((UpperCFrame * CFrame.new(-0.5, 0.5, 0)).Position).to.be.near(Vector3.new(0, 0, 0), 0.001)
            expect((UpperCFrame * CFrame.new(0, -0.5, 0)).Position).to.be.near((LowerCFrame * CFrame.new(0, 0.5, 0)).Position, 0.001)
            expect((LowerCFrame * CFrame.new(0, -0.5, 0)).Position).to.be.near((EndCFrame * CFrame.new(0, 0.5, 0)).Position, 0.001)
            expect((EndCFrame * CFrame.new(0, -0.5,0)).Position).to.be.near(Vector3.new(0, -2, 0), 0.001)

            --Assert that an extended arm is valid with prevent disconnection true.
            UpperCFrame, LowerCFrame, EndCFrame = TestAppendage1:GetAppendageCFrames(CFrame.new(), CFrame.new(0, -4, 0))
            expect((UpperCFrame * CFrame.new(-0.5, 0.5, 0)).Position).to.be.near(Vector3.new(0, 0, 0), 0.001)
            expect((UpperCFrame * CFrame.new(0, -0.5, 0)).Position).to.be.near((LowerCFrame * CFrame.new(0, 0.5, 0)).Position, 0.001)
            expect((LowerCFrame * CFrame.new(0, -0.5, 0)).Position).to.be.near((EndCFrame * CFrame.new(0, 0.5, 0)).Position, 0.001)
            expect((EndCFrame * CFrame.new(0, -0.5,0)).Position).to.never.be.near(Vector3.new(0, -2, 0), 0.001)

            --Assert that an extended arm is valid with prevent disconnection false.
            UpperCFrame, LowerCFrame, EndCFrame = TestAppendage2:GetAppendageCFrames(CFrame.new(), CFrame.new(0, -4, 0))
            expect((UpperCFrame * CFrame.new(-0.5, 0.5, 0)).Position).to.never.be.near(Vector3.new(0, 0, 0), 0.001)
            expect((UpperCFrame * CFrame.new(0, -0.5, 0)).Position).to.be.near((LowerCFrame * CFrame.new(0, 0.5, 0)).Position, 0.001)
            expect((LowerCFrame * CFrame.new(0, -0.5, 0)).Position).to.be.near((EndCFrame * CFrame.new(0, 0.5, 0)).Position, 0.001)
            expect((EndCFrame * CFrame.new(0, -0.5,0)).Position).to.be.near(Vector3.new(0, -4, 0), 0.001)
        end)
    end)
end