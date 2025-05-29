--Tests the Settings class.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Settings = require(ReplicatedStorage.Packages.NexusVRCharacterModel.NexusVRCharacterModel.State.Settings)

return function()
    local TestSettings = nil
    beforeEach(function()
        TestSettings = Settings.new() :: any
        TestSettings.Defaults = {
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
        TestSettings.Overrides = {
            TestValue3 = {
                TestValue4 = {
                    TestValue5 = "Test6",
                    TestValue6 = "Test3",
                    TestValue7 = "Test4",
                }
            },
            TestValue8 = "Test5",
        }
    end)
    afterEach(function()
        TestSettings:Destroy()
    end)

    describe("The setting service", function()
        it("should get settings.", function()
            --Assert that valid results are returned.
            expect(TestSettings:GetSetting("TestValue1.TestValue2")).to.equal("Test1")
            expect(TestSettings:GetSetting("TestValue3.TestValue4.TestValue5")).to.equal("Test6")
            expect(TestSettings:GetSetting("TestValue3.TestValue4.TestValue6")).to.equal("Test3")
            expect(TestSettings:GetSetting("TestValue3.TestValue4.TestValue7")).to.equal("Test4")
            expect(TestSettings:GetSetting("TestValue8")).to.equal("Test5")
            
            --Assert that invalid results return nil.
            expect(TestSettings:GetSetting("")).to.equal(nil)
            expect(TestSettings:GetSetting("TestValue4")).to.equal(nil)
            expect(TestSettings:GetSetting("TestValue1.TestValue3")).to.equal(nil)
            expect(TestSettings:GetSetting("TestValue1.TestValue3.TestValue4")).to.equal(nil)
        end)

        it("should set settings.", function()
            --Assert that set values are correct.
            TestSettings:SetSetting("TestValue9","Test7")
            expect(TestSettings:GetSetting("TestValue9")).to.equal("Test7")
            TestSettings:SetSetting("TestValue3.TestValue4.TestValue5","Test8")
            expect(TestSettings:GetSetting("TestValue3.TestValue4.TestValue5")).to.equal("Test8")
            TestSettings:SetSetting("TestValue10.TestValue11","Test9")
            expect(TestSettings:GetSetting("TestValue10.TestValue11")).to.equal("Test9")
        end)

        it("should set default settings.", function()
            --Connect the events.
            local ConnectionsFired = 0
            TestSettings:GetSettingsChangedSignal("TestValue1.TestValue2"):Connect(function()
                ConnectionsFired = ConnectionsFired + 1
            end)
            TestSettings:GetSettingsChangedSignal("TestValue3.TestValue4.TestValue5"):Connect(function()
                ConnectionsFired = ConnectionsFired + 1
            end)
            TestSettings:GetSettingsChangedSignal("TestValue3.TestValue4.TestValue7"):Connect(function()
                ConnectionsFired = ConnectionsFired + 1
            end)

            --Set the defaults and assert the changed values are correct.
            TestSettings.Overrides = {}
            TestSettings:SetDefaults({
                TestValue1 = {
                    TestValue2 = "Test7",
                },
                TestValue3 = {
                    TestValue4 = {
                        TestValue5 = "Test8",
                        TestValue7 = "Test9",
                        TestValue8 = false,
                    },
                },
            })
            task.wait()
            expect(ConnectionsFired).to.equal(3)
            expect(TestSettings:GetSetting("TestValue1.TestValue2")).to.equal("Test7")
            expect(TestSettings:GetSetting("TestValue3.TestValue4.TestValue5")).to.equal("Test8")
            expect(TestSettings:GetSetting("TestValue3.TestValue4.TestValue7")).to.equal("Test9")
            expect(TestSettings:GetSetting("TestValue3.TestValue4.TestValue8")).to.equal(false)

            --Override some defaults and assert they are correct.
            TestSettings:SetSetting("TestValue1.TestValue2", "Test10")
            TestSettings:SetSetting("TestValue3.TestValue4.TestValue5", "Test11")
            TestSettings:SetSetting("TestValue3.TestValue4.TestValue7", "Test12")
            TestSettings:SetSetting("TestValue3.TestValue4.TestValue8", true)
            task.wait()
            expect(ConnectionsFired).to.equal(6)
            expect(TestSettings:GetSetting("TestValue1.TestValue2")).to.equal("Test10")
            expect(TestSettings:GetSetting("TestValue3.TestValue4.TestValue5")).to.equal("Test11")
            expect(TestSettings:GetSetting("TestValue3.TestValue4.TestValue7")).to.equal("Test12")
            expect(TestSettings:GetSetting("TestValue3.TestValue4.TestValue8")).to.equal(true)

            --Revert the settings and assert the defaults are used.
            TestSettings:SetSetting("TestValue1.TestValue2", nil)
            TestSettings:SetSetting("TestValue3.TestValue4.TestValue5", nil)
            TestSettings:SetSetting("TestValue3.TestValue4.TestValue7", nil)
            TestSettings:SetSetting("TestValue3.TestValue4.TestValue8", nil)
            expect(TestSettings:GetSetting("TestValue1.TestValue2")).to.equal("Test7")
            expect(TestSettings:GetSetting("TestValue3.TestValue4.TestValue5")).to.equal("Test8")
            expect(TestSettings:GetSetting("TestValue3.TestValue4.TestValue7")).to.equal("Test9")
            expect(TestSettings:GetSetting("TestValue3.TestValue4.TestValue8")).to.equal(false)
        end)

        it("should set override settings.", function()
            --Connect the events.
            local ConnectionsFired = 0
            TestSettings:GetSettingsChangedSignal("TestValue1.TestValue2"):Connect(function()
                ConnectionsFired = ConnectionsFired + 1
            end)
            TestSettings:GetSettingsChangedSignal("TestValue3.TestValue4.TestValue5"):Connect(function()
                ConnectionsFired = ConnectionsFired + 1
            end)
            TestSettings:GetSettingsChangedSignal("TestValue3.TestValue4.TestValue7"):Connect(function()
                ConnectionsFired = ConnectionsFired + 1
            end)

            --Set the overrides and assert the changed values are correct.
            TestSettings:SetOverrides({
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
            task.wait()
            expect(ConnectionsFired).to.equal(3)
            expect(TestSettings:GetSetting("TestValue1.TestValue2")).to.equal("Test7")
            expect(TestSettings:GetSetting("TestValue3.TestValue4.TestValue5")).to.equal("Test8")
            expect(TestSettings:GetSetting("TestValue3.TestValue4.TestValue7")).to.equal("Test9")
        end)

        it("should fire changed events.", function()
            --Connect the events.
            local ConnectionsFired = 0
            TestSettings:GetSettingsChangedSignal("TestValue1.TestValue2"):Connect(function()
                ConnectionsFired = ConnectionsFired + 1
            end)
            TestSettings:GetSettingsChangedSignal("TestValue3.TestValue4.TestValue5"):Connect(function()
                ConnectionsFired = ConnectionsFired + 1
            end)
            TestSettings:GetSettingsChangedSignal("TestValue3.TestValue4.TestValue7"):Connect(function()
                ConnectionsFired = ConnectionsFired + 1
            end)

            --Assert the fired connections are valid.
            TestSettings:SetSetting("TestValue1.TestValue2", "Test7")
            task.wait()
            expect(ConnectionsFired).to.equal(1)
            TestSettings:SetSetting("TestValue3.TestValue4.TestValue5", "Test8")
            task.wait()
            expect(ConnectionsFired).to.equal(2)
            TestSettings:SetSetting("TestValue3.TestValue4.TestValue7", "Test9")
            task.wait()
            expect(ConnectionsFired).to.equal(3)
        end)
    end)
end