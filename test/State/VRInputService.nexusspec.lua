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



return true