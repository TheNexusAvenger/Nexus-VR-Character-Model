--Passthrough of Nexus Instance for Wally distribution.
--!strict

local NexusInstance = require(script.Parent.Parent.Parent.Parent:WaitForChild("NexusInstance"))

export type TypedEvent<T...> = NexusInstance.TypedEvent<T...>
export type NexusInstanceClass<TClass, TConstructor> = NexusInstance.NexusInstanceClass<TClass, TConstructor>
export type NexusInstance<TObject> = NexusInstance.NexusInstance<TObject>

return NexusInstance