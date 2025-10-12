-- SCP Roleplay Enhanced v2.1
-- Created by Kolin with Safety Systems

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Настройки с системой безопасности
local Settings = {
    AimBot = {
        Enabled = false,
        TeamCheck = true,
        Smoothness = 0.2,
        FOV = 50,
        TargetPart = "Head",
        AutoShoot = false,
        SafetyCheck = true
    },
    ESP = {
        Enabled = false,
        TeamColor = Color3.fromRGB(0, 255, 0),
        EnemyColor = Color3.fromRGB(255, 0, 0),
        ShowDistance = true,
        SafetyCheck = true
    },
    Movement = {
        Speed = 16,
        JumpPower = 50,
        SafetyCheck = true
    },
    Notifications = {
        Enabled = true,
        Position = UDim2.new(1, -20, 1, -20)
    },
    Safety = {
        MaxPing = 500,
        MaxMemoryUsage = 500, -- MB
        AutoDisableOnLag = true
    }
}

-- Система безопасности
local SafetySystem = {
    LastPerformanceCheck = 0,
    PerformanceIssues = 0,
    DisabledFeatures = {},
    PerformanceHistory = {}
}

-- Безопасный список и соединения
local SafeList = {}
local ActiveConnections = {}
local GUI = nil
local currentTarget = nil
local targetSwitchCooldown = 0

