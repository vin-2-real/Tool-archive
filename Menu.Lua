local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- GUI Setup
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "VinsMenu"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 350, 0, 500)
mainFrame.Position = UDim2.new(0, 50, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BackgroundTransparency = 0.15
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

-- Title Bar
local titleBar = Instance.new("TextLabel", mainFrame)
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
titleBar.Text = "Vins Menu"
titleBar.TextColor3 = Color3.new(1, 1, 1)
titleBar.Font = Enum.Font.GothamBold
titleBar.TextScaled = true
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

-- Minimize Button
local minimizeButton = Instance.new("TextButton", titleBar)
minimizeButton.Size = UDim2.new(0, 30, 0, 30)
minimizeButton.Position = UDim2.new(1, -35, 0, 5)
minimizeButton.Text = "▲"
minimizeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
minimizeButton.TextColor3 = Color3.new(1, 1, 1)
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.TextScaled = true
Instance.new("UICorner", minimizeButton).CornerRadius = UDim.new(1, 0)

-- Dragging
do
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
        if dragging and input == dragInput then
            update(input)
        end
    end)
end

-- Variables
local flySpeed = 50
local lockYEnabled = false
local lockYConnection = nil
local noclipEnabled = false
local noclipConn = nil
local teleportTool = nil
local flying = false
local flyConnection = nil
local activeKeys = {}
local container = nil
local layout = nil

-- Fly Control Functions
local function startFly()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if root:FindFirstChild("FlyVelocity") then return end

    local bv = Instance.new("BodyVelocity", root)
    bv.Name = "FlyVelocity"
    bv.Velocity = Vector3.zero
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)

    flyConnection = RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += cam.CFrame.UpVector end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= cam.CFrame.UpVector end
        if dir.Magnitude > 0 then
            bv.Velocity = dir.Unit * flySpeed
        else
            bv.Velocity = Vector3.zero
        end
    end)
    flying = true
end

local function stopFly()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end

    local bv = root:FindFirstChild("FlyVelocity")
    if bv then
        bv:Destroy()
    end

    flying = false
end

local function toggleFly()
    if flying then
        stopFly()
    else
        startFly()
    end
end

