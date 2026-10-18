--[[ Derek Hub v15.0 — AJJANS Edition | Steal An Egg | Author: ALPHA ]]
task.wait(1)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VU = game:GetService("VirtualUser")
local LP = Players.LocalPlayer

local Config = {
    AutoSteal = false,
    AutoHatch = false,
    AutoButterfly = false,
    SpeedEnabled = false,
    SpeedValue = 16,
    FlyEnabled = false,
    FlySpeed = 60,
    AntiAFK = true,
    KillAura = false,
    AutoEquip = false,
    ToolSwap = false,
    AntiHit = false,
    AntiTrap = false,
    AuraRange = 15,
    AttackDelay = 0.1
}

-- ==========================================
-- ============ دوال مساعدة =============
-- ==========================================
local function getChar()
    local c = LP.Character
    return c, c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
end

local function getImage(model)
    for _, v in ipairs(model:GetDescendants()) do
        if v:IsA("Decal") and v.Texture ~= "" then return v.Texture end
        if v:IsA("Texture") and v.Texture ~= "" then return v.Texture end
        if v:IsA("MeshPart") and v.TextureID ~= "" then return v.TextureID end
        if v:IsA("ImageLabel") and v.Image ~= "" then return v.Image end
    end
    return "rbxassetid://13495565986" -- Golden Egg
end

local function getEggs()
    local eggs = {}
    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and string.lower(prompt.ActionText) == "steal" then
            local model = prompt.Parent
            local pos = (model:IsA("Model") and model:GetPivot().Position) or model.Position
            local name = prompt.ObjectText ~= "" and prompt.ObjectText or model.Name
            
            -- ترتيب تقريبي للقوة (يقدر يعدل حسب اللعبة)
            local score = 10
            local n = string.lower(name)
            if n:find("secret") or n:find("mythic") then score = 100
            elseif n:find("legendary") then score = 80
            elseif n:find("epic") then score = 60
            elseif n:find("rare") then score = 40 end

            table.insert(eggs, {
                model = model, prompt = prompt, pos = pos, name = name,
                image = getImage(model), score = score
            })
        end
    end
    table.sort(eggs, function(a,b) return a.score > b.score end)
    return eggs
end

-- السرقة الفورية (مع محاكاة اللمس)
local function stealEgg(egg, btn)
    local _, hum, hrp = getChar()
    if not hum or not hrp or not egg.model.Parent then return end
    
    local originalCF = hrp.CFrame
    local wasSpeedOn = Config.SpeedEnabled
    Config.SpeedEnabled = false
    hum.WalkSpeed = 16
    
    if btn then
        btn.Text = "..."
        btn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    end
    
    task.spawn(function()
        pcall(function()
            hrp.CFrame = CFrame.new(egg.pos + Vector3.new(0, 2, 0))
            task.wait(0.2) -- انتظار السيرفر
            
            fireproximityprompt(egg.prompt)
            -- محاكاة ضغطة عشان نضمن الاستجابة
            VU:CaptureController()
            VU:ClickButton1(Vector2.new())
            
            task.wait(0.2)
            hrp.CFrame = originalCF
        end)
        Config.SpeedEnabled = wasSpeedOn
        
        if btn and btn.Parent then
            btn.Text = "Done ✓"
            task.wait(0.5)
            if btn.Parent then
                btn.Text = "Steal"
                btn.BackgroundColor3 = Color3.fromRGB(230, 0, 40)
            end
        end
    end)
end

