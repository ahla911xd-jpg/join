local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- 1. Create the main ScreenGui container
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FakeJoinNotifierUI"
screenGui.ResetOnSpawn = false

-- Attempt to protect the GUI by putting it in CoreGui, fallback to PlayerGui
local success = pcall(function()
	screenGui.Parent = game:GetService("CoreGui")
end)
if not success then
	screenGui.Parent = playerGui
end

-- 2. Function to generate and animate a single notification
local function showNotification()
	-- Pick a random User ID (targeting earlier accounts to ensure a higher hit rate)
	local randomId = math.random(1, 100000000)
	
	-- Safely fetch the username to avoid breaking the script if the account is deleted
	local successName, username = pcall(function()
		return Players:GetNameFromUserIdAsync(randomId)
	end)

	if not successName then return end -- Skip and wait for the next loop if the ID is invalid

	-- Create Background Frame
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 260, 0, 46)
	-- Starts offscreen at the TOP center (X: 0.5 center, offset by half width -130. Y: -100 hides it above)
	frame.Position = UDim2.new(0.5, -130, 0, -100) 
	frame.BackgroundColor3 = Color3.fromRGB(35, 37, 41) 
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 6)
	uiCorner.Parent = frame

	-- Create Profile Picture (Avatar Headshot)
	local pfp = Instance.new("ImageLabel")
	pfp.Size = UDim2.new(0, 34, 0, 34)
	pfp.Position = UDim2.new(0, 6, 0.5, -17)
	pfp.BackgroundTransparency = 1
	pfp.Image = "rbxthumb://type=AvatarHeadShot&id=" .. randomId .. "&w=150&h=150"
	pfp.Parent = frame

	local pfpCorner = Instance.new("UICorner")
	pfpCorner.CornerRadius = UDim.new(1, 0)
	pfpCorner.Parent = pfp

	-- Create TextLabel
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, -55, 1, 0)
	textLabel.Position = UDim2.new(0, 48, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = username .. " joined you"
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 14
	textLabel.Parent = frame
	
	-- Animate In (Slide down from top)
	local tweenIn = TweenService:Create(
		frame, 
		TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), 
		{Position = UDim2.new(0.5, -130, 0, 20)} -- Slides down to 20 pixels from the top
	)
	tweenIn:Play()
	
	-- Wait 4 seconds, then Animate Out
	task.delay(4, function()
		local tweenOut = TweenService:Create(
			frame, 
			TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), 
			{Position = UDim2.new(0.5, -130, 0, -100)} -- Slides back up offscreen
		)
		tweenOut:Play()
		tweenOut.Completed:Wait()
		frame:Destroy() 
	end)
end

-- 3. Run the loop indefinitely
task.spawn(function()
	while true do
		showNotification()
		task.wait(math.random(5, 12)) 
	end
end)
