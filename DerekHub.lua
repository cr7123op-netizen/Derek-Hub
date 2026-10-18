--[[ Derek Hub v6.1 — CoreGui Stealth | Steal An Egg | Author: ALPHA ]]
task.wait(2)

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local UIS        = game:GetService("UserInputService")
local Tween      = game:GetService("TweenService")
local VU         = game:GetService("VirtualUser")
local LP         = Players.LocalPlayer

local Config = {
    AutoSteal = false,
    AutoButterfly = false,
    AutoHatch = false,
    StealDelay = 0.4,
}

local function getChar()
    local c = LP.Character
    return c, c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
end

-- 1. سرقة البيض (طبيعية بدون teleport)
local stealing = false
local function startSteal()
    if stealing then return end
    stealing = true
    task.spawn(function()
        while Config.AutoSteal do
            local char, hum, hrp = getChar()
            if char and hum and hrp and hum.Health > 0 then
                local closestEgg, closestDist = nil, math.huge
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if (v:IsA("Model") or v:IsA("Part")) and v.Name:lower():find("egg") and not v.Name:lower():find("plot") then
                        local prompt = v:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            local pos = (v:IsA("Model") and v:GetPivot().Position) or v.Position
                            local dist = (pos - hrp.Position).Magnitude
                            if dist < closestDist then
                                closestEgg, closestDist = {model=v, prompt=prompt, pos=pos}, dist
                            end
                        end
                    end
                end

                if closestEgg then
                    if closestDist > 8 then
                        hum:MoveTo(closestEgg.pos)
                        task.wait(0.2)
                    else
                        hum:MoveTo(hrp.Position)
                        task.wait(math.random(10, 20) / 100)
                        pcall(function() fireproximityprompt(closestEgg.prompt) end)
                        task.wait(math.random(15, 25) / 10)
                    end
                else
                    task.wait(1)
                end
            else
                task.wait(1)
            end
        end
        stealing = false
    end)
end

-- 2. صيد الفراشات
local catching = false
local function startButterfly()
    if catching then return end
    catching = true
    task.spawn(function()
        while Config.AutoButterfly do
            local char, hum, hrp = getChar()
            if char and hum and hrp and hum.Health > 0 then
                local closestB, closestDist = nil, math.huge
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if (v:IsA("Model") or v:IsA("Part")) and (v.Name:lower():find("butterfly") or v.Name:lower():find("moth")) then
                        local prompt = v:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            local pos = (v:IsA("Model") and v:GetPivot().Position) or v.Position
                            local dist = (pos - hrp.Position).Magnitude
                            if dist < closestDist then
                                closestB, closestDist = {model=v, prompt=prompt, pos=pos}, dist
                            end
                        end
                    end
                end

                if closestB then
                    if closestDist > 8 then
                        hum:MoveTo(closestB.pos)
                        task.wait(0.2)
                    else
                        hum:MoveTo(hrp.Position)
                        pcall(function() fireproximityprompt(closestB.prompt) end)
                        task.wait(0.4)
                    end
                else
                    task.wait(1)
                end
            else
                task.wait(1)
            end
        end
        catching = false
    end)
end

-- 3. فقس البيض تلقائياً
local function startHatch()
    task.spawn(function()
        while Config.AutoHatch do
            local char = LP.Character
            if char then
                local plot = Workspace:FindFirstChild(LP.Name .. "'s Plot")
                if plot then
                    for _, v in ipairs(plot:GetDescendants()) do
                        if v:IsA("ProximityPrompt") and (v.ActionText:lower():find("hatch") or v.Parent.Name:lower():find("egg")) then
                            pcall(function() fireproximityprompt(v) end)
                        end
                    end
                end
            end
            task.wait(1)
        end
    end)
end

-- 4. Anti AFK
LP.Idled:Connect(function()
    pcall(function()
        VU:CaptureController()
        VU:ClickButton2(Vector2.new())
    end)
end)

