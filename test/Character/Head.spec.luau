--Tests the Head class.
--!strict
--$NexusUnitTestExtensions

local NexusVRCharacterModel = game:GetService("ServerScriptService"):WaitForChild("NexusVRCharacterModelLoader"):WaitForChild("MainModule"):WaitForChild("NexusVRCharacterModel")
local Head = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("Head"))

return function()
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
            expect(TestHead:GetHeadCFrame(CFrame.new(0, 2, 1))).to.be.near(CFrame.new(0, 1.75, 1.5))
            TestHeadPart.Size = Vector3.new(1, 2, 1)
            expect(TestHead:GetHeadCFrame(CFrame.new(0, 2, 1))).to.be.near(CFrame.new(0, 1.5, 1.5))
            TestFaceFrontAttachment.Position = Vector3.new(0, 0, -1)
            expect(TestHead:GetHeadCFrame(CFrame.new(0, 2, 1))).to.be.near(CFrame.new(0, 1.5, 2))
            TestFaceFrontAttachment.Position = Vector3.new(0, 1, -1)
            expect(TestHead:GetHeadCFrame(CFrame.new(0, 2, 1))).to.be.near(CFrame.new(0, 0.5, 2))
        end)

        it("should return the neck CFrame.", function()
            --Tests the neck CFrame with tilting the head.
            expect(TestHead:GetNeckCFrame(CFrame.new(0, 2, 1))).to.be.near(CFrame.new(0, 1.25, 1.5), 0.01)
            expect(TestHead:GetNeckCFrame(CFrame.Angles(math.rad(30), 0, 0) * CFrame.new(0, 2, 1))).to.be.near(CFrame.Angles(math.rad(30), 0, 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(math.rad(-30), 0, 0), 0.01)
            expect(TestHead:GetNeckCFrame(CFrame.Angles(math.rad(60), 0, 0) * CFrame.new(0, 2, 1))).to.be.near(CFrame.Angles(math.rad(60), 0, 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(math.rad(-60), 0, 0), 0.01)
            expect(TestHead:GetNeckCFrame(CFrame.Angles(math.rad(70), 0, 0) * CFrame.new(0, 2, 1))).to.be.near(CFrame.Angles(math.rad(70), 0, 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(math.rad(-60), 0, 0), 0.01)
            expect(TestHead:GetNeckCFrame(CFrame.Angles(math.rad(-30), 0, 0) * CFrame.new(0, 2, 1))).to.be.near(CFrame.Angles(math.rad(-30), 0, 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(math.rad(30), 0, 0), 0.01)
            expect(TestHead:GetNeckCFrame(CFrame.Angles(math.rad(-60), 0, 0) * CFrame.new(0, 2, 1))).to.be.near(CFrame.Angles(math.rad(-60), 0, 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(math.rad(60), 0, 0), 0.01)
            expect(TestHead:GetNeckCFrame(CFrame.Angles(math.rad(-70), 0, 0) * CFrame.new(0, 2, 1))).to.be.near(CFrame.Angles(math.rad(-70), 0, 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(math.rad(60), 0, 0), 0.01)

            --Tests the neck CFrame with rotating the head.
            expect(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(10), 0) * CFrame.new(0, 2, 1))).to.be.near(CFrame.Angles(0, math.rad(10), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(-10), 0), 0.01)
            expect(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(30), 0) * CFrame.new(0, 2, 1))).to.be.near(CFrame.Angles(0, math.rad(30), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(-30), 0), 0.01)
            expect(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(40), 0) * CFrame.new(0, 2, 1))).to.be.near(CFrame.Angles(0, math.rad(40), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(-35), 0), 0.01)
            expect(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(160), 0) * CFrame.new(0, 2, 1))).to.be.near(CFrame.Angles(0, math.rad(160), 0) * CFrame.new(0, 1.25, 1.5), 0.01)
            expect(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(-10), 0) * CFrame.new(0, 2, 1))).to.be.near(CFrame.Angles(0, math.rad(-10), 0) * CFrame.new(0, 1.25, 1.5), 0.01)
            expect(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(-20), 0) * CFrame.new(0, 2, 1))).to.be.near(CFrame.Angles(0, math.rad(-20), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(10), 0), 0.01)
            expect(TestHead:GetNeckCFrame(CFrame.new(0, 2, 1))).to.be.near(CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(-10), 0), 0.01)
            expect(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(-50), 0) * CFrame.new(0, 2, 1))).to.be.near(CFrame.Angles(0, math.rad(-50), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(35), 0), 0.01)
            expect(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(-60), 0) * CFrame.new(0, 2, 1))).to.be.near(CFrame.Angles(0, math.rad(-60), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(35), 0), 0.01)
            expect(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(-50), 0) * CFrame.new(0, 2, 1))).to.be.near(CFrame.Angles(0, math.rad(-50), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(25), 0), 0.01)

            --Test the neck CFrame with a target angle.
            expect(TestHead:GetNeckCFrame(CFrame.new(0, 2, 1), 0)).to.be.near(CFrame.new(0, 1.25, 1.5), 0.01)
            expect(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(10), 0) * CFrame.new(0, 2, 1), 0)).to.be.near(CFrame.Angles(0, math.rad(10), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(-10), 0), 0.01)
            expect(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(70), 0) * CFrame.new(0, 2, 1), 0)).to.be.near(CFrame.Angles(0, math.rad(70), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(-60), 0), 0.01)
            expect(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(-10), 0) * CFrame.new(0, 2, 1), 0)).to.be.near(CFrame.Angles(0, math.rad(-10), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(10), 0), 0.01)
            expect(TestHead:GetNeckCFrame(CFrame.Angles(0, math.rad(-70), 0) * CFrame.new(0, 2, 1), 0)).to.be.near(CFrame.Angles(0, math.rad(-70), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(60), 0), 0.01)
            expect(TestHead:GetNeckCFrame(CFrame.new(0, 2, 1), 0)).to.be.near(CFrame.new(0, 1.25, 1.5), 0.01)
            expect(TestHead:GetNeckCFrame(CFrame.Angles(0, math.pi, 0) * CFrame.new(0, 2, 1), math.pi)).to.be.near(CFrame.Angles(0, math.rad(180), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(-180), 0), 0.01)
            expect(TestHead:GetNeckCFrame(CFrame.Angles(0, math.pi + math.rad(10), 0) * CFrame.new(0, 2, 1), math.pi)).to.be.near(CFrame.Angles(0, math.rad(190), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(-190), 0), 0.01)
            expect(TestHead:GetNeckCFrame(CFrame.Angles(0, math.pi + math.rad(70), 0) * CFrame.new(0, 2, 1), math.pi)).to.be.near(CFrame.Angles(0, math.rad(250), 0) * CFrame.new(0, 1.25, 1.5) * CFrame.Angles(0, math.rad(-240), 0), 0.01)
        end)
    end)
end