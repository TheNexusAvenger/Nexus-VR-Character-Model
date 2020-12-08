--[[
TheNexusAvenger

Tests the Settings class.
--]]

local NexusUnitTesting = require("NexusUnitTesting")
local ServerScriptService = game:GetService("ServerScriptService")

local NexusVRCharacterModel = require(ServerScriptService:WaitForChild("NexusVRCharacterModelLoader"):WaitForChild("MainModule"))
local Settings = NexusVRCharacterModel:GetResource("State.Settings")
local SettingsTest = NexusUnitTesting.UnitTest:Extend()



--[[
Sets up the test.
--]]
function SettingsTest:Setup()
    self.CuT = Settings.new()
    self.CuT.Defaults = {
        TestValue1 = {
            TestValue2 = "Test1",
        },
        TestValue3 = {
            TestValue4 = {
                TestValue5 = "Test2",
                TestValue6 = "Test3",
            }
        },
    }
    self.CuT.Overrides = {
        TestValue3 = {
            TestValue4 = {
                TestValue5 = "Test6",
                TestValue6 = "Test3",
                TestValue7 = "Test4",
            }
        },
        TestValue8 = "Test5",
    }
end

--[[
Tears down the test.
--]]
function SettingsTest:Teardown()
    NexusVRCharacterModel:ClearInstances()
    if self.CuT then
        self.CuT:Destroy()
    end
end

--[[
Tests the GetSetting method.
--]]
NexusUnitTesting:RegisterUnitTest(SettingsTest.new("GetSetting"):SetRun(function(self)
    --Assert that valid results are returned.
    self:AssertEquals(self.CuT:GetSetting("TestValue1.TestValue2"),"Test1")
    self:AssertEquals(self.CuT:GetSetting("TestValue3.TestValue4.TestValue5"),"Test6")
    self:AssertEquals(self.CuT:GetSetting("TestValue3.TestValue4.TestValue6"),"Test3")
    self:AssertEquals(self.CuT:GetSetting("TestValue3.TestValue4.TestValue7"),"Test4")
    self:AssertEquals(self.CuT:GetSetting("TestValue8"),"Test5")

    --Assert that invalid results return nil.
    self:AssertEquals(self.CuT:GetSetting(""),nil)
    self:AssertEquals(self.CuT:GetSetting("TestValue4"),nil)
    self:AssertEquals(self.CuT:GetSetting("TestValue1.TestValue3"),nil)
    self:AssertEquals(self.CuT:GetSetting("TestValue1.TestValue3.TestValue4"),nil)
end))

--[[
Tests the SetSetting method.
--]]
NexusUnitTesting:RegisterUnitTest(SettingsTest.new("SetSetting"):SetRun(function(self)
    --Assert that set values are correct.
    self.CuT:SetSetting("TestValue9","Test7")
    self:AssertEquals(self.CuT:GetSetting("TestValue9"),"Test7")
    self.CuT:SetSetting("TestValue3.TestValue4.TestValue5","Test8")
    self:AssertEquals(self.CuT:GetSetting("TestValue3.TestValue4.TestValue5"),"Test8")
    self.CuT:SetSetting("TestValue10.TestValue11","Test9")
    self:AssertEquals(self.CuT:GetSetting("TestValue10.TestValue11"),"Test9")
end))

--[[
Tests the SetOverrides method.
--]]
NexusUnitTesting:RegisterUnitTest(SettingsTest.new("SetOverrides"):SetRun(function(self)
    --Connect the events.
    local ConnectionsFired = 0
    self.CuT:GetSettingsChangedSignal("TestValue1.TestValue2"):Connect(function()
        ConnectionsFired = ConnectionsFired + 1
    end)
    self.CuT:GetSettingsChangedSignal("TestValue3.TestValue4.TestValue5"):Connect(function()
        ConnectionsFired = ConnectionsFired + 1
    end)
    self.CuT:GetSettingsChangedSignal("TestValue3.TestValue4.TestValue7"):Connect(function()
        ConnectionsFired = ConnectionsFired + 1
    end)

    --Set the overrides and assert the changed values are correct.
    self.CuT:SetOverrides({
        TestValue1 = {
            TestValue2 = "Test7",
        },
        TestValue3 = {
            TestValue4 = {
                TestValue5 = "Test8",
                TestValue7 = "Test9",
            },
        },
    })
    self:AssertEquals(ConnectionsFired,3)
    self:AssertEquals(self.CuT:GetSetting("TestValue1.TestValue2"),"Test7")
    self:AssertEquals(self.CuT:GetSetting("TestValue3.TestValue4.TestValue5"),"Test8")
    self:AssertEquals(self.CuT:GetSetting("TestValue3.TestValue4.TestValue7"),"Test9")
end))

--[[
Tests the GetSettingsChangedSignal method.
--]]
NexusUnitTesting:RegisterUnitTest(SettingsTest.new("GetSettingsChangedSignal"):SetRun(function(self)
    --Connect the events.
    local ConnectionsFired = 0
    self.CuT:GetSettingsChangedSignal("TestValue1.TestValue2"):Connect(function()
        ConnectionsFired = ConnectionsFired + 1
    end)
    self.CuT:GetSettingsChangedSignal("TestValue3.TestValue4.TestValue5"):Connect(function()
        ConnectionsFired = ConnectionsFired + 1
    end)
    self.CuT:GetSettingsChangedSignal("TestValue3.TestValue4.TestValue7"):Connect(function()
        ConnectionsFired = ConnectionsFired + 1
    end)

    --Assert the fired connections are valid.
    self.CuT:SetSetting("TestValue1.TestValue2","Test7")
    self:AssertEquals(ConnectionsFired,1)
    self.CuT:SetSetting("TestValue3.TestValue4.TestValue5","Test8")
    self:AssertEquals(ConnectionsFired,2)
    self.CuT:SetSetting("TestValue3.TestValue4.TestValue7","Test9")
    self:AssertEquals(ConnectionsFired,3)
end))



return true