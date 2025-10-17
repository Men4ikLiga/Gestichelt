-- Unified Combat Menu by Koliin - FIXED VERSION
local plr = game:GetService("Players").LocalPlayer
local camera = workspace.CurrentCamera
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")

-- Global variables for cleanup
local MenuData = {
    ScreenGui = nil,
    ESPEnabled = false,
    Connections = {},
    Running = true,
    ScriptVersion = "1.6"
}

-- Improved ESP Implementation
local ESP = {
    Enabled = false,
    Players = false,
    Boxes = true,
    Names = true,
    Tracers = false
}

local espObjects = {}
local espConnections = {}

function ESP:Cleanup()
    for player, espData in pairs(espObjects) do
        if espData.Box then espData.Box:Remove() end
        if espData.Name then espData.Name:Remove() end
    end
    espObjects = {}
    
    for _, connection in pairs(espConnections) do
        if connection.characterAdded then connection.characterAdded:Disconnect() end
        if connection.characterRemoving then connection.characterRemoving:Disconnect() end
    end
    espConnections = {}
end

function ESP:Toggle(state)
    self.Enabled = state
    if not state then
        self:Cleanup()
    else
        self:UpdateAllPlayers()
    end
end

function ESP:Add(player, settings)
    if espObjects[player] then 
        self:Remove(player)
    end
    
    local espData = {}
    
    -- Create Box
    if self.Boxes then
        local box = Drawing.new("Square")
        box.Visible = false
        box.Color = settings.Color or Color3.new(1, 0, 0)
        box.Thickness = 2
        box.Filled = false
        espData.Box = box
    end
    
    -- Create Name
    if self.Names then
        local name = Drawing.new("Text")
        name.Visible = false
        name.Color = settings.Color or Color3.new(1, 1, 1)
        name.Size = 14
        name.Text = player.Name
        name.Center = true
        espData.Name = name
    end
    
    espObjects[player] = espData
    
    -- Track player state changes
    local characterAddedConnection = player.CharacterAdded:Connect(function(character)
        wait(1)
        if MenuData.Running then
            self:UpdatePlayer(player)
        end
    end)
    
    local characterRemovingConnection = player.CharacterRemoving:Connect(function()
        if MenuData.Running then
            self:UpdatePlayer(player)
        end
    end)
    
    espConnections[player] = {
        characterAdded = characterAddedConnection,
        characterRemoving = characterRemovingConnection
    }
end

function ESP:Remove(player)
    local espData = espObjects[player]
    if espData then
        if espData.Box then espData.Box:Remove() end
        if espData.Name then espData.Name:Remove() end
        espObjects[player] = nil
    end
    
    local connections = espConnections[player]
    if connections then
        if connections.characterAdded then connections.characterAdded:Disconnect() end
        if connections.characterRemoving then connections.characterRemoving:Disconnect() end
        espConnections[player] = nil
    end
end

function ESP:IsValidTarget(player)
    if not player then return false end
    if not player.Character then return false end
    
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    if humanoid.Health <= 0 then return false end
    
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    return true
end

-- Improved Enemy Detection System
function getPlayerTeam()
    if not plr or not plr.Team then return "Unknown" end
    return plr.Team.Name
end

function isEnemyPlayer(player)
    if player == plr then return false end
    if not player.Team then return false end
    
    local myTeam = getPlayerTeam()
    local enemyTeam = player.Team.Name
    
    -- Если я Класс-D или Повстанец Хаоса
    if myTeam == "Class-D" or myTeam == "Chaos Insurgency" then
        -- Подсвечиваем всех кроме Класс-D и Повстанцев
        return enemyTeam ~= "Class-D" and enemyTeam ~= "Chaos Insurgency"
    
    -- Если я НЕ Класс-D и НЕ Повстанец
    else
        -- Подсвечиваем только Класс-D и Повстанцев
        return enemyTeam == "Class-D" or enemyTeam == "Chaos Insurgency"
    end
end

