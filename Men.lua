-- FIXED Enemy Detection System
function isEnemyPlayer(player)
    if player == plr then return false end
    if not player.Team then return false end
    
    local playerTeam = player.Team.Name
    
    if MenuData.SelectedTeam == "Enemy" then
        -- Я выбрал "Враг" - подсвечиваем ТОЛЬКО Class-D и Chaos
        return playerTeam == "Class-D" or playerTeam == "Chaos Insurgency"
    else
        -- Я выбрал "Работник" - подсвечиваем ТОЛЬКО работников (НЕ Class-D и НЕ Chaos)
        return playerTeam ~= "Class-D" and playerTeam ~= "Chaos Insurgency"
    end
end

-- FIXED Color System with proper team detection
function getEnemyColor(player)
    if not player.Team then return Color3.new(1, 1, 1) end
    
    local enemyTeam = player.Team.Name
    
    if MenuData.SelectedTeam == "Enemy" then
        -- Цвета для врагов (Class-D и Chaos)
        if enemyTeam == "Class-D" then
            return Color3.new(1, 1, 0) -- Желтый для Class-D
        elseif enemyTeam == "Chaos Insurgency" then
            return Color3.new(1, 0, 0) -- Красный для Chaos
        else
            return Color3.new(1, 1, 1) -- Белый для остальных
        end
    else
        -- Цвета для работников (врагов - НЕ Class-D и НЕ Chaos)
        if enemyTeam == "Administration" or enemyTeam == "Facility Guard" or enemyTeam == "O5" then
            return Color3.new(0, 0, 1) -- Синий для администрации/охраны
        elseif enemyTeam == "Scientists" or enemyTeam == "Medical" then
            return Color3.new(0, 1, 0) -- Зеленый для ученых/медиков
        elseif enemyTeam == "MTF" or enemyTeam == "Nu-7" or enemyTeam == "MTF E-11" then
            return Color3.new(1, 0, 0) -- Красный для военных
        else
            return Color3.new(1, 0, 1) -- Фиолетовый для остальных работников
        end
    end
end
