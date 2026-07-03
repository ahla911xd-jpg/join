-- UNIFIED SIMULATION ENGINE, RED THEME & EQUIP COMPATIBLE
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Verify game data core is active
local Fsys = require(ReplicatedStorage:WaitForChild("Fsys"))
local UIManager = Fsys.load("UIManager")
local InventoryDB = Fsys.load("InventoryDB")
local ClientData = Fsys.load("ClientData")

-- Cache state hooks safely
local data = nil
local activeFlags = {F = false, R = false, N = false, M = false}

-- ========================================================
-- 1. ADOPT ME INVENTORY & EQUIP INJECTION HOOKS
-- ========================================================
-- Force local inventory data updates to remain persistently equipable
local function forceInventoryPatch()
    local inventory = ClientData.get("inventory")
    if inventory and inventory.pets then
        -- Hooks into internal state changes so equipping doesn't trigger item desync
        for fakeId, item in pairs(inventory.pets) do
            if string.sub(tostring(fakeId), 1, 5) == "FAKE_" then
                item.equipped = item.equipped or false
            end
        end
    end
end

-- Hook internal TradeApp functions to prevent item deletion cycles
local TradeApp = UIManager.apps.TradeApp
if TradeApp then
    local _overwrite_local_trade_state = TradeApp._overwrite_local_trade_state
    TradeApp._overwrite_local_trade_state = function(self, trade, ...)
        if trade then
            local offer = trade.sender == LocalPlayer and trade.sender_offer or trade.recipient == LocalPlayer and trade.recipient_offer
            if offer and data then
                offer.items = data
            end
        else
            data = nil
        end
        return _overwrite_local_trade_state(self, trade, ...)
    end

    local _change_local_trade_state = TradeApp._change_local_trade_state
    TradeApp._change_local_trade_state = function(self, change, ...)
        local trade = TradeApp.local_trade_state
        if trade then
            local team = trade.sender == LocalPlayer and "sender_offer" or trade.recipient == LocalPlayer and "recipient_offer"
            if team then
                local offer = change[team]
                if offer and offer.items then
                    data = offer.items
                end
            end
        end
        return _change_local_trade_state(self, change, ...)
    end
end

-- ========================================================
-- 2. GENERATION LOGIC (EQUIP-READY ENGINE)
-- ========================================================
local function generate_prop(i, flags)
    return {
        ["flyable"] = flags.F,
        ["rideable"] = flags.R,
        ["neon"] = flags.N,
        ["mega_neon"] = flags.M,
        ["age"] = i,
        ["is_activated"] = true
    }
end

_G.spawn_pet = function(pet_name, targetFlags)
    local flags = {F = targetFlags.F, R = targetFlags.R, N = targetFlags.N, M = targetFlags.M}
    local inventory = ClientData.get("inventory")
    
    for category_name, category_table in pairs(InventoryDB) do
        for id, item in pairs(category_table) do
            if category_name == "pets" and item.name == pet_name then
                -- Generate custom ID starting with FAKE_ tag to protect from inventory deletion loops
                local fake_uuid = "FAKE_" .. string.upper(string.sub(HttpService:GenerateGUID(), 7))
                local new_item = table.clone(item)
                new_item["unique"] = fake_uuid
                new_item["category"] = "pets"
                new_item["equipped"] = false
                
                local random_age = math.random(1, 900000)
                new_item["properties"] = generate_prop(random_age, flags)
                new_item["newness_order"] = math.random(1, 900000)
                
                if inventory and inventory[category_name] then
                    inventory[category_name][fake_uuid] = new_item
                    print("[Spawner Core] Spawned Equipable: " .. pet_name .. " (" .. fake_uuid .. ")")
                    
                    -- Update backpack UI rendering components immediately
                    pcall(function()
                        forceInventoryPatch()
                        if UIManager.apps.BackpackApp then
                            UIManager.apps.BackpackApp:refresh_all()
                        end
                    end)
                    return true
                end
            end
        end
    end
    warn("[Spawner Core] Pet named '" .. tostring(pet_name) .. "' not found in database.")
    return false
end

-- Auto-refresh connection loop to protect fake item allocations during live equip actions
RunService.Heartbeat:Connect(function()
    forceInventoryPatch()
end)

-- ========================================================
-- 3. RED-THEMED INTERFACE BUILDER (SkaiAdmSpawner)
-- ========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SkaiAdmSpawner"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 210)
mainFrame.Position = UDim2.new(0.5, -150, 0.4, -105)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 15, 15) -- Deep Red Tint Dark Panel
mainFrame.BackgroundTransparency = 0
mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 1
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 10)
uiCorner.Parent = mainFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(255, 0, 50) -- Crimson Red Outline
uiStroke.Thickness = 3
uiStroke.Parent = mainFrame