-- ==========================================
-- ============ تصميم الواجهة ============
-- ==========================================
local function mk(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local clr = {
    bg = Color3.fromRGB(10, 5, 8),
    panel = Color3.fromRGB(20, 10, 14),
    accent = Color3.fromRGB(230, 0, 40),
    text = Color3.fromRGB(255, 255, 255),
    subtext = Color3.fromRGB(160, 140, 145),
    stroke = Color3.fromRGB(230, 0, 40),
    off = Color3.fromRGB(40, 20, 25)
}

local uiParent = (gethui and gethui()) or game:GetService("CoreGui") or LP:WaitForChild("PlayerGui")
local gui = mk("ScreenGui", {Name="AJJANS", ResetOnSpawn=false, IgnoreGuiInset=true, ZIndexBehavior=Enum.ZIndexBehavior.Sibling}, uiParent)

-- زر الفتح
local toggleBtn = mk("TextButton", {
    Size=UDim2.fromOffset(60,60), Position=UDim2.new(0,20,0.5,-30),
    BackgroundColor3=clr.accent, Text="A", TextColor3=clr.text,
    Font=Enum.Font.GothamBlack, TextSize=32, BorderSizePixel=0
}, gui)
mk("UICorner",{CornerRadius=UDim.new(1,0)}, toggleBtn)
mk("UIStroke", {Color=clr.text, Thickness=2, Transparency=0.3}, toggleBtn)

-- النافذة الرئيسية
local main = mk("Frame", {
    Size=UDim2.fromOffset(620, 420), Position=UDim2.new(0.5,-310,0.5,-210),
    BackgroundColor3=clr.bg, BorderSizePixel=0, Visible=false
}, gui)
mk("UICorner",{CornerRadius=UDim.new(0,10)}, main)
local stroke = mk("UIStroke",{Color=clr.accent, Thickness=1.5, Transparency=0.2}, main)
local grad = mk("UIGradient",{Color=ColorSequence.new{ColorSequenceKeypoint.new(0, clr.accent), ColorSequenceKeypoint.new(1, Color3.fromRGB(100,0,20))}, Rotation=90}, stroke)

-- شريط العنوان العلوي
local topBar = mk("Frame", {Size=UDim2.new(1,0,0,40), BackgroundColor3=clr.panel, BorderSizePixel=0}, main)
mk("UICorner",{CornerRadius=UDim.new(0,10)}, topBar)
mk("Frame", {Size=UDim2.new(1,0,0,15), Position=UDim2.new(0,0,1,-15), BackgroundColor3=clr.panel, BorderSizePixel=0}, topBar)

mk("TextLabel", {Size=UDim2.new(0,100,1,0), Position=UDim2.new(0,15,0,0), BackgroundTransparency=1, Text="AJJANS", TextColor3=clr.accent, Font=Enum.Font.GothamBlack, TextSize=16, TextXAlignment=Enum.TextXAlignment.Left}, topBar)
mk("TextLabel", {Size=UDim2.new(0,100,1,0), Position=UDim2.new(0,100,0,0), BackgroundTransparency=1, Text="FPS: 60 | VER: 1.0", TextColor3=clr.subtext, Font=Enum.Font.Gotham, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left}, topBar)

local closeBtn = mk("TextButton", {Size=UDim2.fromOffset(30,30), Position=UDim2.new(1,-35,0.5,-15), BackgroundColor3=clr.off, Text="✕", TextColor3=clr.text, Font=Enum.Font.GothamBold, BorderSizePixel=0}, topBar)
mk("UICorner",{CornerRadius=UDim.new(0,6)}, closeBtn)

-- الشريط الجانبي (Left Menu)
local sidebar = mk("Frame", {Size=UDim2.fromOffset(140, 370), Position=UDim2.new(0,10,0,50), BackgroundColor3=clr.panel, BorderSizePixel=0}, main)
mk("UICorner",{CornerRadius=UDim.new(0,8)}, sidebar)
local sideLayout = mk("UIListLayout", {Padding=UDim.new(0,5), SortOrder=Enum.SortOrder.LayoutOrder}, sidebar)
mk("UIPadding", {PaddingTop=UDim.new(0,10)}, sidebar)

local pages = {}
local tabs = {}
local function createSideTab(name, icon, isFirst)
    local btn = mk("TextButton", {Size=UDim2.new(1,-10,0,35), BackgroundColor3=isFirst and clr.accent or clr.panel, Text="   "..icon.."  "..name, TextColor3=clr.text, Font=Enum.Font.GothamMedium, TextSize=13, BorderSizePixel=0, TextXAlignment=Enum.TextXAlignment.Left}, sidebar)
    mk("UICorner",{CornerRadius=UDim.new(0,6)}, btn)
    
    local page = mk("Frame", {Size=UDim2.new(0, 450, 0, 370), Position=UDim2.new(0, 160, 0, 50), BackgroundTransparency=1, Visible=isFirst}, main)
    
    tabs[name] = btn; pages[name] = page
    
    btn.MouseButton1Click:Connect(function()
        for n, p in pairs(pages) do p.Visible = (n == name) end
        for n, b in pairs(tabs) do 
            TweenService:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = (n == name) and clr.accent or clr.panel}):Play()
        end
    end)
    return page
end

local mainPage = createSideTab("Main", "🏠", true)
local autoPage = createSideTab("Automation", "⚙️", false)
local eventPage = createSideTab("Events", "🎉", false)
local predPage = createSideTab("Predictor", "📈", false)
local miscPage = createSideTab("Misc", "🛠️", false)

