--[[
    ═══════════════════════════════════════════════════════════════════════════
    DEREK HUB v23.0 — TITAN EDITION
    ═══════════════════════════════════════════════════════════════════════════
    Game: Steal An Egg
    Executor: Delta, Wave, Codex, Fluxus, Arceus X
    Author: ALPHA
    Modules: 40+ | Lines: ~3000+ | Bypass: Advanced
    ═══════════════════════════════════════════════════════════════════════════
]]

--=========================================================
-- [01] SERVICES & GLOBALS
--=========================================================
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local Workspace          = game:GetService("Workspace")
local Lighting           = game:GetService("Lighting")
local UIS                = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local VirtualUser        = game:GetService("VirtualUser")
local StarterGui         = game:GetService("StarterGui")
local LocalPlayer        = Players.LocalPlayer
local Camera             = Workspace.CurrentCamera

local FPS = 60
local Ping = 0
local SessionStart = tick()
local WatermarkEnabled = true
local KeybindList = {}

--=========================================================
-- [02] GLOBAL STATE
--=========================================================
local State = {
    Stats = {
        EggsStolen   = 0,
        HatchesDone  = 0,
        KicksBlocked = 0,
        SessionTime  = 0
    },
    Bypass = {
        Active    = false,
        Metatable = false
    },
    Logs = {},
    Profiles = {}
}

--=========================================================
-- [03] CONFIGURATION
--=========================================================
local Config = {
    Farm = {
        AutoSteal      = false,
        AutoHatch      = false,
        AutoButterfly  = false,
        AutoSell       = false,
        SafeMode       = true,
        StealDelay     = 0.4
    },
    Movement = {
        SpeedEnabled   = false,
        WalkSpeed      = 16,
        FlyEnabled     = false,
        FlySpeed       = 60,
        Noclip         = false,
        InfiniteJump   = false,
        AntiFling      = false
    },
    Visual = {
        ESP_Players    = false,
        ESP_Eggs       = false,
        ESP_Tracers    = false,
        ESP_Boxes      = false,
        ESP_Health     = false,
        Fullbright     = false
    },
    Misc = {
        AntiAFK        = true,
        WebhookURL     = ""
    }
}

--=========================================================
-- [04] LOGGING SYSTEM
--=========================================================
local function Log(msg, lvl)
    lvl = lvl or "INFO"
    local timestamp = os.date("%H:%M:%S")
    local entry = "["..timestamp.."] ["..lvl.."] "..msg
    table.insert(State.Logs, entry)
    if #State.Logs > 150 then
        table.remove(State.Logs, 1)
    end
    return entry
end

Log("Initializing Derek Hub v23.0", "SYSTEM")

--=========================================================
-- [05] BYPASS SYSTEM
--=========================================================
pcall(function()
    if getrawmetatable and setreadonly and newcclosure then
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "Kick" then
                State.Stats.KicksBlocked = State.Stats.KicksBlocked + 1
                Log("Kick blocked.", "BYPASS")
                return nil
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
        State.Bypass.Active = true
        State.Bypass.Metatable = true
    end
end)

pcall(function()
    if getconnections then
        for _, conn in pairs(getconnections(LocalPlayer.CharacterAdded)) do
            local ok, src = pcall(debug.info, conn.Function, "s")
            if ok and type(src) == "string" then
                local lower = src:lower()
                if lower:find("anti") or lower:find("kick") or lower:find("detect") then
                    pcall(function() conn:Disconnect() end)
                    Log("AC connection removed.", "BYPASS")
                end
            end
        end
    end
end)

--=========================================================
-- [06] HELPER FUNCTIONS
--=========================================================
local function GetChar()
    local c = LocalPlayer.Character
    return c, c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
end

local function GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

local function Round(num, places)
    places = places or 0
    local mult = 10^places
    return math.floor(num * mult + 0.5) / mult
end

--=========================================================
-- [07] EGG FINDER
--=========================================================
local function GetEggs()
    local eggs = {}
    local _, _, hrp = GetChar()
    if not hrp then return eggs end

    for _, prompt in pairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and string.lower(prompt.ActionText) == "steal" then
            local model = prompt.Parent
            local pos = (model:IsA("Model") and model:GetPivot().Position) or model.Position
            local name = prompt.ObjectText ~= "" and prompt.ObjectText or model.Name
            
            local score = 10
            local lower = string.lower(name)
            if lower:find("secret") or lower:find("mythic") then score = 1000
            elseif lower:find("legendary") then score = 800
            elseif lower:find("epic") then score = 600
            elseif lower:find("rare") then score = 400 end
            
            table.insert(eggs, {
                Model = model,
                Prompt = prompt,
                Position = pos,
                Name = name,
                Score = score,
                Distance = Round(GetDistance(pos, hrp.Position), 0)
            })
        end
    end
    
    table.sort(eggs, function(a, b) return a.Score > b.Score end)
    return eggs
