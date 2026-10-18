--[[ Derek Hub v8.0 — Pro Max Edition | Steal An Egg | Author: ALPHA ]]
task.wait(1)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

local Config = {
    AutoSteal = false,
    AutoHatch = false,
    AutoButterfly = false,
    StealDelay = 0.4,
    TeleportSteal = true,
}

local function getChar()
    local c = LP.Character
    return c, c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
end

-- فلترة البيض الحقيقي (اللي فيه برومبت سرقة)
local function getRealEggs()
    local t = {}
    for _, v in pairs(Workspace:GetDescendants()) do
        if (v:IsA("Model") or v:IsA("Part")) and not v:FindFirstChild("Humanoid") then
            local prompt = v:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                local action = prompt.ActionText:lower()
                -- نتأكد إنه للسرقة أو الفقس، ونتجنب بيض القاعدة الشخصية
                if action == "steal" or action == "grab" then
                    -- محاولة جلب الصورة
                    local img = "rbxassetid://13828748735" -- صورة بيضة افتراضية
                    local decal = v:FindFirstChildWhichIsA("Decal", true) or v:FindFirstChildWhichIsA("Texture", true)
                    if decal and decal.Texture ~= "" then
                        img = decal.Texture
                    elseif v:IsA("MeshPart") and v.TextureID ~= "" then
                        img = v.TextureID
                    end
                    
                    -- محاولة جلب السعر
                    local value = "???"
                    local valObj = v:FindFirstChild("Value") or v:FindFirstChild("Price")
                    if valObj and (valObj:IsA("StringValue") or valObj:IsA("NumberValue")) then
                        value = tostring(valObj.Value)
                    end

                    table.insert(t, {model = v, prompt = prompt, pos = (v:IsA("Model") and v:GetPivot().Position) or v.Position, img = img, value = value})
                end
            end
        end
    end
    return t
end

-- سرقة فورية (بدون ما يضرب حيطة)
local function stealSpecific(egg)
    local _, hum, hrp = getChar()
    if not hum or not hrp or not egg.model.Parent then return end
    
    if Config.TeleportSteal then
        local oldCF = hrp.CFrame
        pcall(function()
            -- ينتقل للبيضة، يسرق، ويرجع
            hrp.CFrame = CFrame.new(egg.pos + Vector3.new(0, 3, 0))
            task.wait(0.1)
            fireproximityprompt(egg.prompt)
            task.wait(0.1)
            hrp.CFrame = oldCF
        end)
    else
        -- المشي العادي (إذا حب يتخفى)
        task.spawn(function()
            hum:MoveTo(egg.pos)
            task.wait((hrp.Position - egg.pos).Magnitude / 16)
            pcall(function() fireproximityprompt(egg.prompt) end)
        end)
    end
end

-- UI Library
local function mk(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local colors = {
    bg = Color3.fromRGB(12, 12, 15),
    card = Color3.fromRGB(22, 22, 28),
    accent = Color3.fromRGB(255, 45, 85),
    text = Color3.fromRGB(255, 255, 255),
    subtext = Color3.fromRGB(160, 160, 170),
    off = Color3.fromRGB(40, 40, 48)
}

local uiParent = (gethui and gethui()) or game:GetService("CoreGui") or LP:WaitForChild("PlayerGui")
local gui = mk("ScreenGui", {Name="DerekHub8", ResetOnSpawn=false, IgnoreGuiInset=true, ZIndexBehavior=Enum.ZIndexBehavior.Sibling}, uiParent)

-- اللوحة الرئيسية
local main = mk("Frame", {
    Size=UDim2.fromOffset(400, 480), Position=UDim2.new(0.5,-200,0.5,-240),
    BackgroundColor3=colors.bg, BorderSizePixel=0, Visible=false
}, gui)
mk("UICorner",{CornerRadius=UDim.new(0,16)}, main)
local stroke = mk("UIStroke",{Color=colors.accent, Thickness=1.5, Transparency=0.5}, main)
local gradient = mk("UIGradient",{Color=ColorSequence.new{ColorSequenceKeypoint.new(0, colors.accent), ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 0, 200))}, Rotation=45}, stroke)

