--Tests the Torso class.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Torso = require(ReplicatedStorage.Packages.NexusVRCharacterModel.NexusVRCharacterModel.Character.Torso)

return function()
    describe("A torso instance", function()
        local TestTorso = nil
        beforeEach(function()
            local UpperTorso = Instance.new("Part")
            UpperTorso.Size = Vector3.new(2, 1, 1)
            local LowerTorso = Instance.new("Part")
            LowerTorso.Size = Vector3.new(2, 1, 1)

            local UpperTorsoNeckRigAttachment = Instance.new("Attachment")
            UpperTorsoNeckRigAttachment.Name = "NeckRigAttachment"
            UpperTorsoNeckRigAttachment.Position = Vector3.new(0, 0.5, 0)
            UpperTorsoNeckRigAttachment.Parent = UpperTorso

            local UpperTorsoWaistRigAttachment = Instance.new("Attachment")
            UpperTorsoWaistRigAttachment.Name = "WaistRigAttachment"
            UpperTorsoWaistRigAttachment.Position = Vector3.new(0, -0.5, 0)
            UpperTorsoWaistRigAttachment.Parent = UpperTorso

            local UpperTorsoLeftShoulderRigAttachment = Instance.new("Attachment")
            UpperTorsoLeftShoulderRigAttachment.Name = "LeftShoulderRigAttachment"
            UpperTorsoLeftShoulderRigAttachment.Position = Vector3.new(-1, 0.25, 0)
            UpperTorsoLeftShoulderRigAttachment.Parent = UpperTorso

            local UpperTorsoRightShoulderRigAttachment = Instance.new("Attachment")
            UpperTorsoRightShoulderRigAttachment.Name = "RightShoulderRigAttachment"
            UpperTorsoRightShoulderRigAttachment.Position = Vector3.new(1, 0.25, 0)
            UpperTorsoRightShoulderRigAttachment.Parent = UpperTorso

            local LowerTorsoWaistRigAttachment = Instance.new("Attachment")
            LowerTorsoWaistRigAttachment.Name = "WaistRigAttachment"
            LowerTorsoWaistRigAttachment.Position = Vector3.new(0, 0.5, 0)
            LowerTorsoWaistRigAttachment.Parent = LowerTorso

            local LowerTorsoLeftHipRigAttachment = Instance.new("Attachment")
            LowerTorsoLeftHipRigAttachment.Name = "LeftHipRigAttachment"
            LowerTorsoLeftHipRigAttachment.Position = Vector3.new(0.5, -0.5, 0)
            LowerTorsoLeftHipRigAttachment.Parent = LowerTorso

            local LowerTorsoRightHipRigAttachment = Instance.new("Attachment")
            LowerTorsoRightHipRigAttachment.Name = "RightHipRigAttachment"
            LowerTorsoRightHipRigAttachment.Position = Vector3.new(0.5, -0.5, 0)
            LowerTorsoRightHipRigAttachment.Parent = LowerTorso

            TestTorso = Torso.new(LowerTorso, UpperTorso)
        end)

        it("should return the torso CFrames.", function()
            local LowerCFrame, UpperCFrame = TestTorso:GetTorsoCFrames(CFrame.new())
            expect(UpperCFrame).to.equal(CFrame.new(0, -0.5, 0))
            expect(LowerCFrame).to.equal(CFrame.new(0, -1.5, 0))
            LowerCFrame, UpperCFrame = TestTorso:GetTorsoCFrames(CFrame.Angles(0, math.pi, 0))
            expect(UpperCFrame).to.equal(CFrame.new(0, -0.5, 0) * CFrame.Angles(0, math.pi, 0))
            expect(LowerCFrame).to.equal(CFrame.new(0, -1.5, 0) * CFrame.Angles(0, math.pi, 0))
            LowerCFrame, UpperCFrame = TestTorso:GetTorsoCFrames(CFrame.Angles(math.rad(5), 0, 0))
            expect(UpperCFrame).to.equal(CFrame.Angles(math.rad(5), 0, 0) * CFrame.new(0, -0.5, 0))
            expect(LowerCFrame).to.equal(CFrame.Angles(math.rad(5), 0, 0) * CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-5),0,0) * CFrame.new(0, -0.5, 0))
            LowerCFrame, UpperCFrame = TestTorso:GetTorsoCFrames(CFrame.Angles(math.rad(10), 0, 0))
            expect(UpperCFrame).to.equal(CFrame.Angles(math.rad(10), 0, 0) * CFrame.new(0, -0.5, 0))
            expect(LowerCFrame).to.equal(CFrame.Angles(math.rad(10), 0, 0) * CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-10),0,0) * CFrame.new(0, -0.5, 0))
            LowerCFrame, UpperCFrame = TestTorso:GetTorsoCFrames(CFrame.Angles(math.rad(20), 0, 0))
            expect(UpperCFrame).to.equal(CFrame.Angles(math.rad(20), 0, 0) * CFrame.new(0, -0.5, 0))
            expect(LowerCFrame).to.equal(CFrame.Angles(math.rad(20), 0, 0) * CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-10), 0, 0) * CFrame.new(0, -0.5, 0))
        end)

        it("should return the joint start CFrames.", function()
            local AppendageJointCFrames = TestTorso:GetAppendageJointCFrames(TestTorso:GetTorsoCFrames(CFrame.new()))
            expect(AppendageJointCFrames["RightShoulder"]).to.equal(CFrame.new(1, -0.25, 0))
            expect(AppendageJointCFrames["LeftShoulder"]).to.equal(CFrame.new(-1, -0.25, 0))
            expect(AppendageJointCFrames["RightHip"]).to.equal(CFrame.new(0.5, -2, 0))
            expect(AppendageJointCFrames["LeftHip"]).to.equal(CFrame.new(0.5, -2, 0))
            AppendageJointCFrames = TestTorso:GetAppendageJointCFrames(TestTorso:GetTorsoCFrames(CFrame.Angles(math.rad(20), 0, 0)))
            expect(AppendageJointCFrames["RightShoulder"]).to.equal(CFrame.Angles(math.rad(20), 0, 0) * CFrame.new(1, -0.25, 0))
            expect(AppendageJointCFrames["LeftShoulder"]).to.equal(CFrame.Angles(math.rad(20), 0, 0) * CFrame.new(-1, -0.25, 0))
            expect(AppendageJointCFrames["RightHip"]).to.equal(CFrame.Angles(math.rad(20), 0, 0) * CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-10), 0, 0) * CFrame.new(0.5, -1, 0))
            expect(AppendageJointCFrames["LeftHip"]).to.equal(CFrame.Angles(math.rad(20), 0, 0) * CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-10), 0, 0) * CFrame.new(0.5, -1, 0))
        end)
    end)
end