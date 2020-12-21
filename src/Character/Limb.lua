--[[
TheNexusAvenger

Base class for a limb.
--]]

local NexusVRCharacterModel = require(script.Parent.Parent)
local NexusObject = NexusVRCharacterModel:GetResource("NexusInstance.NexusObject")

local Limb = NexusObject:Extend()
Limb:SetClassName("Limb")



--[[
Returns the CFrame of an attachment.
Returns an empty CFrame if the attachment
does not exist.
--]]
function Limb:GetAttachmentCFrame(Part,AttachmentName)
    local Attachment = Part:FindFirstChild(AttachmentName)
    return Attachment and Attachment.CFrame or CFrame.new()
end



return Limb