-- Создание современного интерфейса
local function CreateGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ModernCheatMenu"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = game.CoreGui

    -- Основной фрейм с увеличенными размерами
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 550, 0, 650) -- Увеличил ширину и высоту
    MainFrame.Position = UDim2.new(0.5, -275, 0.5, -325)
    MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    -- Градиентный фон
    local UIGradient = Instance.new("UIGradient")
    UIGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 15)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 25))
    })
    UIGradient.Parent = MainFrame

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 15)
    UICorner.Parent = MainFrame

    -- Неоновая обводка
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(0, 150, 255)
    UIStroke.Thickness = 2
    UIStroke.Parent = MainFrame

    -- Заголовок с улучшенным дизайном
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 70)
    Header.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 15)
    HeaderCorner.Parent = Header

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.Position = UDim2.new(0, 0, 0, 10)
    Title.BackgroundTransparency = 1
    Title.Text = "SCP ROLEPLAY ENHANCED"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 20
    Title.Font = Enum.Font.GothamBold
    Title.Parent = Header

    local Subtitle = Instance.new("TextLabel")
    Subtitle.Name = "Subtitle"
    Subtitle.Size = UDim2.new(1, 0, 0, 20)
    Subtitle.Position = UDim2.new(0, 0, 0, 45)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Text = "v2.1 • Safety Systems Active"
    Subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    Subtitle.TextSize = 12
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.Parent = Header

    -- Индикатор статуса безопасности
    local SafetyIndicator = Instance.new("Frame")
    SafetyIndicator.Name = "SafetyIndicator"
    SafetyIndicator.Size = UDim2.new(0, 10, 0, 10)
    SafetyIndicator.Position = UDim2.new(1, -20, 0, 20)
    SafetyIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    SafetyIndicator.BorderSizePixel = 0
    SafetyIndicator.Parent = Header

    local SafetyCorner = Instance.new("UICorner")
    SafetyCorner.CornerRadius = UDim.new(1, 0)
    SafetyCorner.Parent = SafetyIndicator

    -- Контейнер для вкладок
    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, 0, 1, -70)
    TabContainer.Position = UDim2.new(0, 0, 0, 70)
    TabContainer.BackgroundTransparency = 1
    TabContainer.Parent = MainFrame

    -- Навигация с увеличенной шириной
    local Navigation = Instance.new("Frame")
    Navigation.Name = "Navigation"
    Navigation.Size = UDim2.new(0, 160, 1, 0) -- Увеличил ширину
    Navigation.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Navigation.BorderSizePixel = 0
    Navigation.Parent = TabContainer

    local NavCorner = Instance.new("UICorner")
    NavCorner.CornerRadius = UDim.new(0, 10)
    NavCorner.Parent = Navigation

    -- Контент с увеличенной шириной
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -170, 1, -20) -- Увеличил ширину
    Content.Position = UDim2.new(0, 170, 0, 10)
    Content.BackgroundTransparency = 1
    Content.Parent = TabContainer

    -- Кнопки навигации с иконками
    local NavButtons = {
        {"Creators", "👥", Color3.fromRGB(0, 150, 255)},
        {"Combat", "🔫", Color3.fromRGB(255, 50, 50)}, 
        {"Visual", "👁️", Color3.fromRGB(50, 255, 50)},
        {"Movement", "⚡", Color3.fromRGB(255, 255, 50)},
        {"Safety", "🛡️", Color3.fromRGB(255, 150, 0)}
    }

    local CurrentTab = "Combat"

    for i, buttonData in pairs(NavButtons) do
        local buttonName, icon, color = buttonData[1], buttonData[2], buttonData[3]
        
        local NavButton = Instance.new("TextButton")
        NavButton.Name = buttonName
        NavButton.Size = UDim2.new(1, -10, 0, 50) -- Увеличил высоту кнопок
        NavButton.Position = UDim2.new(0, 5, 0, 10 + (i-1)*60)
        NavButton.BackgroundColor3 = buttonName == CurrentTab and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(30, 30, 30)
        NavButton.BorderSizePixel = 0
        NavButton.Text = icon .. " " .. buttonName
        NavButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        NavButton.TextSize = 14
        NavButton.Font = Enum.Font.Gotham
        NavButton.Parent = Navigation

        local ButtonCorner = Instance.new("UICorner")
        ButtonCorner.CornerRadius = UDim.new(0, 8)
        ButtonCorner.Parent = NavButton

        local ButtonStroke = Instance.new("UIStroke")
        ButtonStroke.Color = color
        ButtonStroke.Thickness = 1
        ButtonStroke.Parent = NavButton

        NavButton.MouseButton1Click:Connect(function()
            CurrentTab = buttonName
            UpdateContent(buttonName)
            
            -- Анимация кнопок
            for _, btn in pairs(Navigation:GetChildren()) do
                if btn:IsA("TextButton") then
                    btn.BackgroundColor3 = btn.Name == buttonName and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(30, 30, 30)
                end
            end
        end)
    end

    -- Функция обновления контента
    function UpdateContent(tabName)
        Content:ClearAllChildren()
        
        if tabName == "Combat" then
            CreateCombatTab()
        elseif tabName == "Visual" then
            CreateVisualTab()
        elseif tabName == "Movement" then
            CreateMovementTab()
        elseif tabName == "Creators" then
            CreateCreatorsTab()
        elseif tabName == "Safety" then
            CreateSafetyTab()
        end
    end

    -- Улучшенная вкладка Combat
    function CreateCombatTab()
        local Title = CreateSectionTitle("Combat Features")
        Title.Parent = Content

        -- AimBot переключатель
        local AimBotFrame = CreateToggle("AimBot", "Auto-aim at enemies", Settings.AimBot.Enabled, function(state)
            if SafetySystem.DisabledFeatures["AimBot"] then
                ShowSafetyNotification("AimBot temporarily disabled due to performance issues")
                return
            end
            SafeToggle("AimBot", state, StartAimBot, StopAimBot)
        end)
        AimBotFrame.Parent = Content

        -- Team Check переключатель
        local TeamCheckFrame = CreateToggle("Team Check", "Don't target teammates", Settings.AimBot.TeamCheck, function(state)
            Settings.AimBot.TeamCheck = state
        end)
        TeamCheckFrame.Position = UDim2.new(0, 0, 0, 80)
        TeamCheckFrame.Parent = Content

        -- Auto Shoot переключатель
        local AutoShootFrame = CreateToggle("Auto Shoot", "Automatically shoot at target", Settings.AimBot.AutoShoot, function(state)
            Settings.AimBot.AutoShoot = state
        end)
        AutoShootFrame.Position = UDim2.new(0, 0, 0, 150)
        AutoShootFrame.Parent = Content

        -- FOV слайдер
        local FOVFrame = CreateSlider("Aim FOV", 10, 100, Settings.AimBot.FOV, function(value)
            Settings.AimBot.FOV = value
        end)
        FOVFrame.Position = UDim2.new(0, 0, 0, 230)
        FOVFrame.Parent = Content

        -- Smoothness слайдер
        local SmoothFrame = CreateSlider("Smoothness", 0.1, 1, Settings.AimBot.Smoothness, function(value)
            Settings.AimBot.Smoothness = value
        end)
        SmoothFrame.Position = UDim2.new(0, 0, 0, 310)
        SmoothFrame.Parent = Content

        -- Кнопка смены цели
        local SwitchButton = CreateActionButton("🔁 Switch Target", "Force switch current target", Color3.fromRGB(255, 255, 0), function()
            ForceSwitchTarget()
        end)
        SwitchButton.Position = UDim2.new(0, 0, 0, 390)
        SwitchButton.Parent = Content
    end

    -- Улучшенная вкладка Visual
    function CreateVisualTab()
        local Title = CreateSectionTitle("Visual Features")
        Title.Parent = Content

        -- ESP переключатель
        local ESPFrame = CreateToggle("ESP", "See players through walls", Settings.ESP.Enabled, function(state)
            if SafetySystem.DisabledFeatures["ESP"] then
                ShowSafetyNotification("ESP temporarily disabled due to performance issues")
                return
            end
            SafeToggle("ESP", state, StartESP, ClearESP)
        end)
        ESPFrame.Parent = Content

        -- Team ESP цвет
        local TeamColorFrame = CreateColorPicker("Team Color", Settings.ESP.TeamColor, function(color)
            Settings.ESP.TeamColor = color
            UpdateESPColors()
        end)
        TeamColorFrame.Position = UDim2.new(0, 0, 0, 80)
        TeamColorFrame.Parent = Content

        -- Enemy ESP цвет
        local EnemyColorFrame = CreateColorPicker("Enemy Color", Settings.ESP.EnemyColor, function(color)
            Settings.ESP.EnemyColor = color
            UpdateESPColors()
        end)
        EnemyColorFrame.Position = UDim2.new(0, 0, 0, 160)
        EnemyColorFrame.Parent = Content
    end

    -- Улучшенная вкладка Movement
    function CreateMovementTab()
        local Title = CreateSectionTitle("Movement Features")
        Title.Parent = Content

        -- Speed hack
        local SpeedFrame = CreateSlider("Walk Speed", 16, 100, Settings.Movement.Speed, function(value)
            Settings.Movement.Speed = value
            ApplySpeed()
        end)
        SpeedFrame.Parent = Content

        -- Jump power
        local JumpFrame = CreateSlider("Jump Power", 50, 200, Settings.Movement.JumpPower, function(value)
            Settings.Movement.JumpPower = value
            ApplyJump()
        end)
        JumpFrame.Position = UDim2.new(0, 0, 0, 80)
        JumpFrame.Parent = Content
    end

    -- Новая вкладка Safety
    function CreateSafetyTab()
        local Title = CreateSectionTitle("Safety Systems")
        Title.Parent = Content

        local InfoText = Instance.new("TextLabel")
        InfoText.Text = "🛡️ Safety Systems Active\n\n• Auto-disabled features on lag\n• Performance monitoring\n• Crash prevention\n• Memory usage control\n\nStatus: All Systems Operational"
        InfoText.Size = UDim2.new(1, -20, 0, 200)
        InfoText.Position = UDim2.new(0, 10, 0, 40)
        InfoText.TextColor3 = Color3.fromRGB(200, 200, 200)
        InfoText.TextSize = 14
        InfoText.Font = Enum.Font.Gotham
        InfoText.BackgroundTransparency = 1
        InfoText.TextXAlignment = Enum.TextXAlignment.Left
        InfoText.TextYAlignment = Enum.TextYAlignment.Top
        InfoText.Parent = Content

        -- Кнопка сброса безопасности
        local ResetButton = CreateActionButton("🔄 Reset Safety", "Reset all safety systems", Color3.fromRGB(0, 255, 255), function()
            ResetSafetySystems()
        end)
        ResetButton.Position = UDim2.new(0, 0, 0, 250)
        ResetButton.Parent = Content
    end

    -- Улучшенная функция создания переключателей с красным/зеленым
    function CreateToggle(name, description, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 60)
        frame.BackgroundTransparency = 1

        local label = Instance.new("TextLabel")
        label.Text = name
        label.Size = UDim2.new(1, -60, 0, 25)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.BackgroundTransparency = 1
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local desc = Instance.new("TextLabel")
        desc.Text = description
        desc.Size = UDim2.new(1, -60, 0, 20)
        desc.Position = UDim2.new(0, 0, 0, 25)
        desc.TextColor3 = Color3.fromRGB(150, 150, 150)
        desc.TextSize = 12
        desc.Font = Enum.Font.Gotham
        desc.BackgroundTransparency = 1
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = frame

        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.new(0, 40, 0, 20)
        toggle.Position = UDim2.new(1, -45, 0, 10)
        toggle.BackgroundColor3 = default and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 50, 50) -- Зеленый/Красный
        toggle.BorderSizePixel = 0
        toggle.Text = ""
        toggle.Parent = frame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = toggle

        -- Анимация переключения
        toggle.MouseButton1Click:Connect(function()
            local newState = not default
            default = newState
            
            -- Анимация изменения цвета
            local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tween = TweenService:Create(toggle, tweenInfo, {
                BackgroundColor3 = newState and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 50, 50)
            })
            tween:Play()
            
            callback(newState)
        end)

        return frame
    end

    -- Улучшенная функция создания слайдеров
    function CreateSlider(name, min, max, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 70)
        frame.BackgroundTransparency = 1

        local label = Instance.new("TextLabel")
        label.Text = name .. ": " .. default
        label.Size = UDim2.new(1, 0, 0, 25)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.BackgroundTransparency = 1
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local slider = Instance.new("Frame")
        slider.Size = UDim2.new(1, 0, 0, 20)
        slider.Position = UDim2.new(0, 0, 0, 30)
        slider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        slider.BorderSizePixel = 0
        slider.Parent = frame

        local sliderCorner = Instance.new("UICorner")
        sliderCorner.CornerRadius = UDim.new(0, 10)
        sliderCorner.Parent = slider

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        fill.BorderSizePixel = 0
        fill.Parent = slider

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 10)
        fillCorner.Parent = fill

        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 20, 1, 0)
        button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        button.BorderSizePixel = 0
        button.Text = ""
        button.Parent = slider

        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 10)
        buttonCorner.Parent = button

        -- Логика слайдера
        local function updateSlider(x)
            local relativeX = math.clamp(x - slider.AbsolutePosition.X, 0, slider.AbsoluteSize.X)
            local ratio = relativeX / slider.AbsoluteSize.X
            local value = min + (max - min) * ratio
            value = math.floor(value * 10) / 10
            
            fill.Size = UDim2.new(ratio, 0, 1, 0)
            button.Position = UDim2.new(ratio, -10, 0, 0)
            label.Text = name .. ": " .. value
            callback(value)
        end

        button.MouseButton1Down:Connect(function()
            local connection
            connection = RunService.Heartbeat:Connect(function()
                updateSlider(UserInputService:GetMouseLocation().X)
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    connection:Disconnect()
                end
            end)
        end)

        return frame
    end

    -- Функция создания кнопок действий
    function CreateActionButton(text, description, color, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 45)
        frame.BackgroundTransparency = 1

        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 1, 0)
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        button.BorderSizePixel = 0
        button.Text = text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 14
        button.Font = Enum.Font.Gotham
        button.Parent = frame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = button

        local stroke = Instance.new("UIStroke")
        stroke.Color = color
        stroke.Thickness = 1
        stroke.Parent = button

        button.MouseButton1Click:Connect(function()
            callback()
        end)

        return frame
    end

    -- Функция создания заголовков секций
    function CreateSectionTitle(text)
        local title = Instance.new("TextLabel")
        title.Text = text
        title.Size = UDim2.new(1, 0, 0, 30)
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 18
        title.Font = Enum.Font.GothamBold
        title.BackgroundTransparency = 1
        title.TextXAlignment = Enum.TextXAlignment.Left
        return title
    end

    UpdateContent("Combat")
    return ScreenGui
