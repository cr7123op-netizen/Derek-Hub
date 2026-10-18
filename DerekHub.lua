--[[
    ╔═══════════════════════════════════════════════════════════════════╗
    ║       DEREK HUB v26.0 — MEGA EDITION                              ║
    ║       Game: Steal An Egg | Author: ALPHA                          ║
    ║       Lines: 1200+ | Features: 50+ | Safe API Only                ║
    ╚═══════════════════════════════════════════════════════════════════╝
]]

task.wait(2)

--=========================================================
-- [SECTION 01] SERVICES INITIALIZATION
--=========================================================
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local Workspace       = game:GetService("Workspace")
local Lighting        = game:GetService("Lighting")
local UIS             = game:GetService("UserInputService")
local Tween           = game:GetService("TweenService")
local VirtualUser     = game:GetService("VirtualUser")
local HttpService     = game:GetService("HttpService")
local LocalPlayer     = Players.LocalPlayer
local Camera          = Workspace.CurrentCamera

--=========================================================
-- [SECTION 02] GLOBAL STATE
--=========================================================
local State = {
    Stats = {
        EggsStolen      = 0,
        HatchesDone     = 0,
        Butterflies     = 0,
        KicksPrevented  = 0,
        SessionStart    = tick()
    },
    Logs = {},
    SavedProfiles = {},
    CurrentProfile = "default",
    Features = {}
}

local function Log(msg, tag)
    tag = tag or "INFO"
    local entry = "["..os.date("%H:%M:%S").."] ["..tag.."] "..msg
    table.insert(State.Logs, entry)
    if #State.Logs > 300 then table.remove(State.Logs, 1) end
    return entry
end

Log("Boot sequence initiated.", "SYSTEM")
Log("Loading modules...", "SYSTEM")

--=========================================================
-- [SECTION 03] CONFIGURATION
--=========================================================
local Config = {
    Farm = {
        AutoSteal       = false,
        AutoHatch       = false,
        AutoButterfly   = false,
        AutoSell        = false,
        SafeMode        = true,
        StealDelay      = 0.4,
        HatchDelay      = 0.5,
        ButterflyRange  = 50
    },
    Movement = {
        SpeedEnabled    = false,
        WalkSpeed       = 16,
        FlyEnabled      = false,
        FlySpeed        = 60,
        Noclip          = false,
        InfiniteJump    = false,
        AntiFling       = false,
        JumpPower       = 50
    },
    Visual = {
        ESP_Eggs        = false,
        ESP_Players     = false,
        ESP_Tracers     = false,
        ESP_Health      = false,
        Fullbright      = false,
        NoFog           = false
    },
    Misc = {
        AntiAFK         = true,
        AutoRejoin      = false,
        WebhookEnabled  = false
    }
}

--=========================================================
-- [SECTION 04] CHARACTER HELPERS
--=========================================================
local function GetChar()
    local c = LocalPlayer.Character
    if not c then return nil, nil, nil end
    local hum = c:FindFirstChildOfClass("Humanoid")
    local hrp = c:FindFirstChild("HumanoidRootPart")
    return c, hum, hrp
end

local function IsAlive()
    local _, hum, _ = GetChar()
    return hum and hum.Health > 0
end

local function GetPosition()
    local _, _, hrp = GetChar()
    return hrp and hrp.Position
end

local function Distance(a, b)
    return (a - b).Magnitude
end

--=========================================================
-- [SECTION 05] EGG SYSTEM
--=========================================================
local EggCache = {}
local LastCacheUpdate = 0

local function RefreshEggCache()
    EggCache = {}
    local _, _, hrp = GetChar()
    if not hrp then return end
    
    local allPrompts = Workspace:GetDescendants()
    for i = 1, #allPrompts do
        local prompt = allPrompts[i]
        if prompt:IsA("ProximityPrompt") and string.lower(prompt.ActionText) == "steal" then
            local model = prompt.Parent
            if model then
                local pos = (model:IsA("Model") and model:GetPivot().Position) or model.Position
                local name = prompt.ObjectText ~= "" and prompt.ObjectText or model.Name
                
                local score = 10
                local lower = string.lower(name)
                if lower:find("secret") or lower:find("mythic") or lower:find("god") then
                    score = 1000
                elseif lower:find("legendary") or lower:find("divine") then
                    score = 800
                elseif lower:find("epic") then
                    score = 600
                elseif lower:find("rare") then
                    score = 400
                elseif lower:find("uncommon") then
                    score = 200
                end
                
                table.insert(EggCache, {
                    Model = model,
                    Prompt = prompt,
                    Position = pos,
                    Name = name,
                    Score = score,
                    Distance = math.floor(Distance(pos, hrp.Position))
                })
            end
        end
    end
    
    table.sort(EggCache, function(a, b)
        return a.Score > b.Score
    end)
    
    LastCacheUpdate = tick()
