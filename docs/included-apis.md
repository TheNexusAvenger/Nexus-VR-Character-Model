# Included APIs
This document covers APIs that are publicly usable for
interacting with Nexus VR Character Model.

## Avoid Using The APIs Unless Needed
In certain cases, there may be possible calls that can
be made to the Nexus VR Character Model API that have
general solutions that work for VR and non-VR players.
Setting the character's `Humanoid.WalkSpeed` to `0` is
a more general version than calling `SetControllerInputEnabled`
in the `Controller` API for the left and right hand.
Depending on the API call, this may require more work
to maintain long-term if VR and non-VR players are together.
In addition, relying on the API makes it harder to switch
from Nexus VR Character Model if a new project were
to exist.

## Referencing APIs
All supported APIs can be found in the `Api` table
in the main module.
```lua
local NexusVRCharacterModel = require(game:GetService("ReplicatedStorage"):WaitForChild("NexusVRCharacterModel"))
local CameraApi = NexusVRCharacterModel.Api:WaitFor("Camera") --Example getting the Camera API using WaitFor.
local CameraApi = NexusVRCharacterModel.Api.Camera --Example getting the Camera API using direct indexing.
```

Along with referencing the APIs, there are included
helper functions.

### `Api.Registered: CustomEvent`
Event for when an API is registered. The name of the API
is passed as the parameter.

### `Api:Register(ApiName: string, Api: any): nil`
Stores an API that can be referenced. If the API is
already stored, an error will be thrown.

### `Api:WaitFor(ApiName: string): any`
Waits for an API to be registered and returns the API.
If it was already registered, it returns the API
without waiting. Similar to instances, this would
be treated like `WaitForChild` where the usage is
optional instead of indexing (ex: `API:WaitFor("MyApi")
vs `API.MyApi`) as long as the consequences of an API not
being registered are accepted.

### `Api:OnRegistered(ApiName: string, RegisteredCallback: (any) -> ()): nil`
Invokes a callback when an API is registered with a given
name. If it is already registered, the callback will run
asynchronously. This is intended for setting up an API
call without blocking for `WaitFor`.

## `Camera` API
### `Camera:SetActiveCamera(Name: string): nil`
Sets the active camera. Invalid names will not throw an
error and will output a warning instead.

### `Camera:GetActiveCamera(): string`
Returns the name of the camera that is active.

## `Controller` API
### `Controller:SetActiveController(Name: string): nil`
Sets the active camera. Invalid names will not throw an
error and will output a warning instead.

### `Controller:GetActiveController(): string`
Returns the name of the camera that is active.

### `Controller:SetControllerInputEnabled(Hand: Enum.UserCFrame, Enabled: boolean): nil`
Enables or disables user inputs for the given hand
CFrame, including movement, teleporting, and turning.
Invalid `UserCFrame`s (`UserCFrame.Head`) will throw
an error.

### `Controller:EnableControllerInput(Hand: Enum.UserCFrame): nil`
Simple wrapper for `SetControllerInputEnabled(UserCFrame, true)`.

### `Controller:DisableControllerInput(Hand: Enum.UserCFrame): nil`
Simple wrapper for `SetControllerInputEnabled(UserCFrame, false)`.

### `Controller:IsControllerInputEnabled(Hand: Enum.UserCFrame): boolean`
Returns if the inputs for a given hand are enabled.
Invalid `UserCFrame`s (`UserCFrame.Head`) will throw
an error.

## `Input` API
### `Input:Recenter(): nil`
Recenters the service. Does not alter the Y axis.

### `Input:SetEyeLevel(): nil`
Sets the eye level.

### `Input.Recentered: CustomEvent`
Event fired when the custom recenter function is called.

### `Input.EyeLevelSet: CustomEvent`
Event fired when the eye level set function is called.

## `Menu` API
### `Menu.Enabled: boolean`
If `true`, the menu is enabled and the other API functions
can be called. Otherwise, errors will occur when calling the
other Menu API functions.

### `Menu:IsOpen(): boolean`
Returns if the menu is visible.

### `Menu:Open(): nil`
Opens the menu. Does nothing if the menu is already open.

### `Menu:Close(): nil`
Closes the menu. Does nothing if the menu is not open.

### `Menu:CreateView(InitialName: string): MenuView`
Creates and adds a page to the menu. The initial name is
the name that will appear to the user sees the view.
The `MenuView` has the following APIs:
- `MenuView.Name: string` - Name of the view. Can be
  changed at any time.
- `MenuView.Visible: boolean [ReadOnly]` - Whether the
  view is currently focused in the menu. It is only
  intended to be read from.
- `MenuView:GetContainer(): Frame` - Returns the container
  frame used for the view. The size should *not* be assumed
  to be fixed.
- `MenuView:AddBackground(): nil` - Adds the standard
  background to the view.
- `MenuView:Destroy(): nil` - Destroys the view and removes
  it from the menu.

## `Settings` API
### `Settings:GetSetting(Setting: string): any`
Returns the value of a setting.

### `Settings:SetSetting(Setting: string, Value: any): nil`
Sets the value of a setting. Not all settings support
being changed after loading, like `"Extra.NexusVRBackpackEnabled"`.
Calling this may not have the desired effect.

### `Settings:GetSettingsChangedSignal(SettingName: string): CustomEvent`
Returns an event that is invoked when the value of a
setting is changed.