-- ==========================================
-- ============ واجهة (CoreGui) ============
-- ==========================================
local function mk(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local colors = {
    bg = Color3.fromRGB(18, 18, 20),
    panel = Color3.fromRGB(28, 28, 32),
    accent = Color3.fromRGB(220, 40, 50),
    text = Color3.fromRGB(240, 240, 240),
    off = Color3.fromRGB(60, 60, 70)
}

-- محاولة استخدام CoreGui، وإذا فشلت نرجع PlayerGui
local uiParent
pcall(function()
    uiParent = game:GetService("CoreGui")
end)
if not uiParent then
    uiParent = LP:WaitForChild("PlayerGui")
end

local gui = mk("ScreenGui", {
    Name = "DHub",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, uiParent)

-- زر D
local btn = mk("TextButton", {
    Size=UDim2.fromOffset(56,56), Position=UDim2.new(0,15,0.4,0),
    BackgroundColor3=colors.accent, Text="D", TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBold, TextSize=26, BorderSizePixel=0, AutoButtonColor=false
}, gui)
mk("UICorner",{CornerRadius=UDim.new(1,0)}, btn)
mk("UIStroke",{Color=colors.accent, Thickness=2}, btn)

-- البنل
local main = mk("Frame", {
    Size=UDim2.fromOffset(280, 360), Position=UDim2.new(0.5,-140,0.5,-180),
    BackgroundColor3=colors.bg, BorderSizePixel=0, Visible=false
}, gui)
mk("UICorner",{CornerRadius=UDim.new(0,12)}, main)
mk("UIStroke",{Color=colors.accent, Thickness=1.5}, main)

local top = mk("Frame", {Size=UDim2.new(1,0,0,40), BackgroundColor3=colors.panel, BorderSizePixel=0}, main)
mk("UICorner",{CornerRadius=UDim.new(0,12)}, top)
mk("TextLabel",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="Derek Hub v6.1", Font=Enum.Font.GothamBold, TextSize=14, TextColor3=colors.text}, top)

local scroll = mk("ScrollingFrame", {
    Size=UDim2.new(1,-20,1,-60), Position=UDim2.new(0,10,0,50),
    BackgroundTransparency=1, ScrollBarThickness=2, CanvasSize=UDim2.new(0,0,0,0)
}, main)
mk("UIListLayout",{Padding=UDim.new(0,8)}, scroll)

local function addBtn(text, default, callback)
    local row = mk("Frame",{Size=UDim2.new(1,-10,0,36), BackgroundColor3=colors.panel}, scroll)
    mk("UICorner",{CornerRadius=UDim.new(0,8)}, row)
    mk("TextLabel",{Size=UDim2.new(1,-50,1,0), Position=UDim2.new(0,10,0,0), BackgroundTransparency=1, Text=text, TextColor3=colors.text, Font=Enum.Font.GothamMedium, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left}, row)
    
    local sw = mk("Frame",{Size=UDim2.fromOffset(36,20), Position=UDim2.new(1,-46,0.5,-10), BackgroundColor3=default and colors.accent or colors.off}, row)
    mk("UICorner",{CornerRadius=UDim.new(1,0)}, sw)
    local knob = mk("Frame",{Size=UDim2.fromOffset(16,16), Position=UDim2.new(0, default and 18 or 2, 0.5, -8), BackgroundColor3=Color3.new(1,1,1)}, sw)
    mk("UICorner",{CornerRadius=UDim.new(1,0)}, knob)
    
    local state = default
    local click = mk("TextButton",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text=""}, row)
    click.MouseButton1Click:Connect(function()
        state = not state
        Tween:Create(sw, TweenInfo.new(0.15), {BackgroundColor3 = state and colors.accent or colors.off}):Play()
        Tween:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(0, state and 18 or 2, 0.5, -8)}):Play()
        if callback then pcall(callback, state) end
    end)
