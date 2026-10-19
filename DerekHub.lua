--[[ Derek Slip v2 | Steal An Egg | Author: ALPHA ]]
task.wait(2)

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local UIS        = game:GetService("UserInputService")
local Tween      = game:GetService("TweenService")
local LP         = Players.LocalPlayer

local Config = {
    NoSlip = false,
    SpeedBoost = false,
    SpeedValue = 80,
}

local function getChar()
    local c = LP.Character
    return c, c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
end

-- ============ BodyVelocity Speed + No-Slip ============
local bv = nil
RunService.Heartbeat:Connect(function()
    local char, hum, hrp = getChar()
    if not hum or not hrp then
        if bv then bv:Destroy() bv = nil end
        return
    end
    if hum.Health <= 0 then
        if bv then bv:Destroy() bv = nil end
        return
    end

    -- 1) السرعة الحقيقية (BodyVelocity)
    if Config.SpeedBoost then
        if not bv or bv.Parent ~= hrp then
            if bv then bv:Destroy() end
            bv = Instance.new("BodyVelocity")
            bv.Parent = hrp
            bv.MaxForce = Vector3.new(math.huge, 0, math.huge)
            bv.Velocity = Vector3.zero
        end
        -- نخلي WalkSpeed الطبيعي 16 (اللعبة تشوفك طبيعي)
        hum.WalkSpeed = 16

        local dir = hum.MoveDirection
        if dir.Magnitude > 0 then
            bv.Velocity = Vector3.new(dir.X * Config.SpeedValue, 0, dir.Z * Config.SpeedValue)
        else
            bv.Velocity = Vector3.zero
        end
    else
        if bv then bv:Destroy() bv = nil end
    end

    -- 2) No-Slip (يثبتك بالأرض كل فريم)
    if Config.NoSlip then
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {char}
        params.FilterType = Enum.RaycastFilterType.Exclude
        local result = Workspace:Raycast(hrp.Position, Vector3.new(0, -8, 0), params)

        if result then
            local vel = hrp.AssemblyLinearVelocity
            -- نلغي أي انزلاق أفقي (زحلقة) ونحتفظ بالجاذبية
            hrp.AssemblyLinearVelocity = Vector3.new(0, vel.Y, 0)

            -- نمنع Humanoid من الدخول في حالة Sliding/Freefall
            if hum:GetState() == Enum.HumanoidStateType.Freefall or hum:GetState() == Enum.HumanoidStateType.Swimming then
                if result.Distance < 3 then
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end
            end
        end
    end
end)

-- ============ UI ============
local function mk(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local gui = mk("ScreenGui", {
    Name = "DerekSlip",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, LP:WaitForChild("PlayerGui"))

-- زر الدائرة
local openBtn = mk("TextButton", {
    Size = UDim2.fromOffset(60, 60),
    Position = UDim2.new(0, 20, 0.5, -30),
    BackgroundColor3 = Color3.fromRGB(230, 30, 60),
    Text = "D",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBlack,
    TextSize = 30,
    BorderSizePixel = 0,
    AutoButtonColor = false
}, gui)
mk("UICorner", {CornerRadius = UDim.new(1, 0)}, openBtn)
mk("UIStroke", {Color = Color3.fromRGB(50, 150, 255), Thickness = 2}, openBtn)

-- البنل
local main = mk("Frame", {
    Size = UDim2.fromOffset(280, 260),
    Position = UDim2.new(0.5, -140, 0.5, -130),
    BackgroundColor3 = Color3.fromRGB(12, 12, 18),
    BorderSizePixel = 0,
    Visible = false
}, gui)
mk("UICorner", {CornerRadius = UDim.new(0, 12)}, main)
mk("UIStroke", {Color = Color3.fromRGB(230, 30, 60), Thickness = 1.5}, main)

-- شريط العنوان
local top = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = Color3.fromRGB(22, 22, 30),
    BorderSizePixel = 0
}, main)
mk("UICorner", {CornerRadius = UDim.new(0, 12)}, top)
mk("Frame", {Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 1, -20), BackgroundColor3 = Color3.fromRGB(22, 22, 30)}, top)
mk("TextLabel", {
    Size = UDim2.new(1, -50, 1, 0),
    Position = UDim2.fromOffset(15, 0),
    BackgroundTransparency = 1,
    Text = "Derek Slip",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left
}, top)

