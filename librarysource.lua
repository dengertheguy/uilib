-- den.net | Main Script
-- Created by denger

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

-- Initialize Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ESP Variables
local espEnabled = false
local espDrawings = {}
local espColor = Color3.fromRGB(255, 255, 255)
local showDistance = true
local showTracers = false
local showBoxes = false
local showHealthBars = false
local tracerPosition = 'Bottom'
local ESP = {
    TextSize = 13,
    MaxDistance = 1000,
    MinDistance = 5,
    Enabled = false,
    Color = Color3.fromRGB(255, 255, 255)
}

-- Variables for Ping tracking
local lastUpdate = tick()

-- Function to get ping
local function getPing()
    local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    return math.floor(ping)
end

-- ESP Functions
local function createPlayerESP(player)
    if player == LocalPlayer then return end
    
    local esp = {
        box = Drawing.new("Square"),
        tracer = Drawing.new("Line"),
        text = Drawing.new("Text"),
        healthBarOutline = Drawing.new("Square"),
        healthBar = Drawing.new("Square"),
        boxOutline = Drawing.new("Square"),
    }
    
    -- Box settings
    esp.box.Thickness = 1
    esp.box.Filled = false
    esp.box.Color = espColor
    esp.box.Transparency = 1
    esp.box.Visible = false
    
    -- Box outline settings
    esp.boxOutline.Thickness = 2
    esp.boxOutline.Filled = false
    esp.boxOutline.Color = Color3.new(0, 0, 0)
    esp.boxOutline.Transparency = 1
    esp.boxOutline.Visible = false
    
    -- Tracer settings
    esp.tracer.Thickness = 1
    esp.tracer.Color = espColor
    esp.tracer.Transparency = 1
    esp.tracer.Visible = false
    
    -- Text settings
    esp.text.Size = ESP.TextSize
    esp.text.Center = true
    esp.text.Outline = true
    esp.text.Font = Drawing.Fonts.Gotham
    esp.text.Color = espColor
    esp.text.Visible = false
    
    -- Health bar settings
    esp.healthBarOutline.Thickness = 1
    esp.healthBarOutline.Filled = false
    esp.healthBarOutline.Color = Color3.new(0, 0, 0)
    esp.healthBarOutline.Transparency = 1
    esp.healthBarOutline.Visible = false
    
    esp.healthBar.Thickness = 1
    esp.healthBar.Filled = true
    esp.healthBar.Color = Color3.fromRGB(0, 255, 0)
    esp.healthBar.Transparency = 1
    esp.healthBar.Visible = false
    
    espDrawings[player] = esp
    return esp
end

local function removePlayerESP(player)
    local esp = espDrawings[player]
    if esp then
        for name, drawing in pairs(esp) do
            if type(drawing) == "table" then
                for _, line in pairs(drawing) do
                    pcall(function() line:Remove() end)
                end
            else
                pcall(function() drawing:Remove() end)
            end
        end
        espDrawings[player] = nil
    end
end

