--[[ Derek Hub v25.1 — Clean Extended | Steal An Egg | Author: ALPHA ]]
task.wait(2)

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local Lighting          = game:GetService("Lighting")
local UIS               = game:GetService("UserInputService")
local Tween             = game:GetService("TweenService")
local VirtualUser       = game:GetService("VirtualUser")
local LP                = Players.LocalPlayer

local State = {
    Stats = { EggsStolen = 0, Hatches = 0, SessionStart = tick() },
    Logs = {}
}

local function Log(msg, tag)
    tag = tag or "INFO"
    local entry = "["..os.date("%H:%M:%S").."] ["..tag.."] "..msg
    table.insert(State.Logs, entry)
    if #State.Logs > 200 then table.remove(State.Logs, 1) end
end
Log("Initializing Derek Hub v25.1", "SYSTEM")

local Config = {
    Farm = { AutoSteal = false, AutoHatch = false, SafeMode = true, StealDelay = 0.4 },
    Movement = { SpeedEnabled = false, WalkSpeed = 16, FlyEnabled = false, FlySpeed = 60, Noclip = false, InfiniteJump = false },
    Visual = { ESP_Eggs = false, Fullbright = false },
    Misc = { AntiAFK = true }
}

local function GetChar()
    local c = LP.Character
    return c, c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
end

local function GetEggs()
    local list = {}
    local _, _, hrp = GetChar()
    if not hrp then return list end
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and string.lower(obj.ActionText) == "steal" then
            local model = obj.Parent
            local pos = (model:IsA("Model") and model:GetPivot().Position) or model.Position
            local name = obj.ObjectText ~= "" and obj.ObjectText or model.Name
            local score = 10
            local lower = string.lower(name)
            if lower:find("secret") or lower:find("mythic") then score = 1000
            elseif lower:find("legendary") then score = 800
            elseif lower:find("epic") then score = 600
            elseif lower:find("rare") then score = 400 end
            table.insert(list, { model = model, prompt = obj, pos = pos, name = name, score = score, dist = math.floor((pos - hrp.Position).Magnitude) })
        end
    end
    table.sort(list, function(a, b) return a.score > b.score end)
    return list
end

local function StealEgg(egg, callback)
    local _, hum, hrp = GetChar()
    if not hum or not hrp or not egg.model.Parent then return end
    local oldCF = hrp.CFrame
    local oldSpd = hum.WalkSpeed
    hum.WalkSpeed = 16
    task.spawn(function()
        pcall(function()
            hrp.CFrame = CFrame.new(egg.pos + Vector3.new(0, 2.5, 0))
            task.wait(Config.Farm.SafeMode and 0.35 or 0.08)
            fireproximityprompt(egg.prompt)
            State.Stats.EggsStolen = State.Stats.EggsStolen + 1
            task.wait(Config.Farm.SafeMode and 0.35 or 0.08)
            hrp.CFrame = oldCF
        end)
        hum.WalkSpeed = Config.Movement.SpeedEnabled and Config.Movement.WalkSpeed or oldSpd
        if callback then pcall(callback) end
    end)
end

-- الفارم التلقائي
task.spawn(function()
    while task.wait(Config.Farm.StealDelay) do
        if Config.Farm.AutoSteal then
            local eggs = GetEggs()
            if #eggs > 0 then StealEgg(eggs[1]) end
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if Config.Farm.AutoHatch then
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") and string.lower(v.ActionText):find("hatch") then
                    pcall(function() fireproximityprompt(v) end)
                end
            end
        end
    end
end)

-- الحركة
RunService.RenderStepped:Connect(function()
    if Config.Movement.SpeedEnabled then
        local _, hum = GetChar()
        if hum and hum.WalkSpeed ~= Config.Movement.WalkSpeed then
            hum.WalkSpeed = Config.Movement.WalkSpeed
        end
    end
end)