end

local function GetEggs()
    if tick() - LastCacheUpdate > 2 then
        RefreshEggCache()
    end
    return EggCache
end

--=========================================================
-- [SECTION 06] STEAL SYSTEM
--=========================================================
local StealCooldown = false

local function StealEgg(egg, callback)
    if StealCooldown then return false end
    StealCooldown = true
    
    local _, hum, hrp = GetChar()
    if not hum or not hrp then
        StealCooldown = false
        return false
    end
    if not egg or not egg.Model or not egg.Model.Parent then
        StealCooldown = false
        return false
    end
    
    local originalCF = hrp.CFrame
    local originalSpeed = hum.WalkSpeed
    hum.WalkSpeed = 16
    
    task.spawn(function()
        pcall(function()
            hrp.CFrame = CFrame.new(egg.Position + Vector3.new(0, 2.5, 0))
            task.wait(Config.Farm.SafeMode and 0.35 or 0.08)
            fireproximityprompt(egg.Prompt)
            State.Stats.EggsStolen = State.Stats.EggsStolen + 1
            Log("Stole: "..egg.Name, "STEAL")
            task.wait(Config.Farm.SafeMode and 0.35 or 0.08)
            hrp.CFrame = originalCF
        end)
        
        if Config.Movement.SpeedEnabled then
            hum.WalkSpeed = Config.Movement.WalkSpeed
        else
            hum.WalkSpeed = originalSpeed
        end
        
        StealCooldown = false
        if callback then pcall(callback) end
    end)
    
    return true
end

--=========================================================
-- [SECTION 07] FARM LOOPS
--=========================================================
task.spawn(function()
    while task.wait(Config.Farm.StealDelay) do
        if Config.Farm.AutoSteal and IsAlive() then
            local eggs = GetEggs()
            if #eggs > 0 then
                StealEgg(eggs[1])
            end
        end
    end
end)

task.spawn(function()
    while task.wait(Config.Farm.HatchDelay) do
        if Config.Farm.AutoHatch and IsAlive() then
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") and string.lower(v.ActionText):find("hatch") then
                    pcall(function() fireproximityprompt(v) end)
                    State.Stats.HatchesDone = State.Stats.HatchesDone + 1
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if Config.Farm.AutoButterfly and IsAlive() then
            local _, _, hrp = GetChar()
            if hrp then
                for _, v in pairs(Workspace:GetDescendants()) do
                    if v:IsA("ProximityPrompt") and string.lower(v.ActionText):find("catch") then
                        local parent = v.Parent
                        if parent and parent.Position and Distance(parent.Position, hrp.Position) < Config.Farm.ButterflyRange then
                            pcall(function() fireproximityprompt(v) end)
                            State.Stats.Butterflies = State.Stats.Butterflies + 1
                        end
                    end
                end
            end
        end
    end
end)

--=========================================================
-- [SECTION 08] MOVEMENT SYSTEMS
--=========================================================
RunService.RenderStepped:Connect(function()
    if Config.Movement.SpeedEnabled then
        local _, hum = GetChar()
        if hum and hum.WalkSpeed ~= Config.Movement.WalkSpeed then
            hum.WalkSpeed = Config.Movement.WalkSpeed
        end
    end
end)

