--[[
TheNexusAvenger

Manages VR characters.
--]]

local Players = game:GetService("Players")

local NexusVRCharacterModel = require(script.Parent.Parent)
local NexusObject = NexusVRCharacterModel:GetResource("NexusInstance.NexusObject")
local Character = NexusVRCharacterModel:GetResource("Character")

local CharacterService = NexusObject:Extend()
CharacterService:SetClassName("CharacterService")



--[[
Creates a character service.
--]]
function CharacterService:__new()
    self:InitializeSuper()
    self.Characters = {}

    --Connect clearing players.
    Players.PlayerRemoving:Connect(function(Player)
        self.Characters[Player] = nil
    end)
end

--[[
Returns the VR character for a player.
--]]
function CharacterService:GetCharacter(Player)
    --Return if the character is nil.
    if not Player.Character then
        return
    end

    --Create the VR character if it isn't valid.
    if not self.Characters[Player] or self.Characters[Player].Character ~= Player.Character then
        self.Characters[Player] = {
            Character = Player.Character,
            VRCharacter = Character.new(Player.Character),
        }
    end

    --Return the stored character.
    return self.Characters[Player].VRCharacter
end



return CharacterService