--[[
TheNexusAvenger

Base class for a limb.
--]]
--!strict

local Limb = {}
Limb.__index = Limb



--[[
Creates a limb object.
--]]
function Limb.new(): any
    return setmetatable({}, Limb)
end

--[[
Returns the CFrame of an attachment.
Returns an empty CFrame if the attachment
does not exist.
--]]
function Limb:GetAttachmentCFrame(Part: BasePart, AttachmentName: string): CFrame
    local Attachment = Part:FindFirstChild(AttachmentName)
    return Attachment and (Attachment :: Attachment).CFrame or CFrame.new()
end



return Limb