-- شريط العنوان
local title = mk("Frame", {Size=UDim2.new(1,0,0,50), BackgroundColor3=colors.card, BorderSizePixel=0}, main)
mk("UICorner",{CornerRadius=UDim.new(0,16)}, title)
mk("Frame", {Size=UDim2.new(1,0,0,20), Position=UDim2.new(0,0,1,-20), BackgroundColor3=colors.card, BorderSizePixel=0}, title) -- لإخفاء الزوايا السفلية
mk("TextLabel", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="Derek Hub | Pro Max", Font=Enum.Font.GothamBold, TextSize=16, TextColor3=colors.text}, title)

local closeBtn = mk("TextButton", {Size=UDim2.fromOffset(30,30), Position=UDim2.new(1,-40,0.5,-15), BackgroundColor3=colors.off, Text="✕", TextColor3=colors.text, Font=Enum.Font.GothamBold, BorderSizePixel=0}, title)
mk("UICorner",{CornerRadius=UDim.new(0,8)}, closeBtn)

-- التبويبات
local tabBar = mk("Frame", {Size=UDim2.new(1,-24,0,35), Position=UDim2.new(0,12,0,60), BackgroundTransparency=1}, main)
mk("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,8)}, tabBar)

local tabs = {}
local pages = {}
local function createTab(name)
    local btn = mk("TextButton", {Size=UDim2.new(0,115,1,0), BackgroundColor3=colors.card, Text=name, TextColor3=colors.text, Font=Enum.Font.GothamMedium, TextSize=13, BorderSizePixel=0}, tabBar)
    mk("UICorner",{CornerRadius=UDim.new(0,10)}, btn)
    
    local page = mk("ScrollingFrame", {Size=UDim2.new(1,-24,1,-115), Position=UDim2.new(0,12,0,105), BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=3, ScrollBarImageColor3=colors.accent, CanvasSize=UDim2.new(0,0,0,0), Visible=false}, main)
    mk("UIListLayout", {Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder}, page)
    
    tabs[name] = btn; pages[name] = page
    
    btn.MouseButton1Click:Connect(function()
        for n, p in pairs(pages) do p.Visible = (n == name) end
        for n, b in pairs(tabs) do 
            TweenService:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = (n == name) and colors.accent or colors.card}):Play()
        end
    end)
    return page
end

local autoPage = createTab("Auto Farm")
local espPage = createTab("Eggs List")
local miscPage = createTab("Settings")
tabs["Auto Farm"].BackgroundColor3 = colors.accent
pages["Auto Farm"].Visible = true

-- دوال الواجهة
local function addToggle(page, text, default, callback)
    local row = mk("Frame", {Size=UDim2.new(1,-8,0,45), BackgroundColor3=colors.card}, page)
    mk("UICorner",{CornerRadius=UDim.new(0,10)}, row)
    mk("TextLabel", {Size=UDim2.new(1,-70,1,0), Position=UDim2.new(0,15,0,0), BackgroundTransparency=1, Text=text, TextColor3=colors.text, Font=Enum.Font.GothamMedium, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left}, row)
    
    local sw = mk("Frame", {Size=UDim2.fromOffset(40,22), Position=UDim2.new(1,-55,0.5,-11), BackgroundColor3=default and colors.accent or colors.off}, row)
    mk("UICorner",{CornerRadius=UDim.new(1,0)}, sw)
    local knob = mk("Frame", {Size=UDim2.fromOffset(18,18), Position=UDim2.new(0, default and 20 or 2, 0.5, -9), BackgroundColor3=Color3.new(1,1,1)}, sw)
    mk("UICorner",{CornerRadius=UDim.new(1,0)}, knob)
    
    local state = default
    local btn = mk("TextButton", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text=""}, row)
    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(sw, TweenInfo.new(0.2), {BackgroundColor3 = state and colors.accent or colors.off}):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(0, state and 20 or 2, 0.5, -9)}):Play()
        if callback then pcall(callback, state) end
    end)
end