-- ===== محتوى صفحة Main (ستيل + ترقيات + دفاع) =====
local leftPanel = mk("Frame", {Size=UDim2.new(0.5, -5, 1, 0), Position=UDim2.new(0, 0, 0, 0), BackgroundColor3=clr.panel, BorderSizePixel=0}, mainPage)
mk("UICorner",{CornerRadius=UDim.new(0,8)}, leftPanel)
mk("TextLabel", {Size=UDim2.new(1,-20,0,30), Position=UDim2.new(0,10,0,10), BackgroundTransparency=1, Text="Steal Eggs", TextColor3=clr.text, Font=Enum.Font.GothamBold, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left}, leftPanel)

local rightPanel = mk("Frame", {Size=UDim2.new(0.5, -5, 1, 0), Position=UDim2.new(0.5, 5, 0, 0), BackgroundColor3=clr.panel, BorderSizePixel=0}, mainPage)
mk("UICorner",{CornerRadius=UDim.new(0,8)}, rightPanel)
mk("TextLabel", {Size=UDim2.new(1,-20,0,30), Position=UDim2.new(0,10,0,10), BackgroundTransparency=1, Text="Defense", TextColor3=clr.text, Font=Enum.Font.GothamBold, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left}, rightPanel)

-- قائمة البيض (داخل leftPanel)
local eggScroll = mk("ScrollingFrame", {Size=UDim2.new(1,-10,1,-50), Position=UDim2.new(0,5,0,45), BackgroundTransparency=1, ScrollBarThickness=2, ScrollBarImageColor3=clr.accent, CanvasSize=UDim2.new(0,0,0,0)}, leftPanel)
mk("UIListLayout", {Padding=UDim.new(0,5)}, eggScroll)

local function updateEggList()
    for _, v in ipairs(eggScroll:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    local eggs = getEggs()
    for i, egg in ipairs(eggs) do
        local row = mk("Frame", {Size=UDim2.new(1,-5,0,50), BackgroundColor3=clr.bg}, eggScroll)
        mk("UICorner",{CornerRadius=UDim.new(0,6)}, row)
        
        local img = mk("ImageLabel", {Size=UDim2.fromOffset(35,35), Position=UDim2.new(0,5,0.5,-17), BackgroundColor3=clr.panel, Image=egg.image}, row)
        mk("UICorner",{CornerRadius=UDim.new(0,4)}, img)
        
        mk("TextLabel", {Size=UDim2.new(0.5,0,0,15), Position=UDim2.new(0,45,0,8), BackgroundTransparency=1, Text="# "..i.." "..egg.name, TextColor3=clr.text, Font=Enum.Font.GothamBold, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}, row)
        mk("TextLabel", {Size=UDim2.new(0.5,0,0,15), Position=UDim2.new(0,45,0,25), BackgroundTransparency=1, Text="Score: "..egg.score, TextColor3=clr.accent, Font=Enum.Font.Gotham, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left}, row)
        
        local btn = mk("TextButton", {Size=UDim2.fromOffset(60,25), Position=UDim2.new(1,-65,0.5,-12), BackgroundColor3=clr.accent, Text="Steal", TextColor3=clr.text, Font=Enum.Font.GothamBold, TextSize=11, BorderSizePixel=0}, row)
        mk("UICorner",{CornerRadius=UDim.new(0,4)}, btn)
        btn.MouseButton1Click:Connect(function() stealEgg(egg, btn) end)
    end
end
task.spawn(function() while task.wait(2) do if main.Visible and pages["Main"].Visible then updateEggList() end end end)

-- أزرار الدفاع (داخل rightPanel)
local function addDefenseToggle(text, y, callback)
    local lbl = mk("TextLabel", {Size=UDim2.new(1,-60,0,25), Position=UDim2.new(0,10,0,y), BackgroundTransparency=1, Text=text, TextColor3=clr.text, Font=Enum.Font.Gotham, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left}, rightPanel)
    local sw = mk("Frame", {Size=UDim2.fromOffset(35,18), Position=UDim2.new(1,-45,0,y+3), BackgroundColor3=clr.off}, rightPanel)
    mk("UICorner",{CornerRadius=UDim.new(1,0)}, sw)
    local knob = mk("Frame", {Size=UDim2.fromOffset(14,14), Position=UDim2.new(0,2,0.5,-7), BackgroundColor3=clr.text}, sw)
    mk("UICorner",{CornerRadius=UDim.new(1,0)}, knob)
    local state = false
    local btn = mk("TextButton", {Size=UDim2.new(1,-10,0,25), Position=UDim2.new(0,5,0,y), BackgroundTransparency=1, Text=""}, rightPanel)
    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(sw, TweenInfo.new(0.15), {BackgroundColor3 = state and clr.accent or clr.off}):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(0, state and 19 or 2, 0.5, -7)}):Play()
        if callback then callback(state) end
    end)