local function updateESP()
    if not espEnabled then
        for _, drawings in pairs(espDrawings) do
            for _, drawing in pairs(drawings) do
                if type(drawing) == "table" then
                    for _, line in pairs(drawing) do
                        pcall(function() line.Visible = false end)
                    end
                else
                    pcall(function() drawing.Visible = false end)
                end
            end
        end
        return
    end
    
    for _, player in pairs(game.Players:GetPlayers()) do
        if player == game.Players.LocalPlayer then continue end
        
        local esp = espDrawings[player]
        if not esp then
            esp = createPlayerESP(player)
        end
        
        if not player or not player.Parent or not player:IsDescendantOf(game.Players) then
            removePlayerESP(player)
            continue
        end
        
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not player.Character:FindFirstChild("Humanoid") then
            for _, drawing in pairs(esp) do
                if type(drawing) == "table" then
                    for _, line in pairs(drawing) do
                        pcall(function() line.Visible = false end)
                    end
                else
                    pcall(function() drawing.Visible = false end)
                end
            end
            continue
        end
        
        local humanoidRootPart = player.Character.HumanoidRootPart
        local humanoid = player.Character.Humanoid
        
        local localPlayer = game.Players.LocalPlayer
        if not localPlayer or not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then
            continue
        end
        
        local distance = (localPlayer.Character.HumanoidRootPart.Position - humanoidRootPart.Position).Magnitude
        if distance < ESP.MinDistance or distance > ESP.MaxDistance then
            for _, drawing in pairs(esp) do
                if type(drawing) == "table" then
                    for _, line in pairs(drawing) do
                        pcall(function() line.Visible = false end)
                    end
                else
                    pcall(function() drawing.Visible = false end)
                end
            end
            continue
        end
        
        local vector, onScreen = Camera:WorldToViewportPoint(humanoidRootPart.Position)
        
        if onScreen then
            -- Fixed dimensions for consistent scaling
            local fixedWidth = 4
            local fixedHeight = 7
            local position = humanoidRootPart.Position - Vector3.new(0, 3.5, 0)
            
            local cameraRight = Camera.CFrame.RightVector
            
            local topLeft = Camera:WorldToViewportPoint(position - cameraRight * fixedWidth/2 + Vector3.new(0, fixedHeight, 0))
            local topRight = Camera:WorldToViewportPoint(position + cameraRight * fixedWidth/2 + Vector3.new(0, fixedHeight, 0))
            local bottomLeft = Camera:WorldToViewportPoint(position - cameraRight * fixedWidth/2)
            
            local boxWidth = math.abs(topRight.X - topLeft.X)
            local boxHeight = math.abs(bottomLeft.Y - topLeft.Y)
            
            local thickness = math.clamp(1 / (distance * 0.1), 0.5, 1)
            esp.box.Thickness = thickness
            
            local boxSize = Vector2.new(boxWidth, boxHeight)
            local boxPosition = Vector2.new(math.min(topLeft.X, topRight.X), topLeft.Y)
            
            -- Update Text ESP
            esp.text.Text = showDistance and string.format("%s [%d]", player.Name, math.floor(distance)) or player.Name
            esp.text.Position = Vector2.new(boxPosition.X + boxSize.X/2, boxPosition.Y - 16)
            esp.text.Size = ESP.TextSize
            esp.text.Visible = true
            esp.text.Color = espColor
            
            -- Update Box ESP
            if showBoxes then
                esp.boxOutline.Size = boxSize
                esp.boxOutline.Position = boxPosition
                esp.boxOutline.Visible = true
                
                esp.box.Size = boxSize
                esp.box.Position = boxPosition
                esp.box.Visible = true
                esp.box.Color = espColor
            else
                esp.box.Visible = false
                esp.boxOutline.Visible = false
            end
            
            -- Update Health Bar
            if showHealthBars then
                local health = humanoid.Health
                local maxHealth = humanoid.MaxHealth
                local healthPercent = health / maxHealth
                
                local barWidth = 3
                local barPosition = Vector2.new(boxPosition.X - 5, boxPosition.Y)
                
                esp.healthBarOutline.Size = Vector2.new(barWidth, boxHeight)
                esp.healthBarOutline.Position = barPosition
                esp.healthBarOutline.Visible = true
                
                esp.healthBar.Size = Vector2.new(1, boxHeight * healthPercent)
                esp.healthBar.Position = Vector2.new(barPosition.X + 1, barPosition.Y + boxHeight * (1 - healthPercent))
                esp.healthBar.Color = Color3.fromRGB(255 - (255 * healthPercent), 255 * healthPercent, 0)
                esp.healthBar.Visible = true
            else
                esp.healthBar.Visible = false
                esp.healthBarOutline.Visible = false
            end
            
            -- Update Tracer
            if showTracers then
                local tracerStart
                if tracerPosition == "Top" then
                    tracerStart = Vector2.new(Camera.ViewportSize.X / 2, 0)
                elseif tracerPosition == "Middle" then
                    tracerStart = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                else
                    tracerStart = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                end
                
                esp.tracer.From = tracerStart
                esp.tracer.To = Vector2.new(vector.X, vector.Y)
                esp.tracer.Visible = true
                esp.tracer.Color = espColor
            else
                esp.tracer.Visible = false
            end
        else
            for _, drawing in pairs(esp) do
                if type(drawing) == "table" then
                    for _, line in pairs(drawing) do
                        pcall(function() line.Visible = false end)
                    end
                else
                    pcall(function() drawing.Visible = false end)
                end
            end
        end
    end
end

-- Function to create/update highlight for a player
local function updatePlayerHighlight(player)
    if player == LocalPlayer then return end
    
    if Toggles.PlayerESPHighlight.Value then
        if player.Character and LocalPlayer.Character then
            local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
            local localHumanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if humanoidRootPart and localHumanoidRootPart then
                local distance = (localHumanoidRootPart.Position - humanoidRootPart.Position).Magnitude
                
                if distance <= ESP.MaxDistance then
                    local highlight = player.Character:FindFirstChild("PlayerHighlight")
                    if not highlight then
                        highlight = Instance.new("Highlight")
                        highlight.FillColor = Options.PlayerHighlightColor.Value
                        highlight.FillTransparency = Options.PlayerHighlightTransparency.Value
                        highlight.OutlineColor = Options.PlayerHighlightColor.Value
                        highlight.OutlineTransparency = 0
                        highlight.Parent = player.Character
                        highlight.Name = "PlayerHighlight"
                    end
                else
                    removePlayerHighlight(player)
                end
            end
        end
    end
