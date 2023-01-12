--[[
TheNexusAvenger

Tests the RateLimiter class.
--]]
--!strict

local NexusVRCharacterModel = game:GetService("ServerScriptService"):WaitForChild("NexusVRCharacterModelLoader"):WaitForChild("MainModule"):WaitForChild("NexusVRCharacterModel")
local RateLimiter = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("RateLimiter"))

return function()
    describe("A rate limiter", function()
        it("should limit requests", function()
            local TestRateLimiter = RateLimiter.new(5, 0.1)

            --Assert that rate limit is reached.
            for _ = 1, 5 do
                expect(TestRateLimiter:RateLimitReached("Test1")).to.equal(false)
            end
            expect(TestRateLimiter:RateLimitReached("Test2")).to.equal(false)
            expect(TestRateLimiter:RateLimitReached("Test1")).to.equal(true)
            expect(TestRateLimiter:RateLimitReached("Test2")).to.equal(false)

            --Wait to refresh and assert that the rate limit is reached.
            task.wait(0.2)
            for _ = 1, 5 do
                expect(TestRateLimiter:RateLimitReached("Test1")).to.equal(false)
            end
            for _ = 1, 5 do
                expect(TestRateLimiter:RateLimitReached("Test2")).to.equal(false)
            end
            expect(TestRateLimiter:RateLimitReached("Test1")).to.equal(true)
            expect(TestRateLimiter:RateLimitReached("Test2")).to.equal(true)
        end)
    end)
end