end

addDefenseToggle("Bat Kill Aura", 10, function(v) Config.KillAura = v end)
addDefenseToggle("Auto Equip Bat", 40, function(v) Config.AutoEquip = v end)
addDefenseToggle("Tool Swap", 70, function(v) Config.ToolSwap = v end)
addDefenseToggle("Anti-Hit", 100, function(v) Config.AntiHit = v end)
addDefenseToggle("Anti-Trap", 130, function(v) Config.AntiTrap = v end)

-- أزرار السرقات التلقائية (داخل autoPage)
local function addAutoToggle(parent, text, y, callback)
    local row = mk("Frame", {Size=UDim2.new(1,-10,0,35), Position=UDim2.new(0,5,0,y), BackgroundColor3=clr.panel}, parent)
    mk("UICorner",{CornerRadius=UDim.new(0,6)}, row)
    mk("TextLabel", {Size=UDim2.new(1,-50,1,0), Position=UDim2.new(0,10,0,0), BackgroundTransparency=1, Text=text, TextColor3=clr.text, Font=Enum.Font.GothamMedium, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left}, row)
    
    local sw = mk("Frame", {Size=UDim2.fromOffset(35,18), Position=UDim2.new(1,-45,0.5,-9), BackgroundColor3=clr.off}, row)
    mk("UICorner",{CornerRadius=UDim.new(1,0)}, sw)
    local knob = mk("Frame", {Size=UDim2.fromOffset(14,14), Position=UDim2.new(0,2,0.5,-7), BackgroundColor3=clr.text}, sw)
    mk("UICorner",{CornerRadius=UDim.new(1,0)}, knob)
    
    local state = false
    local btn = mk("TextButton", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text=""}, row)
    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(sw, TweenInfo.new(0.15), {BackgroundColor3 = state and clr.accent or clr.off}):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(0, state and 19 or 2, 0.5, -7)}):Play()
        if callback then callback(state) end
    end)
end

addAutoToggle(autoPage, "Auto Steal", 10, function(v) Config.AutoSteal = v end)
addAutoToggle(autoPage, "Auto Hatch", 55, function(v) Config.AutoHatch = v end)
addAutoToggle(autoPage, "Auto Butterfly", 100, function(v) Config.AutoButterfly = v end)