-- Helper to recreate all sliders and toggles
local function buildUI()
    if container then container:Destroy() end
    container = Instance.new("Frame", mainFrame)
    container.Size = UDim2.new(1, -20, 1, -60)
    container.Position = UDim2.new(0, 10, 0, 50)
    container.BackgroundTransparency = 1

    layout = Instance.new("UIListLayout", container)
    layout.Padding = UDim.new(0, 12)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Slider
    local function createSlider(name, min, max, default, callback)
        local frame = Instance.new("Frame", container)
        frame.Size = UDim2.new(1, 0, 0, 50)
        frame.BackgroundTransparency = 1

        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(0.4, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.new(1,1,1)
        label.Font = Enum.Font.Gotham
        label.TextScaled = true

        local sliderBar = Instance.new("Frame", frame)
        sliderBar.Size = UDim2.new(0.5, 0, 0.3, 0)
        sliderBar.Position = UDim2.new(0.45, 0, 0.35, 0)
        sliderBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(0, 6)

        local knob = Instance.new("Frame", sliderBar)
        knob.Size = UDim2.new(0, 12, 1, 0)
        knob.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
        Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 6)

        local valueLabel = Instance.new("TextLabel", frame)
        valueLabel.Size = UDim2.new(0.1, 0, 1, 0)
        valueLabel.Position = UDim2.new(0.95, 0, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.TextColor3 = Color3.new(1, 1, 1)
        valueLabel.Font = Enum.Font.Gotham
        valueLabel.TextScaled = true
        valueLabel.Text = tostring(default)

        local dragging = false

        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        UIS.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local rel = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
                knob.Position = UDim2.new(rel, 0, 0, 0)
                local val = math.round(min + rel * (max - min))
                valueLabel.Text = tostring(val)
                callback(val)
            end
        end)

        local initRel = (default - min) / (max - min)
        knob.Position = UDim2.new(initRel, 0, 0, 0)
        callback(default)
    end

    createSlider("Walk Speed", 16, 100, 16, function(v)
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end)

    createSlider("Fly Speed", 20, 150, 50, function(v)
        flySpeed = v
    end)

    -- Function to create toggle buttons
    local function createToggle(name, callback, initial)
        local frame = Instance.new("Frame", container)
        frame.Size = UDim2.new(1, 0, 0, 50)
        frame.BackgroundTransparency = 1

        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(0.6, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.new(1,1,1)
        label.Font = Enum.Font.Gotham
        label.TextScaled = true

        local button = Instance.new("TextButton", frame)
        button.Size = UDim2.new(0.3, 0, 0.7, 0)
        button.Position = UDim2.new(0.65, 0, 0.15, 0)
        button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        button.Text = initial and "ON" or "OFF"
        button.Font = Enum.Font.Gotham
        button.TextColor3 = Color3.new(1, 1, 1)
        button.TextScaled = true
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

        local on = initial or false
        button.MouseButton1Click:Connect(function()
            on = not on
            button.Text = on and "ON" or "OFF"
            TweenService:Create(button, TweenInfo.new(0.2), {
                BackgroundColor3 = on and Color3.fromRGB(70,130,180) or Color3.fromRGB(45,45,45)
            }):Play()
            callback(on)
        end)

        return button
    end

    -- Teleport Tool toggle
    createToggle("Teleport Tool", function(on)
        if on then
            teleportTool = Instance.new("Tool")
            teleportTool.Name = "TPTool"
            teleportTool.RequiresHandle = false
            teleportTool.ToolTip = "Teleport Tool"
            teleportTool.Parent = player.Backpack
            teleportTool.Equipped:Connect(function(mouse)
                mouse.Button1Down:Connect(function()
                    if mouse.Target then
                        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        if root then
                            root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
                        end
                    end
                end)
            end)
        else
            if teleportTool then teleportTool:Destroy() teleportTool = nil end
        end
    end, false)

    -- Lock Y Position toggle
    createToggle("Lock Y Position", function(on)
        lockYEnabled = on
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if on and root then
            local frozenY = root.Position.Y
            lockYConnection = RunService.Heartbeat:Connect(function()
                if root and root.Parent then
                    local pos = root.Position
                    local cf = root.CFrame
                    root.CFrame = CFrame.new(pos.X, frozenY, pos.Z) * CFrame.Angles(cf:ToEulerAnglesXYZ())
                end
            end)
        else
            if lockYConnection then
                lockYConnection:Disconnect()
                lockYConnection = nil
            end
        end
    end, false)

    -- Noclip toggle
    createToggle("Noclip", function(on)
        noclipEnabled = on
        if on then
            noclipConn = RunService.Stepped:Connect(function()
                if player.Character then
                    for _, part in pairs(player.Character:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
                    end
                end
            end)
        else
            if noclipConn then noclipConn:Disconnect() noclipConn = nil end
        end
    end, false)

    -- Fly toggle button
    createToggle("Fly", function(on)
        if on then
            startFly()
        else
            stopFly()
        end
    end, flying)

    -- **Add the Aim Lock (Closest) toggle button here**
local function createAimLockToggle()
    local frame = Instance.new("Frame", container)
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "Aim Lock (Face & Keep)"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Gotham
    label.TextScaled = true

    local button = Instance.new("TextButton", frame)
    button.Size = UDim2.new(0.3, 0, 0.7, 0)
    button.Position = UDim2.new(0.65, 0, 0.15, 0)
    button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    button.Text = "OFF"
    button.Font = Enum.Font.Gotham
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextScaled = true
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

    local isAimLockActive = false
    local aimLockLoop = nil
    local currentTargetHRP = nil
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")

    button.MouseButton1Click:Connect(function()
        isAimLockActive = not isAimLockActive
        button.Text = isAimLockActive and "ON" or "OFF"
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = isAimLockActive and Color3.fromRGB(70, 130, 180) or Color3.fromRGB(45, 45, 45)
        }):Play()

        if isAimLockActive then
            -- Disable character auto-rotation
            if humanoid then humanoid.AutoRotate = false end

            -- Find initial closest enemy
            local minDist = math.huge
            local camPos = workspace.CurrentCamera.CFrame.Position
            local closestP = nil
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = plr.Character.HumanoidRootPart
                    local dist = (hrp.Position - camPos).Magnitude
                    if dist < minDist and dist <= 100 then
                        minDist = dist
                        closestP = plr
                    end
                end
            end
            currentTargetHRP = closestP and closestP.Character:FindFirstChild("HumanoidRootPart") or nil

            -- Start loop to face target
            aimLockLoop = RunService.RenderStepped:Connect(function()
                -- Re-find the closest target every frame
                local minDist2 = math.huge
                local camPos2 = workspace.CurrentCamera.CFrame.Position
                local closestP2 = nil
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        local hrp = plr.Character.HumanoidRootPart
                        local dist = (hrp.Position - camPos2).Magnitude
                        if dist < minDist2 and dist <= 100 then
                            minDist2 = dist
                            closestP2 = plr
                        end
                    end
                end
                currentTargetHRP = closestP2 and closestP2.Character:FindFirstChild("HumanoidRootPart") or nil

                if currentTargetHRP then
                    -- Face the target
                    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = CFrame.lookAt(hrp.Position, currentTargetHRP.Position)
                    end
                    -- Lock camera onto target
                    local cam = workspace.CurrentCamera
                    cam.CFrame = CFrame.new(cam.CFrame.Position, currentTargetHRP.Position)
                end
            end)
        else
            -- Re-enable character rotation
            if humanoid then humanoid.AutoRotate = true end
            if aimLockLoop then
                aimLockLoop:Disconnect()
                aimLockLoop = nil
            end
        end
    end)
end

-- Call this inside your buildUI() where you add toggles
createAimLockToggle()

-- Build UI initially
buildUI()

-- Toggle UI visibility with button
local minimized = false
local originalSize = mainFrame.Size

minimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    minimizeButton.Text = minimized and "▼" or "▲"

    if minimized then
        if container then container.Visible = false end
        mainFrame:TweenSize(UDim2.new(0, 350, 0, 40), "Out", "Quad", 0.2, true)
    else
        if container then
            container.Visible = true
        else
            buildUI()
        end
        mainFrame:TweenSize(originalSize, "Out", "Quad", 0.2, true)
    end
end)

-- Fly toggle (F key)
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F then
        toggleFly()
        -- update fly toggle button state
        if container then
            for _, child in pairs(container:GetChildren()) do
                if child:IsA("Frame") then
                    local btn = child:FindFirstChildOfClass("TextButton")
                    local lbl = child:FindFirstChildOfClass("TextLabel")
                    if btn and lbl and lbl.Text == "Fly" then
                        btn.Text = flying and "ON" or "OFF"
                        TweenService:Create(btn, TweenInfo.new(0.2), {
                            BackgroundColor3 = flying and Color3.fromRGB(70,130,180) or Color3.fromRGB(45,45,45)
                        }):Play()
                    end
                end
            end
        end
    end
end)