end

addBtn("Auto Steal", false, function(v) Config.AutoSteal = v; if v then startSteal() end end)
addBtn("Auto Butterflies", false, function(v) Config.AutoButterfly = v; if v then startButterfly() end end)
addBtn("Auto Hatch", false, function(v) Config.AutoHatch = v; if v then startHatch() end end)

-- فتح وقفل
local open = false
btn.MouseButton1Click:Connect(function()
    open = not open
    main.Visible = open
end)

-- سحب الزر
local dragging, dragStart, startPos
btn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = btn.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)--[[
    Derek Hub v5.0 — Ultimate Mobile Edition
    Features: Anti-Cheat Bypass | Auto Steal | Fly | Infinite Jump | Auto Butterflies
    Game: Steal An Egg
    Author: ALPHA
]]

if getgenv().__DerekHub then return end
getgenv().__DerekHub = true

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local RS         = game:GetService("ReplicatedStorage")
local VU         = game:GetService("VirtualUser")
local UIS        = game:GetService("UserInputService")
local Tween      = game:GetService("TweenService")
local LP         = Players.LocalPlayer

-- ═══════════════════════════════════════════════
-- ═══════════ الإعدادات الافتراضية ═══════════════
-- ═══════════════════════════════════════════════
local C = {
    AutoSteal = false,
    SafeMode = true,
    Fly = false,
    FlySpeed = 60,
    InfiniteJump = false,
    AutoButterfly = false,
    AntiCatch = false,
    AntiRagdoll = false,
    GodMode = false,
    ESP = false,
    MaxDist = 12,
    MinDelay = 0.30,
    MaxDelay = 0.80,
}

-- ═══════════════════════════════════════════════
-- ═══════════ نظام إدارة الـ Remotes ═════════════
-- ═══════════════════════════════════════════════
local Remotes = {}
for _,v in ipairs(RS:GetDescendants()) do
    if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") or v:IsA("UnreliableRemoteEvent") then
        Remotes[v.Name] = v
    end
end

local function findRemote(kws)
    for n,r in pairs(Remotes) do
        local l = string.lower(n)
        for _,k in ipairs(kws) do
            if l:find(k) then return r end
        end
    end
end

local StealRemote    = findRemote({"steal","grab","takeegg","pickup"})
local ReportRemote   = findRemote({"report","catch","caught","tackle","trip","kick","ban"})
local RagdollRemote  = findRemote({"ragdoll","knock","stun","hit","tackle"})
local ButterflyRemote= findRemote({"butterfly","net","catch"})

-- ═══════════════════════════════════════════════
-- ═══════════ دوال مساعدة (Helper Functions) ═════
-- ═══════════════════════════════════════════════
local function getChar()
    local c = LP.Character
    return c, c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
end

local function getEggs()
    local t = {}
    for _,o in ipairs(Workspace:GetDescendants()) do
        if (o:IsA("Model") or o:IsA("Part")) and not o:FindFirstChild("Humanoid") then
            local n = string.lower(o.Name)
            if n:find("egg") and not n:find("plot") and not n:find("spawn") then
                local p = o:FindFirstChildWhichIsA("ProximityPrompt", true)
                if p then table.insert(t, {model=o, prompt=p}) end
            end
        end
    end
    return t
end

local function getButterflies()
    local t = {}
    for _,o in ipairs(Workspace:GetDescendants()) do
        if o:IsA("Model") or o:IsA("Part") then
            local n = string.lower(o.Name)
            if n:find("butterfly") or n:find("moth") or n:find("flutter") then
                local p = o:FindFirstChildWhichIsA("ProximityPrompt", true)
                if p then table.insert(t, {model=o, prompt=p}) end
            end
        end
    end
    return t
end

