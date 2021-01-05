--[[
TheNexusAvenger

Tests the VRInputService class.
--]]

local NexusUnitTesting = require("NexusUnitTesting")
local ServerScriptService = game:GetService("ServerScriptService")

local NexusVRCharacterModel = require(ServerScriptService:WaitForChild("NexusVRCharacterModelLoader"):WaitForChild("MainModule"))
local VRInputService = NexusVRCharacterModel:GetResource("State.VRInputService")
local VRInputServiceTest = NexusUnitTesting.UnitTest:Extend()



--[[
Sets up the test.
--]]
function VRInputServiceTest:Setup()
    --Create the mock VRSevice.
    self.HeadCFrame = CFrame.new()
    self.MockVRService = {}
    function self.MockVRService.GetUserCFrame(_,Input)
        if Input == Enum.UserCFrame.Head then
            return self.HeadCFrame
        end
        return CFrame.new()
    end
    function self.MockVRService.GetUserCFrameEnabled()
        return true
    end

    --Create the component under testing.
    self.CuT = VRInputService.new(self.MockVRService)
end

--[[
Tears down the test.
--]]
function VRInputServiceTest:Teardown()
    NexusVRCharacterModel:ClearInstances()
end

--[[
Tests the GetVRInputs method.
--]]
NexusUnitTesting:RegisterUnitTest(VRInputServiceTest.new("GetVRInputs"):SetRun(function(self)
    --Assert the inputs are normalized correctly.
    self.HeadCFrame = CFrame.new(0,2,0)
    self:AssertClose(self.CuT:GetVRInputs()[Enum.UserCFrame.Head],CFrame.new(0,0,0),0.01)
    self.HeadCFrame = CFrame.new(0,1,0)
    self:AssertClose(self.CuT:GetVRInputs()[Enum.UserCFrame.Head],CFrame.new(0,-1,0),0.01)
    self.HeadCFrame = CFrame.new(0,1,0) * CFrame.Angles(0,math.rad(50),0)
    self:AssertClose(self.CuT:GetVRInputs()[Enum.UserCFrame.Head],CFrame.new(0,-1,0) * CFrame.Angles(0,math.rad(50),0),0.01)
    self.HeadCFrame = CFrame.new(0,2,0)
    self:AssertClose(self.CuT:GetVRInputs()[Enum.UserCFrame.Head],CFrame.new(0,0,0),0.01)
    self.HeadCFrame = CFrame.new(0,3,0)
    self:AssertClose(self.CuT:GetVRInputs()[Enum.UserCFrame.Head],CFrame.new(0,0,0),0.01)
    self.HeadCFrame = CFrame.new(0,2,0)
    self:AssertClose(self.CuT:GetVRInputs()[Enum.UserCFrame.Head],CFrame.new(0,-1,0),0.01)
    self.HeadCFrame = CFrame.new(0,2,0) * CFrame.Angles(math.rad(20),0,0) * CFrame.new(0,0,-0.5)
    self:AssertClose(self.CuT:GetVRInputs()[Enum.UserCFrame.Head],CFrame.new(0,-1,0) * CFrame.Angles(math.rad(20),0,0) * CFrame.new(0,0,-0.5),0.01)
    self.HeadCFrame = CFrame.new(0,3,0) * CFrame.Angles(math.rad(20),0,0) * CFrame.new(0,0,-0.5)
    self:AssertClose(self.CuT:GetVRInputs()[Enum.UserCFrame.Head],CFrame.Angles(math.rad(20),0,0) * CFrame.new(0,0,-0.5),0.01)
    self.HeadCFrame = CFrame.new(0,2,0)
    self:AssertClose(self.CuT:GetVRInputs()[Enum.UserCFrame.Head],CFrame.new(0,-1,0),0.01)
end))

--[[
Tests the Recenter method.
--]]
NexusUnitTesting:RegisterUnitTest(VRInputServiceTest.new("Recenter"):SetRun(function(self)
    self.HeadCFrame = CFrame.new(1,2,1)
    self:AssertClose(self.CuT:GetVRInputs()[Enum.UserCFrame.Head],CFrame.new(1,0,1),0.01)

    --Recenter without rotation twice and assert the results are correct.
    self.CuT:Recenter()
    self:AssertClose(self.CuT:GetVRInputs()[Enum.UserCFrame.Head],CFrame.new(0,0,0),0.01)
    self.HeadCFrame = CFrame.new(2,2,2)
    self:AssertClose(self.CuT:GetVRInputs()[Enum.UserCFrame.Head],CFrame.new(1,0,1),0.01)
    self.CuT:Recenter()
    self:AssertClose(self.CuT:GetVRInputs()[Enum.UserCFrame.Head],CFrame.new(0,0,0),0.01)
    self.HeadCFrame = CFrame.new(3,2,3) * CFrame.Angles(0,math.rad(45),0)
    self:AssertClose(self.CuT:GetVRInputs()[Enum.UserCFrame.Head],CFrame.new(1,0,1) * CFrame.Angles(0,math.rad(45),0),0.01)

    --Recenter with rotation and assert the results are correct.
    self.CuT:Recenter()
    self:AssertClose(self.CuT:GetVRInputs()[Enum.UserCFrame.Head],CFrame.new(0,0,0),0.01)
    self.HeadCFrame = CFrame.new(3,2,3) * CFrame.Angles(0,math.rad(45),0) * CFrame.new(1,0,1)
    self:AssertClose(self.CuT:GetVRInputs()[Enum.UserCFrame.Head],CFrame.new(1,0,1),0.01)
end))

--[[
Tests the SetEyeLevel method.
--]]
NexusUnitTesting:RegisterUnitTest(VRInputServiceTest.new("SetEyeLevel"):SetRun(function(self)
    self.HeadCFrame = CFrame.new(1,2,1)
    self:AssertClose(self.CuT:GetVRInputs()[Enum.UserCFrame.Head],CFrame.new(1,0,1),0.01)

    --Set the eye level and assert the values are normalized to it.
    self.CuT:SetEyeLevel()
    self:AssertClose(self.CuT:GetVRInputs()[Enum.UserCFrame.Head],CFrame.new(1,0,1),0.01)
    self.HeadCFrame = CFrame.new(1,1,1)
    self:AssertClose(self.CuT:GetVRInputs()[Enum.UserCFrame.Head],CFrame.new(1,-1,1),0.01)
    self.HeadCFrame = CFrame.new(1,3,1)
    self:AssertClose(self.CuT:GetVRInputs()[Enum.UserCFrame.Head],CFrame.new(1,1,1),0.01)
end))



return true