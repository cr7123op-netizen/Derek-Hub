--[[ Derek Hub v11.0 — Sniper Edition | Steal An Egg | Author: ALPHA ]]
task.wait(1)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

-- دوال أساسية
local function getChar()
    local c = LP.Character
    return c, c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
end

-- البحث عن البيضات القابلة للسرقة
local function getEggsList()
    local eggs = {}
    local char, hum, hrp = getChar()
    if not hrp then return eggs end

    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and string.lower(prompt.ActionText) == "steal" then
            local model = prompt.Parent
            local pos = (model:IsA("Model") and model:GetPivot().Position) or model.Position
            
            local name = prompt.ObjectText
            if not name or name == "" then name = model.Name end
            
            table.insert(eggs, {
                model = model,
                prompt = prompt,
                pos = pos,
                name = name,
                dist = math.floor((pos - hrp.Position).Magnitude)
            })
        end
    end
    table.sort(eggs, function(a, b) return a.dist < b.dist end)
    return eggs
end

-- ميزة السرقة الفورية (بدون أي تأخير)
local function instantSteal(egg)
    local _, hum, hrp = getChar()
    if not hum or not hrp or not egg.model.Parent then return end
    
    local originalCF = hrp.CFrame
    pcall(function()
        -- 1. الانتقال الفوري للبيضة
        hrp.CFrame = CFrame.new(egg.pos + Vector3.new(0, 2, 0))
        task.wait(0.03) -- تأخير مجهري عشان السيرفر يلتقط الموقع
        -- 2. السرقة
        fireproximityprompt(egg.prompt)
        -- 3. الرجوع الفوري
        hrp.CFrame = originalCF
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
    card = Color3.fromRGB(22, 22, 28),
    accent = Color3.fromRGB(255, 40, 60),
    text = Color3.fromRGB(255, 255, 255),
    subtext = Color3.fromRGB(150, 150, 160),
    off = Color3.fromRGB(45, 45, 55)
}

local uiParent = (gethui and gethui()) or game:GetService("CoreGui") or LP:WaitForChild("PlayerGui")
local gui = mk("ScreenGui", {Name="DerekHub11", ResetOnSpawn=false, IgnoreGuiInset=true, ZIndexBehavior=Enum.ZIndexBehavior.Sibling}, uiParent)

-- زر الفتح (D)
local toggleBtn = mk("TextButton", {
    Size=UDim2.fromOffset(60,60), Position=UDim2.new(0,20,0.5,-30),
    BackgroundColor3=colors.accent, Text="D", TextColor3=colors.text,
    Font=Enum.Font.GothamBlack, TextSize=28, BorderSizePixel=0
}, gui)
mk("UICorner",{CornerRadius=UDim.new(1,0)}, toggleBtn)
mk("UIStroke", {Color=colors.text, Thickness=2, Transparency=0.5}, toggleBtn)

-- اللوحة الرئيسية
local main = mk("Frame", {
    Size=UDim2.fromOffset(360, 450), Position=UDim2.new(0.5,-180,0.5,-225),
    BackgroundColor3=colors.bg, BorderSizePixel=0, Visible=false
}, gui)
mk("UICorner",{CornerRadius=UDim.new(0,16)}, main)
local stroke = mk("UIStroke",{Color=colors.accent, Thickness=1.5}, main)
local grad = mk("UIGradient",{Color=ColorSequence.new{ColorSequenceKeypoint.new(0, colors.accent), ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 0, 255))}, Rotation=45}, stroke)

-- شريط العنوان
local title = mk("Frame", {Size=UDim2.new(1,0,0,50), BackgroundColor3=colors.card, BorderSizePixel=0}, main)
mk("UICorner",{CornerRadius=UDim.new(0,16)}, title)
mk("Frame", {Size=UDim2.new(1,0,0,20), Position=UDim2.new(0,0,1,-20), BackgroundColor3=colors.card, BorderSizePixel=0}, title)
mk("TextLabel", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="Derek Hub | Sniper", Font=Enum.Font.GothamBold, TextSize=16, TextColor3=colors.text}, title)

local closeBtn = mk("TextButton", {Size=UDim2.fromOffset(30,30), Position=UDim2.new(1,-40,0.5,-15), BackgroundColor3=colors.off, Text="✕", TextColor3=colors.text, Font=Enum.Font.GothamBold, BorderSizePixel=0}, title)
mk("UICorner",{CornerRadius=UDim.new(0,8)}, closeBtn)

-- محتوى القائمة
local listFrame = mk("ScrollingFrame", {
    Size=UDim2.new(1,-20,1,-75), Position=UDim2.new(0,10,0,60),
    BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=3, ScrollBarImageColor3=colors.accent,
    CanvasSize=UDim2.new(0,0,0,0)
}, main)
mk("UIListLayout", {Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder}, listFrame)

-- تحديث القائمة تلقائياً كل ثانية
local listItems = {}
task.spawn(function()
    while task.wait(1) do
        if not main.Visible then continue end
        
        -- مسح القائمة القديمة
        for _, item in pairs(listItems) do item:Destroy() end
        listItems = {}
        
        local eggs = getEggsList()
        
        if #eggs == 0 then
            local empty = mk("TextLabel", {Size=UDim2.new(1,-8,0,40), BackgroundTransparency=1, Text="لا توجد حيوانات أو بيض للسرقة حالياً..", TextColor3=colors.subtext, Font=Enum.Font.GothamMedium, TextSize=14}, listFrame)
            table.insert(listItems, empty)
        else
            for _, egg in ipairs(eggs) do
                local row = mk("Frame", {Size=UDim2.new(1,-8,0,60), BackgroundColor3=colors.card}, listFrame)
                mk("UICorner",{CornerRadius=UDim.new(0,10)}, row)
                
                -- اسم الحيوان / البيضة
                mk("TextLabel", {Size=UDim2.new(0.7,0,0,20), Position=UDim2.new(0,12,0,10), BackgroundTransparency=1, Text=egg.name, TextColor3=colors.text, Font=Enum.Font.GothamBold, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}, row)
                -- المسافة
                mk("TextLabel", {Size=UDim2.new(0.7,0,0,20), Position=UDim2.new(0,12,0,30), BackgroundTransparency=1, Text="Distance: "..egg.dist, TextColor3=colors.accent, Font=Enum.Font.GothamMedium, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left}, row)
                
                -- زر السرقة
                local btn = mk("TextButton", {Size=UDim2.fromOffset(70,34), Position=UDim2.new(1,-82,0.5,-17), BackgroundColor3=colors.accent, Text="Steal", TextColor3=colors.text, Font=Enum.Font.GothamBold, TextSize=13, BorderSizePixel=0}, row)
                mk("UICorner",{CornerRadius=UDim.new(0,8)}, btn)
                
                btn.MouseButton1Click:Connect(function()
                    -- تغيير الزر إلى "Done" للحظة
                    btn.Text = "Done"
                    btn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
                    instantSteal(egg)
                    task.wait(1)
                    if btn and btn.Parent then
                        btn.Text = "Steal"
                        btn.BackgroundColor3 = colors.accent
                    end
                end)
                
                table.insert(listItems, row)
            end
        end
        listFrame.CanvasSize = UDim2.new(0,0,0, #listItems * 68)
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
