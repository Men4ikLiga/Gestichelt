-- Ultimate Combat Menu - FIXED TEAM DETECTION
local plr = game:GetService("Players").LocalPlayer
local camera = workspace.CurrentCamera
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local MenuData = {
    ScreenGui = nil,
    Connections = {},
    Running = true,
    ScriptVersion = "4.2",
    SelectedTeam = "Staff" -- Staff или Enemy
}

-- ESP System
local ESP = {
    Enabled = false,
    Boxes = true,
    Names = true
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
    
    if self.Boxes then
        local box = Drawing.new("Square")
        box.Visible = false
        box.Color = settings.Color or Color3.new(1, 1, 1)
        box.Thickness = 2
        box.Filled = false
        espData.Box = box
    end
    
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

-- FIXED Enemy Detection System
function isEnemyPlayer(player)
    if player == plr then return false end
    if not player.Team then return false end
    
    local enemyTeam = player.Team.Name
    
    if MenuData.SelectedTeam == "Enemy" then
        -- Я выбрал "Враг" - подсвечиваем ТОЛЬКО работников (НЕ Class-D и НЕ Chaos)
        return enemyTeam ~= "Class-D" and enemyTeam ~= "Chaos Insurgency"
    else
        -- Я выбрал "Работник" - подсвечиваем ТОЛЬКО Class-D и Chaos
        return enemyTeam == "Class-D" or enemyTeam == "Chaos Insurgency"
    end
end

-- COMPLETELY FIXED Color System with proper team detection
function getEnemyColor(player)
    if not player.Team then return Color3.new(1, 1, 1) end
    
    local enemyTeam = player.Team.Name
    
    if MenuData.SelectedTeam == "Enemy" then
        -- Цвета для врагов (работников) - Class-D и Chaos НЕ должны сюда попадать
        
        -- Сначала проверяем администрацию/охрану
        if enemyTeam == "Administration" or enemyTeam == "Facility Guard" or enemyTeam == "O5" then
            return Color3.new(0, 0, 1) -- Синий для администрации/охраны
        
        -- Затем проверяем ученых/медиков
        elseif enemyTeam == "Scientists" or enemyTeam == "Medical" then
            return Color3.new(0, 1, 0) -- Зеленый для ученых/медиков
        
        -- Затем проверяем военных
        elseif enemyTeam == "MTF" or enemyTeam == "Nu-7" or enemyTeam == "MTF E-11" then
            return Color3.new(1, 0, 0) -- Красный для военных
        
        -- Все остальные работники (которые не Class-D и не Chaos)
        else
            return Color3.new(1, 0, 1) -- Фиолетовый для остальных работников
        end
        
    else
        -- Цвета для работников (врагов - Class-D и Chaos)
        if enemyTeam == "Class-D" then
            return Color3.new(1, 1, 0) -- Желтый для Class-D
        elseif enemyTeam == "Chaos Insurgency" then
            return Color3.new(0, 0, 0) -- Черный для Chaos
        else
            return Color3.new(1, 1, 1) -- Белый для остальных
        end
    end
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
                if espData.Box then
                    espData.Box.Visible = true
                    espData.Box.Size = Vector2.new(2000 / position.Z, 4000 / position.Z)
                    espData.Box.Position = Vector2.new(position.X - espData.Box.Size.X / 2, position.Y - espData.Box.Size.Y / 2)
                end
                
                if espData.Name then
                    espData.Name.Visible = true
                    espData.Name.Position = Vector2.new(position.X, position.Y - espData.Box.Size.Y / 2 - 20)
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

-- Aimbot System
local combatVars = {
    aimbotKey = Enum.KeyCode.E,
    aimbotActive = false,
    autoShoot = false
}

function getTargetInView()
    local target = nil
    local closestDistance = math.huge
    
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if isEnemyPlayer(player) and ESP:IsValidTarget(player) then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local screenPoint, onScreen = camera:WorldToViewportPoint(head.Position)
                
                if onScreen then
                    -- Raycast check
                    local rayOrigin = camera.CFrame.Position
                    local rayDirection = (head.Position - rayOrigin).Unit * 1000
                    local raycastParams = RaycastParams.new()
                    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                    raycastParams.FilterDescendantsInstances = {plr.Character}
                    
                    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                    
                    local isVisible = false
                    if raycastResult then
                        local hitModel = raycastResult.Instance:FindFirstAncestorOfClass("Model")
                        if hitModel == player.Character then
                            isVisible = true
                        end
                    else
                        isVisible = true
                    end
                    
                    if isVisible then
                        local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                        local mousePos = Vector2.new(screenPoint.X, screenPoint.Y)
                        local distance = (center - mousePos).Magnitude
                        
                        if distance < 300 and distance < closestDistance then
                            target = player
                            closestDistance = distance
                        end
                    end
                end
            end
        end
    end
    return target
end

-- Auto shoot function
function autoShootAtTarget(target)
    if target and target.Character and target.Character:FindFirstChild("Head") then
        pcall(function()
            local targetPosition = target.Character.Head.Position
            local args = {
                [1] = {
                    [1] = targetPosition.X,
                    [2] = targetPosition.Y,
                    [3] = targetPosition.Z
                },
                [2] = target.Character.Head
            }
            game:GetService("ReplicatedStorage").Remotes.ShootRemote:FireServer(unpack(args))
        end)
    end
end

-- Simple UI with Team Selection
local SimpleUI = {}
SimpleUI.__index = SimpleUI

function SimpleUI:CreateWindow(name)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CombatMenu_" .. tick()
    screenGui.Parent = game:GetService("CoreGui")
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 350, 0, 550)
    mainFrame.Position = UDim2.new(0.5, -175, 0.5, -275)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 35)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    titleBar.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.7, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = name .. " v" .. MenuData.ScriptVersion
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Position = UDim2.new(0.05, 0, 0, 0)
    title.Parent = titleBar
    
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 25, 0, 25)
    closeButton.Position = UDim2.new(0.9, 0, 0.15, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Text = "X"
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 14
    closeButton.Parent = titleBar
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -10, 1, -200)
    scrollFrame.Position = UDim2.new(0, 5, 0, 40)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 5
    scrollFrame.Parent = mainFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = scrollFrame
    
    local bottomFrame = Instance.new("Frame")
    bottomFrame.Size = UDim2.new(1, -10, 0, 150)
    bottomFrame.Position = UDim2.new(0, 5, 1, -155)
    bottomFrame.BackgroundTransparency = 1
    bottomFrame.Parent = mainFrame
    
    local self = setmetatable({
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        ScrollFrame = scrollFrame,
        BottomFrame = bottomFrame,
        Elements = {}
    }, SimpleUI)
    
    MenuData.ScreenGui = screenGui
    
    closeButton.MouseButton1Click:Connect(function()
        MenuData.Running = false
        ESP:Cleanup()
        screenGui:Destroy()
        for _, conn in pairs(MenuData.Connections) do
            pcall(function() conn:Disconnect() end)
        end
        print("Combat Menu closed completely")
    end)
    
    uis.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.RightShift and MenuData.Running then
            mainFrame.Visible = not mainFrame.Visible
        end
    end)
    
    return self