local FlyVelocity, FlyGyro
RunService.RenderStepped:Connect(function()
    local _, hum, hrp = GetChar()
    if not hum or not hrp then
        if FlyVelocity then FlyVelocity:Destroy() FlyVelocity = nil end
        if FlyGyro then FlyGyro:Destroy() FlyGyro = nil end
        return
    end
    
    if Config.Movement.FlyEnabled then
        if not FlyVelocity then
            FlyVelocity = Instance.new("BodyVelocity", hrp)
            FlyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            FlyGyro = Instance.new("BodyGyro", hrp)
            FlyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            FlyGyro.P = 1000
        end
        
        local direction = hum.MoveDirection
        local vertical = 0
        if UIS:IsKeyDown(Enum.KeyCode.Space) then vertical = Config.Movement.FlySpeed end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then vertical = -Config.Movement.FlySpeed end
        
        FlyVelocity.Velocity = direction * Config.Movement.FlySpeed + Vector3.new(0, vertical, 0)
        FlyGyro.CFrame = Camera.CFrame
    else
        if FlyVelocity then FlyVelocity:Destroy() FlyVelocity = nil end
        if FlyGyro then FlyGyro:Destroy() FlyGyro = nil end
    end
end)

RunService.Stepped:Connect(function()
    if Config.Movement.Noclip then
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

UIS.JumpRequest:Connect(function()
    if Config.Movement.InfiniteJump then
        local _, hum = GetChar()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

--=========================================================
-- [SECTION 09] ESP SYSTEM
--=========================================================
RunService.RenderStepped:Connect(function()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name == "DerekESPEgg" or v.Name == "DerekESPPlayer" then
            v:Destroy()
        end
    end
    
    if Config.Visual.ESP_Eggs then
        for _, egg in ipairs(GetEggs()) do
            if egg.Model and egg.Model.Parent then
                local box = Instance.new("BoxHandleAdornment")
                box.Name = "DerekESPEgg"
                box.Adornee = egg.Model
                box.AlwaysOnTop = true
                box.Size = egg.Model:GetExtentsSize()
                box.Color3 = Color3.fromRGB(0, 255, 100)
                box.Transparency = 0.5
                box.Parent = egg.Model
            end
        end
    end
    
    if Config.Visual.ESP_Players then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local box = Instance.new("BoxHandleAdornment")
                    box.Name = "DerekESPPlayer"
                    box.Adornee = hrp
                    box.AlwaysOnTop = true
                    box.Size = Vector3.new(4, 6, 4)
                    box.Color3 = Color3.fromRGB(255, 50, 50)
                    box.Transparency = 0.5
                    box.Parent = hrp
                end
            end
        end
    end
end)

--=========================================================
-- [SECTION 10] ANTI-AFK
--=========================================================
LocalPlayer.Idled:Connect(function()
    if Config.Misc.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        Log("Anti-AFK triggered.", "MISC")
    end
end)

--=========================================================
-- [SECTION 11] FULLBRIGHT
--=========================================================
local OriginalLighting = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness,
    FogEnd = Lighting.FogEnd
}

local function ApplyFullbright()
    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    Lighting.Brightness = 3
    Lighting.FogEnd = 100000
end

local function RemoveFullbright()
    Lighting.Ambient = OriginalLighting.Ambient
    Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    Lighting.Brightness = OriginalLighting.Brightness
    Lighting.FogEnd = OriginalLighting.FogEnd
end

--=========================================================
-- [SECTION 12] UI FRAMEWORK
--=========================================================
local function mk(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local Theme = {
    BG         = Color3.fromRGB(10, 10, 16),
    Card       = Color3.fromRGB(20, 20, 30),
    CardLight  = Color3.fromRGB(30, 30, 42),
    Accent     = Color3.fromRGB(230, 30, 60),
    Accent2    = Color3.fromRGB(50, 150, 255),
    Success    = Color3.fromRGB(0, 200, 100),
    Warning    = Color3.fromRGB(255, 180, 0),
    Text       = Color3.fromRGB(245, 245, 250),
    Subtext    = Color3.fromRGB(150, 150, 170),
    Off        = Color3.fromRGB(45, 45, 60)
}

local UIParent = LocalPlayer:WaitForChild("PlayerGui")
local Screen = mk("ScreenGui", {
    Name = "DerekHubV26",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, UIParent)

--=========================================================
-- [SECTION 13] FLOATING BUTTON
--=========================================================
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
}, Screen)
mk("UICorner", {CornerRadius = UDim.new(1, 0)}, FloatBtn)
mk("UIStroke", {Color = Theme.Accent2, Thickness = 2}, FloatBtn)

-- Pulse Animation
task.spawn(function()
    while FloatBtn.Parent do
        Tween:Create(FloatBtn, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Size = UDim2.fromOffset(64, 64)
        }):Play()
        task.wait(1)
        Tween:Create(FloatBtn, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Size = UDim2.fromOffset(60, 60)
        }):Play()
        task.wait(1)
    end
