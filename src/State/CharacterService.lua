--[[
TheNexusAvenger

Manages VR characters.
--]]
--!strict

local Players = game:GetService("Players")

local NexusVRCharacterModel = script.Parent.Parent
local Character = require(NexusVRCharacterModel:WaitForChild("Character"))

local CharacterService = {}
CharacterService.__index = CharacterService
local StaticInstance = nil

export type CharacterService = {
    new: () -> (CharacterService),
    GetInstance: () -> (CharacterService),

    GetCharacter: (self: CharacterService, Player: Player) -> (Character.Character?),
}



--[[
Creates a character service.
--]]
function CharacterService.new(): CharacterService
    --Create the object.
    local self = {
        Characters = {},
    }
    setmetatable(self, CharacterService)

    --Connect clearing players.
    Players.PlayerRemoving:Connect(function(Player)
        self.Characters[Player] = nil
    end)

    --Return the object.
    return (self :: any) :: CharacterService
end

--[[
Returns a singleton instance of the character service.
--]]
function CharacterService.GetInstance(): CharacterService
    if not StaticInstance then
        StaticInstance = CharacterService.new()
    end
    return StaticInstance
end

--[[
Returns the VR character for a player.
--]]
function CharacterService:GetCharacter(Player: Player): Character.Character?
    --Return if the character is nil.
    if not Player.Character then
        return nil
    end

    --Create the VR character if it isn't valid.
    if not self.Characters[Player] or self.Characters[Player].Character ~= Player.Character then
        self.Characters[Player] = {
            Character = Player.Character,
            VRCharacter = Character.new(Player.Character :: Model),
        }
    end

    --Return the stored character.
    return self.Characters[Player].VRCharacter
end



return (CharacterService :: any) :: CharacterService