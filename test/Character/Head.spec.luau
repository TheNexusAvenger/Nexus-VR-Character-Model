--Tests the Head class.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Head = require(ReplicatedStorage.Packages.NexusVRCharacterModel.NexusVRCharacterModel.Character.Head)

return function()
    local function expectNear(Actual: CFrame, Expected: CFrame): ()
        local ActualValues, ExpectedValues = {Actual:GetComponents()}, {Expected:GetComponents()}
        for i, ActualValue in ActualValues do
            expect(math.abs(ActualValue - ExpectedValues[i]) < 0.01).to.equal(true)
        end
    end

    describe("A head instance", function()
        local TestHead, TestHeadPart, TestFaceFrontAttachment, TestNeckRigAttachment
        beforeEach(function()
            TestHeadPart = Instance.new("Part")
            TestHeadPart.Size = Vector3.new(1, 1, 1)
        
            TestFaceFrontAttachment = Instance.new("Attachment")
            TestFaceFrontAttachment.Name = "FaceFrontAttachment"
            TestFaceFrontAttachment.Position = Vector3.new(0, 0, -0.5)
            TestFaceFrontAttachment.Parent = TestHeadPart
        
            TestNeckRigAttachment = Instance.new("Attachment")
            TestNeckRigAttachment.Name = "NeckRigAttachment"
            TestNeckRigAttachment.Position = Vector3.new(0, -0.5, 0)
            TestNeckRigAttachment.Parent = TestHeadPart
        
            TestHead = Head.new(TestHeadPart)
        end)

        it("should return the head CFrame.", function()
            expectNear(TestHead:GetHeadCFrame(CFrame.new(0, 2, 1)), CFrame.new(0, 1.75, 1.5))
            TestHeadPart.Size = Vector3.new(1, 2, 1)
            expectNear(TestHead:GetHeadCFrame(CFrame.new(0, 2, 1)), CFrame.new(0, 1.5, 1.5))
            TestFaceFrontAttachment.Position = Vector3.new(0, 0, -1)
            expectNear(TestHead:GetHeadCFrame(CFrame.new(0, 2, 1)), CFrame.new(0, 1.5, 2))
            TestFaceFrontAttachment.Position = Vector3.new(0, 1, -1)
            expectNear(TestHead:GetHeadCFrame(CFrame.new(0, 2, 1)), CFrame.new(0, 0.5, 2))
        end)

        it("should return the neck CFrame.", function()
            --Tests the neck CFrame with tilting the head.
            expectNear(TestHead:GetNeckCFrame(CFrame.new(0, 2, 1)), CFrame.new(0, 1.25, 1.5))
            expectNear(TestHead:GetNeckCFrame(CFrame.Angles(math.rad(30), 0, 0) * CFrame.new(0, 2, 1)), CFrame.Angles(math.rad(30), 0, 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(math.rad(-30), 0, 0))
            expectNear(TestHead:GetNeckCFrame(CFrame.Angles(math.rad(60), 0, 0) * CFrame.new(0, 2, 1)), CFrame.Angles(math.rad(60), 0, 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(math.rad(-60), 0, 0))
            expectNear(TestHead:GetNeckCFrame(CFrame.Angles(math.rad(70), 0, 0) * CFrame.new(0, 2, 1)), CFrame.Angles(math.rad(70), 0, 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(math.rad(-60), 0, 0))
            expectNear(TestHead:GetNeckCFrame(CFrame.Angles(math.rad(-30), 0, 0) * CFrame.new(0, 2, 1)), CFrame.Angles(math.rad(-30), 0, 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(math.rad(30), 0, 0))
            expectNear(TestHead:GetNeckCFrame(CFrame.Angles(math.rad(-60), 0, 0) * CFrame.new(0, 2, 1)), CFrame.Angles(math.rad(-60), 0, 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(math.rad(60), 0, 0))
            expectNear(TestHead:GetNeckCFrame(CFrame.Angles(math.rad(-70), 0, 0) * CFrame.new(0, 2, 1)), CFrame.Angles(math.rad(-70), 0, 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(math.rad(60), 0, 0))

            --Tests the neck CFrame with rotating the head.
            expectNear(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(10), 0) * CFrame.new(0, 2, 1)), CFrame.Angles(0, math.rad(10), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(-10), 0))
            expectNear(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(30), 0) * CFrame.new(0, 2, 1)), CFrame.Angles(0, math.rad(30), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(-30), 0))
            expectNear(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(40), 0) * CFrame.new(0, 2, 1)), CFrame.Angles(0, math.rad(40), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(-35), 0))
            expectNear(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(160), 0) * CFrame.new(0, 2, 1)), CFrame.Angles(0, math.rad(160), 0) * CFrame.new(0, 1.25, 1.5))
            expectNear(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(-10), 0) * CFrame.new(0, 2, 1)), CFrame.Angles(0, math.rad(-10), 0) * CFrame.new(0, 1.25, 1.5))
            expectNear(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(-20), 0) * CFrame.new(0, 2, 1)), CFrame.Angles(0, math.rad(-20), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(10), 0))
            expectNear(TestHead:GetNeckCFrame(CFrame.new(0, 2, 1)), CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(-10), 0))
            expectNear(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(-50), 0) * CFrame.new(0, 2, 1)), CFrame.Angles(0, math.rad(-50), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(35), 0))
            expectNear(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(-60), 0) * CFrame.new(0, 2, 1)), CFrame.Angles(0, math.rad(-60), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(35), 0))
            expectNear(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(-50), 0) * CFrame.new(0, 2, 1)), CFrame.Angles(0, math.rad(-50), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(25), 0))

            --Test the neck CFrame with a target angle.
            expectNear(TestHead:GetNeckCFrame(CFrame.new(0, 2, 1), 0), CFrame.new(0, 1.25, 1.5))
            expectNear(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(10), 0) * CFrame.new(0, 2, 1), 0), CFrame.Angles(0, math.rad(10), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(-10), 0))
            expectNear(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(70), 0) * CFrame.new(0, 2, 1), 0), CFrame.Angles(0, math.rad(70), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(-60), 0))
            expectNear(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(-10), 0) * CFrame.new(0, 2, 1), 0), CFrame.Angles(0, math.rad(-10), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(10), 0))
            expectNear(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(-70), 0) * CFrame.new(0, 2, 1), 0), CFrame.Angles(0, math.rad(-70), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(60), 0))
            expectNear(TestHead:GetNeckCFrame(CFrame.new(0, 2, 1), 0), CFrame.new(0, 1.25, 1.5))
            expectNear(TestHead:GetNeckCFrame(CFrame.Angles(0, math.pi, 0) * CFrame.new(0, 2, 1), math.pi), CFrame.Angles(0, math.rad(180), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(-180), 0))
            expectNear(TestHead:GetNeckCFrame(CFrame.Angles(0, math.pi + math.rad(10), 0) * CFrame.new(0, 2, 1), math.pi), CFrame.Angles(0, math.rad(190), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(-190), 0))
            expectNear(TestHead:GetNeckCFrame(CFrame.Angles(0, math.pi + math.rad(70), 0) * CFrame.new(0, 2, 1), math.pi), CFrame.Angles(0, math.rad(250), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(-240), 0))
        end)
    end)
end