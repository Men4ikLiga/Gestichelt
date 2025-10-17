-- Unified Combat Menu by Koliin
local plr = game:GetService("Players").LocalPlayer
local camera = workspace.CurrentCamera
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local ts = game:GetService("TeleportService")
local http = game:GetService("HttpService")

-- Global variables for cleanup
local MenuData = {
    ScreenGui = nil,
    ESPEnabled = false,
    Connections = {},
    Running = true,
    ScriptVersion = "1.3"
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

-- Advanced Enemy Detection System
function getPlayerTeam()
    if not plr or not plr.Team then return "Unknown" end
    return plr.Team.Name
end

function isEnemyPlayer(player)
    if player == plr then return false end
    if not player.Team then return false end
    
    local myTeam = getPlayerTeam()
    local enemyTeam = player.Team.Name
    
    -- Если я Повстанец Хаоса (черные)
    if myTeam == "Chaos Insurgency" then
        -- Все кроме Повстанцев - враги
        return enemyTeam ~= "Chaos Insurgency"
    
    -- Если я Класс-D (желтые) 
    elseif myTeam == "Class-D" then
        -- Все кроме Класс-D - враги
        return enemyTeam ~= "Class-D"
    
    -- Если я SCP
    elseif myTeam == "SCP" then
        -- Все люди - враги
        return enemyTeam ~= "SCP"
    
    -- Если я Военный (MTF)
    elseif myTeam == "MTF" or myTeam == "Nu-7" or myTeam == "MTF E-11" then
        -- Повстанцы, Класс-D, SCP - враги
        return enemyTeam == "Chaos Insurgency" or enemyTeam == "Class-D" or enemyTeam == "SCP"
    
    -- Если я Ученый/Администрация/Охранник
    elseif myTeam == "Scientists" or myTeam == "Administration" or myTeam == "Facility Guard" then
        -- Повстанцы, Класс-D, SCP - враги
        return enemyTeam == "Chaos Insurgency" or enemyTeam == "Class-D" or enemyTeam == "SCP"
    
    -- Если команда неизвестна или нет команды
    else
        -- Все кроме моей команды - враги
        return enemyTeam ~= myTeam
    end
end

function getEnemyColor(player)
    if not player.Team then return Color3.new(1, 1, 1) end
    
    local enemyTeam = player.Team.Name
    
    -- Военные - красный
    if enemyTeam == "MTF" or enemyTeam == "Nu-7" or enemyTeam == "MTF E-11" then
        return Color3.new(1, 0, 0) -- Красный
    
    -- Врачи/Ученые - синий
    elseif enemyTeam == "Scientists" or enemyTeam == "Medical" then
        return Color3.new(0, 0.5, 1) -- Синий
    
    -- Администрация/Охранники - зеленый
    elseif enemyTeam == "Administration" or enemyTeam == "Facility Guard" then
        return Color3.new(0, 1, 0) -- Зеленый
    
    -- Повстанцы Хаоса - оранжевый
    elseif enemyTeam == "Chaos Insurgency" then
        return Color3.new(1, 0.5, 0) -- Оранжевый
    
    -- Класс-D - желтый
    elseif enemyTeam == "Class-D" then
        return Color3.new(1, 1, 0) -- Желтый
    
    -- SCP - фиолетовый
    elseif enemyTeam == "SCP" then
        return Color3.new(0.5, 0, 1) -- Фиолетовый
    
    -- Остальные - белый
    else
        return Color3.new(1, 1, 1)
    end
end

-- Simple UI Library (остальная часть кода остается без изменений)
-- ... [остальной код UI без изменений] ...

-- Combat Logic
local combatVars = {
    aimbotKey = Enum.KeyCode.E,
    aimbotActive = false,
    espMode = "ENEMIES"
}

function setupEnemyESP()
    ESP:Cleanup()
    ESP:Toggle(true)
    
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if isEnemyPlayer(player) then
            local color = getEnemyColor(player)
            ESP:Add(player, {Color = color})
        end
    end
end

function getTargetInView()
    local target = nil
    local closestDistance = math.huge
    
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if isEnemyPlayer(player) and ESP:IsValidTarget(player) then
            local head = player.Character.Head
            local screenPoint, onScreen = camera:WorldToViewportPoint(head.Position)
            
            if onScreen then
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
    return target
end

-- Create UI
local ui = SimpleUI:CreateWindow("Combat Menu")

-- ESP Section
local enableESPButton = ui:AddButton("Enable Enemy ESP", function()
    setupEnemyESP()
    enableESPButton.Text = "Enemy ESP Enabled"
    wait(1)
    enableESPButton.Text = "Enable Enemy ESP"
end)

local disableESPButton = ui:AddButton("Disable ESP", function()
    ESP:Toggle(false)
    disableESPButton.Text = "ESP Disabled"
    wait(1)
    disableESPButton.Text = "Disable ESP"
end)

-- Aimbot Section
local aimbotToggle = ui:AddToggle("Aimbot Active", function(state)
    combatVars.aimbotActive = state
end)

local keybind = ui:AddKeybind("Aimbot Key", Enum.KeyCode.E, function(newKey)
    combatVars.aimbotKey = newKey
end)

-- Reload and Close Buttons
local reloadButton = ui:AddBottomButton("🔄 RELOAD SCRIPT", Color3.fromRGB(50, 150, 200), function()
    reloadButton.Text = "Reloading..."
    ReloadScript()
end)

local closeButton = ui:AddBottomButton("❌ CLOSE MENU", Color3.fromRGB(200, 50, 50), function()
    ui.MainFrame.Visible = false
end)

-- Aimbot Logic
local aiming = false
local autoDisarmActive = false

local aimbotConnection = uis.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == combatVars.aimbotKey and combatVars.aimbotActive and MenuData.Running then
        aiming = true
        autoDisarmActive = true
        
        while aiming and MenuData.Running and runService.RenderStepped:Wait() do
            local enemy = getTargetInView()
            if enemy and enemy.Character and enemy.Character:FindFirstChild("Head") then
                local currentCFrame = camera.CFrame
                local targetPosition = enemy.Character.Head.Position
                local newCFrame = CFrame.new(currentCFrame.Position, targetPosition)
                camera.CFrame = newCFrame
                
                if autoDisarmActive then
                    pcall(function()
                        local args = {
                            [1] = {
                                [1] = targetPosition.X,
                                [2] = targetPosition.Y,
                                [3] = targetPosition.Z
                            },
                            [2] = enemy.Character.Head
                        }
                        game:GetService("ReplicatedStorage").Remotes.ShootRemote:FireServer(unpack(args))
                    end)
                end
            end
        end
    end
end)
table.insert(MenuData.Connections, aimbotConnection)