-- ═══════════════════════════════════════════════
-- ═══════════ منطق السرقة التلقائية ══════════════
-- ═══════════════════════════════════════════════
local stealing = false
local function stealEgg(e)
    if not e or not e.model.Parent then return end
    local _, hum, hrp = getChar()
    if not hum or not hrp or hum.Health <= 0 then return end

    local eggPos = (e.model:IsA("Model") and e.model:GetPivot().Position) or e.model.Position
    local myPos = hrp.Position
    local dist = (eggPos - myPos).Magnitude

    if dist > C.MaxDist then return end

    -- مشي طبيعي إذا كانت المسافة متوسطة
    if not C.SafeMode and dist > 4 then
        pcall(function()
            hum:MoveTo(eggPos)
            task.wait(math.clamp(dist / 16, 0.1, 1.0))
        end)
    end

    if e.prompt then
        pcall(function() fireproximityprompt(e.prompt) end)
        return
    end
    if StealRemote then
        pcall(function() StealRemote:FireServer(e.model) end)
    end
end

local function autoSteal()
    if stealing then return end
    stealing = true
    task.spawn(function()
        while C.AutoSteal do
            local _, hum, hrp = getChar()
            if hum and hrp and hum.Health > 0 then
                local eggs = getEggs()
                local best, bestD = nil, math.huge
                for _, e in ipairs(eggs) do
                    local pos = (e.model:IsA("Model") and e.model:GetPivot().Position) or e.model.Position
                    local d = (pos - hrp.Position).Magnitude
                    if d < bestD and d <= C.MaxDist then
                        best, bestD = e, d
                    end
                end
                if best then
                    stealEgg(best)
                    task.wait(math.random() * (C.MaxDelay - C.MinDelay) + C.MinDelay)
                else
                    task.wait(0.5)
                end
            else
                task.wait(0.5)
            end
        end
        stealing = false
    end)
end

-- ═══════════════════════════════════════════════
-- ═══════════ الطيران (Fly) ═════════════════════
-- ═══════════════════════════════════════════════
local flyConnection
local function enableFly()
    if flyConnection then return end
    local char, hum, hrp = getChar()
    if not hum or not hrp then return end

    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.P = 9e4
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.CFrame = hrp.CFrame
    bodyGyro.Parent = hrp

    local bodyVel = Instance.new("BodyVelocity")
    bodyVel.Velocity = Vector3.new(0, 0, 0)
    bodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVel.Parent = hrp

    flyConnection = RunService.RenderStepped:Connect(function()
        if not C.Fly then
            bodyGyro:Destroy()
            bodyVel:Destroy()
            flyConnection:Disconnect()
            flyConnection = nil
            return
        end
        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0 then
            bodyVel.Velocity = (moveDir.Unit * C.FlySpeed) + Vector3.new(0, (UIS:IsKeyDown(Enum.KeyCode.Space) and C.FlySpeed or 0), 0)
        else
            bodyVel.Velocity = Vector3.new(0, (UIS:IsKeyDown(Enum.KeyCode.Space) and C.FlySpeed or 0), 0)
        end
        bodyGyro.CFrame = workspace.CurrentCamera.CFrame
    end)
end

