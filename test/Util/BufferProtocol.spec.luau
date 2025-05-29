--Tests the BufferProtocol class.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BufferProtocol = require(ReplicatedStorage.Packages.NexusVRCharacterModel.NexusVRCharacterModel.Util.BufferProtocol)

return function()
    describe("The buffer protocol", function()
        it("should serialize data.", function()
            local Buffer = BufferProtocol.Serialize({
                UpdateTime = 123,
                CurrentWalkspeed = 456,
                HeadCFrame = CFrame.new(1, 2, 3),
                LeftFootCFrame = CFrame.new(4, 5, 6),
            })

            expect(buffer.len(Buffer)).to.equal(1 + 4 + 8 + 8 + (7 * 4) + (7 * 4))
            expect(buffer.readi8(Buffer, 0)).to.equal(4)
            expect(buffer.readi8(Buffer, 1)).to.equal(1)
            expect(buffer.readf64(Buffer, 2)).to.equal(123)
            expect(buffer.readi8(Buffer, 10)).to.equal(2)
            expect(buffer.readf64(Buffer, 11)).to.equal(456)
            expect(buffer.readi8(Buffer, 19)).to.equal(3)
            expect(buffer.readf32(Buffer, 20)).to.equal(1)
            expect(buffer.readf32(Buffer, 24)).to.equal(2)
            expect(buffer.readf32(Buffer, 28)).to.equal(3)
            expect(buffer.readi8(Buffer, 48)).to.equal(6)
            expect(buffer.readf32(Buffer, 49)).to.equal(4)
            expect(buffer.readf32(Buffer, 53)).to.equal(5)
            expect(buffer.readf32(Buffer, 57)).to.equal(6)
        end)

        it("should deserialize a section of data.", function()
            local Buffer = buffer.create(8 + 1 + 4 + 8 + 8 + (7 * 4) + (7 * 4))
            buffer.writef64(Buffer, 0, 12345)
            buffer.writei8(Buffer, 8, 4)
            --HeadCFrame
            buffer.writei8(Buffer, 9, 3)
            buffer.writef32(Buffer, 10, 1)
            buffer.writef32(Buffer, 14, 2)
            buffer.writef32(Buffer, 18, 3)
            --UpdateTime
            buffer.writei8(Buffer, 38, 1)
            buffer.writef64(Buffer, 39, 123)
            --CurrentWalkspeed
            buffer.writei8(Buffer, 47, 2)
            buffer.writef64(Buffer, 48, 456)
            --LeftFootCFrame
            buffer.writei8(Buffer, 56, 6)
            buffer.writef32(Buffer, 57, 4)
            buffer.writef32(Buffer, 61, 5)
            buffer.writef32(Buffer, 65, 6)

            local Data, DataLength = BufferProtocol.DeserializeSection(Buffer, 8)
            expect(Data.UpdateTime).to.equal(123)
            expect(Data.CurrentWalkspeed).to.equal(456)
            expect(Data.HeadCFrame.X).to.equal(1)
            expect(Data.HeadCFrame.Y).to.equal(2)
            expect(Data.HeadCFrame.Z).to.equal(3)
            local LeftFootCFrame = (Data.LeftFootCFrame :: CFrame)
            expect(LeftFootCFrame.X).to.equal(4)
            expect(LeftFootCFrame.Y).to.equal(5)
            expect(LeftFootCFrame.Z).to.equal(6)
            expect(DataLength).to.equal(1 + 4 + 8 + 8 + (7 * 4) + (7 * 4))
        end)

        it("should dserialize player data.", function()
            local Buffer = buffer.create(2 * (8 + 1 + 2 + 8 + 8))
            buffer.writef64(Buffer, 0, 12345)
            buffer.writei8(Buffer, 8, 2)
            buffer.writei8(Buffer, 9, 1)
            buffer.writef64(Buffer, 10, 123)
            buffer.writei8(Buffer, 18, 2)
            buffer.writef64(Buffer, 19, 234)
            buffer.writef64(Buffer, 27, 23456)
            buffer.writei8(Buffer, 35, 2)
            buffer.writei8(Buffer, 36, 1)
            buffer.writef64(Buffer, 37, 345)
            buffer.writei8(Buffer, 45, 2)
            buffer.writef64(Buffer, 46, 456)
        
            local Data = BufferProtocol.Deserialize(Buffer)
            expect(Data[12345].UpdateTime).to.equal(123)
            expect(Data[12345].CurrentWalkspeed).to.equal(234)
            expect(Data[23456].UpdateTime).to.equal(345)
            expect(Data[23456].CurrentWalkspeed).to.equal(456)
        end)
    end)
end