-- ===== القائمة المنسدلة (Dropdown) =====
local function createDropdown(parent, text, y, options)
    local container = mk("Frame", {Size=UDim2.new(1,-10,0,35), Position=UDim2.new(0,5,0,y), BackgroundColor3=clr.bg}, parent)
    mk("UICorner",{CornerRadius=UDim.new(0,6)}, container)
    mk("TextLabel", {Size=UDim2.new(1,-30,1,0), Position=UDim2.new(0,10,0,0), BackgroundTransparency=1, Text=text..": ---", TextColor3=clr.subtext, Font=Enum.Font.Gotham, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left}, container)
    
    local drop = mk("ScrollingFrame", {Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,1,5), BackgroundColor3=clr.panel, Visible=false, ZIndex=10, CanvasSize=UDim2.new(0,0,0,0), ScrollBarThickness=2}, container)
    mk("UICorner",{CornerRadius=UDim.new(0,6)}, drop)
    mk("UIListLayout", {Padding=UDim.new(0,2)}, drop)
    
    for i, opt in ipairs(options) do
        local oBtn = mk("TextButton", {Size=UDim2.new(1,-4,0,25), Position=UDim2.new(0,2,0,2), BackgroundColor3=clr.bg, Text=opt, TextColor3=clr.text, Font=Enum.Font.Gotham, TextSize=11, BorderSizePixel=0}, drop)
        mk("UICorner",{CornerRadius=UDim.new(0,4)}, oBtn)
        oBtn.MouseButton1Click:Connect(function()
            container:FindFirstChildWhichIsA("TextLabel").Text = text..": "..opt
            drop.Visible = false
            drop.Size = UDim2.new(1,0,0,0)
        end)
    end
    drop.CanvasSize = UDim2.new(0,0,0, #options * 27)
    
    local click = mk("TextButton", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text=""}, container)
    click.MouseButton1Click:Connect(function()
        drop.Visible = not drop.Visible
        drop.Size = drop.Visible and UDim2.new(1,0,0,math.min(#options*27, 100)) or UDim2.new(1,0,0,0)
    end)
end

createDropdown(leftPanel, "Areas", 45, {"Spawn", "Beach", "Cave"})
createDropdown(leftPanel, "Categories", 85, {"Pets", "Eggs", "All"})
createDropdown(leftPanel, "Rarities", 125, {"Common", "Rare", "Epic"})

-- ===== التبويبات الأخرى (نصوص توضيحية) =====
mk("TextLabel", {Size=UDim2.new(1,0,0,40), Position=UDim2.new(0,0,0,0), BackgroundColor3=clr.panel, Text="Events & Predictor Coming Soon...", TextColor3=clr.text, Font=Enum.Font.Gotham, TextSize=14}, eventPage)
mk("UICorner",{CornerRadius=UDim.new(0,6)}, eventPage:FindFirstChildWhichIsA("TextLabel"))

-- ==========================================
-- ============ الوظائف الخلفية ============
-- ==========================================
-- 1. السرعة (BodyVelocity)
local speedVel = nil
RunService.RenderStepped:Connect(function()
    local _, hum, hrp = getChar()
    if not hum or not hrp then if speedVel then speedVel:Destroy() speedVel=nil end return end
    
    if Config.SpeedEnabled then
        hum.WalkSpeed = 16
        if not speedVel or speedVel.Parent ~= hrp then
            if speedVel then speedVel:Destroy() end
            speedVel = Instance.new("BodyVelocity")
            speedVel.Parent = hrp
            speedVel.MaxForce = Vector3.new(1e5,0,1e5)
        end
        speedVel.Velocity = hum.MoveDirection.Magnitude > 0 and hum.MoveDirection * Config.SpeedValue or Vector3.zero
    else
        if speedVel then speedVel:Destroy() speedVel=nil end
    end
end)

-- 2. الطيران
local flyVel, flyGyro = nil, nil
RunService.RenderStepped:Connect(function()
    local _, hum, hrp = getChar()
    if not hum or not hrp then return end
    if Config.FlyEnabled then
        if not flyVel then
            flyVel = Instance.new("BodyVelocity", hrp); flyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
            flyGyro = Instance.new("BodyGyro", hrp); flyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5); flyGyro.P = 1000
        end
        flyVel.Velocity = hum.MoveDirection * Config.FlySpeed + Vector3.new(0, (UIS:IsKeyDown(Enum.KeyCode.Space) and Config.FlySpeed or 0), 0)
        flyGyro.CFrame = workspace.CurrentCamera.CFrame
    else
        if flyVel then flyVel:Destroy() flyVel=nil end
        if flyGyro then flyGyro:Destroy() flyGyro=nil end
    end
end)

-- 3. Auto AFK
LP.Idled:Connect(function() if Config.AntiAFK then VU:CaptureController() VU:ClickButton2(Vector2.new()) end end)

-- 4. Auto Farm Loop
task.spawn(function()
    while task.wait(0.5) do
        local _, hum, hrp = getChar()
        if hum and hrp and hum.Health > 0 then
            if Config.AutoSteal then
                local eggs = getEggs()
                if #eggs > 0 then stealEgg(eggs[1]) end
            end
            if Config.AutoHatch then
                for _, v in pairs(Workspace:GetDescendants()) do
                    if v:IsA("ProximityPrompt") and string.lower(v.ActionText):find("hatch") then pcall(function() fireproximityprompt(v) end) end
                end
            end
            if Config.AutoButterfly then
                for _, v in pairs(Workspace:GetDescendants()) do
                    if v:IsA("ProximityPrompt") and string.lower(v.ActionText):find("catch") then 
                        if (v.Parent.Position - hrp.Position).Magnitude < 30 then pcall(function() fireproximityprompt(v) end) end
                    end
                end
            end
        end
    end
end)

-- تحكم اللوحة
local isOpen = false
toggleBtn.MouseButton1Click:Connect(function() isOpen = not isOpen; main.Visible = isOpen end)
closeBtn.MouseButton1Click:Connect(function() isOpen = false; main.Visible = false end)

-- سحب اللوحة
local drag, start, pos
topBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; start = i.Position; pos = main.Position end end)
UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then local d = i.Position - start; main.Position = UDim2.new(pos.X.Scale, pos.X.Offset + d.X, pos.Y.Scale, pos.Y.Offset + d.Y) end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)