end

-- Function to remove highlight from a player
local function removePlayerHighlight(player)
    if player.Character then
        local highlight = player.Character:FindFirstChild("PlayerHighlight")
        if highlight then highlight:Destroy() end
    end
end

-- Create Window
local Window = Library:CreateWindow({
    Title = 'den.net | V1',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2,
    Watermark = ('den.net | %s ms | %s'):format(
        tostring(getPing()),
        os.date('%X')
    )
})

-- Update watermark
spawn(function()
    while true do
        local now = tick()
        
        if now - lastUpdate >= 1 then
            lastUpdate = now
            
            Library:SetWatermark(('den.net | %s ms | %s'):format(
                tostring(getPing()),
                os.date('%X')
            ))
        end
        wait()
    end
end)

-- Create Tabs
local Tabs = {
    Main = Window:AddTab('Main'),
    ESP = Window:AddTab('ESP'),
    Combat = Window:AddTab('Combat'),
    Misc = Window:AddTab('Misc'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

-- ESP Tab
local ESPGroupBox = Tabs.ESP:AddLeftGroupbox('Player ESP')
local ESPSettingsBox = Tabs.ESP:AddRightGroupbox('ESP Settings')

-- ESP Settings
ESPGroupBox:AddToggle('ESPEnabled', {
    Text = 'Enable ESP',
    Default = false,
    Flag = 'ESPV2Enabled',
    Callback = function(Value)
        espEnabled = Value
        
        if Value then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    createPlayerESP(player)
                end
            end
        else
            for _, esp in pairs(espDrawings) do
                for name, drawing in pairs(esp) do
                    if type(drawing) == "table" then
                        for _, line in pairs(drawing) do
                            pcall(function() 
                                line.Visible = false
                                line:Remove()
                            end)
                        end
                    else
                        pcall(function() 
                            drawing.Visible = false
                            drawing:Remove()
                        end)
                    end
                end
            end
            table.clear(espDrawings)
        end
    end
}):AddKeyPicker('ESPKey', {
    Default = '',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'ESP',
    NoUI = false
})

ESPGroupBox:AddToggle('ShowDistance', {
    Text = 'Show Distance',
    Default = true,
    Flag = 'ESPV2ShowDistance',
    Callback = function(Value)
        showDistance = Value
    end
})

ESPGroupBox:AddToggle('ShowTracers', {
    Text = 'Show Tracers',
    Default = false,
    Flag = 'ESPV2ShowTracers',
    Callback = function(Value)
        showTracers = Value
    end
})

ESPGroupBox:AddToggle('ShowBoxes', {
    Text = 'Show Boxes',
    Default = false,
    Flag = 'ESPV2ShowBoxes',
    Callback = function(Value)
        showBoxes = Value
    end
})

ESPGroupBox:AddToggle('ShowHealthBars', {
    Text = 'Show Health Bars',
    Default = false,
    Flag = 'ESPV2ShowHealthBars',
    Callback = function(Value)
        showHealthBars = Value
    end
})

ESPSettingsBox:AddSlider('TextSize', {
    Text = 'Text Size',
    Default = 13,
    Min = 10,
    Max = 24,
    Rounding = 0,
    Flag = 'ESPV2TextSize',
    Callback = function(Value)
        ESP.TextSize = Value
    end
})

ESPSettingsBox:AddSlider('MaxDistance', {
    Text = 'Max Distance',
    Default = 1000,
    Min = 50,
    Max = 10000,
    Rounding = 0,
    Suffix = ' studs',
    Flag = 'ESPV2MaxDistance',
    Callback = function(Value)
        ESP.MaxDistance = Value
        -- Update highlights when max distance changes
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                updatePlayerHighlight(player)
            end
        end
    end
})

ESPSettingsBox:AddDropdown('TracerPosition', {
    Text = 'Tracer Position',
    Default = 'Bottom',
    Values = {'Top', 'Middle', 'Bottom'},
    Flag = 'ESPV2TracerPosition',
    Callback = function(Value)
        tracerPosition = Value
    end
})

ESPSettingsBox:AddLabel('ESP Color'):AddColorPicker('ESPColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'ESP Color',
    Flag = 'ESPV2Color',
    Callback = function(Value)
        espColor = Value
        ESP.Color = Value
        
        for player, esp in pairs(espDrawings) do
            pcall(function()
                if esp.text then esp.text.Color = Value end
                if esp.tracer then esp.tracer.Color = Value end
                if esp.box then esp.box.Color = Value end
                if esp.boxOutline then esp.boxOutline.Color = Value end
            end)
        end
    end
})

-- Player Highlight
local TabBox = Tabs.ESP:AddLeftTabbox()
local HighlightTab = TabBox:AddTab('Player Highlight')

HighlightTab:AddToggle('PlayerESPHighlight', {
    Text = 'Enable',
    Default = false,
    Tooltip = 'Highlights players through walls',
    
    Callback = function(Value)
        if Value then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    updatePlayerHighlight(player)
                    
                    -- Connect character added event
                    player.CharacterAdded:Connect(function()
                        if Toggles.PlayerESPHighlight.Value then
                            updatePlayerHighlight(player)
                        end
                    end)
                end
            end
        else
            for _, player in pairs(Players:GetPlayers()) do
                removePlayerHighlight(player)
            end
        end
    end
}):AddKeyPicker('HighlightKey', {
    Default = '',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'Highlight',
    NoUI = false
})

HighlightTab:AddLabel('Color'):AddColorPicker('PlayerHighlightColor', {
    Default = Color3.new(1, 0, 0),
    Title = 'Player Highlight Color',
    Transparency = 0,

    Callback = function(Value)
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                local highlight = player.Character:FindFirstChild("PlayerHighlight")
                if highlight then
                    highlight.FillColor = Value
                    highlight.OutlineColor = Value
                end
            end
        end
    end
})

HighlightTab:AddSlider('PlayerHighlightTransparency', {
    Text = 'Transparency',
    Default = 0.5,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Compact = false,

    Callback = function(Value)
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                local highlight = player.Character:FindFirstChild("PlayerHighlight")
                if highlight then
                    highlight.FillTransparency = Value
                end
            end
        end
    end
})

-- Player Added Event for Highlight
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        updatePlayerHighlight(player)
        
        player.CharacterAdded:Connect(function()
            if Toggles.PlayerESPHighlight.Value then
                updatePlayerHighlight(player)
            end
        end)
    end
end)