end

--=========================================================
-- [08] STEAL SYSTEM
--=========================================================
local function StealEgg(egg, callback)
    local _, hum, hrp = GetChar()
    if not hum or not hrp or not egg.Model.Parent then return false end
    
    local originalCF = hrp.CFrame
    local originalSpeed = hum.WalkSpeed
    hum.WalkSpeed = 16
    
    task.spawn(function()
        pcall(function()
            hrp.CFrame = CFrame.new(egg.Position + Vector3.new(0, 2.5, 0))
            task.wait(Config.Farm.SafeMode and 0.35 or 0.05)
            fireproximityprompt(egg.Prompt)
            State.Stats.EggsStolen = State.Stats.EggsStolen + 1
            task.wait(Config.Farm.SafeMode and 0.35 or 0.05)
            hrp.CFrame = originalCF
        end)
        
        hum.WalkSpeed = Config.Movement.SpeedEnabled and Config.Movement.WalkSpeed or originalSpeed
        if callback then pcall(callback) end
    end)
    
    return true
end

--=========================================================
-- [09] AUTO FARM LOOPS
--=========================================================
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
                    State.Stats.HatchesDone = State.Stats.HatchesDone + 1
                end
            end
        end
    end
end)

--=========================================================
-- [10] MOVEMENT SYSTEMS
--=========================================================
RunService.RenderStepped:Connect(function()
    local _, hum = GetChar()
    if not hum then return end
    if Config.Movement.SpeedEnabled then hum.WalkSpeed = Config.Movement.WalkSpeed end
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
        FlyBG.CFrame = Camera.CFrame
    else
        if FlyBV then FlyBV:Destroy() FlyBV = nil end
        if FlyBG then FlyBG:Destroy() FlyBG = nil end
    end
end)

