-- Unified Combat Menu by Koliin
local plr = game:GetService("Players").LocalPlayer
local camera = workspace.CurrentCamera
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")

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
        connection:Disconnect()
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
        wait(1) -- Wait for character to fully load
        self:UpdatePlayer(player)
    end)
    
    local characterRemovingConnection = player.CharacterRemoving:Connect(function()
        self:UpdatePlayer(player)
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
        connections.characterAdded:Disconnect()
        connections.characterRemoving:Disconnect()
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
    
    local isValid = self:IsValidTarget(player) and isWarsPlayer(player)
    
    if espData.Box then
        espData.Box.Visible = isValid and self.Enabled
    end
    if espData.Name then
        espData.Name.Visible = isValid and self.Enabled
    end
end

function ESP:UpdateAllPlayers()
    if not self.Enabled then return end
    
    for player, espData in pairs(espObjects) do
        self:UpdatePlayer(player)
    end
end

function ESP:Update()
    if not self.Enabled then return end
    
    for player, espData in pairs(espObjects) do
        if self:IsValidTarget(player) and isWarsPlayer(player) then
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

-- Simple UI Library
local SimpleUI = {}
SimpleUI.__index = SimpleUI

function SimpleUI:CreateWindow(name)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CombatMenu"
    screenGui.Parent = game:GetService("CoreGui")
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 300, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = name
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -10, 1, -40)
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
    button.Size = UDim2.new(1, 0, 0, 35)
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = text
    button.Font = Enum.Font.Gotham
    button.TextSize = 14
    button.Parent = self.ScrollFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    
    button.MouseButton1Click:Connect(function()
        callback()
    end)
    
    table.insert(self.Elements, button)
    self:UpdateSize()
    
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
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = toggleButton
    
    local toggleIndicator = Instance.new("Frame")
    toggleIndicator.Size = UDim2.new(0, 20, 0, 20)
    toggleIndicator.Position = UDim2.new(1, -25, 0.5, -10)
    toggleIndicator.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    toggleIndicator.Parent = toggleButton
    
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(0, 4)
    indicatorCorner.Parent = toggleIndicator
    
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
    table.insert(self.Elements, toggleFrame)
    self:UpdateSize()
    
    return {
        SetState = function(newState)
            state = newState
            updateToggle()
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
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = keybindButton
    
    local keyText = Instance.new("TextLabel")
    keyText.Size = UDim2.new(0, 60, 0, 25)
    keyText.Position = UDim2.new(1, -65, 0.5, -12.5)
    keyText.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    keyText.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyText.Text = defaultKey.Name
    keyText.Font = Enum.Font.GothamBold
    keyText.TextSize = 12
    keyText.Parent = keybindButton
    
    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(0, 4)
    keyCorner.Parent = keyText
    
    local currentKey = defaultKey
    local listening = false
    
    keybindButton.MouseButton1Click:Connect(function()
        if not listening then
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
                    callback(currentKey)
                end
            end)
        end
    end)
    
    table.insert(self.Elements, keybindFrame)
    self:UpdateSize()
    
    return {
        GetKey = function() return currentKey end
    }
end

function SimpleUI:UpdateSize()
    local totalSize = 0
    for _, element in pairs(self.Elements) do
        totalSize = totalSize + element.AbsoluteSize.Y + 5
    end
    self.ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalSize)
end

-- Combat Logic
local combatVars = {
    aimbotKey = Enum.KeyCode.E,
    aimbotActive = false,
    espMode = "WARS"
}

function isWarsPlayer(player)
    if player == plr then return false end
    if not player.Team then return false end
    
    local teamName = player.Team.Name
    return teamName == "Chaos Insurgency" or teamName == "Class-D" or teamName == "SCP"
end

function setupWarsESP()
    ESP:Cleanup() -- Clear previous ESP
    ESP:Toggle(true)
    
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if isWarsPlayer(player) then
            ESP:Add(player, {
                Color = Color3.new(1, 0, 0)
            })
        end
    end
end

function getTargetInView()
    local target = nil
    local closestDistance = math.huge
    
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if isWarsPlayer(player) and ESP:IsValidTarget(player) then
            local head = player.Character.Head
            local screenPoint, onScreen = camera:WorldToViewportPoint(head.Position)
            
            -- Check if player is on screen and within reasonable distance
            if onScreen then
                local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                local mousePos = Vector2.new(screenPoint.X, screenPoint.Y)
                local distance = (center - mousePos).Magnitude
                
                -- Check if player is within view cone (adjust 300 for FOV)
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
local enableESPButton = ui:AddButton("Enable WARS ESP", function()
    setupWarsESP()
    enableESPButton.Text = "WARS ESP Enabled"
    wait(1)
    enableESPButton.Text = "Enable WARS ESP"
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

-- Aimbot Logic
local aiming = false
local autoDisarmActive = false

uis.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == combatVars.aimbotKey and combatVars.aimbotActive then
        aiming = true
        autoDisarmActive = true
        
        while aiming and runService.RenderStepped:Wait() do
            local enemy = getTargetInView()
            if enemy and enemy.Character and enemy.Character:FindFirstChild("Head") then
                -- Smooth aim at head
                local currentCFrame = camera.CFrame
                local targetPosition = enemy.Character.Head.Position
                local newCFrame = CFrame.new(currentCFrame.Position, targetPosition)
                camera.CFrame = newCFrame
                
                -- Auto disarm (continuous)
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

uis.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == combatVars.aimbotKey then
        aiming = false
        autoDisarmActive = false
    end
end)

-- Player tracking for ESP updates
game:GetService("Players").PlayerAdded:Connect(function(player)
    if ESP.Enabled and isWarsPlayer(player) then
        ESP:Add(player, {Color = Color3.new(1, 0, 0)})
    end
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
    ESP:Remove(player)
end)

-- ESP Update Loop
runService.RenderStepped:Connect(function()
    ESP:Update()
end)

-- Anti AFK
for _, connection in pairs(getconnections(plr.Idled)) do
    connection:Disable()
end

print("Combat Menu Loaded! Press RightShift to toggle menu.")
