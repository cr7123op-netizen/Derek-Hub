--[[ Derek Hub v10.0 — God Tier Edition | Steal An Egg | Author: ALPHA ]]
task.wait(1)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

local Config = {
    AutoSteal = false,
    InstantGrab = true,
    ESP = false,
    StealDelay = 0.3
}

-- ==========================================
-- ============ دوال مساعدة =============
-- ==========================================
local function getChar()
    local c = LP.Character
    return c, c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
end

-- البحث عن البيض وقراءة بياناته الحقيقية
local function getRealEggs()
    local eggs = {}
    local char, hum, hrp = getChar()
    if not hrp then return eggs end

    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and string.lower(prompt.ActionText) == "steal" then
            local model = prompt.Parent
            local pos = (model:IsA("Model") and model:GetPivot().Position) or model.Position
            
            -- جلب الاسم الحقيقي
            local realName = prompt.ObjectText
            if not realName or realName == "" then
                realName = model.Name
            end

            -- جلب السعر الحقيقي (يبحث عن Value أو Price داخل المودل)
            local price = "???"
            local valObj = model:FindFirstChild("Value") or model:FindFirstChild("Price") or model:FindFirstChildWhichIsA("NumberValue")
            if valObj then
                price = tostring(valObj.Value)
            else
                -- محاولة قراءة السعر من النص إذا كان مكتوب
                local match = string.match(realName, "%$(%d+)")
                if match then price = match end
            end

            table.insert(eggs, {
                model = model,
                prompt = prompt,
                pos = pos,
                name = realName,
                price = price,
                dist = math.floor((pos - hrp.Position).Magnitude)
            })
        end
    end
    -- ترتيب من الأقرب للأبعد
    table.sort(eggs, function(a, b) return a.dist < b.dist end)
    return eggs
end

-- سرقة فورية (الانتقال والرجوع)
local function stealEgg(egg)
    local _, hum, hrp = getChar()
    if not hum or not hrp or not egg.model.Parent then return end
    
    local oldCF = hrp.CFrame
    pcall(function()
        hrp.CFrame = CFrame.new(egg.pos + Vector3.new(0, 2, 0))
        task.wait(0.1)
        fireproximityprompt(egg.prompt)
        task.wait(0.1)
        hrp.CFrame = oldCF
    end)
end

-- ==========================================
-- ============ واجهة المستخدم ============
-- ==========================================
local function mk(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local colors = {
    bg = Color3.fromRGB(10, 10, 12),
    card = Color3.fromRGB(20, 20, 25),
    accent = Color3.fromRGB(255, 30, 60),
    text = Color3.fromRGB(255, 255, 255),
    subtext = Color3.fromRGB(170, 170, 180),
    off = Color3.fromRGB(40, 40, 48)
}

local uiParent = (gethui and gethui()) or game:GetService("CoreGui") or LP:WaitForChild("PlayerGui")
local gui = mk("ScreenGui", {Name="DerekHub10", ResetOnSpawn=false, IgnoreGuiInset=true, ZIndexBehavior=Enum.ZIndexBehavior.Sibling}, uiParent)

-- زر الفتح
local toggleBtn = mk("TextButton", {
    Size=UDim2.fromOffset(60,60), Position=UDim2.new(0,20,0.5,-30),
    BackgroundColor3=colors.accent, Text="D", TextColor3=colors.text,
    Font=Enum.Font.GothamBlack, TextSize=28, BorderSizePixel=0
}, gui)
mk("UICorner",{CornerRadius=UDim.new(1,0)}, toggleBtn)
mk("UIStroke", {Color=colors.text, Thickness=2, Transparency=0.5}, toggleBtn)

-- اللوحة الرئيسية
local main = mk("Frame", {
    Size=UDim2.fromOffset(380, 480), Position=UDim2.new(0.5,-190,0.5,-240),
    BackgroundColor3=colors.bg, BorderSizePixel=0, Visible=false
}, gui)
mk("UICorner",{CornerRadius=UDim.new(0,16)}, main)
local stroke = mk("UIStroke",{Color=colors.accent, Thickness=1.5, Transparency=0.3}, main)
local grad = mk("UIGradient",{Color=ColorSequence.new{ColorSequenceKeypoint.new(0, colors.accent), ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 0, 255))}, Rotation=45}, stroke)

-- شريط العنوان
local title = mk("Frame", {Size=UDim2.new(1,0,0,50), BackgroundColor3=colors.card, BorderSizePixel=0}, main)
mk("UICorner",{CornerRadius=UDim.new(0,16)}, title)
mk("Frame", {Size=UDim2.new(1,0,0,20), Position=UDim2.new(0,0,1,-20), BackgroundColor3=colors.card, BorderSizePixel=0}, title)
mk("TextLabel", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="Derek Hub | v10.0", Font=Enum.Font.GothamBold, TextSize=16, TextColor3=colors.text}, title)

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