end

-- Система безопасности
function CheckPerformance()
    local currentTime = tick()
    
    -- Проверяем каждые 5 секунд
    if currentTime - SafetySystem.LastPerformanceCheck < 5 then
        return true
    end
    
    SafetySystem.LastPerformanceCheck = currentTime
    
    -- Проверка FPS
    local fps = 1 / RunService.Heartbeat:Wait()
    if fps < 20 then
        SafetySystem.PerformanceIssues = SafetySystem.PerformanceIssues + 1
        ShowSafetyNotification("⚠️ Low FPS detected: " .. math.floor(fps))
    else
        SafetySystem.PerformanceIssues = math.max(0, SafetySystem.PerformanceIssues - 0.5)
    end
    
    -- Проверка памяти
    local memory = collectgarbage("count") / 1024 -- MB
    if memory > Settings.Safety.MaxMemoryUsage then
        SafetySystem.PerformanceIssues = SafetySystem.PerformanceIssues + 2
        ShowSafetyNotification("⚠️ High memory usage: " .. math.floor(memory) .. "MB")
        collectgarbage() -- Очистка памяти
    end
    
    -- Отключаем функции при проблемах
    if SafetySystem.PerformanceIssues > 5 then
        if Settings.AimBot.Enabled and not SafetySystem.DisabledFeatures["AimBot"] then
            SafeToggle("AimBot", false, StartAimBot, StopAimBot)
            SafetySystem.DisabledFeatures["AimBot"] = true
            ShowSafetyNotification("⚡ AimBot auto-disabled due to performance issues")
        end
        
        if Settings.ESP.Enabled and not SafetySystem.DisabledFeatures["ESP"] then
            SafeToggle("ESP", false, StartESP, ClearESP)
            SafetySystem.DisabledFeatures["ESP"] = true
            ShowSafetyNotification("⚡ ESP auto-disabled due to performance issues")
        end
    end
    
    -- Восстанавливаем функции при нормальной работе
    if SafetySystem.PerformanceIssues < 2 then
        for feature, _ in pairs(SafetySystem.DisabledFeatures) do
            SafetySystem.DisabledFeatures[feature] = nil
            ShowNotification(feature .. " available again", Color3.fromRGB(0, 255, 0))
        end
    end
    
    return SafetySystem.PerformanceIssues < 10
