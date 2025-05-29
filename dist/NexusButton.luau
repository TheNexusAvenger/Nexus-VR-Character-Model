--Passthrough of Nexus Button for Wally distribution.
--!strict

local NexusButton = require(script.Parent.Parent.Parent.Parent:WaitForChild("NexusButton"))

export type ButtonFactory = NexusButton.ButtonFactory 
export type TextButtonFactory = NexusButton.TextButtonFactory 
export type NexusButton = NexusButton.NexusButton 
export type NexusInstanceNexusButton = NexusButton.NexusInstanceNexusButton 
export type ControllerIcon = NexusButton.ControllerIcon 
export type NexusInstanceControllerIcon = NexusButton.NexusInstanceControllerIcon 
export type ThemedFrame = NexusButton.ThemedFrame 
export type NexusInstanceThemedFrame = NexusButton.NexusInstanceThemedFrame 

return NexusButton