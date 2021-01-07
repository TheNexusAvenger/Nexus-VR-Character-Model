--[[
TheNexusAvenger

Performs rate limit checks on inputs.
--]]

local Players = game:GetService("Players")

local NexusVRCharacterModel = require(script.Parent.Parent)
local NexusObject = NexusVRCharacterModel:GetResource("NexusInstance.NexusObject")

local RateLimiter = NexusObject:Extend()
RateLimiter:SetClassName("RateLimiter")



--[[
Creates a rate limiter.
The rate limit must be >=1.
--]]
function RateLimiter:__new(RateLimit,RefrestDuration)
    self:InitializeSuper()
    self.RateLimit = RateLimit or 1
    self.UsedLimits = {}
    self.RefrestDuration = RefrestDuration or 1

    --Connect removing player keys.
    Players.PlayerRemoving:Connect(function(Player)
        if self.UsedLimits[Player] then
            self.UsedLimits[Player] = nil
        end
    end)
end

--[[
Returns if the rate limit was reached
for a given key.
--]]
function RateLimiter:RateLimitReached(Key)
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



return RateLimiter