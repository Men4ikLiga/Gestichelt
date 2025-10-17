-- Unified Combat Menu by Koliin
local plr = game:GetService("Players").LocalPlayer
local camera = workspace.CurrentCamera
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")

-- Simple ESP Implementation
local ESP = {
    Enabled = false,
    Players = false,
    Boxes = true,
    Names = true,
    Tracers = false
}

local espObjects = {}

function ESP:Toggle(state)
    self.Enabled = state
    if not state then
        for _, obj in pairs(espObjects) do
            if obj then
                obj:Remove()
            end
        end
        espObjects = {}
    else
        self:Update()
    end
end

function ESP:Add(player, settings)
    if espObjects[player] then return end
    
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
end

function ESP:Update()
    if not self.Enabled then return end
    
    for player, espData in pairs(espObjects) do
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
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
    
    button.MouseButton1Click:Connect(callback)
    
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
    ESP:Toggle(true)
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if isWarsPlayer(player) then
            ESP:Add(player, {
                Color = Color3.new(1, 0, 0)
            })
        end
    end
end

function getClosestWarsPlayer()
    local target = nil
    local maxDist = math.huge
    
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if isWarsPlayer(player) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (player.Character.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
            if dist < maxDist then
                target = player
                maxDist = dist
            end
        end
    end
    return target
end

-- Create UI
local ui = SimpleUI:CreateWindow("Combat Menu")

-- ESP Section
ui:AddButton("Enable WARS ESP", function()
    setupWarsESP()
end)

ui:AddButton("Disable ESP", function()
    ESP:Toggle(false)
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

uis.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == combatVars.aimbotKey and combatVars.aimbotActive then
        aiming = true
        while aiming and runService.RenderStepped:Wait() do
            local enemy = getClosestWarsPlayer()
            if enemy and enemy.Character and enemy.Character:FindFirstChild("Head") and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                -- Aim at head
                camera.CFrame = CFrame.new(camera.CFrame.Position, enemy.Character.Head.Position)
                
                -- Auto shoot
                pcall(function()
                    local args = {
                        [1] = {
                            [1] = enemy.Character.Head.Position.X,
                            [2] = enemy.Character.Head.Position.Y,
                            [3] = enemy.Character.Head.Position.Z
                        },
                        [2] = enemy.Character.Head
                    }
                    game:GetService("ReplicatedStorage").Remotes.ShootRemote:FireServer(unpack(args))
                end)
            end
        end
    end
end)

uis.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == combatVars.aimbotKey then
        aiming = false
    end
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