function getEnemyColor(player)
    if not player.Team then return Color3.new(1, 1, 1) end
    
    local myTeam = getPlayerTeam()
    local enemyTeam = player.Team.Name
    
    -- Если я Класс-D или Повстанец
    if myTeam == "Class-D" or myTeam == "Chaos Insurgency" then
        -- Военные - красный
        if enemyTeam == "MTF" or enemyTeam == "Nu-7" or enemyTeam == "MTF E-11" then
            return Color3.new(1, 0, 0) -- Красный
        -- Ученые/Медики - зеленый
        elseif enemyTeam == "Scientists" or enemyTeam == "Medical" then
            return Color3.new(0, 1, 0) -- Зеленый
        -- Администрация/Охрана - синий
        elseif enemyTeam == "Administration" or enemyTeam == "Facility Guard" then
            return Color3.new(0, 0, 1) -- Синий
        end
    
    -- Если я работник
    else
        -- Класс-D - желтый
        if enemyTeam == "Class-D" then
            return Color3.new(1, 1, 0) -- Желтый
        -- Повстанцы Хаоса - красный
        elseif enemyTeam == "Chaos Insurgency" then
            return Color3.new(1, 0, 0) -- Красный
        end
    end
    
    return Color3.new(1, 1, 1) -- Белый для остальных
end

function ESP:UpdatePlayer(player)
    local espData = espObjects[player]
    if not espData then return end
    
    local isValid = self:IsValidTarget(player) and isEnemyPlayer(player)
    local color = getEnemyColor(player)
    
    if espData.Box then
        espData.Box.Visible = isValid and self.Enabled and MenuData.Running
        espData.Box.Color = color
    end
    if espData.Name then
        espData.Name.Visible = isValid and self.Enabled and MenuData.Running
        espData.Name.Color = color
        espData.Name.Text = player.Name .. " [" .. (player.Team and player.Team.Name or "No Team") .. "]"
    end
end

function ESP:UpdateAllPlayers()
    if not self.Enabled then return end
    
    for player, espData in pairs(espObjects) do
        self:UpdatePlayer(player)
    end
end

function ESP:Update()
    if not self.Enabled or not MenuData.Running then return end
    
    for player, espData in pairs(espObjects) do
        if self:IsValidTarget(player) and isEnemyPlayer(player) then
            local rootPart = player.Character.HumanoidRootPart
            local position, onScreen = camera:WorldToViewportPoint(rootPart.Position)
            
            if onScreen then
                -- Update Box
                if espData.Box then
                    espData.Box.Visible = true
                    espData.Box.Size = Vector2.new(2000 / position.Z, 3000 / position.Z)
                    espData.Box.Position = Vector2.new(position.X, position.Y)
                end
                
                -- Update Name
                if espData.Name then
                    espData.Name.Visible = true
                    espData.Name.Position = Vector2.new(position.X, position.Y - 40)
                end
            else
                if espData.Box then espData.Box.Visible = false end
                if espData.Name then espData.Name.Visible = false end
            end
        else
            if espData.Box then espData.Box.Visible = false end
            if espData.Name then espData.Name.Visible = false end
        end
    end
end

-- Simple UI Library (исправленная версия)
local SimpleUI = {}
SimpleUI.__index = SimpleUI

function SimpleUI:CreateWindow(name)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CombatMenu_" .. tick()
    screenGui.Parent = game:GetService("CoreGui")
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 320, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    titleBar.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.7, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = name .. " v" .. MenuData.ScriptVersion
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Position = UDim2.new(0.05, 0, 0, 0)
    title.Parent = titleBar
    
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 25, 0, 25)
    closeButton.Position = UDim2.new(0.9, 0, 0.1, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Text = "X"
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 12
    closeButton.Parent = titleBar
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -10, 1, -100)
    scrollFrame.Position = UDim2.new(0, 5, 0, 35)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 5
    scrollFrame.Parent = mainFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = scrollFrame
    
    local self = setmetatable({
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        ScrollFrame = scrollFrame,
        Elements = {}
    }, SimpleUI)
    
    MenuData.ScreenGui = screenGui
    
    -- Close button functionality
    closeButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
    end)
    
    -- Toggle key
    uis.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.RightShift then
            mainFrame.Visible = not mainFrame.Visible
        end
    end)
    
    return self
end

function SimpleUI:AddButton(text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 30)
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = text
    button.Font = Enum.Font.Gotham
    button.TextSize = 12
    button.Parent = self.ScrollFrame
    
    button.MouseButton1Click:Connect(function()
        callback()
    end)
    
    return button
end

