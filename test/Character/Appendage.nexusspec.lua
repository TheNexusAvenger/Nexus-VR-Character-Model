--[[
TheNexusAvenger

Tests the Appendage class.
--]]

local NexusUnitTesting = require("NexusUnitTesting")
local ServerScriptService = game:GetService("ServerScriptService")

local NexusVRCharacterModel = require(ServerScriptService:WaitForChild("NexusVRCharacterModelLoader"):WaitForChild("MainModule"))
local Appendage = NexusVRCharacterModel:GetResource("Character.Appendage")
local AppendageTest = NexusUnitTesting.UnitTest:Extend()



--[[
Sets up the test.
--]]
function AppendageTest:Setup()
    self.UpperLimb = Instance.new("Part")
    self.UpperLimb.Size = Vector3.new(1,1,1)
    self.LowerLimb = Instance.new("Part")
    self.LowerLimb.Size = Vector3.new(1,1,1)
    self.LimbEnd = Instance.new("Part")
    self.LimbEnd.Size = Vector3.new(1,1,1)

    self.UpperLimbUpperAttachment = Instance.new("Attachment")
    self.UpperLimbUpperAttachment.Position = Vector3.new(-0.5,0.5,0)
    self.UpperLimbUpperAttachment.Name = "UpperLimbAttachment"
    self.UpperLimbUpperAttachment.Parent = self.UpperLimb

    self.UpperLimbLowerAttachment = Instance.new("Attachment")
    self.UpperLimbLowerAttachment.Position = Vector3.new(0,-0.5,0)
    self.UpperLimbLowerAttachment.Name = "MiddleLimbAttachment"
    self.UpperLimbLowerAttachment.Parent = self.UpperLimb

    self.LowerLimbUpperAttachment = Instance.new("Attachment")
    self.LowerLimbUpperAttachment.Position = Vector3.new(0,0.5,0)
    self.LowerLimbUpperAttachment.Name = "MiddleLimbAttachment"
    self.LowerLimbUpperAttachment.Parent = self.LowerLimb

    self.LowerLimbLowerAttachment = Instance.new("Attachment")
    self.LowerLimbLowerAttachment.Position = Vector3.new(0,-0.5,0)
    self.LowerLimbLowerAttachment.Name = "LowerLimbAttachment"
    self.LowerLimbLowerAttachment.Parent = self.LowerLimb

    self.LimbEndUpperAttachment = Instance.new("Attachment")
    self.LimbEndUpperAttachment.Position = Vector3.new(0,0.5,0)
    self.LimbEndUpperAttachment.Name = "LowerLimbAttachment"
    self.LimbEndUpperAttachment.Parent = self.LimbEnd

    self.LimbEndLowerAttachment = Instance.new("Attachment")
    self.LimbEndLowerAttachment.Position = Vector3.new(0,-0.5,0)
    self.LimbEndLowerAttachment.Name = "LowerEndAttachment"
    self.LimbEndLowerAttachment.Parent = self.LimbEnd

    self.CuT1 = Appendage.new(self.UpperLimb,self.LowerLimb,self.LimbEnd,"UpperLimbAttachment","MiddleLimbAttachment","LowerLimbAttachment","LowerEndAttachment",true)
    self.CuT2 = Appendage.new(self.UpperLimb,self.LowerLimb,self.LimbEnd,"UpperLimbAttachment","MiddleLimbAttachment","LowerLimbAttachment","LowerEndAttachment",false)
end

--[[
Tears down the test.
--]]
function AppendageTest:Teardown()
    NexusVRCharacterModel:ClearInstances()
end

--[[
Tests the GetAppendageCFrames method.
--]]
NexusUnitTesting:RegisterUnitTest(AppendageTest.new("GetAppendageCFrames"):SetRun(function(self)
    --Assert that an unextended arm is valid with prevent disconnection true.
    local UpperCFrame,LowerCFrame,EndCFrame = self.CuT1:GetAppendageCFrames(CFrame.new(),CFrame.new(0,-2,0))
    self:AssertClose((UpperCFrame * CFrame.new(-0.5,0.5,0)).Position,Vector3.new(0,0,0),0.01)
    self:AssertClose((UpperCFrame * CFrame.new(0,-0.5,0)).Position,(LowerCFrame * CFrame.new(0,0.5,0)).Position,0.01)
    self:AssertClose((LowerCFrame * CFrame.new(0,-0.5,0)).Position,(EndCFrame * CFrame.new(0,0.5,0)).Position,0.01)
    self:AssertClose((EndCFrame * CFrame.new(0,-0.5,0)).Position,Vector3.new(0,-2,0),0.01)

    --Assert that an unextended arm is valid with prevent disconnection false.
    UpperCFrame,LowerCFrame,EndCFrame = self.CuT2:GetAppendageCFrames(CFrame.new(),CFrame.new(0,-2,0))
    self:AssertClose((UpperCFrame * CFrame.new(-0.5,0.5,0)).Position,Vector3.new(0,0,0),0.01)
    self:AssertClose((UpperCFrame * CFrame.new(0,-0.5,0)).Position,(LowerCFrame * CFrame.new(0,0.5,0)).Position,0.01)
    self:AssertClose((LowerCFrame * CFrame.new(0,-0.5,0)).Position,(EndCFrame * CFrame.new(0,0.5,0)).Position,0.01)
    self:AssertClose((EndCFrame * CFrame.new(0,-0.5,0)).Position,Vector3.new(0,-2,0),0.01)

    --Assert that an extended arm is valid with prevent disconnection true.
    UpperCFrame,LowerCFrame,EndCFrame = self.CuT1:GetAppendageCFrames(CFrame.new(),CFrame.new(0,-4,0))
    self:AssertClose((UpperCFrame * CFrame.new(-0.5,0.5,0)).Position,Vector3.new(0,0,0),0.01)
    self:AssertClose((UpperCFrame * CFrame.new(0,-0.5,0)).Position,(LowerCFrame * CFrame.new(0,0.5,0)).Position,0.01)
    self:AssertClose((LowerCFrame * CFrame.new(0,-0.5,0)).Position,(EndCFrame * CFrame.new(0,0.5,0)).Position,0.01)
    self:AssertNotClose((EndCFrame * CFrame.new(0,-0.5,0)).Position,Vector3.new(0,-4,0),0.01)

    --Assert that an extended arm is valid with prevent disconnection false.
    UpperCFrame,LowerCFrame,EndCFrame = self.CuT2:GetAppendageCFrames(CFrame.new(),CFrame.new(0,-4,0))
    self:AssertNotClose((UpperCFrame * CFrame.new(-0.5,0.5,0)).Position,Vector3.new(0,0,0),0.01)
    self:AssertClose((UpperCFrame * CFrame.new(0,-0.5,0)).Position,(LowerCFrame * CFrame.new(0,0.5,0)).Position,0.01)
    self:AssertClose((LowerCFrame * CFrame.new(0,-0.5,0)).Position,(EndCFrame * CFrame.new(0,0.5,0)).Position,0.01)
    self:AssertClose((EndCFrame * CFrame.new(0,-0.5,0)).Position,Vector3.new(0,-4,0),0.01)
end))



return true