-- الأوتو فارم (يشتغل بالانتقال الآمن)
local stealing = false
local function startAutoSteal()
    if stealing then return end
    stealing = true
    task.spawn(function()
        while Config.AutoSteal do
            local _, hum, hrp = getChar()
            if hum and hrp and hum.Health > 0 then
                local eggs = getRealEggs()
                if #eggs > 0 then
                    local best, bestDist = nil, math.huge
                    for _, egg in ipairs(eggs) do
                        local d = (egg.pos - hrp.Position).Magnitude
                        if d < bestDist then best, bestDist = egg, d end
                    end
                    
                    if best then
                        stealSpecific(best)
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

addToggle(autoPage, "Auto Steal (Teleport)", false, function(v) Config.AutoSteal = v; if v then startAutoSteal() end end)
addToggle(autoPage, "Use Teleport (تجاوز الجدران)", true, function(v) Config.TeleportSteal = v end)
addToggle(autoPage, "Auto Hatch", false, function(v) Config.AutoHatch = v; if v then 
    task.spawn(function() while Config.AutoHatch do for _,v in pairs(Workspace:GetDescendants()) do if v:IsA("ProximityPrompt") and v.ActionText:lower():find("hatch") then fireproximityprompt(v) end end task.wait(1) end end)
end end)

-- قائمة البيض (تتحدث تلقائياً)
local espElements = {}
task.spawn(function()
    while task.wait(1.5) do
        if not pages["Eggs List"].Visible then continue end
        
        for _, el in pairs(espElements) do el:Destroy() end
        espElements = {}
        
        local currentEggs = getRealEggs()
        
        if #currentEggs == 0 then
            local noEggs = mk("TextLabel", {Size=UDim2.new(1,-8,0,40), BackgroundTransparency=1, Text="No Eggs found nearby.", TextColor3=colors.subtext, Font=Enum.Font.Gotham, TextSize=14}, pages["Eggs List"])
            table.insert(espElements, noEggs)
        else
            for i, egg in ipairs(currentEggs) do
                local row = mk("Frame", {Size=UDim2.new(1,-8,0,60), BackgroundColor3=colors.card}, pages["Eggs List"])
                mk("UICorner",{CornerRadius=UDim.new(0,10)}, row)
                
                -- صورة البيضة
                local img = mk("ImageLabel", {Size=UDim2.fromOffset(45,45), Position=UDim2.new(0,8,0.5,-22), BackgroundColor3=colors.bg, Image=egg.img, ScaleType=Enum.ScaleType.Fit}, row)
                mk("UICorner",{CornerRadius=UDim.new(0,8)}, img)
                
                mk("TextLabel", {Size=UDim2.new(0.5,0,0,20), Position=UDim2.new(0,60,0,10), BackgroundTransparency=1, Text=egg.model.Name, TextColor3=colors.text, Font=Enum.Font.GothamBold, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}, row)
                mk("TextLabel", {Size=UDim2.new(0.5,0,0,20), Position=UDim2.new(0,60,0,30), BackgroundTransparency=1, Text="Value: " .. egg.value, TextColor3=colors.accent, Font=Enum.Font.GothamMedium, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left}, row)
                
                local stealBtn = mk("TextButton", {Size=UDim2.fromOffset(70,32), Position=UDim2.new(1,-80,0.5,-16), BackgroundColor3=colors.accent, Text="Steal", TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, TextSize=12, BorderSizePixel=0}, row)
                mk("UICorner",{CornerRadius=UDim.new(0,8)}, stealBtn)
                
                stealBtn.MouseButton1Click:Connect(function()
                    stealSpecific(egg)
                end)
                
                table.insert(espElements, row)
            end
        end
        pages["Eggs List"].CanvasSize = UDim2.new(0,0,0, #espElements * 68)
    end
end)

-- زر فتح وقفل
local toggleBtn = mk("TextButton", {
    Size=UDim2.fromOffset(60,60), Position=UDim2.new(0,20,0.5,-30),
    BackgroundColor3=colors.accent, Text="D", TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBlack, TextSize=28, BorderSizePixel=0
}, gui)
mk("UICorner",{CornerRadius=UDim.new(1,0)}, toggleBtn)
local btnStroke = mk("UIStroke", {Color=Color3.new(1,1,1), Thickness=2, Transparency=0.5}, toggleBtn)

local isOpen = false
toggleBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    main.Visible = isOpen
    if isOpen then
        TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Size=UDim2.fromOffset(400, 480)}):Play()
    end
end)
closeBtn.MouseButton1Click:Connect(function()
    isOpen = false
    main.Visible = false
end)

-- سحب
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