-- Player Events
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer and espEnabled then
        createPlayerESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if espDrawings[player] then
        for _, esp in pairs(espDrawings[player]) do
            for name, drawing in pairs(esp) do
                if type(drawing) == "table" then
                    for _, line in pairs(drawing) do
                        pcall(function() line:Remove() end)
                    end
                else
                    pcall(function() drawing:Remove() end)
                end
            end
        end
        espDrawings[player] = nil
    end
end)

-- Update ESP
RunService.RenderStepped:Connect(updateESP)

-- Update highlights with distance check
RunService.RenderStepped:Connect(function()
    if Toggles.PlayerESPHighlight.Value then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if player.Character and LocalPlayer.Character then
                    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
                    local localHumanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    
                    if humanoidRootPart and localHumanoidRootPart then
                        local distance = (localHumanoidRootPart.Position - humanoidRootPart.Position).Magnitude
                        if distance <= ESP.MaxDistance then
                            updatePlayerHighlight(player)
                        else
                            removePlayerHighlight(player)
                        end
                    end
                end
            end
        end
    end
end)

-- UI Settings
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'LeftAlt', NoUI = true, Text = 'Menu keybind' })

Library.ToggleKeybind = Options.MenuKeybind

-- Theme Manager
ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder('den.net')
ThemeManager.BuiltInThemes['Tokyo Night'] = { 6, game:GetService('HttpService'):JSONDecode('{"FontColor":"ffffff","MainColor":"191925","AccentColor":"6759b3","BackgroundColor":"16161f","OutlineColor":"323232"}') }
ThemeManager.BuiltInThemes['Mint'] = { 5, game:GetService('HttpService'):JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"3db488","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') }
ThemeManager.DefaultTheme = 'Tokyo Night'
ThemeManager:ApplyTheme('Tokyo Night')
ThemeManager:ApplyToTab(Tabs['UI Settings'])

-- Save Manager
SaveManager:SetLibrary(Library)
SaveManager:SetFolder('den.net/configs')
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
SaveManager:BuildConfigSection(Tabs['UI Settings'])

-- Set default theme
Library:SetWatermarkVisibility(true)
Library:SetWatermark('den.net | v1')

-- Load saved settings
SaveManager:LoadAutoloadConfig()

-- Add this helper function at the top of the file
local function AddUICorner(instance, radius)
    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, radius or 4)
    corner.Parent = instance
    return corner
end