local blackFrame = Instance.new("Frame")
blackFrame.Size = UDim2.new(0, 310, 0, 220)
blackFrame.BackgroundColor3 = Color3.fromRGB(15, 0, 0) -- Pure dark velvet accent background
blackFrame.BorderSizePixel = 0
blackFrame.ZIndex = 0
blackFrame.Parent = screenGui

local blackCorner = Instance.new("UICorner")
blackCorner.CornerRadius = UDim.new(0, 15.5)
blackCorner.Parent = blackFrame

-- Keep outline background tracking the main UI position
local function syncShadow()
    blackFrame.Position = UDim2.new(
        mainFrame.Position.X.Scale,
        mainFrame.Position.X.Offset - 5,
        mainFrame.Position.Y.Scale,
        mainFrame.Position.Y.Offset - 5
    )
end
mainFrame:GetPropertyChangedSignal("Position"):Connect(syncShadow)
syncShadow()

-- Crimson/Ruby Red color palette rotation loop
local colorPalette = {
    Color3.fromRGB(255, 0, 0),     -- Pure Red
    Color3.fromRGB(200, 0, 50),    -- Deep Crimson
    Color3.fromRGB(255, 80, 80),   -- Light Red Coral
    Color3.fromRGB(150, 0, 20),    -- Wine Dark Red
    Color3.fromRGB(255, 0, 100),   -- Ruby Pinkish Red
    Color3.fromRGB(180, 20, 20)    -- Blood Brick Red
}
local currentIndex = 1
coroutine.wrap(function()
    while true do
        local nextIndex = currentIndex % #colorPalette + 1
        local tween = TweenService:Create(uiStroke, TweenInfo.new(3, Enum.EasingStyle.Linear), {Color = colorPalette[nextIndex]})
        tween:Play()
        currentIndex = nextIndex
        task.wait(3)
    end
end)()

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 25)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "m0_3a on dc"
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.TextSize = 20
titleLabel.TextColor3 = Color3.fromRGB(255, 230, 230)
titleLabel.Parent = mainFrame

local petNameBox = Instance.new("TextBox")
petNameBox.Size = UDim2.new(0.85, 0, 0, 28)
petNameBox.Position = UDim2.new(0.075, 0, 0.18, 0)
petNameBox.BackgroundColor3 = Color3.fromRGB(55, 25, 25)
petNameBox.BackgroundTransparency = 0.2
petNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
petNameBox.TextSize = 14
petNameBox.Font = Enum.Font.FredokaOne
petNameBox.PlaceholderText = "Enter Pet Name to Spawn"
petNameBox.Text = ""
petNameBox.ClearTextOnFocus = false
petNameBox.Parent = mainFrame

Instance.new("UICorner", petNameBox).CornerRadius = UDim.new(0, 6)
local textStroke = Instance.new("UIStroke", petNameBox)
textStroke.Color = Color3.new(0, 0, 0)
textStroke.Thickness = 1.2

local boxGlow = Instance.new("UIStroke", petNameBox)
boxGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
boxGlow.Color = Color3.fromRGB(255, 100, 100)
boxGlow.Thickness = 2.2

-- Auto capitalization helper
local function capitalizeWords(str)
    return str:gsub("(%S)(%S*)", function(first, rest) return first:upper() .. rest:lower() end)
end

petNameBox:GetPropertyChangedSignal("Text"):Connect(function()
    local inputText = petNameBox.Text
    local newText = capitalizeWords(inputText)
    if newText ~= inputText then
        local cursor = petNameBox.CursorPosition
        petNameBox.Text = newText
        petNameBox.CursorPosition = cursor
    end
end)

-- Spawn Button
local startButton = Instance.new("TextButton")
startButton.Size = UDim2.new(0.6, 0, 0, 25)
startButton.Position = UDim2.new(0.2, 0, 0.815, 0)
startButton.Text = "Start Spawning"
startButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0) -- Solid Bright Red
startButton.Font = Enum.Font.FredokaOne
startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
startButton.TextSize = 16
startButton.Parent = mainFrame
Instance.new("UICorner", startButton).CornerRadius = UDim.new(0, 8)
local buttonStroke = Instance.new("UIStroke", startButton)
buttonStroke.Color = Color3.fromRGB(255, 200, 200)
buttonStroke.Thickness = 1.5