-- ═══════════════════════════════════════════════
-- ═══════════ القفز اللانهائي ═══════════════════
-- ═══════════════════════════════════════════════
UIS.JumpRequest:Connect(function()
    if C.InfiniteJump then
        local _, hum = getChar()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ═══════════════════════════════════════════════
-- ═══════════ حدث الفراشات (Butterfly Bloom) ════
-- ═══════════════════════════════════════════════
local catchingButterfly = false
local function autoButterfly()
    if catchingButterfly then return end
    catchingButterfly = true
    task.spawn(function()
        while C.AutoButterfly do
            local char, hum, hrp = getChar()
            if char and hum and hrp and hum.Health > 0 then
                local butterflies = getButterflies()
                local best, bestD = nil, math.huge
                for _, b in ipairs(butterflies) do
                    local pos = (b.model:IsA("Model") and b.model:GetPivot().Position) or b.model.Position
                    local d = (pos - hrp.Position).Magnitude
                    if d < bestD then
                        best, bestD = b, d
                    end
                end

                if best then
                    local pos = (best.model:IsA("Model") and best.model:GetPivot().Position) or best.model.Position
                    -- الطيران للفراشة إذا كانت بعيدة
                    if bestD > 10 and not C.Fly then
                        pcall(function() hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0)) end)
                        task.wait(0.1)
                    end
                    -- محاولة الإمساك
                    if best.prompt then
                        pcall(function() fireproximityprompt(best.prompt) end)
                    end
                    if ButterflyRemote then
                        pcall(function() ButterflyRemote:FireServer(best.model) end)
                    end
                    task.wait(0.15)
                else
                    task.wait(0.5)
                end
            else
                task.wait(0.5)
            end
        end
        catchingButterfly = false
    end)
end

-- ═══════════════════════════════════════════════
-- ═══════════ طبقات الحماية (Anti-Cheat) ════════
-- ═══════════════════════════════════════════════
local function enableAntiCatch()
    if not (getrawmetatable and setreadonly and newcclosure) then return end
    local mt = getrawmetatable(game)
    if mt and mt.__namecall then
        local old = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            if self == ReportRemote then return nil end
            if self == RagdollRemote and C.AntiRagdoll then return nil end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end
end

local function antiRagdoll()
    task.spawn(function()
        while C.AntiRagdoll do
            local _, hum, hrp = getChar()
            if hum then
                if hum:GetState() == Enum.HumanoidStateType.Physics then
                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
                end
                hum.PlatformStand = false
                if hrp then
                    local r = hrp:FindFirstChild("Ragdoll")
                    if r then pcall(function() r:Destroy() end) end
                end
            end
            task.wait(0.1)
        end
    end)
end

local function godMode()
    task.spawn(function()
        while C.GodMode do
            local _, hum = getChar()
            if hum then
                hum.Health = hum.MaxHealth
                hum.BreakJointsOnDeath = false
            end
            task.wait(0.25)
        end
    end)
end

-- ═══════════════════════════════════════════════
-- ═══════════ ESP (رؤية البيض) ══════════════════
-- ═══════════════════════════════════════════════
local espObjs = {}
local function updateESP()
    if not C.ESP then
        for _, b in pairs(espObjs) do b:Destroy() end
        espObjs = {}
        return
    end
    for _, d in ipairs(getEggs()) do
        local egg = d.model
        if not espObjs[egg] then
            local b = Instance.new("BoxHandleAdornment")
            b.Adornee = egg
            b.AlwaysOnTop = true
            b.ZIndex = 5
            b.Size = egg:IsA("Model") and egg:GetExtentsSize() or egg.Size
            b.Color3 = Color3.fromRGB(255, 30, 30)
            b.Transparency = 0.5
            b.Parent = egg
            espObjs[egg] = b
        end
    end
    for e, b in pairs(espObjs) do
        if not e.Parent then
            b:Destroy()
            espObjs[e] = nil
        end
    end
end
RunService.RenderStepped:Connect(updateESP)

LP.Idled:Connect(function()
    pcall(function()
        VU:CaptureController()
        VU:ClickButton2(Vector2.new())
    end)
end)