function Library:Create(Class, Properties)
    local _Instance = Class;

    if type(Class) == 'string' then
        _Instance = Instance.new(Class);
    end;

    for Property, Value in next, Properties do
        _Instance[Property] = Value;
    end;

    -- Add UICorner to specific UI elements
    if Class == 'Frame' or Class == 'TextButton' or Class == 'TextBox' or 
       Class == 'ImageButton' or Class == 'ImageLabel' then
        AddUICorner(_Instance)
    end

    return _Instance;
end;

function Library:CreateWindow(...)
    local Window = { ... }
    local TargetFrame = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.fromScale(0.5, 0.5);
        Size = UDim2.fromOffset(Window.Size.X, Window.Size.Y);
        Visible = false;
        ZIndex = 1;
        Parent = ScreenGui;
    });

    -- Add rounded corners to the main window
    AddUICorner(TargetFrame, 6)  -- Larger radius for main window

    -- Add rounded corners to the window content frame
    local ContentFrame = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = TargetFrame;
    });
    AddUICorner(ContentFrame, 6)

    {{ ... }}
end

function Library:CreateButton(Container, Text, Callback)
    local Button = Library:Create('TextButton', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        Size = UDim2.new(1, -4, 0, 20);
        Position = UDim2.new(0, 2, 0, 2);
        AutoButtonColor = false;
        Text = Text;
        Font = Enum.Font.GothamMedium;
        TextColor3 = Library.FontColor;
        TextSize = 14;
        Parent = Container;
    });
    
    -- Button already gets UICorner from Library:Create

    return Button;
end

function Library:CreateDropdown(Container, Options)
    local Dropdown = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        Size = UDim2.new(1, -4, 0, 20);
        Position = UDim2.new(0, 2, 0, 2);
        Parent = Container;
    });
    
    -- Dropdown already gets UICorner from Library:Create

    local DropdownList = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 0, 1, 2);
        Size = UDim2.new(1, 0, 0, #Options.Items * 20);
        Visible = false;
        Parent = Dropdown;
    });
    AddUICorner(DropdownList, 4)

    local DropdownLabel = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, -4, 0, 20);
        Position = UDim2.new(0, 4, 0, 0);
        Font = Enum.Font.GothamMedium;
        Text = Options.Text;
        TextColor3 = Library.FontColor;
        TextSize = 14;
        TextXAlignment = Enum.TextXAlignment.Left;
        Parent = Dropdown;
    })

    {{ ... }}
end

function Library:CreateSlider(Container, Options)
    local Slider = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        Size = UDim2.new(1, -4, 0, 20);
        Position = UDim2.new(0, 2, 0, 2);
        Parent = Container;
    });
    
    -- Slider already gets UICorner from Library:Create

    local SliderBar = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Size = UDim2.new(0.5, 0, 1, 0);
        Parent = Slider;
    });
    AddUICorner(SliderBar, 4)

    {{ ... }}
end

function Library:Notify(Text, Time)
    local Notification = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 20, 1, -96);
        Size = UDim2.new(0, 300, 0, 76);
        Parent = ScreenGui;
    });
    
    -- Notification already gets UICorner from Library:Create

    local NotifContent = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        Parent = Notification;
    });
    AddUICorner(NotifContent, 4)

    local NotificationLabel = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 4, 0, 4);
        Size = UDim2.new(1, -8, 1, -8);
        Font = Enum.Font.GothamMedium;
        Text = Text;
        TextColor3 = Library.FontColor;
        TextSize = 14;
        TextWrapped = true;
        Parent = NotifContent;
    })

    {{ ... }}
end

function Library:CreateColorPicker(Container, Options)
    local ColorPicker = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        Size = UDim2.new(1, -4, 0, 20);
        Position = UDim2.new(0, 2, 0, 2);
        Parent = Container;
    });
    
    -- ColorPicker already gets UICorner from Library:Create

    local ColorDisplay = Library:Create('Frame', {
        BackgroundColor3 = Options.Default;
        BorderColor3 = Library.OutlineColor;
        Size = UDim2.new(0, 30, 0, 16);
        Position = UDim2.new(1, -32, 0, 2);
        Parent = ColorPicker;
    });
    AddUICorner(ColorDisplay, 4)

    local ColorPickerLabel = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, -4, 1, 0);
        Position = UDim2.new(0, 4, 0, 0);
        Font = Enum.Font.GothamMedium;
        Text = Options.Text;
        TextColor3 = Library.FontColor;
        TextSize = 14;
        TextXAlignment = Enum.TextXAlignment.Left;
        Parent = ColorPicker;
    })

    {{ ... }}
end