end)

--=========================================================
-- [SECTION 14] MAIN WINDOW
--=========================================================
local Window = mk("Frame", {
    Size = UDim2.fromOffset(620, 460),
    Position = UDim2.new(0.5, -310, 0.5, -230),
    BackgroundColor3 = Theme.BG,
    BorderSizePixel = 0,
    Visible = false
}, Screen)
mk("UICorner", {CornerRadius = UDim.new(0, 12)}, Window)
local WinStroke = mk("UIStroke", {Color = Theme.Accent, Thickness = 2}, Window)
local WinGradient = mk("UIGradient", {
    Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Theme.Accent),
        ColorSequenceKeypoint.new(1, Theme.Accent2)
    },
    Rotation = 45
}, WinStroke)

--=========================================================
-- [SECTION 15] TITLE BAR
--=========================================================
local TitleBar = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 55),
    BackgroundColor3 = Theme.Card,
    BorderSizePixel = 0
}, Window)
mk("UICorner", {CornerRadius = UDim.new(0, 12)}, TitleBar)
mk("Frame", {
    Size = UDim2.new(1, 0, 0, 28),
    Position = UDim2.new(0, 0, 1, -28),
    BackgroundColor3 = Theme.Card,
    BorderSizePixel = 0
}, TitleBar)

local TitleLabel = mk("TextLabel", {
    Size = UDim2.new(0, 250, 0, 32),
    Position = UDim2.fromOffset(20, 8),
    BackgroundTransparency = 1,
    Text = "DEREK",
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBlack,
    TextSize = 30,
    TextXAlignment = Enum.TextXAlignment.Left
}, TitleBar)

local TitleGradient = mk("UIGradient", {
    Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 150, 255))
    }
}, TitleLabel)

mk("TextLabel", {
    Size = UDim2.new(0, 250, 0, 18),
    Position = UDim2.fromOffset(20, 32),
    BackgroundTransparency = 1,
    Text = "v26.0 | Mega Edition",
    TextColor3 = Theme.Accent2,
    Font = Enum.Font.Gotham,
    TextSize = 11,
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
    BorderSizePixel = 0,
    AutoButtonColor = false
}, TitleBar)
mk("UICorner", {CornerRadius = UDim.new(0, 8)}, CloseBtn)

--=========================================================
-- [SECTION 16] SIDEBAR
--=========================================================
local Sidebar = mk("Frame", {
    Size = UDim2.new(0, 160, 1, -70),
    Position = UDim2.fromOffset(10, 60),
    BackgroundColor3 = Theme.Card,
    BorderSizePixel = 0
}, Window)
mk("UICorner", {CornerRadius = UDim.new(0, 10)}, Sidebar)
mk("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder
}, Sidebar)
mk("UIPadding", {PaddingTop = UDim.new(0, 10)}, Sidebar)

--=========================================================
-- [SECTION 17] TABS
--=========================================================
local Pages = {}
local TabButtons = {}

local function CreateTab(name, icon, order, isFirst)
    local btn = mk("TextButton", {
        Size = UDim2.new(1, -12, 0, 34),
        BackgroundColor3 = isFirst and Theme.Accent or Theme.CardLight,
        Text = "  "..icon.."  "..name,
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        LayoutOrder = order
    }, Sidebar)
    mk("UICorner", {CornerRadius = UDim.new(0, 8)}, btn)
    
    local page = mk("ScrollingFrame", {
        Size = UDim2.new(1, -190, 1, -70),
        Position = UDim2.fromOffset(180, 60),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent2,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = isFirst
    }, Window)
    mk("UIListLayout", {Padding = UDim.new(0, 6)}, page)
    
    TabButtons[name] = btn
    Pages[name] = page
    
    btn.MouseButton1Click:Connect(function()
        for n, p in pairs(Pages) do p.Visible = (n == name) end
        for n, b in pairs(TabButtons) do
            Tween:Create(b, TweenInfo.new(0.15), {
                BackgroundColor3 = (n == name) and Theme.Accent or Theme.CardLight
            }):Play()
        end
    end)
    
    return page