-- ═══════════════════════════════════════════════
-- ═══════════ واجهة المستخدم (Mobile UI) ════════
-- ═══════════════════════════════════════════════
local function mk(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local clr = {
    bg = Color3.fromRGB(15, 10, 12),
    panel = Color3.fromRGB(25, 15, 18),
    accent = Color3.fromRGB(220, 30, 40),
    accent2 = Color3.fromRGB(255, 60, 70),
    text = Color3.fromRGB(245, 235, 235),
    subtext = Color3.fromRGB(160, 150, 150),
    knobOff = Color3.fromRGB(60, 45, 50),
}

local gui = mk("ScreenGui", {Name="DerekHubUI", ResetOnSpawn=false, IgnoreGuiInset=true, ZIndexBehavior=Enum.ZIndexBehavior.Sibling}, LP:WaitForChild("PlayerGui"))

-- ═══════ زر الفتح (حرف D) ═══════
local iconBtn = mk("TextButton", {
    Name = "DerekIcon",
    Size = UDim2.fromOffset(64, 64),
    Position = UDim2.new(0, 20, 0.5, -32),
    BackgroundColor3 = clr.accent,
    BorderSizePixel = 0, AutoButtonColor = false,
    Text = "D",
    Font = Enum.Font.GothamBlack,
    TextSize = 30,
    TextColor3 = Color3.new(1, 1, 1),
    ZIndex = 100,
}, gui)
mk("UICorner", {CornerRadius = UDim.new(1, 0)}, iconBtn)
local iconStroke = mk("UIStroke", {Color = clr.accent2, Thickness = 2.5, Transparency = 0.2}, iconBtn)

task.spawn(function()
    while iconBtn.Parent do
        Tween:Create(iconStroke, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Thickness=5, Transparency=0.7}):Play()
        task.wait(1)
        Tween:Create(iconStroke, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Thickness=2.5, Transparency=0.2}):Play()
        task.wait(1)
    end
end)

-- ═══════ البنل الرئيسي ═══════
local panel = mk("Frame", {
    Name = "Panel",
    Size = UDim2.fromOffset(340, 480),
    Position = UDim2.new(0.5, -170, 0.5, -240),
    BackgroundColor3 = clr.bg, BorderSizePixel = 0,
    Visible = false, ZIndex = 90,
}, gui)
mk("UICorner", {CornerRadius = UDim.new(0, 14)}, panel)
mk("UIStroke", {Color = clr.accent, Thickness = 1.5, Transparency = 0.3}, panel)

local titleBar = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 48),
    BackgroundColor3 = clr.panel, BorderSizePixel = 0,
}, panel)
mk("UICorner", {CornerRadius = UDim.new(0, 14)}, titleBar)
mk("Frame", {Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14), BackgroundColor3 = clr.panel, BorderSizePixel = 0}, titleBar)

local titleIcon = mk("TextButton", {
    Size = UDim2.fromOffset(34, 34), Position = UDim2.new(0, 10, 0.5, -17),
    BackgroundColor3 = clr.accent, BorderSizePixel = 0,
    Text = "D", Font = Enum.Font.GothamBlack, TextSize = 18,
    TextColor3 = Color3.new(1, 1, 1), AutoButtonColor = false,
}, titleBar)
mk("UICorner", {CornerRadius = UDim.new(1, 0)}, titleIcon)

mk("TextLabel", {
    Size = UDim2.new(1, -120, 0, 20), Position = UDim2.new(0, 52, 0, 7),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 15,
    TextColor3 = clr.text, Text = "Derek Hub", TextXAlignment = Enum.TextXAlignment.Left,
}, titleBar)
mk("TextLabel", {
    Size = UDim2.new(1, -120, 0, 16), Position = UDim2.new(0, 52, 0, 25),
    BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 10,
    TextColor3 = clr.accent2, Text = "v5.0 Mobile", TextXAlignment = Enum.TextXAlignment.Left,
}, titleBar)

local closeBtn = mk("TextButton", {
    Size = UDim2.fromOffset(32, 32), Position = UDim2.new(1, -42, 0.5, -16),
    BackgroundColor3 = clr.accent, Text = "✕", TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold, TextSize = 16, BorderSizePixel = 0, AutoButtonColor = false,
}, titleBar)
mk("UICorner", {CornerRadius = UDim.new(0, 8)}, closeBtn)

