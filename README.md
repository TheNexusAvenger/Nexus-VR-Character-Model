# Nexus-VR-Character-Model
Nexus VR Character Model replaces the default
controls and camera of R15 Roblox characters
and maps the character to the player's headset
and hand controllers.

## Menu
To access the menu, the left controller must be
rotated counter-clockwise and the right controller
must be rotated clockwise so that they are facing
each other or upwards while facing roughly forward.
This gesture is used to be out of the way of most
games.

## Limitations
* Optimizations for specific headsets and controllers
  can't be made because the hardware is not communicated
  to the developer. Some headsets, like the Valve Index,
  may perform poorly.
* R6 characters are not supported. R15 is recommended
  for new projects since R15 gets better support and
  has more functionality.
* Collisions may not act as expected.
* Roblox's Core GUIs are unable to be modified.
* The foot-planting code is old and could use a rewrite.
* The menu gesture is not obvious. Most players may
  not know about it.

# Setup
The repository can be synced into Roblox using
[Rojo](https://github.com/rojo-rbx/rojo), which
will include the [loader](NexusVRCharacterModelLoader.server.lua)
with the `MainModule`. If the loader contains
`MainModule`, it will load the `MainModule`.
Otherwise, the asset id `6052374981` will be
fetched. The behavior allows for automatic
updates while still allowing an easy way to use
static versions. The loader uploaded to the
website does not include the `MainModule`, so
it will default to fetching the latest version.

## [Nexus-VR-Core](https://github.com/thenexusAvenger/nexus-vr-core)
Nexus VR Core is used for user interfaces
in Nexus VR Character Model. When Nexus VR
Character Model is loaded, a module named
`NexusVRCore` will be loaded in `ReplicatedStorage`.
See Nexus VR Core's docs on how to use it
to make user interfaces that can be interacted
with by VR users.

## Contributing
Both issues and pull requests are accepted for this project.

## License
Nexus VR Character Model is available under the terms of the MIT 
License. See [LICENSE](LICENSE) for details.