end

function SimpleUI:AddButton(text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 35)
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = text
    button.Font = Enum.Font.Gotham
    button.TextSize = 14
    button.Parent = self.ScrollFrame
    
    button.MouseButton1Click:Connect(function()
        if MenuData.Running then
            callback()
        end
    end)
    
    return button
end

function SimpleUI:AddToggle(text, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, 0, 0, 35)
    toggleFrame.BackgroundTransparency = 1
    toggleFrame.Parent = self.ScrollFrame
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(1, 0, 1, 0)
    toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Text = text
    toggleButton.Font = Enum.Font.Gotham
    toggleButton.TextSize = 14
    toggleButton.TextXAlignment = Enum.TextXAlignment.Left
    toggleButton.Parent = toggleFrame
    
    local toggleIndicator = Instance.new("Frame")
    toggleIndicator.Size = UDim2.new(0, 20, 0, 20)
    toggleIndicator.Position = UDim2.new(0.9, -25, 0.2, 0)
    toggleIndicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    toggleIndicator.Parent = toggleButton
    
    local state = false
    
    local function updateToggle()
        if state then
            toggleIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        else
            toggleIndicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        end
        if MenuData.Running then
            callback(state)
        end
    end
    
    toggleButton.MouseButton1Click:Connect(function()
        if MenuData.Running then
            state = not state
            updateToggle()
        end
    end)
    
    updateToggle()
    
    return {
        SetState = function(newState)
            if MenuData.Running then
                state = newState
                updateToggle()
            end
        end
    }