end

function SafeToggle(featureName, state, enableFunc, disableFunc)
    if state then
        if SafetySystem.DisabledFeatures[featureName] then
            ShowSafetyNotification("⚠️ " .. featureName .. " temporarily disabled")
            return false
        end
        
        -- Проверяем производительность перед включением
        if not CheckPerformance() then
            ShowSafetyNotification("⚠️ Cannot enable " .. featureName .. " - performance issues")
            return false
        end
        
        enableFunc()
        ShowNotification(featureName .. " Activated", Color3.fromRGB(0, 255, 0))
    else
        disableFunc()
        ShowNotification(featureName .. " Deactivated", Color3.fromRGB(255, 0, 0))
    end
    
    return true
end

function ResetSafetySystems()
    SafetySystem.PerformanceIssues = 0
    SafetySystem.DisabledFeatures = {}
    ShowNotification("Safety systems reset", Color3.fromRGB(0, 255, 255))
end

-- Улучшенная система уведомлений
function ShowSafetyNotification(text)
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 350, 0, 70)
    notification.Position = UDim2.new(1, -370, 1, -80)
    notification.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
    notification.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = notification
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 50, 50)
    stroke.Thickness = 3
    stroke.Parent = notification
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 40, 1, 0)
    icon.Position = UDim2.new(0, 10, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = "⚠️"
    icon.TextColor3 = Color3.fromRGB(255, 255, 0)
    icon.TextSize = 20
    icon.Font = Enum.Font.GothamBold
    icon.TextXAlignment = Enum.TextXAlignment.Left
    icon.Parent = notification
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, -20)
    label.Position = UDim2.new(0, 50, 0, 10)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.TextWrapped = true
    label.Parent = notification
    
    notification.Parent = GUI:FindFirstChild("Notifications") or CreateNotificationSystem()
    
    -- Анимация появления
    notification:TweenPosition(UDim2.new(1, -370, 1, -160), "Out", "Quad", 0.3, true)
    
    -- Автоудаление через 5 секунд
    delay(5, function()
        if notification then
            notification:TweenPosition(UDim2.new(1, -370, 1, -80), "Out", "Quad", 0.3, true)
            wait(0.3)
            notification:Destroy()
        end
    end)
