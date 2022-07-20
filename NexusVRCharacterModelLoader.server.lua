--[[
TheNexusAvenger

Loads Nexus VR Character Model.
GitHub: TheNexusAvenger/Nexus-VR-Character-Model
--]]

local Configuration = {
    Appearance = {
        --Transparency of the character when in first person.
        LocalCharacterTransparency = 0.5,

        --If true, arms will be allowed to disconnect.
        --Recommended to be true locally so that the controllers match the hands,
        --and false for other players so that arms appear normal.
        LocalAllowArmDisconnection = true,
        NonLocalAllowArmDisconnection = true,

        --Maximum angle the neck can turn before the torso turns.
        MaxNeckRotation = math.rad(35),
        MaxNeckSeatedRotation = math.rad(60),

        --Maximum angle the neck can tilt before the torso tilts.
        MaxNeckTilt = math.rad(60),

        --Maximum angle the center of the torso can bend.
        MaxTorsoBend = math.rad(10),
    },
    Camera = {
        --Options for the camera that can be enabled by the user.
        EnabledCameraOptions = {
            "Default",
            "ThirdPersonTrack",
        },

        --Default camera option.
        DefaultCameraOption = "Default",
    },
    Movement = {
        --Movement methods that can be enabled by the user.
        EnabledMovementMethods = {
            "Teleport",
            "SmoothLocomotion",
            --"None", --Disables controls but still allows character updates. Intended for stationay games or momentarily freezing players.
        },

        --Default movement method.
        DefaultMovementMethod = "Teleport",

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
}



--Load the Nexus VR Character Model module.
local NexusVRCharacterModelModule
local MainModule = script:FindFirstChild("MainModule")
if MainModule then
    NexusVRCharacterModelModule = require(MainModule)
else
    NexusVRCharacterModelModule = require(6052374981)
end

--Load Nexus VR Character Model.
NexusVRCharacterModelModule:SetConfiguration(Configuration)
NexusVRCharacterModelModule:Load()