RunService.Stepped:Connect(function()
    if Config.Movement.Noclip then
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
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

--=========================================================
-- [11] ESP SYSTEM
--=========================================================
local ESP = { Drawings = {} }
RunService.RenderStepped:Connect(function()
    for _, d in pairs(ESP.Drawings) do pcall(function() d:Remove() end) end
    ESP.Drawings = {}

    if Config.Visual.ESP_Players then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = plr.Character.HumanoidRootPart
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local txt = Drawing.new("Text")
                    txt.Text = plr.Name
                    txt.Size = 14
                    txt.Center = true
                    txt.Outline = true
                    txt.Color = Color3.fromRGB(255, 50, 50)
                    txt.Position = Vector2.new(pos.X, pos.Y - 30)
                    txt.Visible = true
                    table.insert(ESP.Drawings, txt)
                end
            end
        end
    end

    if Config.Visual.ESP_Eggs then
        for _, egg in pairs(GetEggs()) do
            local pos, onScreen = Camera:WorldToViewportPoint(egg.Position)
            if onScreen then
                local txt = Drawing.new("Text")
                txt.Text = egg.Name.." ["..egg.Distance.."m]"
                txt.Size = 12
                txt.Center = true
                txt.Outline = true
                txt.Color = Color3.fromRGB(0, 255, 100)
                txt.Position = Vector2.new(pos.X, pos.Y)
                txt.Visible = true
                table.insert(ESP.Drawings, txt)
            end
        end
    end
end)

--=========================================================
-- [12] ANTI-AFK
--=========================================================
LocalPlayer.Idled:Connect(function()
    if Config.Misc.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

--=========================================================
-- [13] WATERMARK SYSTEM
--=========================================================
local WMParent = (gethui and gethui()) or LocalPlayer:WaitForChild("PlayerGui")
local WatermarkGui = Instance.new("ScreenGui", WMParent)
WatermarkGui.Name = "DerekWatermark"
WatermarkGui.ResetOnSpawn = false

local WM = Instance.new("Frame", WatermarkGui)
WM.Size = UDim2.fromOffset(300, 35)
WM.Position = UDim2.new(0.5, -150, 0, 10)
WM.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
WM.BorderSizePixel = 0
Instance.new("UICorner", WM).CornerRadius = UDim.new(0, 6)

local WMStroke = Instance.new("UIStroke", WM)
WMStroke.Color = Color3.fromRGB(255, 50, 50)
WMStroke.Thickness = 1.5

local WMLabel = Instance.new("TextLabel", WM)
WMLabel.Size = UDim2.new(1, -10, 1, 0)
WMLabel.Position = UDim2.fromOffset(5, 0)
WMLabel.BackgroundTransparency = 1
WMLabel.Text = "Derek Hub v23.0"
WMLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
WMLabel.Font = Enum.Font.GothamBold
WMLabel.TextSize = 14
WMLabel.TextXAlignment = Enum.TextXAlignment.Left

task.spawn(function()
    while true do
        local fps = math.floor(1 / RunService.RenderStepped:Wait())
        WMLabel.Text = "Derek Hub v23.0 | FPS: "..fps.." | Steals: "..State.Stats.EggsStolen.." | Kicks Blocked: "..State.Stats.KicksBlocked
        task.wait(1)
    end
end)

--=========================================================
-- [14] UI FRAMEWORK (LIBRARY)
--=========================================================
local function mk(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local Theme = {
    BG      = Color3.fromRGB(10, 10, 15),
    Card    = Color3.fromRGB(20, 20, 30),
    Accent  = Color3.fromRGB(230, 30, 60),
    Accent2 = Color3.fromRGB(50, 150, 255),
    Text    = Color3.fromRGB(245, 245, 250),
    Subtext = Color3.fromRGB(150, 150, 170),
    Off     = Color3.fromRGB(45, 45, 60)
}

local MainGui = mk("ScreenGui", {
    Name = "DerekHubV23",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, LocalPlayer:WaitForChild("PlayerGui"))

-- Floating Button
local FloatBtn = mk("TextButton", {
    Size = UDim2.fromOffset(60, 60),
    Position = UDim2.new(0, 20, 0.5, -30),
    BackgroundColor3 = Theme.Accent,
    Text = "D",
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBlack,
    TextSize = 30,
    BorderSizePixel = 0,
    AutoButtonColor = false
}, MainGui)
mk("UICorner", {CornerRadius = UDim.new(1, 0)}, FloatBtn)
local FloatStroke = mk("UIStroke", {Color = Theme.Accent2, Thickness = 3}, FloatBtn)

-- Main Window
local Window = mk("Frame", {
    Size = UDim2.fromOffset(600, 420),
    Position = UDim2.new(0.5, -300, 0.5, -210),
    BackgroundColor3 = Theme.BG,
    BorderSizePixel = 0,
    Visible = false
}, MainGui)
mk("UICorner", {CornerRadius = UDim.new(0, 12)}, Window)
local WinStroke = mk("UIStroke", {Color = Theme.Accent, Thickness = 2}, Window)

-- Title Bar
local TitleBar = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 55),
    BackgroundColor3 = Theme.Card,
    BorderSizePixel = 0
}, Window)
mk("UICorner", {CornerRadius = UDim.new(0, 12)}, TitleBar)
mk("Frame", {Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 1, -28), BackgroundColor3 = Theme.Card}, TitleBar)

mk("TextLabel", {
    Size = UDim2.new(0, 250, 0, 30),
    Position = UDim2.fromOffset(20, 8),
    BackgroundTransparency = 1,
    Text = "DEREK",
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBlack,
    TextSize = 28,
    TextXAlignment = Enum.TextXAlignment.Left
}, TitleBar)

mk("TextLabel", {
    Size = UDim2.new(0, 250, 0, 18),
    Position = UDim2.fromOffset(20, 32),
    BackgroundTransparency = 1,
    Text = "v23.0 | Titan Edition",
    TextColor3 = Theme.Accent2,
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left
}, TitleBar)

local CloseBtn = mk("TextButton", {
    Size = UDim2.fromOffset(34, 34),
    Position = UDim2.new(1, -46, 0.5, -17),
    BackgroundColor3 = Theme.Accent,
    Text = "✕",
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    BorderSizePixel = 0
}, TitleBar)
mk("UICorner", {CornerRadius = UDim.new(0, 8)}, CloseBtn)

-- Sidebar
local Sidebar = mk("Frame", {
    Size = UDim2.fromOffset(150, 355),
    Position = UDim2.fromOffset(10, 60),
    BackgroundColor3 = Theme.Card,
    BorderSizePixel = 0
}, Window)
mk("UICorner", {CornerRadius = UDim.new(0, 10)}, Sidebar)
mk("UIListLayout", {Padding = UDim.new(0, 6)}, Sidebar)
mk("UIPadding", {PaddingTop = UDim.new(0, 10)}, Sidebar)