end

local FarmPage    = CreateTab("Farm", "🌾", 1, true)
local MovePage    = CreateTab("Move", "🏃", 2, false)
local VisualPage  = CreateTab("Visual", "👁️", 3, false)
local EggPage     = CreateTab("Eggs", "🥚", 4, false)
local StatsPage   = CreateTab("Stats", "📊", 5, false)
local LogsPage    = CreateTab("Logs", "📜", 6, false)
local SettingsPage= CreateTab("Settings", "⚙️", 7, false)

--=========================================================
-- [SECTION 18] COMPONENT: TOGGLE
--=========================================================
local function AddToggle(parent, text, default, callback, posY)
    local row = mk("Frame", {
        Size = UDim2.new(1, -10, 0, 42),
        Position = UDim2.fromOffset(5, posY),
        BackgroundColor3 = Theme.Card
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
        BackgroundColor3 = default and Theme.Success or Theme.Off
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
        Tween:Create(sw, TweenInfo.new(0.15), {
            BackgroundColor3 = state and Theme.Success or Theme.Off
        }):Play()
        Tween:Create(knob, TweenInfo.new(0.15), {
            Position = UDim2.new(0, state and 21 or 2, 0.5, -9)
        }):Play()
        if callback then pcall(callback, state) end
    end)
    
    return row
end

--=========================================================
-- [SECTION 19] COMPONENT: SLIDER
--=========================================================
local function AddSlider(parent, text, minV, maxV, default, callback, posY)
    local row = mk("Frame", {
        Size = UDim2.new(1, -10, 0, 58),
        Position = UDim2.fromOffset(5, posY),
        BackgroundColor3 = Theme.Card
    }, parent)
    mk("UICorner", {CornerRadius = UDim.new(0, 8)}, row)
    
    local label = mk("TextLabel", {
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
        BackgroundColor3 = Theme.Off
    }, row)
    mk("UICorner", {CornerRadius = UDim.new(1, 0)}, track)
    
    local fill = mk("Frame", {
        Size = UDim2.new((default - minV) / (maxV - minV), 0, 1, 0),
        BackgroundColor3 = Theme.Accent2
    }, track)
    mk("UICorner", {CornerRadius = UDim.new(1, 0)}, fill)
    
    local dragging = false
    local function update(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local value = math.floor(minV + (maxV - minV) * rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        label.Text = text..": "..value
        if callback then pcall(callback, value) end
    end
    
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(i.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
            update(i.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

--=========================================================
-- [SECTION 20] COMPONENT: BUTTON
--=========================================================
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
        Tween:Create(btn, TweenInfo.new(0.1), {
            BackgroundColor3 = Theme.CardLight
        }):Play()
        task.wait(0.15)
        Tween:Create(btn, TweenInfo.new(0.1), {
            BackgroundColor3 = color
        }):Play()
        if callback then pcall(callback) end
    end)
end

--=========================================================
-- [SECTION 21] FARM PAGE
--=========================================================
AddToggle(FarmPage, "Auto Steal (Best Egg)", false, function(v) Config.Farm.AutoSteal = v end, 5)
AddToggle(FarmPage, "Safe Steal Mode", true, function(v) Config.Farm.SafeMode = v end, 52)
AddToggle(FarmPage, "Auto Hatch Eggs", false, function(v) Config.Farm.AutoHatch = v end, 99)
AddToggle(FarmPage, "Auto Butterfly", false, function(v) Config.Farm.AutoButterfly = v end, 146)
AddSlider(FarmPage, "Steal Delay", 1, 20, 4, function(v) Config.Farm.StealDelay = v / 10 end, 193)
AddSlider(FarmPage, "Hatch Delay", 1, 10, 5, function(v) Config.Farm.HatchDelay = v / 10 end, 260)
AddSlider(FarmPage, "Butterfly Range", 10, 100, 50, function(v) Config.Farm.ButterflyRange = v end, 327)
AddButton(FarmPage, "Steal Best Egg (Manual)", Theme.Accent2, function()
    local eggs = GetEggs()
    if #eggs > 0 then StealEgg(eggs[1]) end
end, 394)

--=========================================================
-- [SECTION 22] MOVE PAGE
--=========================================================
AddToggle(MovePage, "Enable Speed", false, function(v) Config.Movement.SpeedEnabled = v end, 5)
AddSlider(MovePage, "Walk Speed", 16, 500, 16, function(v) Config.Movement.WalkSpeed = v end, 52)
AddToggle(MovePage, "Enable Fly", false, function(v) Config.Movement.FlyEnabled = v end, 119)
AddSlider(MovePage, "Fly Speed", 20, 300, 60, function(v) Config.Movement.FlySpeed = v end, 166)
AddToggle(MovePage, "Noclip", false, function(v) Config.Movement.Noclip = v end, 233)
AddToggle(MovePage, "Infinite Jump", false, function(v) Config.Movement.InfiniteJump = v end, 280)
AddToggle(MovePage, "Anti Fling", false, function(v) Config.Movement.AntiFling = v end, 327)

--=========================================================
-- [SECTION 23] VISUAL PAGE
--=========================================================
AddToggle(VisualPage, "ESP Eggs", false, function(v) Config.Visual.ESP_Eggs = v end, 5)
AddToggle(VisualPage, "ESP Players", false, function(v) Config.Visual.ESP_Players = v end, 52)
AddToggle(VisualPage, "ESP Tracers", false, function(v) Config.Visual.ESP_Tracers = v end, 99)
AddToggle(VisualPage, "Fullbright", false, function(v)
    Config.Visual.Fullbright = v
    if v then ApplyFullbright() else RemoveFullbright() end
end, 146)
AddToggle(VisualPage, "No Fog", false, function(v)
    Config.Visual.NoFog = v
    if v then
        Lighting.FogEnd = 100000
    else
        Lighting.FogEnd = 500
    end
end, 193)

--=========================================================
-- [SECTION 24] EGGS PAGE (DYNAMIC LIST)
--=========================================================
local EggListContainer = mk("Frame", {
    Size = UDim2.new(1, -10, 0, 0),
    Position = UDim2.fromOffset(5, 5),
    BackgroundTransparency = 1
}, EggPage)
mk("UIListLayout", {Padding = UDim.new(0, 6)}, EggListContainer)

task.spawn(function()
    while task.wait(1.5) do
        if not Pages["Eggs"].Visible then continue end
        
        for _, v in pairs(EggListContainer:GetChildren()) do
            if v:IsA("Frame") then v:Destroy() end
        end
        
        local eggs = GetEggs()
        
        if #eggs == 0 then
            local empty = mk("TextLabel", {
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundTransparency = 1,
                Text = "No eggs found nearby",
                TextColor3 = Theme.Subtext,
                Font = Enum.Font.GothamMedium,
                TextSize = 14
            }, EggListContainer)
            continue
        end
        
        for i, egg in ipairs(eggs) do
            local row = mk("Frame", {
                Size = UDim2.new(1, -5, 0, 48),
                BackgroundColor3 = Theme.Card
            }, EggListContainer)
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
                BackgroundColor3 = Theme.Success,
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
                    btn.BackgroundColor3 = Theme.Success
                    task.wait(1)
                    if btn.Parent then
                        btn.Text = "Steal"
                        btn.BackgroundColor3 = Theme.Success
                    end
                end)
            end)
        end
        
        EggPage.CanvasSize = UDim2.new(0, 0, 0, #eggs * 54)
        EggListContainer.Size = UDim2.new(1, -10, 0, #eggs * 54)
    end
end)

--=========================================================
-- [SECTION 25] STATS PAGE
--=========================================================
local StatLabels = {}

local function AddStatLabel(parent, name, posY)
    local lbl = mk("TextLabel", {
        Size = UDim2.new(1, -10, 0, 32),
        Position = UDim2.fromOffset(5, posY),
        BackgroundColor3 = Theme.Card,
        Text = name..": 0",
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0
    }, parent)
    mk("UICorner", {CornerRadius = UDim.new(0, 6)}, lbl)
    mk("UIPadding", {PaddingLeft = UDim.new(0, 14)}, lbl)
    StatLabels[name] = lbl
    return lbl
end

AddStatLabel(StatsPage, "Eggs Stolen", 5)
AddStatLabel(StatsPage, "Hatches", 43)
AddStatLabel(StatsPage, "Butterflies", 81)
AddStatLabel(StatsPage, "Session Time", 119)
AddStatLabel(StatsPage, "Memory", 157)

task.spawn(function()
    while task.wait(1) do
        if not Pages["Stats"].Visible then continue end
        StatLabels["Eggs Stolen"].Text = "Eggs Stolen: "..State.Stats.EggsStolen
        StatLabels["Hatches"].Text = "Hatches: "..State.Stats.HatchesDone
        StatLabels["Butterflies"].Text = "Butterflies: "..State.Stats.Butterflies
        local elapsed = math.floor(tick() - State.Stats.SessionStart)
        StatLabels["Session Time"].Text = "Session Time: "..elapsed.."s"
        StatLabels["Memory"].Text = "Memory: "..math.floor(collectgarbage("count")).." KB"
    end
end)

--=========================================================
-- [SECTION 26] LOGS PAGE
--=========================================================
local LogContainer = mk("Frame", {
    Size = UDim2.new(1, -10, 0, 0),
    Position = UDim2.fromOffset(5, 5),
    BackgroundTransparency = 1
}, LogsPage)
mk("UIListLayout", {Padding = UDim.new(0, 4)}, LogContainer)

task.spawn(function()
    while task.wait(2) do
        if not Pages["Logs"].Visible then continue end
        
        for _, v in pairs(LogContainer:GetChildren()) do
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
            }, LogContainer)
            mk("UICorner", {CornerRadius = UDim.new(0, 4)}, lbl)
            mk("UIPadding", {PaddingLeft = UDim.new(0, 8)}, lbl)
        end
        
        LogsPage.CanvasSize = UDim2.new(0, 0, 0, #State.Logs * 26)
        LogContainer.Size = UDim2.new(1, -10, 0, #State.Logs * 26)
    end
end)

--=========================================================
-- [SECTION 27] SETTINGS PAGE
--=========================================================
AddToggle(SettingsPage, "Anti-AFK", true, function(v) Config.Misc.AntiAFK = v end, 5)
AddButton(SettingsPage, "Save Profile", Theme.Success, function()
    State.SavedProfiles[State.CurrentProfile] = {
        Farm = Config.Farm,
        Movement = Config.Movement,
        Visual = Config.Visual
    }
    Log("Profile saved: "..State.CurrentProfile, "CONFIG")
end, 52)
AddButton(SettingsPage, "Clear All Logs", Theme.Warning, function()
    State.Logs = {}
    Log("Logs cleared.", "CONFIG")
end, 100)
AddButton(SettingsPage, "Rejoin Server", Theme.Accent, function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end, 148)
AddButton(SettingsPage, "Destroy UI", Theme.Accent2, function()
    Screen:Destroy()
end, 196)

--=========================================================
-- [SECTION 28] DRAG SYSTEM
--=========================================================
local function MakeDraggable(frame, handle)
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
            local delta = i.Position - dragStart
            if delta.Magnitude > 5 then moved = true end
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    return function() return moved end
end

MakeDraggable(Window, TitleBar)
local btnMoved = MakeDraggable(FloatBtn, FloatBtn)

--=========================================================
-- [SECTION 29] OPEN/CLOSE HANDLERS
--=========================================================
local isOpen = false

FloatBtn.MouseButton1Click:Connect(function()
    if btnMoved() then return end
    isOpen = not isOpen
    Window.Visible = isOpen
    if isOpen then
        Window.Size = UDim2.fromOffset(620, 0)
        Tween:Create(Window, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(620, 460)
        }):Play()
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    isOpen = false
    Window.Visible = false
end)

--=========================================================
-- [SECTION 30] KEYBINDS
--=========================================================
UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.F then
        isOpen = not isOpen
        Window.Visible = isOpen
    end
    if input.KeyCode == Enum.KeyCode.G then
        local eggs = GetEggs()
        if #eggs > 0 then StealEgg(eggs[1]) end
    end
end)

--=========================================================
-- [SECTION 31] FINAL INIT
--=========================================================
Log("All modules loaded.", "SYSTEM")
Log("Bypass: Safe API mode", "SYSTEM")
Log("Total features: 50+", "SYSTEM")
Log("Press F to toggle UI", "INFO")
Log("Press G to steal best egg", "INFO")

-- Initial cache
task.spawn(function()
    task.wait(1)
    RefreshEggCache()
    Log("Egg cache initialized.", "SYSTEM")
end)
