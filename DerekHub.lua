--[[ Derek Hub v6.2 — Hyperion Bypass | Steal An Egg | Author: ALPHA ]]
task.wait(1)

local Players    = game:GetService("Players")
local Workspace  = game:GetService("Workspace")
local UIS        = game:GetService("UserInputService")
local LP         = Players.LocalPlayer

local Config = { AutoSteal = false, AutoButterfly = false, AutoHatch = false }

local function getChar()
    local c = LP.Character
    return c, c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
end

-- بحث آمن وخفيف جداً (ما يستخدم GetDescendants)
local function getTargets()
    local t = {}
    for _, folderName in ipairs({"Eggs", "Map", "Butterflies", "Spawns"}) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then
            for _, v in ipairs(folder:GetChildren()) do
                if (v:IsA("Model") or v:IsA("Part")) then
                    local n = v.Name:lower()
                    if n:find("egg") or n:find("butterfly") then
                        local p = v:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if p then table.insert(t, {model=v, prompt=p, pos=v.Position or v:GetPivot().Position}) end
                    end
                end
            end
        end
    end
    -- إذا البيض مو داخل فولدر، نبحث في الـ Workspace مباشرة
    for _, v in ipairs(Workspace:GetChildren()) do
        if (v:IsA("Model") or v:IsA("Part")) then
            local n = v.Name:lower()
            if (n:find("egg") or n:find("butterfly")) and not n:find("plot") then
                local p = v:FindFirstChildWhichIsA("ProximityPrompt", true)
                if p then table.insert(t, {model=v, prompt=p, pos=v.Position or v:GetPivot().Position}) end
            end
        end
    end
    return t
end

-- منطق السرقة
local stealing = false
local function startSteal()
    if stealing then return end
    stealing = true
    task.spawn(function()
        while Config.AutoSteal do
            local _, hum, hrp = getChar()
            if hum and hrp and hum.Health > 0 then
                local closest, closestDist = nil, math.huge
                for _, v in ipairs(getTargets()) do
                    local d = (v.pos - hrp.Position).Magnitude
                    if d < closestDist then closest, closestDist = v, d end
                end
                
                if closest then
                    if closestDist > 8 then
                        hum:MoveTo(closest.pos)
                        task.wait(0.2)
                    else
                        hum:MoveTo(hrp.Position)
                        task.wait(0.1)
                        pcall(function() fireproximityprompt(closest.prompt) end)
                        task.wait(1.5) -- تأخير آمن جداً
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

-- ==========================================
-- ======== واجهة مخفية (gethui) ============
-- ==========================================
local function mk(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

-- استخدام gethui إذا متوفر، وإلا CoreGui
local uiParent
if gethui then
    uiParent = gethui()
elseif game:GetService("CoreGui") then
    uiParent = game:GetService("CoreGui")
else
    uiParent = LP:WaitForChild("PlayerGui")
end

local gui = mk("ScreenGui", {Name="DHub", ResetOnSpawn=false, IgnoreGuiInset=true}, uiParent)

local btn = mk("TextButton", {
    Size=UDim2.fromOffset(50,50), Position=UDim2.new(0,15,0.4,0),
    BackgroundColor3=Color3.fromRGB(220,40,50), Text="D", TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBold, TextSize=24, BorderSizePixel=0
}, gui)
mk("UICorner",{CornerRadius=UDim.new(1,0)}, btn)

local main = mk("Frame", {
    Size=UDim2.fromOffset(200, 200), Position=UDim2.new(0.5,-100,0.5,-100),
    BackgroundColor3=Color3.fromRGB(18,18,20), BorderSizePixel=0, Visible=false
}, gui)
mk("UICorner",{CornerRadius=UDim.new(0,10)}, main)

local list = mk("UIListLayout",{Padding=UDim.new(0,10), HorizontalAlignment=Enum.HorizontalAlignment.Center, VerticalAlignment=Enum.VerticalAlignment.Center}, main)

local function addBtn(text, callback)
    local b = mk("TextButton",{Size=UDim2.new(1,-20,0,40), BackgroundColor3=Color3.fromRGB(28,28,32), Text=text, TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamMedium, TextSize=14, BorderSizePixel=0}, main)
    mk("UICorner",{CornerRadius=UDim.new(0,8)}, b)
    local state = false
    b.MouseButton1Click:Connect(function()
        state = not state
        b.BackgroundColor3 = state and Color3.fromRGB(220,40,50) or Color3.fromRGB(28,28,32)
        if callback then callback(state) end
    end)
end

addBtn("Auto Steal", function(v) Config.AutoSteal = v; if v then startSteal() end end)
addBtn("Close", function() main.Visible = false end)

local open = false
btn.MouseButton1Click:Connect(function()
    open = not open
    main.Visible = open
end)

-- سحب
local dragging, dragStart, startPos
btn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = btn.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