function SimpleUI:AddToggle(text, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, 0, 0, 30)
    toggleFrame.BackgroundTransparency = 1
    toggleFrame.Parent = self.ScrollFrame
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(1, 0, 1, 0)
    toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Text = text
    toggleButton.Font = Enum.Font.Gotham
    toggleButton.TextSize = 12
    toggleButton.TextXAlignment = Enum.TextXAlignment.Left
    toggleButton.Parent = toggleFrame
    
    local toggleIndicator = Instance.new("Frame")
    toggleIndicator.Size = UDim2.new(0, 20, 0, 20)
    toggleIndicator.Position = UDim2.new(0.9, -25, 0.15, 0)
    toggleIndicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    toggleIndicator.Parent = toggleButton
    
    local state = false
    
    local function updateToggle()
        if state then
            toggleIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        else
            toggleIndicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        end
        callback(state)
    end
    
    toggleButton.MouseButton1Click:Connect(function()
        state = not state
        updateToggle()
    end)
    
    updateToggle()
    
    return {
        SetState = function(newState)
            state = newState
            updateToggle()
        end
    }
end

-- Improved Aimbot System
local combatVars = {
    aimbotKey = Enum.KeyCode.E,
    aimbotActive = false
}

function getTargetInView()
    local target = nil
    local closestDistance = math.huge
    
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if isEnemyPlayer(player) then
            local character = player.Character
            if character and character:FindFirstChild("Head") then
                local head = character.Head
                local screenPoint, onScreen = camera:WorldToViewportPoint(head.Position)
                
                if onScreen then
                    -- Simple distance check (без raycast для простоты)
                    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                    local mousePos = Vector2.new(screenPoint.X, screenPoint.Y)
                    local distance = (center - mousePos).Magnitude
                    
                    if distance < 200 and distance < closestDistance then
                        target = player
                        closestDistance = distance
                    end
                end
            end
        end
    end
    return target
end

function setupEnemyESP()
    ESP:Cleanup()
    
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if isEnemyPlayer(player) then
            local color = getEnemyColor(player)
            ESP:Add(player, {Color = color})
        end
    end
    
    ESP:Toggle(true)
end

-- Create UI
local ui = SimpleUI:CreateWindow("Combat Menu")

-- ESP Section
ui:AddButton("Enable Enemy ESP", function()
    setupEnemyESP()
end)

ui:AddButton("Disable ESP", function()
    ESP:Toggle(false)
end)

-- Aimbot Section
local aimbotToggle = ui:AddToggle("Aimbot Active", function(state)
    combatVars.aimbotActive = state
end)

-- Aimbot Logic
local aiming = false

uis.InputBegan:Connect(function(input)
    if input.KeyCode == combatVars.aimbotKey and combatVars.aimbotActive then
        aiming = true
        
        while aiming and runService.RenderStepped:Wait() do
            local enemy = getTargetInView()
            if enemy and enemy.Character and enemy.Character:FindFirstChild("Head") then
                local currentCFrame = camera.CFrame
                local targetPosition = enemy.Character.Head.Position
                local newCFrame = CFrame.new(currentCFrame.Position, targetPosition)
                camera.CFrame = newCFrame
            end
        end
    end
end)

uis.InputEnded:Connect(function(input)
    if input.KeyCode == combatVars.aimbotKey then
        aiming = false
    end
end)

-- Player tracking
game:GetService("Players").PlayerAdded:Connect(function(player)
    wait(2)
    if ESP.Enabled and isEnemyPlayer(player) then
        local color = getEnemyColor(player)
        ESP:Add(player, {Color = color})
    end
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
    ESP:Remove(player)
end)

-- Team change tracking
coroutine.wrap(function()
    if plr and plr.Team then
        local lastTeam = plr.Team
        while true do
            wait(2)
            if plr.Team ~= lastTeam then
                lastTeam = plr.Team
                if ESP.Enabled then
                    setupEnemyESP()
                end
            end
        end
    end
end)()

-- ESP Update Loop
runService.RenderStepped:Connect(function()
    ESP:Update()
end)

-- Auto setup ESP for existing players
coroutine.wrap(function()
    wait(3)
    setupEnemyESP()
end)()

print("Combat Menu Fixed Version Loaded! v" .. MenuData.ScriptVersion)
print("Press RightShift to toggle menu")
print("Features: Fixed ESP colors, Improved Aimbot, Auto team tracking")
