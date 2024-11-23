--Tests the VRInputService class.
--!strict
--$NexusUnitTestExtensions

local NexusVRCharacterModel = game:GetService("ServerScriptService"):WaitForChild("NexusVRCharacterModelLoader"):WaitForChild("MainModule"):WaitForChild("NexusVRCharacterModel")
local VRInputService = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("VRInputService"))

return function()
    local MockVRService, TestVRInputService = nil, nil
    beforeEach(function()
        --Create the mock VRSevice.
        MockVRService = {
            HeadCFrame = CFrame.new()
        }
        function MockVRService.GetUserCFrame(self, Input)
            if Input == Enum.UserCFrame.Head then
                return self.HeadCFrame
            end
            return CFrame.new()
        end
        function MockVRService.GetUserCFrameEnabled()
            return true
        end

        --Create the test VRInputService.
        TestVRInputService = VRInputService.new(MockVRService :: any) :: any
    end)

    describe("The VR input service", function()
        it("should get the VR inputs.", function()
            MockVRService.HeadCFrame = CFrame.new(0, 2, 0)
            expect(TestVRInputService:GetVRInputs()[Enum.UserCFrame.Head]).to.be.near(CFrame.new(0, 0, 0))
            MockVRService.HeadCFrame = CFrame.new(0, 1, 0)
            expect(TestVRInputService:GetVRInputs()[Enum.UserCFrame.Head]).to.be.near(CFrame.new(0, -1, 0))
            MockVRService.HeadCFrame = CFrame.new(0, 1, 0) * CFrame.Angles(0, math.rad(50), 0)
            expect(TestVRInputService:GetVRInputs()[Enum.UserCFrame.Head]).to.be.near(CFrame.new(0, -1, 0) * CFrame.Angles(0, math.rad(50), 0))
            MockVRService.HeadCFrame = CFrame.new(0, 2, 0)
            expect(TestVRInputService:GetVRInputs()[Enum.UserCFrame.Head]).to.be.near(CFrame.new(0, 0, 0))
            MockVRService.HeadCFrame = CFrame.new(0, 3, 0)
            expect(TestVRInputService:GetVRInputs()[Enum.UserCFrame.Head]).to.be.near(CFrame.new(0, 0, 0))
            MockVRService.HeadCFrame = CFrame.new(0, 2, 0)
            expect(TestVRInputService:GetVRInputs()[Enum.UserCFrame.Head]).to.be.near(CFrame.new(0, -1, 0))
            MockVRService.HeadCFrame = CFrame.new(0, 2, 0) * CFrame.Angles(math.rad(20), 0, 0) * CFrame.new(0, 0, -0.5)
            expect(TestVRInputService:GetVRInputs()[Enum.UserCFrame.Head]).to.be.near(CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(20), 0, 0) * CFrame.new(0, 0, -0.5))
            MockVRService.HeadCFrame = CFrame.new(0, 3, 0) * CFrame.Angles(math.rad(20), 0, 0) * CFrame.new(0, 0, -0.5)
            expect(TestVRInputService:GetVRInputs()[Enum.UserCFrame.Head]).to.be.near(CFrame.Angles(math.rad(20), 0, 0) * CFrame.new(0, 0, -0.5))
            MockVRService.HeadCFrame = CFrame.new(0, 2, 0)
            expect(TestVRInputService:GetVRInputs()[Enum.UserCFrame.Head]).to.be.near(CFrame.new(0, -1, 0))
        end)

        it("should recenter.", function()
            MockVRService.HeadCFrame = CFrame.new(1, 2, 1)
            expect(TestVRInputService:GetVRInputs()[Enum.UserCFrame.Head]).to.be.near(CFrame.new(1, 0, 1))

            --Recenter without rotation twice and assert the results are correct.
            TestVRInputService:Recenter()
            expect(TestVRInputService:GetVRInputs()[Enum.UserCFrame.Head]).to.be.near(CFrame.new(0, 0, 0))
            MockVRService.HeadCFrame = CFrame.new(2, 2, 2)
            expect(TestVRInputService:GetVRInputs()[Enum.UserCFrame.Head]).to.be.near(CFrame.new(1, 0, 1))
            TestVRInputService:Recenter()
            expect(TestVRInputService:GetVRInputs()[Enum.UserCFrame.Head]).to.be.near(CFrame.new(0, 0, 0))
            MockVRService.HeadCFrame = CFrame.new(3, 2, 3) * CFrame.Angles(0, math.rad(45), 0)
            expect(TestVRInputService:GetVRInputs()[Enum.UserCFrame.Head]).to.be.near(CFrame.new(1, 0, 1) * CFrame.Angles(0, math.rad(45), 0))

            --Recenter with rotation and assert the results are correct.
            TestVRInputService:Recenter()
            expect(TestVRInputService:GetVRInputs()[Enum.UserCFrame.Head]).to.be.near(CFrame.new(0, 0, 0))
            MockVRService.HeadCFrame = CFrame.new(3, 2, 3) * CFrame.Angles(0, math.rad(45), 0) * CFrame.new(1, 0, 1)
            expect(TestVRInputService:GetVRInputs()[Enum.UserCFrame.Head]).to.be.near(CFrame.new(1, 0, 1))
        end)

        it("should set the eye level.", function()
            MockVRService.HeadCFrame = CFrame.new(1, 2, 1)
            expect(TestVRInputService:GetVRInputs()[Enum.UserCFrame.Head]).to.be.near(CFrame.new(1, 0, 1))

            --Set the eye level and assert the values are normalized to it.
            TestVRInputService:SetEyeLevel()
            expect(TestVRInputService:GetVRInputs()[Enum.UserCFrame.Head]).to.be.near(CFrame.new(1, 0, 1))
            MockVRService.HeadCFrame = CFrame.new(1, 1, 1)
            expect(TestVRInputService:GetVRInputs()[Enum.UserCFrame.Head]).to.be.near(CFrame.new(1, -1, 1))
            MockVRService.HeadCFrame = CFrame.new(1, 3, 1)
            expect(TestVRInputService:GetVRInputs()[Enum.UserCFrame.Head]).to.be.near(CFrame.new(1, 1, 1))
        end)

        it("should get thumbstick positions.", function()
            --Assert zero Vector3 is returned for an invalid input.
            expect(TestVRInputService:GetThumbstickPosition(nil :: any)).to.equal(Vector3.zero)
            expect(TestVRInputService:GetThumbstickPosition(Enum.KeyCode.ButtonX)).to.equal(Vector3.zero)

            --Assert that the stored value is returned when it changes.
            expect(TestVRInputService:GetThumbstickPosition(Enum.KeyCode.Thumbstick1)).to.equal(Vector3.new(0, 0, 0))
            TestVRInputService.ThumbstickValues[Enum.KeyCode.Thumbstick1] = Vector3.new(0, 1, 0)
            expect(TestVRInputService:GetThumbstickPosition(Enum.KeyCode.Thumbstick1)).to.equal(Vector3.new(0, 1, 0))
            TestVRInputService.ThumbstickValues[Enum.KeyCode.Thumbstick1] = Vector3.new(0, 0.5, 0)
            expect(TestVRInputService:GetThumbstickPosition(Enum.KeyCode.Thumbstick1)).to.equal(Vector3.new(0, 0.5, 0))
        end)
    end)
end