--[[
TheNexusAvenger

Tests the Head class.
--]]

local NexusUnitTesting = require("NexusUnitTesting")
local ServerScriptService = game:GetService("ServerScriptService")

local NexusVRCharacterModel = require(ServerScriptService:WaitForChild("NexusVRCharacterModelLoader"):WaitForChild("MainModule"))
local Head = NexusVRCharacterModel:GetResource("Character.Head")
local HeadTest = NexusUnitTesting.UnitTest:Extend()



--[[
Sets up the test.
--]]
function HeadTest:Setup()
    self.Head = Instance.new("Part")
    self.Head.Size = Vector3.new(1,1,1)

    self.FaceFrontAttachment = Instance.new("Attachment")
    self.FaceFrontAttachment.Name = "FaceFrontAttachment"
    self.FaceFrontAttachment.Position = Vector3.new(0,0,-0.5)
    self.FaceFrontAttachment.Parent = self.Head

    self.NeckRigAttachment = Instance.new("Attachment")
    self.NeckRigAttachment.Name = "NeckRigAttachment"
    self.NeckRigAttachment.Position = Vector3.new(0,-0.5,0)
    self.NeckRigAttachment.Parent = self.Head

    self.CuT = Head.new(self.Head)
end

--[[
Tears down the test.
--]]
function HeadTest:Teardown()
    NexusVRCharacterModel:ClearInstances()
end

--[[
Tests the GetHeadCFrame method.
--]]
NexusUnitTesting:RegisterUnitTest(HeadTest.new("GetHeadCFrame"):SetRun(function(self)
    self:AssertClose(self.CuT:GetHeadCFrame(CFrame.new(0,2,1)),CFrame.new(0,1.75,1.5),0.01)
    self.Head.Size = Vector3.new(1,2,1)
    self:AssertClose(self.CuT:GetHeadCFrame(CFrame.new(0,2,1)),CFrame.new(0,1.5,1.5),0.01)
    self.FaceFrontAttachment.Position = Vector3.new(0,0,-1)
    self:AssertClose(self.CuT:GetHeadCFrame(CFrame.new(0,2,1)),CFrame.new(0,1.5,2),0.01)
    self.FaceFrontAttachment.Position = Vector3.new(0,1,-1)
    self:AssertClose(self.CuT:GetHeadCFrame(CFrame.new(0,2,1)),CFrame.new(0,0.5,2),0.01)
end))

--[[
Tests the GetNeckCFrame method.
--]]
NexusUnitTesting:RegisterUnitTest(HeadTest.new("GetNeckCFrame"):SetRun(function(self)
    --Tests the neck CFrame with tilting the head.
    self:AssertClose(self.CuT:GetNeckCFrame(CFrame.new(0,2,1)),CFrame.new(0,1.25,1.5),0.01)
    self:AssertClose(self.CuT:GetNeckCFrame(CFrame.Angles(math.rad(30),0,0) * CFrame.new(0,2,1)),CFrame.Angles(math.rad(30),0,0) * CFrame.new(0,1.25,1.5) * CFrame.Angles(math.rad(-30),0,0),0.01)
    self:AssertClose(self.CuT:GetNeckCFrame(CFrame.Angles(math.rad(60),0,0) * CFrame.new(0,2,1)),CFrame.Angles(math.rad(60),0,0) * CFrame.new(0,1.25,1.5) * CFrame.Angles(math.rad(-60),0,0),0.01)
    self:AssertClose(self.CuT:GetNeckCFrame(CFrame.Angles(math.rad(70),0,0) * CFrame.new(0,2,1)),CFrame.Angles(math.rad(70),0,0) * CFrame.new(0,1.25,1.5) * CFrame.Angles(math.rad(-60),0,0),0.01)
    self:AssertClose(self.CuT:GetNeckCFrame(CFrame.Angles(math.rad(-30),0,0) * CFrame.new(0,2,1)),CFrame.Angles(math.rad(-30),0,0) * CFrame.new(0,1.25,1.5) * CFrame.Angles(math.rad(30),0,0),0.01)
    self:AssertClose(self.CuT:GetNeckCFrame(CFrame.Angles(math.rad(-60),0,0) * CFrame.new(0,2,1)),CFrame.Angles(math.rad(-60),0,0) * CFrame.new(0,1.25,1.5) * CFrame.Angles(math.rad(60),0,0),0.01)
    self:AssertClose(self.CuT:GetNeckCFrame(CFrame.Angles(math.rad(-70),0,0) * CFrame.new(0,2,1)),CFrame.Angles(math.rad(-70),0,0) * CFrame.new(0,1.25,1.5) * CFrame.Angles(math.rad(60),0,0),0.01)

    --Tests the neck CFrame with rotating the head.
    self:AssertClose(self.CuT:GetNeckCFrame(CFrame.Angles(0,math.rad(10),0) * CFrame.new(0,2,1)),CFrame.Angles(0,math.rad(10),0) * CFrame.new(0,1.25,1.5) * CFrame.Angles(0,math.rad(-10),0),0.01)
    self:AssertClose(self.CuT:GetNeckCFrame(CFrame.Angles(0,math.rad(30),0) * CFrame.new(0,2,1)),CFrame.Angles(0,math.rad(30),0) * CFrame.new(0,1.25,1.5) * CFrame.Angles(0,math.rad(-30),0),0.01)
    self:AssertClose(self.CuT:GetNeckCFrame(CFrame.Angles(0,math.rad(40),0) * CFrame.new(0,2,1)),CFrame.Angles(0,math.rad(40),0) * CFrame.new(0,1.25,1.5) * CFrame.Angles(0,math.rad(-35),0),0.01)
    self:AssertClose(self.CuT:GetNeckCFrame(CFrame.Angles(0,math.rad(160),0) * CFrame.new(0,2,1)),CFrame.Angles(0,math.rad(160),0) * CFrame.new(0,1.25,1.5),0.01)
    self:AssertClose(self.CuT:GetNeckCFrame(CFrame.Angles(0,math.rad(-10),0) * CFrame.new(0,2,1)),CFrame.Angles(0,math.rad(-10),0) * CFrame.new(0,1.25,1.5),0.01)
    self:AssertClose(self.CuT:GetNeckCFrame(CFrame.Angles(0,math.rad(-20),0) * CFrame.new(0,2,1)),CFrame.Angles(0,math.rad(-20),0) * CFrame.new(0,1.25,1.5) * CFrame.Angles(0,math.rad(10),0),0.01)
    self:AssertClose(self.CuT:GetNeckCFrame(CFrame.new(0,2,1)),CFrame.new(0,1.25,1.5) * CFrame.Angles(0,math.rad(-10),0),0.01)
    self:AssertClose(self.CuT:GetNeckCFrame(CFrame.Angles(0,math.rad(-50),0) * CFrame.new(0,2,1)),CFrame.Angles(0,math.rad(-50),0) * CFrame.new(0,1.25,1.5) * CFrame.Angles(0,math.rad(35),0),0.01)
    self:AssertClose(self.CuT:GetNeckCFrame(CFrame.Angles(0,math.rad(-60),0) * CFrame.new(0,2,1)),CFrame.Angles(0,math.rad(-60),0) * CFrame.new(0,1.25,1.5) * CFrame.Angles(0,math.rad(35),0),0.01)
    self:AssertClose(self.CuT:GetNeckCFrame(CFrame.Angles(0,math.rad(-50),0) * CFrame.new(0,2,1)),CFrame.Angles(0,math.rad(-50),0) * CFrame.new(0,1.25,1.5) * CFrame.Angles(0,math.rad(25),0),0.01)
end))



return true