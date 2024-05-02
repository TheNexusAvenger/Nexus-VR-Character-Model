⚠️ Nexus VR Character Model V.3 is in preview. It should **NOT** be used in production games yet.

# V.3 Migration
Nexus VR Character Model is changing the character movement and replication
to the new [VRService.AvatarGestures](https://devforum.roblox.com/t/animating-your-avatar-in-vr/2954399/).
This move drastically improves compatibility and makes transitioning away
from Nexus VR Character Model easier.

While at first it seems this like a good time to remove Nexus VR Character Model,
you may want to keep it if:
- You want to keep teleport controls as an option.
- You want Nexus VR Backpack's loader included.
  - Note: [Nexus VR Backpack can be loaded without Nexus VR Character Model](https://github.com/TheNexusAvenger/Nexus-VR-Backpack?tab=readme-ov-file#manual).
- You want characters + accesories to be transparent.
- You want the menu.
- You use any of the existing APIs and can't easily remove them yet.

## Loader Changes
In order to load the preview, you must change the module that loads in
from `10728814921` to `10728816434`. You can optionally remove the following
options from the loader:
- `Character.LocalAllowArmDisconnection` (no longer supported)
- `Character.NonLocalAllowArmDisconnection` (no longer supported)
- `Character.MaxNeckRotation` (managed by Roblox)
- `Character.MaxNeckSeatedRotation` (managed by Roblox)
- `Character.MaxNeckTilt` (managed by Roblox)
- `Character.MaxTorsoBend` (managed by Roblox)
- `Extra.TEMPORARY_UseIKControl` (managed by Roblox)

At the moment, `Camera.EnabledCameraOptions`, `Camera.DefaultCameraOption`, and
`Camera.DisableHeadLocked` are unused, but may become supported in a future
preview release. Help for implementing the cameras would be appreciated (see
the limitations section for why custom cameras may still make sense).

## API Changes
For now, no APIs are removed, but the `Input` and `Camera` APIs are non-functional
due to custom cameras not being implemented. Be aware any APIs exposed but not documented
are not supported and may be abruptly removed.

There were 2 `RemoteEvent`s that handled replication. Both have been removed,
and should not have been used outside of Nexus VR Character Model.

## Known Issues/Limitations
### Roblox Limitations
- [Teleporting characters is broken](https://devforum.roblox.com/t/animating-your-avatar-in-vr/2954399/9)
  as of Roblox release 623. Smooth locomotion is recommended for now, and other
  character teleports (like elevator, teleporters, or custom spawns) may not work
  as expected.
- [Crouching is not supported.](https://devforum.roblox.com/t/animating-your-avatar-in-vr/2954399/28)
- It is possible for hands to not extend up to the controller. This is due to
  Roblox prioritizing arms being connected over matching the hand placement.
- Depending on how Roblox is opened, it is easy for the camera to be stuck far
  above the head of the character.

### Preview Limitations
- Custom cameras are not supported and the menu option is hidden. The third-person
  preview meant for recording and the ability to go upside-down in first-person
  are not possible right now.
- Recentering and setting the eye level are disabled. Their implementation depends
  on how the cameras are implemented. However, it is probably that they will be
  combined into a single Recneter button using [`VRService:RecenterUserHeadCFrame()`](https://create.roblox.com/docs/reference/engine/classes/VRService#RecenterUserHeadCFrame).

## Full Release Timeline
There is no current timeline for V.3's release. The goal is to get the preview
limitations sorted out and for the Roblox limitations due to bugs off the list.
V.3 will probably be in a preview for a couple of months.