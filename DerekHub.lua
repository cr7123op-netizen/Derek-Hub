--[[ Derek Hub v7.0 — Ultimate Edition | Steal An Egg | Author: ALPHA ]]
task.wait(1)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer

local Config = {
    AutoSteal = false,
    AutoHatch = false,
    AutoButterfly = false,
    StealDelay = 0.5
}

-- Core Functions
local function getChar()
    local c = LP.Character
    return c, c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
end

local function getEggs()
    local t = {}
    for _, v in pairs(Workspace:GetDescendants()) do
        if (v:IsA("Model") or v:IsA("Part")) then
            local n = v.Name:lower()
            if (n:find("egg") or n:find("pet") or n:find("animal")) and not n:find("plot") and not n:find("base") then
                local prompt = v:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    local value = "???"
                    local match = string.match(v.Name, "%((%d+)%)")
                    if match then value = match end
                    table.insert(t, {model = v, prompt = prompt, pos = (v:IsA("Model") and v:GetPivot().Position) or v.Position, value = value})
                end
            end
        end
    end
    return t
end

local function stealSpecific(egg)
    local _, hum, hrp = getChar()
    if not hum or not hrp or not egg.model.Parent then return end
    
    local oldCF = hrp.CFrame
    pcall(function()
        -- Teleport to egg
        hrp.CFrame = egg.model.CFrame * CFrame.new(0, 2, 0)
        task.wait(0.05)
        -- Steal
        fireproximityprompt(egg.prompt)
        task.wait(0.05)
        -- Return
        hrp.CFrame = oldCF
    end)
end

-- UI Library
local function mk(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local colors = {
    bg = Color3.fromRGB(15, 15, 18),
    panel = Color3.fromRGB(22, 22, 28),
    accent = Color3.fromRGB(220, 40, 50),
    text = Color3.fromRGB(240, 240, 245),
    subtext = Color3.fromRGB(150, 150, 160),
    off = Color3.fromRGB(50, 50, 60)
}

local uiParent = (gethui and gethui()) or CoreGui or LP:WaitForChild("PlayerGui")
local gui = mk("ScreenGui", {Name="DerekHub", ResetOnSpawn=false, IgnoreGuiInset=true, ZIndexBehavior=Enum.ZIndexBehavior.Sibling}, uiParent)

-- Main Frame
local main = mk("Frame", {
    Size=UDim2.fromOffset(380, 450), Position=UDim2.new(0.5,-190,0.5,-225),
    BackgroundColor3=colors.bg, BorderSizePixel=0, Visible=false
}, gui)
mk("UICorner",{CornerRadius=UDim.new(0,12)}, main)
mk("UIStroke",{Color=colors.accent, Thickness=1.5}, main)

-- Title Bar
local title = mk("Frame", {Size=UDim2.new(1,0,0,40), BackgroundColor3=colors.panel, BorderSizePixel=0}, main)
mk("UICorner",{CornerRadius=UDim.new(0,12)}, title)
mk("TextLabel", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="Derek Hub v7.0", Font=Enum.Font.GothamBold, TextSize=16, TextColor3=colors.text}, title)

-- Close Button
local closeBtn = mk("TextButton", {Size=UDim2.fromOffset(30,30), Position=UDim2.new(1,-35,0.5,-15), BackgroundColor3=colors.accent, Text="X", TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, BorderSizePixel=0}, title)
mk("UICorner",{CornerRadius=UDim.new(0,8)}, closeBtn)

-- Tabs
local tabBar = mk("Frame", {Size=UDim2.new(1,-20,0,30), Position=UDim2.new(0,10,0,50), BackgroundTransparency=1}, main)
mk("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,10)}, tabBar)

local tabs = {}
local pages = {}
local function createTab(name)
    local btn = mk("TextButton", {Size=UDim2.new(0,100,1,0), BackgroundColor3=colors.panel, Text=name, TextColor3=colors.text, Font=Enum.Font.GothamMedium, TextSize=13, BorderSizePixel=0}, tabBar)
    mk("UICorner",{CornerRadius=UDim.new(0,6)}, btn)
    
    local page = mk("ScrollingFrame", {Size=UDim2.new(1,-20,1,-100), Position=UDim2.new(0,10,0,90), BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=2, CanvasSize=UDim2.new(0,0,0,0), Visible=false}, main)
    mk("UIListLayout", {Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder}, page)
    
    tabs[name] = btn
    pages[name] = page
    
    btn.MouseButton1Click:Connect(function()
        for n, p in pairs(pages) do p.Visible = (n == name) end
        for n, b in pairs(tabs) do b.BackgroundColor3 = (n == name) and colors.accent or colors.panel end
    end)
    return page
end

local autoPage = createTab("Auto")
local espPage = createTab("Animals")
local miscPage = createTab("Misc")
tabs["Auto"].BackgroundColor3 = colors.accent
pages["Auto"].Visible = true

-- Toggles
local function addToggle(page, text, default, callback)
    local row = mk("Frame", {Size=UDim2.new(1,-10,0,40), BackgroundColor3=colors.panel}, page)
    mk("UICorner",{CornerRadius=UDim.new(0,8)}, row)
    mk("TextLabel", {Size=UDim2.new(1,-60,1,0), Position=UDim2.new(0,12,0,0), BackgroundTransparency=1, Text=text, TextColor3=colors.text, Font=Enum.Font.GothamMedium, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left}, row)
    
    local sw = mk("Frame", {Size=UDim2.fromOffset(40,22), Position=UDim2.new(1,-50,0.5,-11), BackgroundColor3=default and colors.accent or colors.off}, row)
    mk("UICorner",{CornerRadius=UDim.new(1,0)}, sw)
    local knob = mk("Frame", {Size=UDim2.fromOffset(18,18), Position=UDim2.new(0, default and 20 or 2, 0.5, -9), BackgroundColor3=Color3.new(1,1,1)}, sw)
    mk("UICorner",{CornerRadius=UDim.new(1,0)}, knob)
    
    local state = default
    local btn = mk("TextButton", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text=""}, row)
    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(sw, TweenInfo.new(0.15), {BackgroundColor3 = state and colors.accent or colors.off}):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(0, state and 20 or 2, 0.5, -9)}):Play()
        if callback then pcall(callback, state) end
    end)
