--Passthrough of Nexus VR Core for Wally distribution.
--!strict

local NexusVRCore = require(script.Parent.Parent.Parent.Parent:WaitForChild("NexusVRCore"))

export type BaseScreenGui<T> = NexusVRCore.BaseScreenGui<T>
export type NexusInstanceBaseScreenGui<T> = NexusVRCore.NexusInstanceBaseScreenGui<T>
export type ScreenGui2D = NexusVRCore.ScreenGui2D
export type NexusInstanceScreenGui2D = NexusVRCore.NexusInstanceScreenGui2D
export type ScreenGui3D = NexusVRCore.ScreenGui3D
export type NexusInstanceScreenGui3D = NexusVRCore.NexusInstanceScreenGui3D

return NexusVRCore