local autoPage = createTab("Auto")
local espPage = createTab("Eggs List")
tabs["Auto"].BackgroundColor3 = colors.accent
pages["Auto"].Visible = true

-- دالة إضافة Toggle
local function addToggle(page, text, default, callback)
    local row = mk("Frame", {Size=UDim2.new(1,-8,0,45), BackgroundColor3=colors.card}, page)
    mk("UICorner",{CornerRadius=UDim.new(0,10)}, row)
    mk("TextLabel", {Size=UDim2.new(1,-70,1,0), Position=UDim2.new(0,15,0,0), BackgroundTransparency=1, Text=text, TextColor3=colors.text, Font=Enum.Font.GothamMedium, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left}, row)
    
    local sw = mk("Frame", {Size=UDim2.fromOffset(40,22), Position=UDim2.new(1,-55,0.5,-11), BackgroundColor3=default and colors.accent or colors.off}, row)
    mk("UICorner",{CornerRadius=UDim.new(1,0)}, sw)
    local knob = mk("Frame", {Size=UDim2.fromOffset(18,18), Position=UDim2.new(0, default and 20 or 2, 0.5, -9), BackgroundColor3=colors.text}, sw)
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

-- الأوتو فارم
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
                    stealEgg(eggs[1])
                    task.wait(Config.StealDelay)
                else
                    task.wait(0.5)
                end
            else
                task.wait(1)
            end
        end
        stealing = false
    end)
end

addToggle(autoPage, "Auto Steal", false, function(v) Config.AutoSteal = v; if v then startAutoSteal() end end)
addToggle(autoPage, "Auto Hatch (فقس)", false, function(v) 
    Config.AutoHatch = v
    if v then
        task.spawn(function() 
            while Config.AutoHatch do 
                for _,v in pairs(Workspace:GetDescendants()) do 
                    if v:IsA("ProximityPrompt") and string.lower(v.ActionText):find("hatch") then 
                        pcall(function() fireproximityprompt(v) end)
                    end 
                end 
                task.wait(1) 
            end
        end)
    end
end)

-- تحديث قائمة البيض
local espElements = {}
task.spawn(function()
    while task.wait(1.5) do
        if not pages["Eggs List"].Visible then continue end
        
        for _, el in pairs(espElements) do el:Destroy() end
        espElements = {}
        
        local currentEggs = getRealEggs()
        
        if #currentEggs == 0 then
            local noEggs = mk("TextLabel", {Size=UDim2.new(1,-8,0,40), BackgroundTransparency=1, Text="لا يوجد بيض للسرقة حالياً", TextColor3=colors.subtext, Font=Enum.Font.Gotham, TextSize=14}, pages["Eggs List"])
            table.insert(espElements, noEggs)
        else
            for i, egg in ipairs(currentEggs) do
                local row = mk("Frame", {Size=UDim2.new(1,-8,0,60), BackgroundColor3=colors.card}, pages["Eggs List"])
                mk("UICorner",{CornerRadius=UDim.new(0,10)}, row)
                
                mk("TextLabel", {Size=UDim2.new(0.6,0,0,20), Position=UDim2.new(0,12,0,10), BackgroundTransparency=1, Text=egg.name, TextColor3=colors.text, Font=Enum.Font.GothamBold, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}, row)
                mk("TextLabel", {Size=UDim2.new(0.6,0,0,20), Position=UDim2.new(0,12,0,30), BackgroundTransparency=1, Text="Value: "..egg.price.." | Dist: "..egg.dist, TextColor3=colors.accent, Font=Enum.Font.GothamMedium, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left}, row)
                
                local stealBtn = mk("TextButton", {Size=UDim2.fromOffset(70,32), Position=UDim2.new(1,-80,0.5,-16), BackgroundColor3=colors.accent, Text="Steal", TextColor3=colors.text, Font=Enum.Font.GothamBold, TextSize=12, BorderSizePixel=0}, row)
                mk("UICorner",{CornerRadius=UDim.new(0,8)}, stealBtn)
                
                stealBtn.MouseButton1Click:Connect(function()
                    stealEgg(egg)
                end)
                
                table.insert(espElements, row)
            end
        end
        pages["Eggs List"].CanvasSize = UDim2.new(0,0,0, #espElements * 68)
    end
end)

-- فتح/قفل اللوحة
local isOpen = false
toggleBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    main.Visible = isOpen
end)
closeBtn.MouseButton1Click:Connect(function()
    isOpen = false
    main.Visible = false
end)

-- سحب الواجهة
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

-- سحب زر الفتح
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