local closeBtn = mk("TextButton", {
    Size = UDim2.fromOffset(30, 30),
    Position = UDim2.new(1, -38, 0.5, -15),
    BackgroundColor3 = Color3.fromRGB(230, 30, 60),
    Text = "✕",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    BorderSizePixel = 0
}, top)
mk("UICorner", {CornerRadius = UDim.new(0, 6)}, closeBtn)

-- Toggle helper
local function addToggle(y, text, default, callback)
    local row = mk("Frame", {
        Size = UDim2.new(1, -20, 0, 50),
        Position = UDim2.fromOffset(10, y),
        BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    }, main)
    mk("UICorner", {CornerRadius = UDim.new(0, 8)}, row)
    mk("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    }, row)
    local sw = mk("Frame", {
        Size = UDim2.fromOffset(42, 22),
        Position = UDim2.new(1, -54, 0.5, -11),
        BackgroundColor3 = default and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(50, 50, 65)
    }, row)
    mk("UICorner", {CornerRadius = UDim.new(1, 0)}, sw)
    local knob = mk("Frame", {
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.new(0, default and 21 or 2, 0.5, -9),
        BackgroundColor3 = Color3.new(1, 1, 1)
    }, sw)
    mk("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)
    local state = default
    local click = mk("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = ""}, row)
    click.MouseButton1Click:Connect(function()
        state = not state
        Tween:Create(sw, TweenInfo.new(0.15), {BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(50, 50, 65)}):Play()
        Tween:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(0, state and 21 or 2, 0.5, -9)}):Play()
        callback(state)
    end)
    return row
end

addToggle(55, "Speed Boost", false, function(v) Config.SpeedBoost = v end)
addToggle(115, "No-Slip", false, function(v) Config.NoSlip = v end)

-- Speed slider
local sliderRow = mk("Frame", {
    Size = UDim2.new(1, -20, 0, 60),
    Position = UDim2.fromOffset(10, 175),
    BackgroundColor3 = Color3.fromRGB(22, 22, 30)
}, main)
mk("UICorner", {CornerRadius = UDim.new(0, 8)}, sliderRow)
local sliderLabel = mk("TextLabel", {
    Size = UDim2.new(1, -20, 0, 20),
    Position = UDim2.fromOffset(12, 6),
    BackgroundTransparency = 1,
    Text = "Speed: " .. Config.SpeedValue,
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left
}, sliderRow)
local track = mk("Frame", {
    Size = UDim2.new(1, -24, 0, 8),
    Position = UDim2.fromOffset(12, 40),
    BackgroundColor3 = Color3.fromRGB(50, 50, 65)
}, sliderRow)
mk("UICorner", {CornerRadius = UDim.new(1, 0)}, track)
local fill = mk("Frame", {
    Size = UDim2.new((Config.SpeedValue - 20) / (300 - 20), 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(50, 150, 255)
}, track)
mk("UICorner", {CornerRadius = UDim.new(1, 0)}, fill)

local draggingSlider = false
track.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = true
        local rel = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.floor(20 + (300 - 20) * rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        sliderLabel.Text = "Speed: " .. v
        Config.SpeedValue = v
    end
end)
UIS.InputChanged:Connect(function(i)
    if draggingSlider and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
        local rel = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.floor(20 + (300 - 20) * rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        sliderLabel.Text = "Speed: " .. v
        Config.SpeedValue = v
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = false
    end
end)

-- ============ Drag ============
local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos, moved
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = frame.Position
            moved = false
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = i.Position - dragStart
            if d.Magnitude > 5 then moved = true end
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    return function() return moved end
end

local btnMoved = makeDraggable(openBtn, openBtn)
makeDraggable(main, top)

local isOpen = false
openBtn.MouseButton1Click:Connect(function()
    if btnMoved() then return end
    isOpen = not isOpen
    main.Visible = isOpen
end)
closeBtn.MouseButton1Click:Connect(function()
    isOpen = false
    main.Visible = false
end)