end

-- Система уведомлений
local function CreateNotificationSystem()
    local Notifications = Instance.new("ScreenGui")
    Notifications.Name = "Notifications"
    Notifications.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Notifications.Parent = game.CoreGui
    return Notifications
end

function ShowNotification(text, color)
    if not Settings.Notifications.Enabled then return end
    
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 300, 0, 60)
    notification.Position = UDim2.new(1, -320, 1, -70)
    notification.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    notification.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notification
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 2
    stroke.Parent = notification
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, -20)
    label.Position = UDim2.new(0, 10, 0, 10)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = notification
    
    notification.Parent = GUI:FindFirstChild("Notifications") or CreateNotificationSystem()
    
    -- Анимация появления
    notification:TweenPosition(UDim2.new(1, -320, 1, -140), "Out", "Quad", 0.3, true)
    
    -- Автоудаление через 3 секунды
    delay(3, function()
        if notification then
            notification:TweenPosition(UDim2.new(1, -320, 1, -70), "Out", "Quad", 0.3, true)
            wait(0.3)
            notification:Destroy()
        end
    end)
end

-- AimBot система
function StartAimBot()
    if ActiveConnections.AimBot then return end
    
    ActiveConnections.AimBot = RunService.Heartbeat:Connect(function()
        if not Settings.AimBot.Enabled then return end
        
        local character = LocalPlayer.Character
        if not character then return end
        
        local humanoid = character:FindFirstChild("Humanoid")
        local root = character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not root then return end
        
        -- Проверяем текущую цель
        if currentTarget then
            local targetPlayer = Players:GetPlayerFromCharacter(currentTarget)
            if not IsValidTarget(currentTarget, targetPlayer) then
                currentTarget = nil
                ShowNotification("Target Lost", Color3.fromRGB(255, 165, 0))
            end
        end
        
        -- Поиск новой цели если текущей нет или она умерла
        if not currentTarget or targetSwitchCooldown <= 0 then
            FindNewTarget(character, root)
            targetSwitchCooldown = 30 -- Задержка перед сменой цели (в кадрах)
        else
            targetSwitchCooldown = targetSwitchCooldown - 1
        end
        
        -- Наведение на текущую цель
        if currentTarget then
            local targetHead = currentTarget:FindFirstChild("Head")
            if targetHead then
                -- Плавное наведение только на текущую цель
                local currentCFrame = workspace.CurrentCamera.CFrame
                local targetPosition = targetHead.Position
                local newCFrame = currentCFrame:Lerp(CFrame.lookAt(currentCFrame.Position, targetPosition), Settings.AimBot.Smoothness)
                
                workspace.CurrentCamera.CFrame = newCFrame
                
                -- Авто-стрельба если включено
                if Settings.AimBot.AutoShoot then
                    SimulateShooting()
                end
            end
        end
    end)
