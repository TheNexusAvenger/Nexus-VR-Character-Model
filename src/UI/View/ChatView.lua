--[[
TheNexusAvenger

View for the chat.
Just moves the chat window. Does not
add any additional functionality.
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local NexusVRCharacterModel = require(script.Parent.Parent.Parent)
local NexusInstance = NexusVRCharacterModel:GetResource("NexusInstance.NexusInstance")

local ChatView = NexusInstance:Extend()
ChatView:SetClassName("ChatView")



--[[
Creates the chat view.
--]]
function ChatView:__new(View: table): nil
    self:InitializeSuper()

    --Create the loading text.
    --May be needed if the chat structure changes.
    local Container = View:GetContainer()
    local LoadingText = Instance.new("TextLabel")
    LoadingText.BackgroundTransparency = 1
    LoadingText.Size = UDim2.new(0.6, 0, 0.2, 0)
    LoadingText.Position = UDim2.new(0.2, 0, 0.4, 0)
    LoadingText.Font = Enum.Font.SourceSansBold
    LoadingText.Text = "Loading..."
    LoadingText.TextScaled = true
    LoadingText.TextColor3 = Color3.fromRGB(255, 255, 255)
    LoadingText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    LoadingText.TextStrokeTransparency = 0
    LoadingText.Parent = Container

    --Set up the chat.
    --Done in a task in case it fails or yields.
    task.spawn(function()
        --Load the chat.
        --Taken from the main script.
        local Chat = require(Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("ChatScript"):WaitForChild("ChatMain"))
        local ClientChatModules = game:GetService("Chat"):WaitForChild("ClientChatModules")
        local ChatSettings = require(ClientChatModules:WaitForChild("ChatSettings"))

        local containerTable = {}
        containerTable.ChatWindow = {}
        containerTable.SetCore = {}
        containerTable.GetCore = {}

        containerTable.ChatWindow.ChatTypes = {}
        containerTable.ChatWindow.ChatTypes.BubbleChatEnabled = ChatSettings.BubbleChatEnabled
        containerTable.ChatWindow.ChatTypes.ClassicChatEnabled = ChatSettings.ClassicChatEnabled

        --// Connection functions
        local function ConnectEvent(name)
            local event = Instance.new("BindableEvent")
            event.Name = name
            containerTable.ChatWindow[name] = event

            event.Event:connect(function(...) Chat[name](Chat, ...) end)
        end

        local function ConnectFunction(name)
            local func = Instance.new("BindableFunction")
            func.Name = name
            containerTable.ChatWindow[name] = func

            func.OnInvoke = function(...) return Chat[name](Chat, ...) end
        end

        local function ReverseConnectEvent(name)
            local event = Instance.new("BindableEvent")
            event.Name = name
            containerTable.ChatWindow[name] = event

            Chat[name]:connect(function(...) event:Fire(...) end)
        end

        local function ConnectSignal(name)
            local event = Instance.new("BindableEvent")
            event.Name = name
            containerTable.ChatWindow[name] = event

            event.Event:connect(function(...) Chat[name]:fire(...) end)
        end

        local function ConnectSetCore(name)
            local event = Instance.new("BindableEvent")
            event.Name = name
            containerTable.SetCore[name] = event

            event.Event:connect(function(...) Chat[name.."Event"]:fire(...) end)
        end

        local function ConnectGetCore(name)
            local func = Instance.new("BindableFunction")
            func.Name = name
            containerTable.GetCore[name] = func

            func.OnInvoke = function(...) return Chat["f"..name](...) end
        end

        --// Do connections
        ConnectEvent("ToggleVisibility")
        ConnectEvent("SetVisible")
        ConnectEvent("FocusChatBar")
        ConnectEvent("EnterWhisperState")
        ConnectFunction("GetVisibility")
        ConnectFunction("GetMessageCount")
        ConnectEvent("TopbarEnabledChanged")
        ConnectFunction("IsFocused")

        ReverseConnectEvent("ChatBarFocusChanged")
        ReverseConnectEvent("VisibilityStateChanged")
        ReverseConnectEvent("MessagesChanged")
        ReverseConnectEvent("MessagePosted")

        ConnectSignal("CoreGuiEnabled")

        ConnectSetCore("ChatMakeSystemMessage")
        ConnectSetCore("ChatWindowPosition")
        ConnectSetCore("ChatWindowSize")
        ConnectGetCore("ChatWindowPosition")
        ConnectGetCore("ChatWindowSize")
        ConnectSetCore("ChatBarDisabled")
        ConnectGetCore("ChatBarDisabled")

        --Move the chat GUI to the container.
        local ChatWindow = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Chat")
        while #ChatWindow:GetChildren() == 0 do task.wait() end
        local ChatFrame = ChatWindow:FindFirstChildOfClass("Frame")
        ChatFrame.Size = UDim2.new(1, 0, 1, 0)
        ChatFrame.Parent = Container

        --Destroy the loading text.
        LoadingText:Destroy()

        --Connect starting chat.
        --For some reason, it is not done when VR is enabled.
        UserInputService.InputBegan:Connect(function(Input,Processed)
            if Processed then return end
            if not UserInputService:GetFocusedTextBox() and Input.KeyCode == Enum.KeyCode.Slash and Container.Visible then
                --Focus the chat bar.
                --Done the next frame so that the slash is not inputted.
                RunService.Stepped:Wait()
                Chat:FocusChatBar()
            end
        end)

        --Force the GUI to always be visible.
        --Bit hacky and relies on checking for the passed value to be not false and not nil instead of checking if it true.
        while true do
            Chat:SetVisible(tick())
            task.wait(0.1)
        end
    end)
end




return ChatView