local aimbotEndConnection = uis.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == combatVars.aimbotKey then
        aiming = false
        autoDisarmActive = false
    end
end)
table.insert(MenuData.Connections, aimbotEndConnection)

-- Player tracking for ESP updates
local playerAddedConnection = game:GetService("Players").PlayerAdded:Connect(function(player)
    if ESP.Enabled and isEnemyPlayer(player) and MenuData.Running then
        local color = getEnemyColor(player)
        ESP:Add(player, {Color = color})
    end
end)
table.insert(MenuData.Connections, playerAddedConnection)

local playerRemovingConnection = game:GetService("Players").PlayerRemoving:Connect(function(player)
    if MenuData.Running then
        ESP:Remove(player)
    end
end)
table.insert(MenuData.Connections, playerRemovingConnection)

-- Team change tracking
local function trackTeamChanges()
    if plr and plr.Team then
        local lastTeam = plr.Team
        while MenuData.Running do
            wait(1)
            if plr.Team ~= lastTeam then
                lastTeam = plr.Team
                if ESP.Enabled then
                    setupEnemyESP() -- Перезагрузить ESP при смене команды
                end
            end
        end
    end
end

coroutine.wrap(trackTeamChanges)()

-- ESP Update Loop
local espUpdateConnection = runService.RenderStepped:Connect(function()
    if MenuData.Running then
        ESP:Update()
    end
end)
table.insert(MenuData.Connections, espUpdateConnection)

-- Anti AFK
for _, connection in pairs(getconnections(plr.Idled)) do
    connection:Disable()
end

print("Advanced Combat Menu Loaded! v" .. MenuData.ScriptVersion)
print("Enemy detection system active - ESP will adapt to your current team")
print("Press RightShift to toggle menu")