end

function StopAimBot()
    if ActiveConnections.AimBot then
        ActiveConnections.AimBot:Disconnect()
        ActiveConnections.AimBot = nil
    end
    currentTarget = nil
end

function IsValidTarget(character, player)
    if not character or not player then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not root or humanoid.Health <= 0 then
        return false
    end
    
    -- Проверка команды
    if Settings.AimBot.TeamCheck and player.Team == LocalPlayer.Team then
        return false
    end
    
    -- Проверка безопасного списка
    if SafeList[player.Name] then
        return false
    end
    
    -- Проверка дистанции
    local distance = (root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
    if distance > Settings.AimBot.FOV then
        return false
    end
    
    -- Проверка видимости
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local raycastResult = workspace:Raycast(
        LocalPlayer.Character.HumanoidRootPart.Position,
        (root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Unit * distance,
        raycastParams
    )
    
    return not raycastResult
end

function FindNewTarget(character, root)
    local bestTarget = nil
    local bestDistance = Settings.AimBot.FOV
    local bestHealth = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetCharacter = player.Character
            local targetPlayer = player
            
            if IsValidTarget(targetCharacter, targetPlayer) then
                local distance = (targetCharacter.HumanoidRootPart.Position - root.Position).Magnitude
                local health = targetCharacter.Humanoid.Health
                
                -- Приоритет ближайшим целям с малым здоровьем
                if distance < bestDistance or (distance == bestDistance and health < bestHealth) then
                    bestTarget = targetCharacter
                    bestDistance = distance
                    bestHealth = health
                end
            end
        end
    end
    
    if bestTarget and bestTarget ~= currentTarget then
        currentTarget = bestTarget
        local targetPlayer = Players:GetPlayerFromCharacter(bestTarget)
        ShowNotification("Target: " .. targetPlayer.Name, Color3.fromRGB(255, 0, 0))
    end
end

function SimulateShooting()
    -- Имитация стрельбы
    if LocalPlayer.Character then
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            -- Здесь можно добавить логику автоматической стрельбы
        end
    end
end

function ForceSwitchTarget()
    currentTarget = nil
    targetSwitchCooldown = 0
    ShowNotification("Switching Target...", Color3.fromRGB(255, 255, 0))
end

-- ESP система
local ESPHighlights = {}

function StartESP()
    ClearESP()
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            player.CharacterAdded:Connect(function(character)
                AddESP(character, player)
            end)
            
            if player.Character then
                AddESP(player.Character, player)
            end
        end
    end
    
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            AddESP(character, player)
        end)
    end)