end

function SimpleUI:AddKeybind(text, defaultKey, callback)
    local keybindFrame = Instance.new("Frame")
    keybindFrame.Size = UDim2.new(1, 0, 0, 35)
    keybindFrame.BackgroundTransparency = 1
    keybindFrame.Parent = self.ScrollFrame
    
    local keybindButton = Instance.new("TextButton")
    keybindButton.Size = UDim2.new(1, 0, 1, 0)
    keybindButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    keybindButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    keybindButton.Text = text
    keybindButton.Font = Enum.Font.Gotham
    keybindButton.TextSize = 14
    keybindButton.TextXAlignment = Enum.TextXAlignment.Left
    keybindButton.Parent = keybindFrame
    
    local keyText = Instance.new("TextLabel")
    keyText.Size = UDim2.new(0, 60, 0, 25)
    keyText.Position = UDim2.new(0.85, -65, 0.15, 0)
    keyText.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    keyText.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyText.Text = defaultKey.Name
    keyText.Font = Enum.Font.GothamBold
    keyText.TextSize = 12
    keyText.Parent = keybindButton
    
    local currentKey = defaultKey
    local listening = false
    
    keybindButton.MouseButton1Click:Connect(function()
        if MenuData.Running and not listening then
            listening = true
            keyText.Text = "..."
            keyText.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
            
            local connection
            connection = uis.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    currentKey = input.KeyCode
                    keyText.Text = input.KeyCode.Name
                    keyText.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                    listening = false
                    connection:Disconnect()
                    if MenuData.Running then
                        callback(currentKey)
                    end
                end
            end)
        end
    end)
    
    return {
        GetKey = function() return currentKey end
    }
end