-- ═══════ التبويبات ═══════
local tabBar = mk("Frame", {
    Size = UDim2.new(1, -20, 0, 40), Position = UDim2.new(0, 10, 0, 58),
    BackgroundColor3 = clr.panel, BorderSizePixel = 0,
}, panel)
mk("UICorner", {CornerRadius = UDim.new(0, 10)}, tabBar)
mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Center}, tabBar)

local content = mk("ScrollingFrame", {
    Size = UDim2.new(1, -20, 1, -158), Position = UDim2.new(0, 10, 0, 106),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 3, CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarImageColor3 = clr.accent,
}, panel)
mk("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, content)

local pages = {}
local function makePage(name)
    local f = mk("Frame", {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, Visible = false}, content)
    mk("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, f)
    pages[name] = f
end
makePage("Steal"); makePage("Movement"); makePage("Protect"); makePage("Events")

local tabButtons = {}
local function selectTab(name)
    for n, f in pairs(pages) do f.Visible = (n == name) end
    for n, b in pairs(tabButtons) do
        Tween:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = (n == name) and clr.accent or clr.panel}):Play()
    end
end

for _, name in ipairs({"Steal", "Movement", "Protect", "Events"}) do
    local btn = mk("TextButton", {
        Size = UDim2.new(0, 72, 0, 30), BackgroundColor3 = clr.panel,
        Text = name, TextColor3 = clr.text, Font = Enum.Font.GothamMedium,
        TextSize = 11, BorderSizePixel = 0, AutoButtonColor = false,
    }, tabBar)
    mk("UICorner", {CornerRadius = UDim.new(0, 8)}, btn)
    btn.MouseButton1Click:Connect(function() selectTab(name) end)
    tabButtons[name] = btn
end
selectTab("Steal")

