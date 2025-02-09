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
  to the developer. Some headsets, like the HP Reverb G2,
  may perform poorly.
* R6 characters are not supported. R15 is recommended
  for new projects since R15 gets better support and
  has more functionality.
* The foot-planting code is old and could use a rewrite.
* The menu gesture is not obvious. Most players may
  not know about it.
* `VRService.AvatarGestures` support is incomplete.
  * `ThirdPersonTrack` camera does not work and the camera
    setting is restricted.
  * [Crouching is not supported.](https://devforum.roblox.com/t/vrserviceavatargestures-to-allow-for-vr-crouching/3266565)
  * [Teleporting players is broken with no workaround.](https://devforum.roblox.com/t/animating-your-avatar-in-vr/2954399/9)
  * Rolling the camera with a seat (ex: rollercoaster,
    plane) is not supported.
  * Setting the eye level is unsupported  outside of
    recentering, and the internal recenter APIs don't
    work.
  * The hands might not reach the controller's hands
    due to not being able to disconnect the arms.

## Setup
The repository can be synced into Roblox using
[Rojo](https://github.com/rojo-rbx/rojo), which
will include the [loader](NexusVRCharacterModelLoader.server.lua)
with the `MainModule`. If the loader contains
`MainModule`, it will load the `MainModule`.
Otherwise, the asset id `10728814921` will be
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

## API
See [included-apis.md](docs/included-apis.md) for the APIs
that can be referenced.

## Contributing
Both issues and pull requests are accepted for this project.

## License
Nexus VR Character Model is available under the terms of the MIT 
License. See [LICENSE](LICENSE) for details.