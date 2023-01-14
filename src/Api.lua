--[[
TheNexusAvenger

Main module for creating the usable API.
--]]
--!strict

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")



--[[
Creates a shim for interacted with a limited API for a module.
--]]
local function CreateShim(Source: {[string]: any}, FunctionNames: {string}): {[string]: any}
    local Shim = {}
    for _, FunctionName in FunctionNames do
        Shim[FunctionName] = Source[FunctionName]
    end
    return Shim
end



return function()
    local NexusVRCharacterModel = script.Parent
    local NexusEvent = require(NexusVRCharacterModel:WaitForChild("NexusInstance"):WaitForChild("Event"):WaitForChild("NexusEvent"))
    local API = {} :: any
    API.Registered = NexusEvent.new()

    --[[
    Stores an API that can be referenced. If the API is already stored,
    an error will be thrown.
    --]]
    function API:Register(ApiName: string, Api: any): ()
        if self[ApiName] ~= nil then
            error("API already registered: "..tostring(ApiName))
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
            --Build the initial shims for the APIs.
            local CameraService = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("CameraService")).GetInstance()
            local ControlService = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("ControlService")).GetInstance()
            API:Register("Camera", CreateShim(CameraService, {"SetActiveCamera",}))
            API:Register("Controller", CreateShim(ControlService, {"SetActiveController",}))
            API:Register("Input", CreateShim(require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("VRInputService")).GetInstance(), {"Recenter", "SetEyeLevel", "Recentered", "EyeLevelSet",}))
            API:Register("Settings", CreateShim(require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("Settings")).GetInstance(), {"GetSetting", "SetSetting", "GetSettingsChangedSignal"}))

            --Add the additional API adapters for the shims.
            API.Camera.GetActiveCamera = function()
                return CameraService.ActiveCamera
            end
            API.Controller.GetActiveController = function()
                return ControlService.ActiveController
            end

            --Add the custom APIs for the shims.
            local ActiveControllers = {}
            API.Controller.SetControllerInputEnabled = function(_, Hand: Enum.UserCFrame, Enabled: boolean): ()
                if Hand ~= Enum.UserCFrame.LeftHand and Hand ~= Enum.UserCFrame.RightHand then
                    error("The following UserCFrame is invalid and can't be disabled: "..tostring(Hand))
                end
                ActiveControllers[Hand] = (Enabled ~= false)
            end
            API.Controller.EnableControllerInput = function(self, Hand: Enum.UserCFrame): ()
                self:SetControllerInputEnabled(Hand, true)
            end
            API.Controller.DisableControllerInput = function(self, Hand: Enum.UserCFrame): ()
                self:SetControllerInputEnabled(Hand, false)
            end
            API.Controller.IsControllerInputEnabled = function(_, Hand: Enum.UserCFrame): boolean
                if Hand ~= Enum.UserCFrame.LeftHand and Hand ~= Enum.UserCFrame.RightHand then
                    error("The following UserCFrame is invalid and can't be disabled: "..tostring(Hand))
                end
                return ActiveControllers[Hand] ~= false
            end

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
                return GetMainMenu().Enabled
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
        end)
    end

    --Return the APIs.
    return API
end