end

-- Open/Close
local toggleBtn = mk("TextButton", {
    Size=UDim2.fromOffset(60,60), Position=UDim2.new(0,20,0.5,-30),
    BackgroundColor3=colors.accent, Text="D", TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBlack, TextSize=28, BorderSizePixel=0
}, gui)
mk("UICorner",{CornerRadius=UDim.new(1,0)}, toggleBtn)

local isOpen = false
toggleBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    main.Visible = isOpen
end)
closeBtn.MouseButton1Click:Connect(function()
    isOpen = false
    main.Visible = false
end)

-- Auto Logic
local stealing = false
local function startAutoSteal()
    if stealing then return end
    stealing = true
    task.spawn(function()
        while Config.AutoSteal do
            local _, hum, hrp = getChar()
            if hum and hrp and hum.Health > 0 then
                local best, bestDist = nil, math.huge
                for _, egg in ipairs(getEggs()) do
                    local d = (egg.pos - hrp.Position).Magnitude
                    if d < bestDist then best, bestDist = egg, d end
                end
                
                if best then
                    if bestDist > 10 then
                        hum:MoveTo(best.pos)
                        task.wait(0.2)
                    else
                        pcall(function() fireproximityprompt(best.prompt) end)
                        task.wait(Config.StealDelay)
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

addToggle(autoPage, "Auto Steal (Move)", false, function(v) Config.AutoSteal = v; if v then startAutoSteal() end end)

local function autoHatchLoop()
    task.spawn(function()
        while Config.AutoHatch do
            local char = LP.Character
            if char then
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("ProximityPrompt") and v.ActionText:lower():find("hatch") then
                        pcall(function() fireproximityprompt(v) end)
                    end
                end
            end
            task.wait(1)
        end
    end)
end
addToggle(autoPage, "Auto Hatch", false, function(v) Config.AutoHatch = v; if v then autoHatchLoop() end end)

local function autoButterflyLoop()
    task.spawn(function()
        while Config.AutoButterfly do
            local _, hum, hrp = getChar()
            if hum and hrp then
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if v.Name:lower():find("butterfly") then
                        local p = v:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if p and (v.Position - hrp.Position).Magnitude < 30 then
                            pcall(function() fireproximityprompt(p) end)
                        end
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end
addToggle(autoPage, "Auto Butterfly", false, function(v) Config.AutoButterfly = v; if v then autoButterflyLoop() end end)

-- ESP Logic
local espElements = {}
task.spawn(function()
    while task.wait(1) do
        if not pages["Animals"].Visible then continue end
        
        local currentEggs = getEggs()
        
        for _, el in pairs(espElements) do el:Destroy() end
        espElements = {}
        
        if #currentEggs == 0 then
            local noEggs = mk("TextLabel", {Size=UDim2.new(1,-10,0,40), BackgroundTransparency=1, Text="No Animals/Eggs found nearby.", TextColor3=colors.subtext, Font=Enum.Font.Gotham, TextSize=14}, pages["Animals"])
            table.insert(espElements, noEggs)
        else
            for i, egg in ipairs(currentEggs) do
                local row = mk("Frame", {Size=UDim2.new(1,-10,0,50), BackgroundColor3=colors.panel}, pages["Animals"])
                mk("UICorner",{CornerRadius=UDim.new(0,8)}, row)
                
                mk("TextLabel", {Size=UDim2.new(0.6,0,0,20), Position=UDim2.new(0,12,0,6), BackgroundTransparency=1, Text=egg.model.Name, TextColor3=colors.text, Font=Enum.Font.GothamBold, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}, row)
                mk("TextLabel", {Size=UDim2.new(0.6,0,0,20), Position=UDim2.new(0,12,0,26), BackgroundTransparency=1, Text="Value: " .. egg.value, TextColor3=colors.accent, Font=Enum.Font.GothamMedium, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left}, row)
                
                local stealBtn = mk("TextButton", {Size=UDim2.fromOffset(70,30), Position=UDim2.new(1,-80,0.5,-15), BackgroundColor3=colors.accent, Text="Steal", TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, TextSize=12, BorderSizePixel=0}, row)
                mk("UICorner",{CornerRadius=UDim.new(0,6)}, stealBtn)
                
                stealBtn.MouseButton1Click:Connect(function()
                    stealSpecific(egg)
                end)
                
                table.insert(espElements, row)
            end
        end
        pages["Animals"].CanvasSize = UDim2.new(0,0,0, #espElements * 58)
    end
end)

-- Misc
addToggle(miscPage, "Anti-AFK", true, function(v) end)

LP.Idled:Connect(function()
    game:GetService("VirtualUser"):CaptureController()
    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
end)

-- Dragging
local dragging, dragStart, startPos
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = main.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

local draggingBtn, dragStartBtn, startPosBtn
toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingBtn = true; dragStartBtn = input.Position; startPosBtn = toggleBtn.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if draggingBtn and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStartBtn
        toggleBtn.Position = UDim2.new(startPosBtn.X.Scale, startPosBtn.X.Offset + delta.X, startPosBtn.Y.Scale, startPosBtn.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then draggingBtn = false end
end)
