--[[
TheNexusAvenger

Tests the RateLimiter class.
--]]

local NexusUnitTesting = require("NexusUnitTesting")
local ServerScriptService = game:GetService("ServerScriptService")

local NexusVRCharacterModel = require(ServerScriptService:WaitForChild("NexusVRCharacterModelLoader"):WaitForChild("MainModule"))
local RateLimiter = NexusVRCharacterModel:GetResource("State.RateLimiter")
local RateLimiterTest = NexusUnitTesting.UnitTest:Extend()



--[[
Sets up the test.
--]]
function RateLimiterTest:Setup()
    self.CuT = RateLimiter.new(5,0.1)
end

--[[
Tears down the test.
--]]
function RateLimiterTest:Teardown()
    NexusVRCharacterModel:ClearInstances()
end

--[[
Tests the RateLimitReached method.
--]]
NexusUnitTesting:RegisterUnitTest(RateLimiterTest.new("RateLimitReached"):SetRun(function(self)
    --Assert that rate limit is reached.
    for _ = 1,5 do
        self:AssertFalse(self.CuT:RateLimitReached("Test1"))
    end
    self:AssertFalse(self.CuT:RateLimitReached("Test2"))
    self:AssertTrue(self.CuT:RateLimitReached("Test1"))
    self:AssertFalse(self.CuT:RateLimitReached("Test2"))

    --Wait to refresh and assert that the rate limit is reached.
    wait(0.2)
    for _ = 1,5 do
        self:AssertFalse(self.CuT:RateLimitReached("Test1"))
    end
    for _ = 1,5 do
        self:AssertFalse(self.CuT:RateLimitReached("Test2"))
    end
    self:AssertTrue(self.CuT:RateLimitReached("Test1"))
    self:AssertTrue(self.CuT:RateLimitReached("Test2"))
end))



return true