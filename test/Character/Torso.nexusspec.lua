--[[
TheNexusAvenger

Tests the Torso class.
--]]

local NexusUnitTesting = require("NexusUnitTesting")
local ServerScriptService = game:GetService("ServerScriptService")

local NexusVRCharacterModel = require(ServerScriptService:WaitForChild("NexusVRCharacterModelLoader"):WaitForChild("MainModule"))
local Torso = NexusVRCharacterModel:GetResource("Character.Torso")
local TorsoTest = NexusUnitTesting.UnitTest:Extend()



--[[
Sets up the test.
--]]
function TorsoTest:Setup()
    self.UpperTorso = Instance.new("Part")
    self.UpperTorso.Size = Vector3.new(2,1,1)
    self.LowerTorso = Instance.new("Part")
    self.LowerTorso.Size = Vector3.new(2,1,1)

    self.NeckRigAttachment = Instance.new("Attachment")
    self.NeckRigAttachment.Name = "NeckRigAttachment"
    self.NeckRigAttachment.Position = Vector3.new(0,0.5,0)
    self.NeckRigAttachment.Parent = self.UpperTorso

    self.WaistRigAttachment = Instance.new("Attachment")
    self.WaistRigAttachment.Name = "WaistRigAttachment"
    self.WaistRigAttachment.Position = Vector3.new(0,-0.5,0)
    self.WaistRigAttachment.Parent = self.UpperTorso

    self.LeftShoulderRigAttachment = Instance.new("Attachment")
    self.LeftShoulderRigAttachment.Name = "LeftShoulderRigAttachment"
    self.LeftShoulderRigAttachment.Position = Vector3.new(-1,0.25,0)
    self.LeftShoulderRigAttachment.Parent = self.UpperTorso

    self.RightShoulderRigAttachment = Instance.new("Attachment")
    self.RightShoulderRigAttachment.Name = "RightShoulderRigAttachment"
    self.RightShoulderRigAttachment.Position = Vector3.new(1,0.25,0)
    self.RightShoulderRigAttachment.Parent = self.UpperTorso

    self.WaistRigAttachment = Instance.new("Attachment")
    self.WaistRigAttachment.Name = "WaistRigAttachment"
    self.WaistRigAttachment.Position = Vector3.new(0,0.5,0)
    self.WaistRigAttachment.Parent = self.LowerTorso

    self.LeftHipRigAttachment = Instance.new("Attachment")
    self.LeftHipRigAttachment.Name = "LeftHipRigAttachment"
    self.LeftHipRigAttachment.Position = Vector3.new(0.5,-0.5,0)
    self.LeftHipRigAttachment.Parent = self.LowerTorso

    self.RightHipRigAttachment = Instance.new("Attachment")
    self.RightHipRigAttachment.Name = "RightHipRigAttachment"
    self.RightHipRigAttachment.Position = Vector3.new(0.5,-0.5,0)
    self.RightHipRigAttachment.Parent = self.LowerTorso

    self.CuT = Torso.new(self.LowerTorso,self.UpperTorso)
end

--[[
Tears down the test.
--]]
function TorsoTest:Teardown()
    NexusVRCharacterModel:ClearInstances()
end

--[[
Tests the GetTorsoCFrames method.
--]]
NexusUnitTesting:RegisterUnitTest(TorsoTest.new("GetTorsoCFrames"):SetRun(function(self)
    local LowerCFrame,UpperCFrame = self.CuT:GetTorsoCFrames(CFrame.new())
    self:AssertClose(UpperCFrame,CFrame.new(0,-0.5,0),0.01)
    self:AssertClose(LowerCFrame,CFrame.new(0,-1.5,0),0.01)
    LowerCFrame,UpperCFrame = self.CuT:GetTorsoCFrames(CFrame.Angles(0,math.pi,0))
    self:AssertClose(UpperCFrame,CFrame.new(0,-0.5,0) * CFrame.Angles(0,math.pi,0),0.01)
    self:AssertClose(LowerCFrame,CFrame.new(0,-1.5,0) * CFrame.Angles(0,math.pi,0),0.01)
    LowerCFrame,UpperCFrame = self.CuT:GetTorsoCFrames(CFrame.Angles(math.rad(5),0,0))
    self:AssertClose(UpperCFrame,CFrame.Angles(math.rad(5),0,0) * CFrame.new(0,-0.5,0),0.01)
    self:AssertClose(LowerCFrame,CFrame.Angles(math.rad(5),0,0) * CFrame.new(0,-1,0) * CFrame.Angles(math.rad(-5),0,0) * CFrame.new(0,-0.5,0),0.01)
    LowerCFrame,UpperCFrame = self.CuT:GetTorsoCFrames(CFrame.Angles(math.rad(10),0,0))
    self:AssertClose(UpperCFrame,CFrame.Angles(math.rad(10),0,0) * CFrame.new(0,-0.5,0),0.01)
    self:AssertClose(LowerCFrame,CFrame.Angles(math.rad(10),0,0) * CFrame.new(0,-1,0) * CFrame.Angles(math.rad(-10),0,0) * CFrame.new(0,-0.5,0),0.01)
    LowerCFrame,UpperCFrame = self.CuT:GetTorsoCFrames(CFrame.Angles(math.rad(20),0,0))
    self:AssertClose(UpperCFrame,CFrame.Angles(math.rad(20),0,0) * CFrame.new(0,-0.5,0),0.01)
    self:AssertClose(LowerCFrame,CFrame.Angles(math.rad(20),0,0) * CFrame.new(0,-1,0) * CFrame.Angles(math.rad(-10),0,0) * CFrame.new(0,-0.5,0),0.01)
end))

--[[
Tests the GetAppendageJointCFrames method.
--]]
NexusUnitTesting:RegisterUnitTest(TorsoTest.new("GetAppendageJointCFrames"):SetRun(function(self)
    local AppendageJointCFrames = self.CuT:GetAppendageJointCFrames(self.CuT:GetTorsoCFrames(CFrame.new()))
    self:AssertClose(AppendageJointCFrames["RightShoulder"],CFrame.new(1,-0.25,0),0.01)
    self:AssertClose(AppendageJointCFrames["LeftShoulder"],CFrame.new(-1,-0.25,0),0.01)
    self:AssertClose(AppendageJointCFrames["RightHip"],CFrame.new(0.5,-2,0),0.01)
    self:AssertClose(AppendageJointCFrames["LeftHip"],CFrame.new(0.5,-2,0),0.01)
    AppendageJointCFrames = self.CuT:GetAppendageJointCFrames(self.CuT:GetTorsoCFrames(CFrame.Angles(math.rad(20),0,0)))
    self:AssertClose(AppendageJointCFrames["RightShoulder"],CFrame.Angles(math.rad(20),0,0) * CFrame.new(1,-0.25,0),0.01)
    self:AssertClose(AppendageJointCFrames["LeftShoulder"],CFrame.Angles(math.rad(20),0,0) * CFrame.new(-1,-0.25,0),0.01)
    self:AssertClose(AppendageJointCFrames["RightHip"],CFrame.Angles(math.rad(20),0,0) * CFrame.new(0,-1,0) * CFrame.Angles(math.rad(-10),0,0) * CFrame.new(0.5,-1,0),0.01)
    self:AssertClose(AppendageJointCFrames["LeftHip"],CFrame.Angles(math.rad(20),0,0) * CFrame.new(0,-1,0) * CFrame.Angles(math.rad(-10),0,0) * CFrame.new(0.5,-1,0),0.01)
end))



return true