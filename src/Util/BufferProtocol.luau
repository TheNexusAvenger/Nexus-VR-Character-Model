--Serializes and deserializes buffers for Nexus Buffered Replication.
--!strict

local BUFFER_PROTOCOL_FIELDS = {
    --Normal.
    {
        Name = "UpdateTime",
        Type = "number",
    },
    {
        Name = "CurrentWalkspeed",
        Type = "number",
    },
    {
        Name = "HeadCFrame",
        Type = "CFrame",
    },
    {
        Name = "LeftHandCFrame",
        Type = "CFrame",
    },
    {
        Name = "RightHandCFrame",
        Type = "CFrame",
    },

    --Enigma.
    {
        Name = "LeftFootCFrame",
        Type = "CFrame",
    },
    {
        Name = "RightFootCFrame",
        Type = "CFrame",
    },
}
local FIELD_TYPE_TO_LENGTH = {
    ["number"] = 8,
    ["CFrame"] = 7 * 4,
}

local BufferProtocol = {}

export type BufferProtocolData = {
    --Normal.
    UpdateTime: number,
    CurrentWalkspeed: number?,
    HeadCFrame: CFrame,
    LeftHandCFrame: CFrame?,
    RightHandCFrame: CFrame?,
    
    --Enigma.
    LeftFootCFrame: CFrame?,
    RightFootCFrame: CFrame?,
}



--[[
Serializes a request to a buffer.
--]]
function BufferProtocol.Serialize(Data: BufferProtocolData): buffer
    --Determine the fields to write.
    local FieldsToSerialize = {}
    local SerializedLength = 1
    for i, FieldData in BUFFER_PROTOCOL_FIELDS do
        local FieldValue = Data[FieldData.Name]
        if not FieldValue or typeof(FieldValue) ~= FieldData.Type then continue end
        local FieldLength = FIELD_TYPE_TO_LENGTH[FieldData.Type]
        SerializedLength += 1 + FIELD_TYPE_TO_LENGTH[FieldData.Type]
        table.insert(FieldsToSerialize, {
            Index = i,
            Length = FieldLength,
            Data = FieldValue,
        })
    end

    --Write the fields.
    local Buffer = buffer.create(SerializedLength)
    local Offset = 1
    buffer.writei8(Buffer, 0, #FieldsToSerialize)
    for _, Field in FieldsToSerialize do
        --Write the field type.
        buffer.writei8(Buffer, Offset, Field.Index)
        Offset += 1

        --Write the field data.
        local FieldValue = Field.Data
        local FieldType = typeof(FieldValue)
        if FieldType == "number" then
            buffer.writef64(Buffer, Offset, FieldValue)
        elseif FieldType == "CFrame" then
            local Position = FieldValue.Position
            local AxisAngleVector3, AxisAngleRotation = FieldValue:ToAxisAngle()
            buffer.writef32(Buffer, Offset, Position.X)
            buffer.writef32(Buffer, Offset + 4, Position.Y)
            buffer.writef32(Buffer, Offset + 8, Position.Z)
            buffer.writef32(Buffer, Offset + 12, AxisAngleVector3.X)
            buffer.writef32(Buffer, Offset + 16, AxisAngleVector3.Y)
            buffer.writef32(Buffer, Offset + 20, AxisAngleVector3.Z)
            buffer.writef32(Buffer, Offset + 24, AxisAngleRotation)
        end
        Offset += Field.Length
    end
    return Buffer
end

--[[
Deserializes a section of a buffer.
--]]
function BufferProtocol.DeserializeSection(Buffer: buffer, StartOffset: number): (BufferProtocolData, number)
    local Data = {} :: BufferProtocolData
    local InitialOffset = StartOffset
    local TotalFields = buffer.readi8(Buffer, StartOffset)
    StartOffset += 1
    for i = 1, TotalFields do
        local FieldData = BUFFER_PROTOCOL_FIELDS[buffer.readi8(Buffer, StartOffset)]
        StartOffset += 1
        if FieldData.Type == "number" then
            Data[FieldData.Name] = buffer.readf64(Buffer, StartOffset)
            StartOffset += 8
        elseif FieldData.Type == "CFrame" then
            local Position = CFrame.new(buffer.readf32(Buffer, StartOffset), buffer.readf32(Buffer, StartOffset + 4), buffer.readf32(Buffer, StartOffset + 8))
            local AxisAngleVector3, AxisAngleRotation = Vector3.new(buffer.readf32(Buffer, StartOffset + 12), buffer.readf32(Buffer, StartOffset + 16), buffer.readf32(Buffer, StartOffset + 20)), buffer.readf32(Buffer, StartOffset + 24)
            Data[FieldData.Name] = Position * CFrame.fromAxisAngle(AxisAngleVector3, AxisAngleRotation)
            StartOffset += 7 * 4
        end
    end
    return Data, StartOffset - InitialOffset
end

--[[
Deserializess data for players.
--]]
function BufferProtocol.Deserialize(Buffer: buffer): {[number]: BufferProtocolData}
    local BufferLength = buffer.len(Buffer)
    local CurrentIndex = 0
    local Data = {}
    while CurrentIndex < BufferLength do
        local UserId = buffer.readf64(Buffer, CurrentIndex)
        CurrentIndex += 8
        local PlayerData, DataRead = BufferProtocol.DeserializeSection(Buffer, CurrentIndex)
        Data[UserId] = PlayerData
        CurrentIndex += DataRead
    end
    return Data
end



return BufferProtocol