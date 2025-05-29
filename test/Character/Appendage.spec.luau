--Tests the Appendage class.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Appendage = require(ReplicatedStorage.Packages.NexusVRCharacterModel.NexusVRCharacterModel.Character.Appendage)

return function()
    local function expectNear(Actual: Vector3, Expected: Vector3): ()
        local ActualValues, ExpectedValues = {Actual.X, Actual.Y, Actual.Z}, {Expected.X, Expected.Y, Expected.Z}
        for i, ActualValue in ActualValues do
            expect(math.abs(ActualValue - ExpectedValues[i]) < 0.001).to.equal(true)
        end
    end

    local function expectNeverNear(Actual: Vector3, Expected: Vector3): ()
        local ActualValues, ExpectedValues = {Actual.X, Actual.Y, Actual.Z}, {Expected.X, Expected.Y, Expected.Z}
        local IsNear = true
        for i, ActualValue in ActualValues do
            if math.abs(ActualValue - ExpectedValues[i]) < 0.001 then continue end
            IsNear = false
        end
        expect(IsNear).to.equal(false)
    end

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
            expectNear((UpperCFrame * CFrame.new(-0.5, 0.5, 0)).Position, Vector3.new(0, 0, 0))
            expectNear((UpperCFrame * CFrame.new(0, -0.5, 0)).Position, (LowerCFrame * CFrame.new(0, 0.5, 0)).Position)
            expectNear((LowerCFrame * CFrame.new(0, -0.5, 0)).Position, (EndCFrame * CFrame.new(0, 0.5, 0)).Position)
            expectNear((EndCFrame * CFrame.new(0, -0.5,0)).Position, Vector3.new(0, -2, 0))

            --Assert that an unextended arm is valid with prevent disconnection false.
            UpperCFrame, LowerCFrame, EndCFrame = TestAppendage2:GetAppendageCFrames(CFrame.new(), CFrame.new(0, -2, 0))
            expectNear((UpperCFrame * CFrame.new(-0.5, 0.5, 0)).Position, Vector3.new(0, 0, 0))
            expectNear((UpperCFrame * CFrame.new(0, -0.5, 0)).Position, (LowerCFrame * CFrame.new(0, 0.5, 0)).Position)
            expectNear((LowerCFrame * CFrame.new(0, -0.5, 0)).Position, (EndCFrame * CFrame.new(0, 0.5, 0)).Position)
            expectNear((EndCFrame * CFrame.new(0, -0.5,0)).Position, Vector3.new(0, -2, 0))

            --Assert that an extended arm is valid with prevent disconnection true.
            UpperCFrame, LowerCFrame, EndCFrame = TestAppendage1:GetAppendageCFrames(CFrame.new(), CFrame.new(0, -4, 0))
            expectNear((UpperCFrame * CFrame.new(-0.5, 0.5, 0)).Position, Vector3.new(0, 0, 0))
            expectNear((UpperCFrame * CFrame.new(0, -0.5, 0)).Position, (LowerCFrame * CFrame.new(0, 0.5, 0)).Position)
            expectNear((LowerCFrame * CFrame.new(0, -0.5, 0)).Position, (EndCFrame * CFrame.new(0, 0.5, 0)).Position)
            expectNeverNear((EndCFrame * CFrame.new(0, -0.5,0)).Position, Vector3.new(0, -2, 0))

            --Assert that an extended arm is valid with prevent disconnection false.
            UpperCFrame, LowerCFrame, EndCFrame = TestAppendage2:GetAppendageCFrames(CFrame.new(), CFrame.new(0, -4, 0))
            expectNeverNear((UpperCFrame * CFrame.new(-0.5, 0.5, 0)).Position, Vector3.new(0, 0, 0))
            expectNear((UpperCFrame * CFrame.new(0, -0.5, 0)).Position, (LowerCFrame * CFrame.new(0, 0.5, 0)).Position)
            expectNear((LowerCFrame * CFrame.new(0, -0.5, 0)).Position, (EndCFrame * CFrame.new(0, 0.5, 0)).Position)
            expectNear((EndCFrame * CFrame.new(0, -0.5,0)).Position, Vector3.new(0, -4, 0))
        end)
    end)
end