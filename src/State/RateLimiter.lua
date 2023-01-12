--[[
TheNexusAvenger

Performs rate limit checks on inputs.
--]]
--!strict

local Players = game:GetService("Players")

local RateLimiter = {}
RateLimiter.__index = RateLimiter

export type RateLimiter = {
    new: (RateLimit: number?, RefrestDuration: number?) -> (RateLimiter),

    RateLimitReached: (self: RateLimiter, Key: any) -> (boolean),
}



--[[
Creates a rate limiter.
The rate limit must be >=1.
--]]
function RateLimiter.new(RateLimit: number?, RefrestDuration: number?): RateLimiter
    --Create the object.
    local self = {
        RateLimit = RateLimit or 1,
        RefrestDuration = RefrestDuration or 1,
        UsedLimits = {}
    }
    setmetatable(self, RateLimiter)

    --Connect removing player keys.
    Players.PlayerRemoving:Connect(function(Player: Player)
        if self.UsedLimits[Player] then
            self.UsedLimits[Player] = nil
        end
    end)

    --Return the object.
    return (self :: any) :: RateLimiter
end

--[[
Returns if the rate limit was reached
for a given key.
--]]
function RateLimiter:RateLimitReached(Key: any): boolean
    --Add the key if it isn't defined.
    if not self.UsedLimits[Key] then
        self.UsedLimits[Key] = {
            StartTime = tick(),
            Count = 0,
        }
    end

    --Reset the key if the refresh time was reached.
    local StoredKey = self.UsedLimits[Key]
    local CurrentTime = tick()
    if CurrentTime > StoredKey.StartTime + self.RefrestDuration then
        StoredKey.StartTime = CurrentTime
        StoredKey.Count = 0
    end

    --Increment the counter and return if the limit was reached.
    StoredKey.Count = StoredKey.Count + 1
    return StoredKey.Count > self.RateLimit
end



return (RateLimiter :: any) :: RateLimiter