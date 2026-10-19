--[[ Derek Slip | Steal An Egg | Author: ALPHA ]]
task.wait(2)

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local UIS        = game:GetService("UserInputService")
local LP         = Players.LocalPlayer

local Config = {
    NoSlip = false
}

-- ============ No-Slip System ============
-- يثبتك بالأرض بـ Raycast (زي تأثير السكن الكبير)
local noSlipConnection
local function enableNoSlip()
    if noSlipConnection then return end
    noSlipConnection = RunService.Heartbeat:Connect(function()
        if not Config.NoSlip then return end
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        if hum.Health <= 0 then return end

        -- فحص الأرض تحتك
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {char}
        params.FilterType = Enum.RaycastFilterType.Exclude

        local result = Workspace:Raycast(hrp.Position, Vector3.new(0, -6, 0), params)
        if result then
            -- نلغي السرعة الأفقية اللي تجيك من الانحدار/الجليد
            local vel = hrp.AssemblyLinearVelocity
            local verticalVel = vel.Y
            -- نثبت X و Z، ونخلي Y للجاذبية
            hrp.AssemblyLinearVelocity = Vector3.new(0, verticalVel, 0)

            -- نمنع الـ Humanoid من الإنزلاق
            if hum:GetState() == Enum.HumanoidStateType.Freefall and result.Distance < 1.5 then
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end
    end)
end

local function disableNoSlip()
    if noSlipConnection then
        noSlipConnection:Disconnect()
        noSlipConnection = nil
    end
end

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
    Size = UDim2.fromOffset(260, 180),
    Position = UDim2.new(0.5, -130, 0.5, -90),
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

-- زر No-Slip
local toggleRow = mk("Frame", {
    Size = UDim2.new(1, -20, 0, 50),
    Position = UDim2.fromOffset(10, 55),
    BackgroundColor3 = Color3.fromRGB(22, 22, 30)
}, main)
mk("UICorner", {CornerRadius = UDim.new(0, 8)}, toggleRow)

mk("TextLabel", {
    Size = UDim2.new(1, -70, 1, 0),
    Position = UDim2.fromOffset(12, 0),
    BackgroundTransparency = 1,
    Text = "No-Slip (منع التزحلق)",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamMedium,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left
}, toggleRow)

local sw = mk("Frame", {
    Size = UDim2.fromOffset(42, 22),
    Position = UDim2.new(1, -54, 0.5, -11),
    BackgroundColor3 = Color3.fromRGB(50, 50, 65)
}, toggleRow)
mk("UICorner", {CornerRadius = UDim.new(1, 0)}, sw)
local knob = mk("Frame", {
    Size = UDim2.fromOffset(18, 18),
    Position = UDim2.new(0, 2, 0.5, -9),
    BackgroundColor3 = Color3.new(1, 1, 1)
}, sw)
mk("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)

local state = false
local clickBtn = mk("TextButton", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = ""
}, toggleRow)

clickBtn.MouseButton1Click:Connect(function()
    state = not state
    Config.NoSlip = state
    game:GetService("TweenService"):Create(sw, TweenInfo.new(0.15), {
        BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(50, 50, 65)
    }):Play()
    game:GetService("TweenService"):Create(knob, TweenInfo.new(0.15), {
        Position = UDim2.new(0, state and 21 or 2, 0.5, -9)
    }):Play()
    if state then enableNoSlip() else disableNoSlip() end
end)

-- ملاحظة صغيرة تحت
mk("TextLabel", {
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.fromOffset(10, 120),
    BackgroundTransparency = 1,
    Text = "Activé = ما تتزحلق على الجليد",
    TextColor3 = Color3.fromRGB(150, 150, 170),
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left
}, main)

-- ============ Drag & Toggle ============
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