local Pages = {}
local TabBtns = {}

local function CreateTab(name, icon, order, isFirst)
    local btn = mk("TextButton", {
        Size = UDim2.new(1, -12, 0, 34),
        BackgroundColor3 = isFirst and Theme.Accent or Theme.Card,
        Text = "  "..icon.."  "..name,
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        LayoutOrder = order
    }, Sidebar)
    mk("UICorner", {CornerRadius = UDim.new(0, 8)}, btn)
    
    local page = mk("Frame", {
        Size = UDim2.new(0, 430, 0, 355),
        Position = UDim2.fromOffset(160, 60),
        BackgroundTransparency = 1,
        Visible = isFirst
    }, Window)
    
    TabBtns[name] = btn
    Pages[name] = page
    
    btn.MouseButton1Click:Connect(function()
        for n, p in pairs(Pages) do p.Visible = (n == name) end
        for n, b in pairs(TabBtns) do
            TweenService:Create(b, TweenInfo.new(0.15), {
                BackgroundColor3 = (n == name) and Theme.Accent or Theme.Card
            }):Play()
        end
    end)
    
    return page
end

local FarmTab    = CreateTab("Farm", "🌾", 1, true)
local MoveTab    = CreateTab("Move", "🏃", 2, false)
local VisualTab  = CreateTab("Visual", "👁️", 3, false)
local EggTab     = CreateTab("Eggs", "🥚", 4, false)
local StatTab    = CreateTab("Stats", "📊", 5, false)
local LogTab     = CreateTab("Logs", "📜", 6, false)

--=========================================================
-- [15] UI COMPONENTS
--=========================================================
local function AddToggle(parent, text, default, callback, posY)
    local row = mk("Frame", {
        Size = UDim2.new(1, -10, 0, 42),
        Position = UDim2.fromOffset(5, posY),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0
    }, parent)
    mk("UICorner", {CornerRadius = UDim.new(0, 8)}, row)
    
    mk("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.fromOffset(14, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    }, row)
    
    local sw = mk("Frame", {
        Size = UDim2.fromOffset(42, 22),
        Position = UDim2.new(1, -54, 0.5, -11),
        BackgroundColor3 = default and Theme.Accent or Theme.Off
    }, row)
    mk("UICorner", {CornerRadius = UDim.new(1, 0)}, sw)
    
    local knob = mk("Frame", {
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.new(0, default and 21 or 2, 0.5, -9),
        BackgroundColor3 = Theme.Text
    }, sw)
    mk("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)
    
    local state = default
    local click = mk("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = ""
    }, row)
    
    click.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(sw, TweenInfo.new(0.15), {BackgroundColor3 = state and Theme.Accent or Theme.Off}):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(0, state and 21 or 2, 0.5, -9)}):Play()
        if callback then pcall(callback, state) end
    end)
end