startButton.MouseButton1Click:Connect(function()
    local pet_name = petNameBox.Text
    if pet_name ~= "" then
        local success = _G.spawn_pet(pet_name, activeFlags)
        buttonStroke.Color = success and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 50, 50)
        task.delay(1, function() buttonStroke.Color = Color3.fromRGB(255, 200, 200) end)
    end
end)

-- Status Frame Display Window
local infoBox = Instance.new("Frame")
infoBox.Size = UDim2.new(0.85, 0, 0, 30)
infoBox.Position = UDim2.new(0.075, 0, 0.6, 0)
infoBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
infoBox.BackgroundTransparency = 0.5
infoBox.Parent = mainFrame
Instance.new("UICorner", infoBox).CornerRadius = UDim.new(0, 8)

local infoText = Instance.new("TextLabel")
infoText.Size = UDim2.new(1, 0, 1, 0)
infoText.BackgroundTransparency = 1
infoText.Text = "Normal"
infoText.Font = Enum.Font.FredokaOne
infoText.TextSize = 14
infoText.TextColor3 = Color3.new(1, 1, 1)
infoText.Parent = infoBox

local function updateInfoBox()
    local activeText = {}
    if activeFlags.M then table.insert(activeText, "Mega") end
    if activeFlags.N then table.insert(activeText, "Neon") end
    if activeFlags.F then table.insert(activeText, "Fly") end
    if activeFlags.R then table.insert(activeText, "Ride") end
    
    if #activeText > 0 then
        infoText.Text = table.concat(activeText, " ")
        infoText.TextColor3 = Color3.fromRGB(255, 50, 50)
    else
        infoText.Text = "Normal"
        infoText.TextColor3 = Color3.new(1, 1, 1)
    end
end

-- Modifier Buttons Configuration (F, R, N, M)
local prefixes = {"F", "R", "N", "M"}
local flagColors = {
    M = Color3.fromRGB(255, 0, 100), N = Color3.fromRGB(255, 50, 50),
    F = Color3.fromRGB(255, 100, 100), R = Color3.fromRGB(200, 0, 0)
}

for i, prefix in ipairs(prefixes) do
    local pBtn = Instance.new("TextButton")
    pBtn.Size = UDim2.new(0.18, 0, 0, 25)
    pBtn.Position = UDim2.new(0.075 + (i - 1) * 0.22, 0, 0.4, 0)
    pBtn.Text = prefix
    pBtn.BackgroundColor3 = Color3.fromRGB(75, 30, 30)
    pBtn.Font = Enum.Font.FredokaOne
    pBtn.TextColor3 = Color3.new(1, 1, 1)
    pBtn.Parent = mainFrame
    Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 6)
    
    local pStroke = Instance.new("UIStroke", pBtn)
    pStroke.Color = flagColors[prefix]
    pStroke.Thickness = 2

    pBtn.MouseButton1Click:Connect(function()
        if prefix == "M" and activeFlags.N then activeFlags.N = false end
        if prefix == "N" and activeFlags.M then activeFlags.M = false end
        
        activeFlags[prefix] = not activeFlags[prefix]
        pBtn.BackgroundColor3 = activeFlags[prefix] and Color3.fromRGB(120, 50, 50) or Color3.fromRGB(75, 30, 30)
        updateInfoBox()
    end)
end

-- Mass Spawner Button 
local spawnAllButton = Instance.new("TextButton")
spawnAllButton.Size = UDim2.new(0.6, 0, 0, 25)
spawnAllButton.Position = UDim2.new(0.2, 0, 0.9, 0)
spawnAllButton.Text = "Spawn All High Tiers"
spawnAllButton.BackgroundColor3 = Color3.fromRGB(130, 0, 30)
spawnAllButton.Font = Enum.Font.FredokaOne
spawnAllButton.TextColor3 = Color3.new(1, 1, 1)
spawnAllButton.TextSize = 14
spawnAllButton.Parent = mainFrame
Instance.new("UICorner", spawnAllButton).CornerRadius = UDim.new(0, 8)

local highTierPets = {
    "Shadow Dragon", "Bat Dragon", "Frost Dragon", "Giraffe", "Owl", 
    "Parrot", "Crow", "Evil Unicorn", "Arctic Reindeer", "Balloon Unicorn"
}

spawnAllButton.MouseButton1Click:Connect(function()
    for _, petName in ipairs(highTierPets) do
        _G.spawn_pet(petName, activeFlags)
        task.wait(0.05)
    end
end)

-- Dragging Interface Controls
local dragging, dragStart, startPos
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

print("[Unified Red Loader] All features hooked successfully.")
