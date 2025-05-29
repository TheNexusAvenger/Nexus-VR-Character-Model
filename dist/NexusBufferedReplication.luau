--Passthrough of Nexus Buffered Replication for Wally distribution.
--!strict

local NexusBufferedReplication = require(script.Parent.Parent.Parent.Parent:WaitForChild("NexusBufferedReplication"))

export type BufferedRemoteEventReceiver<TKey, TData> = NexusBufferedReplication.BufferedRemoteEventReceiver<TKey, TData>
export type PlayerBufferedRemoteEventReceiver<TData> = NexusBufferedReplication.PlayerBufferedRemoteEventReceiver<TData>
export type BufferedRemoteEvent = NexusBufferedReplication.BufferedRemoteEvent
export type BufferedRemoteEventSender<TKey, TData> = NexusBufferedReplication.BufferedRemoteEventSender<TKey, TData>
export type EnrollableRemoteEvent = NexusBufferedReplication.EnrollableRemoteEvent

return NexusBufferedReplication