local FlyBV, FlyBG
RunService.RenderStepped:Connect(function()
    local _, hum, hrp = GetChar()
    if not hum or not hrp then
        if FlyBV then FlyBV:Destroy() FlyBV = nil end
        if FlyBG then FlyBG:Destroy() FlyBG = nil end
        return
    end
    if Config.Movement.FlyEnabled then
        if not FlyBV then
            FlyBV = Instance.new("BodyVelocity", hrp)
            FlyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            FlyBG = Instance.new("BodyGyro", hrp)
            FlyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            FlyBG.P = 1000
        end
        local dir = hum.MoveDirection
        local vert = 0
        if UIS:IsKeyDown(Enum.KeyCode.Space) then vert = Config.Movement.FlySpeed end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then vert = -Config.Movement.FlySpeed end
        FlyBV.Velocity = dir * Config.Movement.FlySpeed + Vector3.new(0, vert, 0)
        FlyBG.CFrame = Workspace.CurrentCamera.CFrame
    else
        if FlyBV then FlyBV:Destroy() FlyBV = nil end
        if FlyBG then FlyBG:Destroy() FlyBG = nil end
    end
end)

RunService.Stepped:Connect(function()
    if Config.Movement.Noclip then
        local char = LP.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)

UIS.JumpRequest:Connect(function()
    if Config.Movement.InfiniteJump then
        local _, hum = GetChar()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ESP
RunService.RenderStepped:Connect(function()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name == "DerekESP" then v:Destroy() end
    end
    if Config.Visual.ESP_Eggs then
        for _, egg in ipairs(GetEggs()) do
            local box = Instance.new("BoxHandleAdornment")
            box.Name = "DerekESP"
            box.Adornee = egg.model
            box.AlwaysOnTop = true
            box.Size = egg.model:GetExtentsSize()
            box.Color3 = Color3.fromRGB(0, 255, 100)
            box.Transparency = 0.5
            box.Parent = egg.model
        end
    end
end)

LP.Idled:Connect(function()
    if Config.Misc.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

--=========================================================
-- [ UI ]
--=========================================================
local function mk(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local Theme = {
    BG = Color3.fromRGB(12, 12, 18), Card = Color3.fromRGB(22, 22, 32),
    Accent = Color3.fromRGB(230, 30, 60), Accent2 = Color3.fromRGB(50, 150, 255),
    Text = Color3.fromRGB(245, 245, 250), Sub = Color3.fromRGB(150, 150, 170),
    Off = Color3.fromRGB(45, 45, 60), Success = Color3.fromRGB(0, 200, 100)
}

local gui = mk("ScreenGui", { Name = "DerekHubV25", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, LP:WaitForChild("PlayerGui"))

-- زر الفتح
local openBtn = mk("TextButton", {
    Size = UDim2.fromOffset(60, 60), Position = UDim2.new(0, 20, 0.5, -30),
    BackgroundColor3 = Theme.Accent, Text = "D", TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBlack, TextSize = 30, BorderSizePixel = 0
}, gui)
mk("UICorner", {CornerRadius = UDim.new(1, 0)}, openBtn)
mk("UIStroke", {Color = Theme.Accent2, Thickness = 2}, openBtn)

local main = mk("Frame", {
    Size = UDim2.fromOffset(560, 420), Position = UDim2.new(0.5, -280, 0.5, -210),
    BackgroundColor3 = Theme.BG, BorderSizePixel = 0, Visible = false
}, gui)
mk("UICorner", {CornerRadius = UDim.new(0, 12)}, main)
mk("UIStroke", {Color = Theme.Accent, Thickness = 2}, main)

local topBar = mk("Frame", { Size = UDim2.new(1, 0, 0, 55), BackgroundColor3 = Theme.Card, BorderSizePixel = 0 }, main)
mk("UICorner", {CornerRadius = UDim.new(0, 12)}, topBar)
mk("Frame", { Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 1, -28), BackgroundColor3 = Theme.Card }, topBar)

mk("TextLabel", { Size = UDim2.new(0, 250, 0, 30), Position = UDim2.fromOffset(20, 8), BackgroundTransparency = 1, Text = "DEREK", TextColor3 = Theme.Text, Font = Enum.Font.GothamBlack, TextSize = 28, TextXAlignment = Enum.TextXAlignment.Left }, topBar)
mk("TextLabel", { Size = UDim2.new(0, 250, 0, 18), Position = UDim2.fromOffset(20, 32), BackgroundTransparency = 1, Text = "v25.1", TextColor3 = Theme.Accent2, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, topBar)

local closeBtn = mk("TextButton", { Size = UDim2.fromOffset(34, 34), Position = UDim2.new(1, -46, 0.5, -17), BackgroundColor3 = Theme.Accent, Text = "✕", TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 16, BorderSizePixel = 0 }, topBar)
mk("UICorner", {CornerRadius = UDim.new(0, 8)}, closeBtn)

local tabBar = mk("Frame", { Size = UDim2.new(1, -20, 0, 35), Position = UDim2.fromOffset(10, 65), BackgroundTransparency = 1 }, main)
mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, tabBar)

local Pages, Tabs = {}, {}
local function CreateTab(name, isFirst)
    local btn = mk("TextButton", { Size = UDim2.fromOffset(90, 35), BackgroundColor3 = isFirst and Theme.Accent or Theme.Card, Text = name, TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 12, BorderSizePixel = 0 }, tabBar)
    mk("UICorner", {CornerRadius = UDim.new(0, 8)}, btn)
    local page = mk("ScrollingFrame", { Size = UDim2.new(1, -20, 1, -115), Position = UDim2.fromOffset(10, 110), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent2, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = isFirst }, main)
    mk("UIListLayout", { Padding = UDim.new(0, 6) }, page)
    Tabs[name] = btn; Pages[name] = page
    btn.MouseButton1Click:Connect(function()
        for n, p in pairs(Pages) do p.Visible = (n == name) end
        for n, b in pairs(Tabs) do Tween:Create(b, TweenInfo.new(0.15), { BackgroundColor3 = (n == name) and Theme.Accent or Theme.Card }):Play() end
    end)
    return page
end

local FarmTab = CreateTab("Farm", true)
local MoveTab = CreateTab("Move", false)
local VisualTab = CreateTab("Visual", false)
local EggTab = CreateTab("Eggs", false)

local function AddToggle(parent, text, default, callback, y)
    local row = mk("Frame", { Size = UDim2.new(1, -10, 0, 42), Position = UDim2.fromOffset(5, y), BackgroundColor3 = Theme.Card }, parent)
    mk("UICorner", {CornerRadius = UDim.new(0, 8)}, row)
    mk("TextLabel", { Size = UDim2.new(1, -70, 1, 0), Position = UDim2.fromOffset(14, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, row)
    local sw = mk("Frame", { Size = UDim2.fromOffset(42, 22), Position = UDim2.new(1, -54, 0.5, -11), BackgroundColor3 = default and Theme.Success or Theme.Off }, row)
    mk("UICorner", {CornerRadius = UDim.new(1, 0)}, sw)
    local knob = mk("Frame", { Size = UDim2.fromOffset(18, 18), Position = UDim2.new(0, default and 21 or 2, 0.5, -9), BackgroundColor3 = Theme.Text }, sw)
    mk("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)
    local state = default
    local click = mk("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "" }, row)
    click.MouseButton1Click:Connect(function()
        state = not state
        Tween:Create(sw, TweenInfo.new(0.15), { BackgroundColor3 = state and Theme.Success or Theme.Off }):Play()
        Tween:Create(knob, TweenInfo.new(0.15), { Position = UDim2.new(0, state and 21 or 2, 0.5, -9) }):Play()
        if callback then pcall(callback, state) end
    end)
end

local function AddSlider(parent, text, minV, maxV, default, callback, y)
    local row = mk("Frame", { Size = UDim2.new(1, -10, 0, 58), Position = UDim2.fromOffset(5, y), BackgroundColor3 = Theme.Card }, parent)
    mk("UICorner", {CornerRadius = UDim.new(0, 8)}, row)
    local lbl = mk("TextLabel", { Size = UDim2.new(1, -20, 0, 20), Position = UDim2.fromOffset(14, 6), BackgroundTransparency = 1, Text = text..": "..default, TextColor3 = Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, row)
    local track = mk("Frame", { Size = UDim2.new(1, -28, 0, 8), Position = UDim2.fromOffset(14, 38), BackgroundColor3 = Theme.Off }, row)
    mk("UICorner", {CornerRadius = UDim.new(1, 0)}, track)
    local fill = mk("Frame", { Size = UDim2.new((default - minV) / (maxV - minV), 0, 1, 0), BackgroundColor3 = Theme.Accent2 }, track)
    mk("UICorner", {CornerRadius = UDim.new(1, 0)}, fill)
    local drag = false
    local function update(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(minV + (maxV - minV) * rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = text..": "..val
        if callback then pcall(callback, val) end
    end
    track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; update(i.Position.X) end end)
    UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then update(i.Position.X) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)
end

AddToggle(FarmTab, "Auto Steal (Best Egg)", false, function(v) Config.Farm.AutoSteal = v end, 5)
AddToggle(FarmTab, "Safe Steal Mode", true, function(v) Config.Farm.SafeMode = v end, 52)
AddToggle(FarmTab, "Auto Hatch", false, function(v) Config.Farm.AutoHatch = v end, 99)
AddSlider(FarmTab, "Steal Delay", 1, 20, 4, function(v) Config.Farm.StealDelay = v / 10 end, 146)

AddToggle(MoveTab, "Enable Speed", false, function(v) Config.Movement.SpeedEnabled = v end, 5)
AddSlider(MoveTab, "Walk Speed", 16, 500, 16, function(v) Config.Movement.WalkSpeed = v end, 52)
AddToggle(MoveTab, "Enable Fly", false, function(v) Config.Movement.FlyEnabled = v end, 119)
AddSlider(MoveTab, "Fly Speed", 20, 300, 60, function(v) Config.Movement.FlySpeed = v end, 166)
AddToggle(MoveTab, "Noclip", false, function(v) Config.Movement.Noclip = v end, 233)
AddToggle(MoveTab, "Infinite Jump", false, function(v) Config.Movement.InfiniteJump = v end, 280)

AddToggle(VisualTab, "ESP Eggs", false, function(v) Config.Visual.ESP_Eggs = v end, 5)
AddToggle(VisualTab, "Fullbright", false, function(v)
    Config.Visual.Fullbright = v
    if v then Lighting.Ambient = Color3.fromRGB(255, 255, 255); Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255); Lighting.Brightness = 3
    else Lighting.Ambient = Color3.fromRGB(70, 70, 70); Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128); Lighting.Brightness = 2 end
end, 52)
AddToggle(VisualTab, "Anti-AFK", true, function(v) Config.Misc.AntiAFK = v end, 99)

task.spawn(function()
    while task.wait(1.5) do
        if not Pages["Eggs"].Visible then continue end
        for _, v in pairs(EggTab:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
        local eggs = GetEggs()
        for i, egg in ipairs(eggs) do
            local row = mk("Frame", { Size = UDim2.new(1, -5, 0, 48), BackgroundColor3 = Theme.Card }, EggTab)
            mk("UICorner", {CornerRadius = UDim.new(0, 8)}, row)
            mk("TextLabel", { Size = UDim2.new(0.65, 0, 0, 22), Position = UDim2.fromOffset(10, 4), BackgroundTransparency = 1, Text = "#"..i.." "..egg.name, TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, row)
            mk("TextLabel", { Size = UDim2.new(0.65, 0, 0, 18), Position = UDim2.fromOffset(10, 26), BackgroundTransparency = 1, Text = "Score: "..egg.score.." | "..egg.dist.."m", TextColor3 = Theme.Accent2, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left }, row)
            local b = mk("TextButton", { Size = UDim2.fromOffset(70, 30), Position = UDim2.new(1, -80, 0.5, -15), BackgroundColor3 = Theme.Success, Text = "Steal", TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 12 }, row)
            mk("UICorner", {CornerRadius = UDim.new(0, 6)}, b)
            b.MouseButton1Click:Connect(function()
                b.Text = "..."; b.BackgroundColor3 = Theme.Off
                StealEgg(egg, function()
                    b.Text = "✓"; b.BackgroundColor3 = Theme.Success
                    task.wait(1)
                    if b.Parent then b.Text = "Steal"; b.BackgroundColor3 = Theme.Success end
                end)
            end)
        end
        EggTab.CanvasSize = UDim2.new(0, 0, 0, #eggs * 54)
    end
end)

-- نظام السحب المحسن للزر
local function MakeDrag(frame, handle)
    local dragging, dragStart, startPos, moved
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = i.Position; startPos = frame.Position; moved = false
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

MakeDrag(main, topBar)
local isBtnMoved = MakeDrag(openBtn, openBtn)

local isOpen = false
openBtn.MouseButton1Click:Connect(function()
    if isBtnMoved() then return end -- إذا كان يسحب، ما يفتح
    isOpen = not isOpen
    main.Visible = isOpen
end)

closeBtn.MouseButton1Click:Connect(function()
    isOpen = false
    main.Visible = false
end)

Log("Derek Hub v25.1 loaded.", "SYSTEM")