-- ═══════ عناصر الواجهة ═══════
local function addToggle(page, text, default, callback)
    local row = mk("Frame", {Size = UDim2.new(1, -10, 0, 44), BackgroundColor3 = clr.panel, BorderSizePixel = 0}, page)
    mk("UICorner", {CornerRadius = UDim.new(0, 10)}, row)
    mk("TextLabel", {
        Size = UDim2.new(1, -80, 1, 0), Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
        TextSize = 14, TextColor3 = clr.text, Text = text, TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local sw = mk("Frame", {Size = UDim2.fromOffset(48, 26), Position = UDim2.new(1, -60, 0.5, -13), BackgroundColor3 = default and clr.accent or clr.knobOff, BorderSizePixel = 0}, row)
    mk("UICorner", {CornerRadius = UDim.new(1, 0)}, sw)
    local knob = mk("Frame", {Size = UDim2.fromOffset(20, 20), Position = UDim2.new(0, default and 25 or 3, 0.5, -10), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, sw)
    mk("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)
    local state = default
    local btn = mk("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = ""}, row)
    btn.MouseButton1Click:Connect(function()
        state = not state
        Tween:Create(sw, TweenInfo.new(0.18), {BackgroundColor3 = state and clr.accent or clr.knobOff}):Play()
        Tween:Create(knob, TweenInfo.new(0.18), {Position = UDim2.new(0, state and 25 or 3, 0.5, -10)}):Play()
        if callback then pcall(callback, state) end
    end)
end

local function addSlider(page, text, minV, maxV, default, suffix, callback)
    local row = mk("Frame", {Size = UDim2.new(1, -10, 0, 64), BackgroundColor3 = clr.panel, BorderSizePixel = 0}, page)
    mk("UICorner", {CornerRadius = UDim.new(0, 10)}, row)
    local lbl = mk("TextLabel", {
        Size = UDim2.new(1, -20, 0, 22), Position = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 12,
        TextColor3 = clr.text, Text = text .. ": " .. default .. (suffix or ""),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local track = mk("Frame", {Size = UDim2.new(1, -24, 0, 8), Position = UDim2.new(0, 12, 0, 42), BackgroundColor3 = Color3.fromRGB(50, 35, 40), BorderSizePixel = 0}, row)
    mk("UICorner", {CornerRadius = UDim.new(1, 0)}, track)
    local fill = mk("Frame", {Size = UDim2.new((default - minV) / (maxV - minV), 0, 1, 0), BackgroundColor3 = clr.accent, BorderSizePixel = 0}, track)
    mk("UICorner", {CornerRadius = UDim.new(1, 0)}, fill)
    local drag = false
    local function setX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor((minV + (maxV - minV) * rel) * 100 + 0.5) / 100
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = text .. ": " .. val .. (suffix or "")
        if callback then pcall(callback, val) end
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; setX(i.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            setX(i.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
end

-- ═══════ ربط العناصر بالمنطق ═══════
addToggle(pages["Steal"], "Auto Steal", false, function(v) C.AutoSteal = v; if v then autoSteal() end end)
addToggle(pages["Steal"], "Safe Mode", true, function(v) C.SafeMode = v end)
addSlider(pages["Steal"], "Max Distance", 5, 30, 12, " stud", function(v) C.MaxDist = v end)
addSlider(pages["Steal"], "Min Delay", 0.1, 2, 0.30, "s", function(v) C.MinDelay = v end)
addSlider(pages["Steal"], "Max Delay", 0.2, 3, 0.80, "s", function(v) C.MaxDelay = v end)

addToggle(pages["Movement"], "Fly", false, function(v) C.Fly = v; if v then enableFly() end end)
addSlider(pages["Movement"], "Fly Speed", 20, 200, 60, "", function(v) C.FlySpeed = v end)
addToggle(pages["Movement"], "Infinite Jump", false, function(v) C.InfiniteJump = v end)

addToggle(pages["Protect"], "Anti Catch", false, function(v) C.AntiCatch = v; if v then enableAntiCatch() end end)
addToggle(pages["Protect"], "Anti Ragdoll", false, function(v) C.AntiRagdoll = v; if v then antiRagdoll() end end)
addToggle(pages["Protect"], "God Mode", false, function(v) C.GodMode = v; if v then godMode() end end)

addToggle(pages["Events"], "Auto Butterflies", false, function(v) C.AutoButterfly = v; if v then autoButterfly() end end)
addToggle(pages["Events"], "ESP Eggs", false, function(v) C.ESP = v end)

-- ═══════ فتح/قفل البنل ═══════
local isOpen = false
local function openPanel()
    if isOpen then return end
    isOpen = true
    panel.Visible = true
    panel.Size = UDim2.fromOffset(340, 0)
    panel.BackgroundTransparency = 1
    Tween:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(340, 480), BackgroundTransparency = 0}):Play()
    Tween:Create(iconBtn, TweenInfo.new(0.2), {Size = UDim2.fromOffset(50, 50), Position = UDim2.new(0, 20, 0.5, -25)}):Play()
end
local function closePanel()
    if not isOpen then return end
    isOpen = false
    Tween:Create(panel, TweenInfo.new(0.2), {Size = UDim2.fromOffset(340, 0), BackgroundTransparency = 1}):Play()
    Tween:Create(iconBtn, TweenInfo.new(0.2), {Size = UDim2.fromOffset(64, 64), Position = UDim2.new(0, 20, 0.5, -32)}):Play()
    task.delay(0.22, function() if not isOpen then panel.Visible = false end end)
end

iconBtn.MouseButton1Click:Connect(function()
    if isOpen then closePanel() else openPanel() end
end)
closeBtn.MouseButton1Click:Connect(closePanel)

-- ═══════ السحب (Dragging) ═══════
local dragIcon = false
local dragStart, startPos
iconBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragIcon = true; dragStart = i.Position; startPos = iconBtn.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if dragIcon and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = i.Position - dragStart
        iconBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragIcon = false end
end)

local dragPanel = false
titleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragPanel = true; dragStart = i.Position; startPos = panel.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if dragPanel and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = i.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragPanel = false end
end)