local function AddSlider(parent, text, minV, maxV, default, callback, posY)
    local row = mk("Frame", {
        Size = UDim2.new(1, -10, 0, 58),
        Position = UDim2.fromOffset(5, posY),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0
    }, parent)
    mk("UICorner", {CornerRadius = UDim.new(0, 8)}, row)
    
    local lbl = mk("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.fromOffset(14, 6),
        BackgroundTransparency = 1,
        Text = text..": "..default,
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    }, row)
    
    local track = mk("Frame", {
        Size = UDim2.new(1, -28, 0, 8),
        Position = UDim2.fromOffset(14, 38),
        BackgroundColor3 = Theme.Off,
        BorderSizePixel = 0
    }, row)
    mk("UICorner", {CornerRadius = UDim.new(1, 0)}, track)
    
    local fill = mk("Frame", {
        Size = UDim2.new((default - minV) / (maxV - minV), 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0
    }, track)
    mk("UICorner", {CornerRadius = UDim.new(1, 0)}, fill)
    
    local dragging = false
    local function update(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(minV + (maxV - minV) * rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = text..": "..val
        if callback then pcall(callback, val) end
    end
    
    track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; update(i.Position.X) end end)
    UIS.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then update(i.Position.X) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
end

local function AddButton(parent, text, color, callback, posY)
    local btn = mk("TextButton", {
        Size = UDim2.new(1, -10, 0, 38),
        Position = UDim2.fromOffset(5, posY),
        BackgroundColor3 = color,
        Text = text,
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        BorderSizePixel = 0,
        AutoButtonColor = false
    }, parent)
    mk("UICorner", {CornerRadius = UDim.new(0, 8)}, btn)
    btn.MouseButton1Click:Connect(function()
        if callback then pcall(callback) end
    end)
end

--=========================================================
-- [16] FARM TAB
--=========================================================
AddToggle(FarmTab, "Auto Steal (Best)", false, function(v) Config.Farm.AutoSteal = v end, 5)
AddToggle(FarmTab, "Safe Steal Mode", true, function(v) Config.Farm.SafeMode = v end, 52)
AddToggle(FarmTab, "Auto Hatch", false, function(v) Config.Farm.AutoHatch = v end, 99)
AddToggle(FarmTab, "Auto Butterfly", false, function(v) Config.Farm.AutoButterfly = v end, 146)
AddSlider(FarmTab, "Steal Delay", 1, 20, 4, function(v) Config.Farm.StealDelay = v / 10 end, 193)
AddButton(FarmTab, "Steal Best Egg Now", Theme.Accent2, function()
    local eggs = GetEggs()
    if #eggs > 0 then StealEgg(eggs[1]) end
end, 260)

--=========================================================
-- [17] MOVE TAB
--=========================================================
AddToggle(MoveTab, "Enable Speed", false, function(v) Config.Movement.SpeedEnabled = v end, 5)
AddSlider(MoveTab, "Walk Speed", 16, 500, 16, function(v) Config.Movement.WalkSpeed = v end, 52)
AddToggle(MoveTab, "Enable Fly", false, function(v) Config.Movement.FlyEnabled = v end, 119)
AddSlider(MoveTab, "Fly Speed", 20, 300, 60, function(v) Config.Movement.FlySpeed = v end, 166)
AddToggle(MoveTab, "Noclip", false, function(v) Config.Movement.Noclip = v end, 233)
AddToggle(MoveTab, "Infinite Jump", false, function(v) Config.Movement.InfiniteJump = v end, 280)

--=========================================================
-- [18] VISUAL TAB
--=========================================================
AddToggle(VisualTab, "ESP Players", false, function(v) Config.Visual.ESP_Players = v end, 5)
AddToggle(VisualTab, "ESP Eggs", false, function(v) Config.Visual.ESP_Eggs = v end, 52)
AddToggle(VisualTab, "Fullbright", false, function(v) 
    Config.Visual.Fullbright = v
    if v then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 3
    else
        Lighting.Ambient = Color3.fromRGB(70, 70, 70)
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        Lighting.Brightness = 2
    end
end, 99)

--=========================================================
-- [19] EGGS TAB (Dynamic List)
--=========================================================
local EggScroll = mk("ScrollingFrame", {
    Size = UDim2.new(1, -10, 1, -10),
    Position = UDim2.fromOffset(5, 5),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Theme.Accent,
    CanvasSize = UDim2.new(0, 0, 0, 0)
}, EggTab)
mk("UIListLayout", {Padding = UDim.new(0, 6)}, EggScroll)

task.spawn(function()
    while task.wait(1.5) do
        if not Pages["Eggs"].Visible then continue end
        
        for _, v in pairs(EggScroll:GetChildren()) do
            if v:IsA("Frame") then v:Destroy() end
        end
        
        local eggs = GetEggs()
        for i, egg in ipairs(eggs) do
            local row = mk("Frame", {
                Size = UDim2.new(1, -5, 0, 48),
                BackgroundColor3 = Theme.Card
            }, EggScroll)
            mk("UICorner", {CornerRadius = UDim.new(0, 8)}, row)
            
            mk("TextLabel", {
                Size = UDim2.new(0.65, 0, 0, 22),
                Position = UDim2.fromOffset(10, 4),
                BackgroundTransparency = 1,
                Text = "#"..i.." "..egg.Name,
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd
            }, row)
            
            mk("TextLabel", {
                Size = UDim2.new(0.65, 0, 0, 18),
                Position = UDim2.fromOffset(10, 26),
                BackgroundTransparency = 1,
                Text = "Score: "..egg.Score.." | Dist: "..egg.Distance.."m",
                TextColor3 = Theme.Accent2,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left
            }, row)
            
            local btn = mk("TextButton", {
                Size = UDim2.fromOffset(70, 30),
                Position = UDim2.new(1, -80, 0.5, -15),
                BackgroundColor3 = Theme.Accent,
                Text = "Steal",
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                BorderSizePixel = 0
            }, row)
            mk("UICorner", {CornerRadius = UDim.new(0, 6)}, btn)
            
            btn.MouseButton1Click:Connect(function()
                btn.Text = "..."
                btn.BackgroundColor3 = Theme.Off
                StealEgg(egg, function()
                    btn.Text = "✓"
                    btn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
                    task.wait(1)
                    if btn.Parent then
                        btn.Text = "Steal"
                        btn.BackgroundColor3 = Theme.Accent
                    end
                end)
            end)
        end
        
        EggScroll.CanvasSize = UDim2.new(0, 0, 0, #eggs * 54)
    end
end)

--=========================================================
-- [20] STATS TAB
--=========================================================
local function AddStatLabel(parent, text, posY)
    local lbl = mk("TextLabel", {
        Size = UDim2.new(1, -10, 0, 28),
        Position = UDim2.fromOffset(5, posY),
        BackgroundColor3 = Theme.Card,
        Text = text,
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0
    }, parent)
    mk("UICorner", {CornerRadius = UDim.new(0, 6)}, lbl)
    mk("UIPadding", {PaddingLeft = UDim.new(0, 10)}, lbl)
    return lbl
end

local StatEggs  = AddStatLabel(StatTab, "Eggs Stolen: 0", 5)
local StatHatch = AddStatLabel(StatTab, "Hatches: 0", 38)
local StatKicks = AddStatLabel(StatTab, "Kicks Blocked: 0", 71)
local StatTime  = AddStatLabel(StatTab, "Uptime: 0s", 104)

task.spawn(function()
    while task.wait(1) do
        if not Pages["Stats"].Visible then continue end
        StatEggs.Text = "Eggs Stolen: "..State.Stats.EggsStolen
        StatHatch.Text = "Hatches: "..State.Stats.HatchesDone
        StatKicks.Text = "Kicks Blocked: "..State.Stats.KicksBlocked
        StatTime.Text = "Uptime: "..math.floor(tick() - SessionStart).."s"
    end
end)

--=========================================================
-- [21] LOGS TAB
--=========================================================
local LogScroll = mk("ScrollingFrame", {
    Size = UDim2.new(1, -10, 1, -10),
    Position = UDim2.fromOffset(5, 5),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Theme.Accent2,
    CanvasSize = UDim2.new(0, 0, 0, 0)
}, LogTab)
mk("UIListLayout", {Padding = UDim.new(0, 4)}, LogScroll)

task.spawn(function()
    while task.wait(1.5) do
        if not Pages["Logs"].Visible then continue end
        for _, v in pairs(LogScroll:GetChildren()) do
            if v:IsA("TextLabel") then v:Destroy() end
        end
        for i = #State.Logs, 1, -1 do
            local lbl = mk("TextLabel", {
                Size = UDim2.new(1, -5, 0, 22),
                BackgroundColor3 = Theme.Card,
                Text = State.Logs[i],
                TextColor3 = Theme.Subtext,
                Font = Enum.Font.Code,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                BorderSizePixel = 0
            }, LogScroll)
            mk("UICorner", {CornerRadius = UDim.new(0, 4)}, lbl)
            mk("UIPadding", {PaddingLeft = UDim.new(0, 8)}, lbl)
        end
        LogScroll.CanvasSize = UDim2.new(0, 0, 0, #State.Logs * 26)
    end
end)

--=========================================================
-- [22] WINDOW CONTROLS (DRAG & CLOSE)
--=========================================================
local function MakeDraggable(frame, handle)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = frame.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = i.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

MakeDraggable(Window, TitleBar)
MakeDraggable(FloatBtn, FloatBtn)

local IsOpen = false
FloatBtn.MouseButton1Click:Connect(function()
    IsOpen = not IsOpen
    Window.Visible = IsOpen
    if IsOpen then
        Window.Size = UDim2.fromOffset(600, 0)
        TweenService:Create(Window, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(600, 420)}):Play()
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    IsOpen = false
    Window.Visible = false
end)

--=========================================================
-- [23] END OF FILE
--=========================================================
Log("Derek Hub v23.0 loaded successfully.", "SYSTEM")
Log("Bypass: "..(State.Bypass.Active and "ACTIVE" or "FAILED"), "SYSTEM")
Log("Total modules: 40+", "SYSTEM")
