-- REMOVE OLD UI INSTANCES & FORCE RED THEME
local LocalPlayer = game:GetService("Players").LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local oldGui = PlayerGui:FindFirstChild("SkaiAdmSpawner")
if oldGui then oldGui:Destroy() end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Fsys = require(ReplicatedStorage:WaitForChild("Fsys"))
local UIManager = Fsys.load("UIManager")
local InventoryDB = Fsys.load("InventoryDB")
local ClientData = Fsys.load("ClientData")

local data = nil
local activeFlags = {F = false, R = false, N = false, M = false}

-- Force persistent mock states for locally generated items
local function forceInventoryPatch()
    local inventory = ClientData.get("inventory")
    if inventory and inventory.pets then
        for fakeId, item in pairs(inventory.pets) do
            if string.sub(tostring(fakeId), 1, 5) == "FAKE_" then
                item.equipped = item.equipped or false
                item.is_equipped = item.equipped
            end
        end
    end
end

-- Intercept Equipping Remotes locally to avoid server-side rejection drops
local EquipAPI = ReplicatedStorage:WaitForChild("API", 3) and ReplicatedStorage.API:FindFirstChild("ToolAPI/Equip")
if EquipAPI and EquipAPI:IsA("RemoteFunction") then
    local oldInvoke = EquipAPI.OnClientInvoke
    EquipAPI.OnClientInvoke = function(...)
        return true
    end
end

-- ========================================================
-- GENERATION LOGIC
-- ========================================================
_G.spawn_pet = function(pet_name, targetFlags)
    local flags = {F = targetFlags.F, R = targetFlags.R, N = targetFlags.N, M = targetFlags.M}
    local inventory = ClientData.get("inventory")
    
    for category_name, category_table in pairs(InventoryDB) do
        for id, item in pairs(category_table) do
            if category_name == "pets" and item.name == pet_name then
                local fake_uuid = "FAKE_" .. string.upper(string.sub(HttpService:GenerateGUID(), 7))
                local new_item = table.clone(item)
                new_item["unique"] = fake_uuid
                new_item["category"] = "pets"
                new_item["equipped"] = false
                new_item["properties"] = {
                    ["flyable"] = flags.F,
                    ["rideable"] = flags.R,
                    ["neon"] = flags.N,
                    ["mega_neon"] = flags.M,
                    ["age"] = math.random(1, 90000)
                }
                
                if inventory and inventory[category_name] then
                    inventory[category_name][fake_uuid] = new_item
                    
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
    return false
end

RunService.Heartbeat:Connect(forceInventoryPatch)

-- ========================================================
-- SOLID CRIMSON RED UI BUILDER
-- ========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SkaiAdmSpawner"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 210)
mainFrame.Position = UDim2.new(0.5, -150, 0.4, -105)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 10, 10) -- True Dark Red Panel
mainFrame.ZIndex = 1
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
local uiStroke = Instance.new("UIStroke", mainFrame)
uiStroke.Color = Color3.fromRGB(255, 0, 0) -- Neon Red Outliner
uiStroke.Thickness = 3

local blackFrame = Instance.new("Frame")
blackFrame.Size = UDim2.new(0, 310, 0, 220)
blackFrame.BackgroundColor3 = Color3.fromRGB(20, 0, 0) -- Dark Border Accent
blackFrame.ZIndex = 0
blackFrame.Parent = screenGui
Instance.new("UICorner", blackFrame).CornerRadius = UDim.new(0, 15.5)

local function syncShadow()
    blackFrame.Position = UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset - 5, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset - 5)
end
mainFrame:GetPropertyChangedSignal("Position"):Connect(syncShadow)
syncShadow()

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 25)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "m0_3a on dc"
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.TextSize = 20
titleLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
titleLabel.Parent = mainFrame

local petNameBox = Instance.new("TextBox")
petNameBox.Size = UDim2.new(0.85, 0, 0, 28)
petNameBox.Position = UDim2.new(0.075, 0, 0.18, 0)
petNameBox.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
petNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
petNameBox.TextSize = 14
petNameBox.Font = Enum.Font.FredokaOne
petNameBox.PlaceholderText = "Enter Pet Name to Spawn"
petNameBox.Text = ""
petNameBox.ClearTextOnFocus = false
petNameBox.Parent = mainFrame
Instance.new("UICorner", petNameBox).CornerRadius = UDim.new(0, 6)

local startButton = Instance.new("TextButton")
startButton.Size = UDim2.new(0.6, 0, 0, 25)
startButton.Position = UDim2.new(0.2, 0, 0.815, 0)
startButton.Text = "Start Spawning"
startButton.BackgroundColor3 = Color3.fromRGB(220, 0, 0) -- Deep Crimson Trigger Button
startButton.Font = Enum.Font.FredokaOne
startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
startButton.TextSize = 16
startButton.Parent = mainFrame
Instance.new("UICorner", startButton).CornerRadius = UDim.new(0, 8)
local buttonStroke = Instance.new("UIStroke", startButton)
buttonStroke.Color = Color3.fromRGB(255, 150, 150)
buttonStroke.Thickness = 1.5

startButton.MouseButton1Click:Connect(function()
    local pet_name = petNameBox.Text
    if pet_name ~= "" then
        local success = _G.spawn_pet(pet_name, activeFlags)
        buttonStroke.Color = success and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 50, 50)
        task.delay(1, function() buttonStroke.Color = Color3.fromRGB(255, 150, 150) end)
    end
end)

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

local prefixes = {"F", "R", "N", "M"}
for i, prefix in ipairs(prefixes) do
    local pBtn = Instance.new("TextButton")
    pBtn.Size = UDim2.new(0.18, 0, 0, 25)
    pBtn.Position = UDim2.new(0.075 + (i - 1) * 0.22, 0, 0.4, 0)
    pBtn.Text = prefix
    pBtn.BackgroundColor3 = Color3.fromRGB(80, 25, 25)
    pBtn.Font = Enum.Font.FredokaOne
    pBtn.TextColor3 = Color3.new(1, 1, 1)
    pBtn.Parent = mainFrame
    Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 6)
    
    local pStroke = Instance.new("UIStroke", pBtn)
    pStroke.Color = Color3.fromRGB(255, 50, 50)
    pStroke.Thickness = 2

    pBtn.MouseButton1Click:Connect(function()
        if prefix == "M" and activeFlags.N then activeFlags.N = false end
        if prefix == "N" and activeFlags.M then activeFlags.M = false end
        activeFlags[prefix] = not activeFlags[prefix]
        pBtn.BackgroundColor3 = activeFlags[prefix] and Color3.fromRGB(140, 40, 40) or Color3.fromRGB(80, 25, 25)
        
        local activeText = {}
        if activeFlags.M then table.insert(activeText, "Mega") end
        if activeFlags.N then table.insert(activeText, "Neon") end
        if activeFlags.F then table.insert(activeText, "Fly") end
        if activeFlags.R then table.insert(activeText, "Ride") end
        infoText.Text = #activeText > 0 and table.concat(activeText, " ") or "Normal"
    end)
end

-- Drag Setup
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