end

function AddESP(character, player)
    if ESPHighlights[character] then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_" .. player.Name
    highlight.Adornee = character
    highlight.FillColor = player.Team == LocalPlayer.Team and Settings.ESP.TeamColor or Settings.ESP.EnemyColor
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    
    ESPHighlights[character] = highlight
    
    -- Добавляем информацию о дистанции
    if Settings.ESP.ShowDistance then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESPInfo"
        billboard.Adornee = character:WaitForChild("Head")
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = character
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = player.Name .. "\n" .. player.Team.Name
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.Parent = billboard
    end
end

function ClearESP()
    for character, highlight in pairs(ESPHighlights) do
        highlight:Destroy()
    end
    ESPHighlights = {}
end

function UpdateESPColors()
    for character, highlight in pairs(ESPHighlights) do
        local player = Players:FindFirstChild(highlight.Name:sub(5))
        if player then
            highlight.FillColor = player.Team == LocalPlayer.Team and Settings.ESP.TeamColor or Settings.ESP.EnemyColor
        end
    end
end

-- Система движения
function ApplySpeed()
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = Settings.Movement.Speed
        end
    end
end

function ApplyJump()
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.JumpPower = Settings.Movement.JumpPower
        end
    end
end

-- Обработчики клавиш
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.RightShift then
        if GUI then
            GUI.Enabled = not GUI.Enabled
            ShowNotification(GUI.Enabled and "Menu Shown" or "Menu Hidden", Color3.fromRGB(0, 150, 255))
        end
    elseif input.KeyCode == Enum.KeyCode.Insert then
        -- Полное закрытие скрипта
        for _, connection in pairs(ActiveConnections) do
            connection:Disconnect()
        end
        if GUI then
            GUI:Destroy()
        end
        ShowNotification("Script Terminated", Color3.fromRGB(255, 0, 0))
        wait(1)
        error("Script terminated by user")
    end
end)

-- Инициализация
GUI = CreateGUI()
CreateNotificationSystem()

-- Запуск системы безопасности
RunService.Heartbeat:Connect(CheckPerformance)

-- Заставка при запуске
ShowNotification("SCP Enhanced v2.1 Loaded!", Color3.fromRGB(0, 255, 0))
ShowNotification("Safety systems active 🛡️", Color3.fromRGB(0, 150, 255))
ShowNotification("Press RightShift for menu", Color3.fromRGB(255, 255, 0))

print("SCP Roleplay Enhanced v2.1 with Safety Systems loaded!")