-- Team Selection Function
function SimpleUI:AddTeamSelector()
    local teamFrame = Instance.new("Frame")
    teamFrame.Size = UDim2.new(1, 0, 0, 80)
    teamFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    teamFrame.Parent = self.BottomFrame
    
    local teamLabel = Instance.new("TextLabel")
    teamLabel.Size = UDim2.new(1, 0, 0, 25)
    teamLabel.BackgroundTransparency = 1
    teamLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    teamLabel.Text = "Select Your Team:"
    teamLabel.Font = Enum.Font.GothamBold
    teamLabel.TextSize = 14
    teamLabel.Parent = teamFrame
    
    local staffButton = Instance.new("TextButton")
    staffButton.Size = UDim2.new(0.45, 0, 0, 35)
    staffButton.Position = UDim2.new(0.025, 0, 0.5, 0)
    staffButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    staffButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    staffButton.Text = "Staff"
    staffButton.Font = Enum.Font.GothamBold
    staffButton.TextSize = 14
    staffButton.Parent = teamFrame
    
    local enemyButton = Instance.new("TextButton")
    enemyButton.Size = UDim2.new(0.45, 0, 0, 35)
    enemyButton.Position = UDim2.new(0.525, 0, 0.5, 0)
    enemyButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    enemyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    enemyButton.Text = "Enemy"
    enemyButton.Font = Enum.Font.GothamBold
    enemyButton.TextSize = 14
    enemyButton.Parent = teamFrame
    
    local function updateTeamButtons()
        if MenuData.SelectedTeam == "Staff" then
            staffButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
            enemyButton.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
        else
            staffButton.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
            enemyButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        end
    end
    
    staffButton.MouseButton1Click:Connect(function()
        if MenuData.Running then
            MenuData.SelectedTeam = "Staff"
            updateTeamButtons()
            print("Team set to: Staff")
            print("🟡 Yellow = Class-D")
            print("⚫ Black = Chaos Insurgency")
            print("❌ Staff members are NOT highlighted!")
            if ESP.Enabled then
                setupEnemyESP()
            end
        end
    end)
    
    enemyButton.MouseButton1Click:Connect(function()
        if MenuData.Running then
            MenuData.SelectedTeam = "Enemy"
            updateTeamButtons()
            print("Team set to: Enemy")
            print("🔵 Blue = Administration/Guards")
            print("🟢 Green = Scientists/Medical") 
            print("🔴 Red = MTF/Military")
            print("🟣 Purple = Other Staff")
            print("❌ Class-D and Chaos are NOT highlighted!")
            if ESP.Enabled then
                setupEnemyESP()
            end
        end
    end)
    
    updateTeamButtons()
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

-- Team Selection
ui:AddTeamSelector()

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

local autoShootToggle = ui:AddToggle("Auto Shoot", function(state)
    combatVars.autoShoot = state
end)

local keybind = ui:AddKeybind("Aimbot Key", Enum.KeyCode.E, function(newKey)
    combatVars.aimbotKey = newKey
    print("Aimbot key changed to: " .. newKey.Name)
end)

-- Aimbot Logic
local aiming = false

local aimbotConnection = uis.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == combatVars.aimbotKey and combatVars.aimbotActive and MenuData.Running then
        aiming = true
        
        while aiming and MenuData.Running and runService.RenderStepped:Wait() do
            local enemy = getTargetInView()
            if enemy and enemy.Character and enemy.Character:FindFirstChild("Head") then
                local currentCFrame = camera.CFrame
                local targetPosition = enemy.Character.Head.Position
                local newCFrame = CFrame.new(currentCFrame.Position, targetPosition)
                camera.CFrame = newCFrame
                
                if combatVars.autoShoot then
                    autoShootAtTarget(enemy)
                end
            end
        end
    end
end)

local aimbotEndConnection = uis.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == combatVars.aimbotKey then
        aiming = false
    end
end)

-- Player tracking
local playerAddedConnection = game:GetService("Players").PlayerAdded:Connect(function(player)
    wait(2)
    if MenuData.Running and ESP.Enabled and isEnemyPlayer(player) then
        local color = getEnemyColor(player)
        ESP:Add(player, {Color = color})
    end
end)

local playerRemovingConnection = game:GetService("Players").PlayerRemoving:Connect(function(player)
    if MenuData.Running then
        ESP:Remove(player)
    end
end)

-- ESP Update Loop
local espUpdateConnection = runService.RenderStepped:Connect(function()
    if MenuData.Running and ESP.Enabled then
        ESP:Update()
    end
end)

-- Store connections
table.insert(MenuData.Connections, aimbotConnection)
table.insert(MenuData.Connections, aimbotEndConnection)
table.insert(MenuData.Connections, playerAddedConnection)
table.insert(MenuData.Connections, playerRemovingConnection)
table.insert(MenuData.Connections, espUpdateConnection)

-- Auto setup
coroutine.wrap(function()
    wait(5)
    print("Ultimate Combat Menu v" .. MenuData.ScriptVersion .. " Loaded!")
    print("Press RightShift to open/hide menu")
    print("Press X to completely close the script")
    print("Current Team: " .. MenuData.SelectedTeam)
end)()
