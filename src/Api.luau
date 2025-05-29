--Main module for creating the usable API.
--!strict

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")



return function()
    local NexusVRCharacterModel = script.Parent
    local TypedEvent = require(NexusVRCharacterModel:WaitForChild("Packages"):WaitForChild("NexusInstance")).TypedEvent
    local API = {} :: any
    API.Registered = TypedEvent.new()

    --[[
    Stores an API that can be referenced. If the API is already stored,
    an error will be thrown.
    --]]
    function API:Register(ApiName: string, Api: any): ()
        if self[ApiName] ~= nil then
            error(`API already registered: {ApiName}`)
        end
        self[ApiName] = Api
        self.Registered:Fire(ApiName)
    end

    --[[
    Waits for an API to be registered and returns the API. If it was
    already registered, it returns the API without waiting. Similar
    to instances, this would be treated like WaitForChild where the
    usage is optional instead of indexing (ex: API:WaitFor("MyApi")
    vs API.MyApi) as long as the consequences of an API not
    being registered are accepted.
    --]]
    function API:WaitFor(ApiName: string): any
        while not self[ApiName] do
            self.Registered:Wait()
        end
        return self[ApiName]
    end

    --[[
    Invokes a callback when an API is registered with a given
    name. If it is already registered, the callback will run
    asynchronously. This is intended for setting up an API
    call without blocking for WaitFor.
    --]]
    function API:OnRegistered(ApiName: string, RegisteredCallback: (any) -> ()): ()
        --Run the callback immediately if the API is loaded.
        if self[ApiName] then
            task.spawn(function()
                RegisteredCallback(self[ApiName])
            end)
            return
        end

        --Connect the registered event.
        self.Registered:Connect(function(RegisteredFunctionName)
            if ApiName ~= RegisteredFunctionName then return end
            RegisteredCallback(self[ApiName])
        end)
    end

    --Create the client API.
    --Done in a task to resolve recurisve requiring.
    if RunService:IsClient() then
        task.defer(function()
            --Create the camera API.
            local CameraService = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("CameraService")).GetInstance()
            local CameraAPI = {}
            function CameraAPI:SetActiveCamera(Name: string): ()
                CameraService:SetActiveCamera(Name)
            end
            function CameraAPI:GetActiveCamera(): string
                return CameraService.ActiveCamera
            end
            API:Register("Camera", CameraAPI)

            --Create the controller API.
            local ActiveControllers = {}
            local ControlService = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("ControlService")).GetInstance()
            local ControllerAPI = {}
            function ControllerAPI:SetActiveController(Name: string): ()
                ControlService:SetActiveController(Name)
            end
            function ControllerAPI:GetActiveController(): (string)
                return ControlService.ActiveController
            end
            function ControllerAPI:SetControllerInputEnabled(Hand: Enum.UserCFrame, Enabled: boolean): ()
                if Hand ~= Enum.UserCFrame.LeftHand and Hand ~= Enum.UserCFrame.RightHand then
                    error(`The following UserCFrame is invalid and can't be disabled: {Hand}`)
                end
                ActiveControllers[Hand] = (Enabled ~= false)
            end
            function ControllerAPI:EnableControllerInput(Hand: Enum.UserCFrame): ()
                self:SetControllerInputEnabled(Hand, true)
            end
            function ControllerAPI:DisableControllerInput(Hand: Enum.UserCFrame): ()
                self:SetControllerInputEnabled(Hand, false)
            end
            function ControllerAPI:IsControllerInputEnabled(Hand: Enum.UserCFrame): boolean
                if Hand ~= Enum.UserCFrame.LeftHand and Hand ~= Enum.UserCFrame.RightHand then
                    error(`The following UserCFrame is invalid and can't be disabled: {Hand}`)
                end
                return ActiveControllers[Hand] ~= false
            end
            API:Register("Controller", ControllerAPI)

            --Create the input API.
            local VRInputService = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("VRInputService")).GetInstance()
            local InputAPI = {}
            InputAPI.Recentered = VRInputService.Recentered
            InputAPI.EyeLevelSet = VRInputService.EyeLevelSet
            function InputAPI:Recenter(): ()
                VRInputService:Recenter()
            end
            function InputAPI:SetEyeLevel(): ()
                VRInputService:SetEyeLevel()
            end
            API:Register("Input", InputAPI)

            --Create the Menu API.
            --The Menu API does not work outside of VR.
            --Release 454 and later has/had a bug that made VREnabled false on start. This mitigates that now and in the future if VR loads dynamically.
            local MenuAPI = {} :: any
            local function GetMainMenu(): any
                if not MenuAPI.Enabled then
                    error("Menu API is not enabled for non-VR players. Check Api.Menu.Enabled before calling.")
                end
                return require(NexusVRCharacterModel:WaitForChild("UI"):WaitForChild("MainMenu")).GetInstance()
            end
            if UserInputService.VREnabled then
                MenuAPI.Enabled = true
            else
                MenuAPI.Enabled = false
                UserInputService:GetPropertyChangedSignal("VREnabled"):Connect(function()
                    MenuAPI.Enabled = UserInputService.VREnabled
                end)
            end

            MenuAPI.CreateView = function(_, ...)
                return GetMainMenu():CreateView(...)
            end
            MenuAPI.IsOpen = function()
                return GetMainMenu().ScreenGui.Enabled
            end
            MenuAPI.Open = function(self)
                if self:IsOpen() then return end
                GetMainMenu():Toggle()
            end
            MenuAPI.Close = function(self)
                if not self:IsOpen() then return end
                GetMainMenu():Toggle()
            end
            API:Register("Menu", MenuAPI)

            --Create the settings API.
            local SettingsService = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("Settings")).GetInstance()
            local SettingsAPI = {}
            function SettingsAPI:GetSetting(Setting: string): any
                return SettingsService:GetSetting(Setting)
            end
            function SettingsAPI:SetSetting(Setting: string, Value: any): ()
                SettingsService:SetSetting(Setting, Value)
            end
            function SettingsAPI:GetSettingsChangedSignal(Setting: string)
                return SettingsService:GetSettingsChangedSignal(Setting)
            end
            API:Register("Settings", SettingsAPI)
        end)
    end

    --Return the APIs.
    return API
end