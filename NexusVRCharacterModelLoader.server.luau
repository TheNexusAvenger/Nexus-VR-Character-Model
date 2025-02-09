--Loads Nexus VR Character Model.
--GitHub: TheNexusAvenger/Nexus-VR-Character-Model

local Configuration = {
    Appearance = {
        --Transparency of the character when in first person.
        LocalCharacterTransparency = 0.5,

        --If true, arms will be allowed to disconnect.
        --Recommended to be true locally so that the controllers match the hands,
        --and false for other players so that arms appear normal.
        --Has no effect if VRService.AvatarGestures is active.
        LocalAllowArmDisconnection = true,
        NonLocalAllowArmDisconnection = true,

        --Maximum angle the neck can turn before the torso turns.
        --Has no effect if VRService.AvatarGestures is active.
        MaxNeckRotation = math.rad(35),
        MaxNeckSeatedRotation = math.rad(60),

        --Maximum angle the neck can tilt before the torso tilts.
        --Has no effect if VRService.AvatarGestures is active.
        MaxNeckTilt = math.rad(60),

        --Maximum angle the center of the torso can bend.
        --Has no effect if VRService.AvatarGestures is active.
        MaxTorsoBend = math.rad(10),
    },
    Camera = {
        --Options for the camera that can be enabled by the user.
        EnabledCameraOptions = {
            "Default",
            "ThirdPersonTrack",
            --"Disabled", --Behavior depends on Workspace.CurrentCamera.HeadLocked! When false, the camera will not move. When true, the camera will move with the headset.
        },

        --Default camera option.
        DefaultCameraOption = "Default",

        --If true, Workspace.CurrentCamera.HeadLocked will be locked to false.
        --A Roblox engineer requested keeping HeadLocked on (DisableHeadLocked = false). To keep backwards compatibility, this defaults to true.
        --Has no effect if VRService.AvatarGestures is active.
        DisableHeadLocked = false,

        --Disables FadeOutViewOnCollision (black screen when in parts).
        --This is provided as a workaround for games where this is a problem. Only enable if players are complaining.
        DisableFadeOutViewOnCollision = false,
    },
    Movement = {
        --Movement methods that can be enabled by the user.
        EnabledMovementMethods = {
            "Teleport",
            "SmoothLocomotion",
            --"None", --Disables controls but still allows character updates. Intended for stationary games or momentarily freezing players.
        },

        --Default movement method.
        DefaultMovementMethod = "SmoothLocomotion",

        --Blur effect for snap turning and teleports.
        SnapTeleportBlur = true,
    },
    Menu = {
        --If true, a gesture will be active for opening
        --the Nexus VR Character Model menu. If you manually
        --set this to false, you will lock players from being
        --able to change camera options, movement options,
        --recallibration, and chat.
        MenuToggleGestureActive = true,
    },
    Output = {
        --To suppress warnings from Nexus VR Character Model
        --where supported (missing configuration entries),
        --the names of the warnings can be added here.
        --Add "All" to suppress all warnings.
        SuppressWarnings = {},

        --If true, clients can check the client output to see
        --if Nexus VR Character Model is loaded. In order for
        --the message to appear, the client must hold down Ctrl
        --(left or right) when opening the F9 developer console.
        AllowClientToOutputLoadedMessage = true,
    },
    Extra = {
        --If true, Nexus VR Backpack (https://github.com/TheNexusAvenger/Nexus-VR-Backpack)
        --will be inserted into the game and loaded. This replaces
        --the default Roblox backpack.
        NexusVRBackpackEnabled = true,

        --If true, version information will be hidden on the client.
        --Version information may be detectable based on behavior, or by exploiters decompiling
        --the client code.
        HideVersion = false,

        --If true, Enigma (https://github.com/TheNexusAvenger/Enigma) will be enabled
        --to allow players to use additional SteamVR trackers.
        --It is only recommended to disable if this causes problems, and said problems
        --can't be addressed.
        EnigmaEnabled = true,

        --If true, Nexus-Appendage with IKControl will be used.
        --Workspace.IKControlConstraintSupport MUST NOT be set to Disabled for proper results.
        --This will be set to true if physics-based joints are enabled.
        TEMPORARY_UseIKControl = false,
    },
}



--Load the Nexus VR Character Model module.
local NexusVRCharacterModelModule
local MainModule = script:FindFirstChild("MainModule")
if MainModule then
    NexusVRCharacterModelModule = require(MainModule)
else
    NexusVRCharacterModelModule = require(10728814921)
end

--Load Nexus VR Character Model.
NexusVRCharacterModelModule:SetConfiguration(Configuration)
NexusVRCharacterModelModule:Load()
