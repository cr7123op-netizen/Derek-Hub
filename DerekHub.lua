--[[ Derek Hub v14.0 — Ghost Protocol | Steal An Egg | Author: ALPHA ]]
task.wait(1)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

local Config = {
    SpeedEnabled = false,
    SpeedValue = 16,
}

-- دوال أساسية
local function getChar()
    local c = LP.Character
    return c, c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
end

-- جلب الصورة (بحث عميق)
local function getModelImage(model)
    for _, v in ipairs(model:GetDescendants()) do
        if v:IsA("BillboardGui") then
            local img = v:FindFirstChildWhichIsA("ImageLabel", true)
            if img and img.Image ~= "" then return img.Image end
        end
        if v:IsA("ImageLabel") and v.Image ~= "" then return v.Image end
        if v:IsA("Decal") and v.Texture ~= "" then return v.Texture end
        if v:IsA("Texture") and v.Texture ~= "" then return v.Texture end
        if v:IsA("MeshPart") and v.TextureID ~= "" then return v.TextureID end
    end
    return "rbxassetid://13495565986" -- صورة بيضة ذهبية افتراضية
end

-- القوة والترتيب
local function getEggScore(model, name)
    local valObj = model:FindFirstChild("Value") or model:FindFirstChild("Price") or model:FindFirstChildWhichIsA("NumberValue") or model:FindFirstChildWhichIsA("IntValue")
    if valObj then return valObj.Value end
    
    local n = string.lower(name)
    if n:find("mythic") or n:find("secret") or n:find("god") then return 1000000 end
    if n:find("legendary") or n:find("divine") then return 500000 end
    if n:find("epic") then return 100000 end
    if n:find("rare") then return 50000 end
    if n:find("uncommon") then return 10000 end
    return 1000
end

-- جلب القائمة
local function getEggsList()
    local eggs = {}
    local _, _, hrp = getChar()
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
                dist = math.floor((pos - hrp.Position).Magnitude),
                score = getEggScore(model, name),
                image = getModelImage(model)
            })
        end
    end
    table.sort(eggs, function(a, b) return a.score > b.score end)
    return eggs
end

-- السرقة (مع الانتظار للسيرفر)
local function stealEgg(egg, callback)
    local _, hum, hrp = getChar()
    if not hum or not hrp or not egg.model.Parent then return end
    
    local originalCF = hrp.CFrame
    
    -- إيقاف السرعة العالية أثناء السرقة
    local wasSpeedOn = Config.SpeedEnabled
    Config.SpeedEnabled = false
    hum.WalkSpeed = 16
    
    task.spawn(function()
        pcall(function()
            -- الانتقال للبيضة
            hrp.CFrame = CFrame.new(egg.pos + Vector3.new(0, 3, 0))
            -- انتظار السيرفر يتقبل الموقع
            task.wait(0.4)
            -- السرقة
            fireproximityprompt(egg.prompt)
            -- انتظار السيرفر يسجل السرقة
            task.wait(0.4)
            -- الرجوع
            hrp.CFrame = originalCF
        end)
        -- إرجاع السرعة
        Config.SpeedEnabled = wasSpeedOn
        if callback then callback() end
    end)
end

-- السرعة الفيزيائية (تجاوز الحماية)
local speedBodyVel = nil
RunService.RenderStepped:Connect(function()
    local char, hum, hrp = getChar()
    if not hum or not hrp then 
        if speedBodyVel then speedBodyVel:Destroy() speedBodyVel = nil end
        return 
    end

    if Config.SpeedEnabled then
        hum.WalkSpeed = 16 -- نخلي سرعة المشي طبيعية عشان ما ينكشف
        
        if not speedBodyVel or speedBodyVel.Parent ~= hrp then
            if speedBodyVel then speedBodyVel:Destroy() end
            speedBodyVel = Instance.new("BodyVelocity")
            speedBodyVel.Parent = hrp
            speedBodyVel.MaxForce = Vector3.new(1e5, 0, 1e5)
            speedBodyVel.Velocity = Vector3.zero
        end
        
        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0 then
            speedBodyVel.Velocity = moveDir * Config.SpeedValue
        else
            speedBodyVel.Velocity = Vector3.zero
        end
    else
        if speedBodyVel then
            speedBodyVel:Destroy()
            speedBodyVel = nil
        end
    end
end)

-- ==========================================
-- ============ واجهة المستخدم ============
-- ==========================================
local function mk(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

-- الألوان (أحمر + أزرق + سماوي)
local colors = {
    bg = Color3.fromRGB(8, 8, 16),
    card = Color3.fromRGB(16, 16, 30),
    red = Color3.fromRGB(255, 30, 60),
    cyan = Color3.fromRGB(0, 220, 255),
    blue = Color3.fromRGB(50, 100, 255),
    text = Color3.fromRGB(255, 255, 255),
    subtext = Color3.fromRGB(150, 150, 180),
    off = Color3.fromRGB(40, 40, 60)
}

local uiParent = (gethui and gethui()) or game:GetService("CoreGui") or LP:WaitForChild("PlayerGui")
local gui = mk("ScreenGui", {Name="DerekHub14", ResetOnSpawn=false, IgnoreGuiInset=true, ZIndexBehavior=Enum.ZIndexBehavior.Sibling}, uiParent)

-- زر الفتح
local toggleBtn = mk("TextButton", {
    Size=UDim2.fromOffset(60,60), Position=UDim2.new(0,20,0.5,-30),
    BackgroundColor3=colors.red, Text="D", TextColor3=colors.text,
    Font=Enum.Font.GothamBlack, TextSize=28, BorderSizePixel=0
}, gui)
mk("UICorner",{CornerRadius=UDim.new(1,0)}, toggleBtn)
mk("UIStroke", {Color=colors.cyan, Thickness=2}, toggleBtn)

-- اللوحة
local main = mk("Frame", {
    Size=UDim2.fromOffset(380, 500), Position=UDim2.new(0.5,-190,0.5,-250),
    BackgroundColor3=colors.bg, BorderSizePixel=0, Visible=false
}, gui)
mk("UICorner",{CornerRadius=UDim.new(0,16)}, main)
local stroke = mk("UIStroke",{Color=colors.cyan, Thickness=1.5}, main)
local grad = mk("UIGradient",{Color=ColorSequence.new{ColorSequenceKeypoint.new(0, colors.red), ColorSequenceKeypoint.new(1, colors.blue)}, Rotation=45}, stroke)

-- شريط العنوان
local title = mk("Frame", {Size=UDim2.new(1,0,0,50), BackgroundColor3=colors.card, BorderSizePixel=0}, main)
mk("UICorner",{CornerRadius=UDim.new(0,16)}, title)
mk("Frame", {Size=UDim2.new(1,0,0,20), Position=UDim2.new(0,0,1,-20), BackgroundColor3=colors.card, BorderSizePixel=0}, title)
mk("TextLabel", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="Derek Hub | Ghost", Font=Enum.Font.GothamBold, TextSize=16, TextColor3=colors.text}, title)

local closeBtn = mk("TextButton", {Size=UDim2.fromOffset(30,30), Position=UDim2.new(1,-40,0.5,-15), BackgroundColor3=colors.red, Text="✕", TextColor3=colors.text, Font=Enum.Font.GothamBold, BorderSizePixel=0}, title)
mk("UICorner",{CornerRadius=UDim.new(0,8)}, closeBtn)

-- التبويبات
local tabBar = mk("Frame", {Size=UDim2.new(1,-24,0,35), Position=UDim2.new(0,12,0,60), BackgroundTransparency=1}, main)
mk("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,8)}, tabBar)

local tabs, pages = {}, {}
local function createTab(name, isFirst)
    local btn = mk("TextButton", {Size=UDim2.new(0,165,1,0), BackgroundColor3=isFirst and colors.red or colors.card, Text=name, TextColor3=colors.text, Font=Enum.Font.GothamMedium, TextSize=13, BorderSizePixel=0}, tabBar)
    mk("UICorner",{CornerRadius=UDim.new(0,10)}, btn)
    
    local page = mk("ScrollingFrame", {Size=UDim2.new(1,-24,1,-110), Position=UDim2.new(0,12,0,105), BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=3, ScrollBarImageColor3=colors.cyan, CanvasSize=UDim2.new(0,0,0,0), Visible=isFirst}, main)
    mk("UIListLayout", {Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder}, page)
    
    tabs[name] = btn; pages[name] = page
    btn.MouseButton1Click:Connect(function()
        for n, p in pairs(pages) do p.Visible = (n == name) end
        for n, b in pairs(tabs) do 
            TweenService:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = (n == name) and colors.red or colors.card}):Play()
        end
    end)
    return page
end

local eggsPage = createTab("Eggs (الأقوى)", true)
local speedPage = createTab("Speed (السرعة)", false)

-- ===== تبويب البيض =====
local eggElements = {}
task.spawn(function()
    while task.wait(1.5) do
        if not pages["Eggs (الأقوى)"].Visible then continue end
        
        for _, el in pairs(eggElements) do el:Destroy() end
        eggElements = {}
        
        local eggs = getEggsList()
        
        if #eggs == 0 then
            local empty = mk("TextLabel", {Size=UDim2.new(1,-8,0,40), BackgroundTransparency=1, Text="لا توجد بيضات للسرقة حالياً", TextColor3=colors.subtext, Font=Enum.Font.GothamMedium, TextSize=14}, pages["Eggs (الأقوى)"])
            table.insert(eggElements, empty)
        else
            for i, egg in ipairs(eggs) do
                local row = mk("Frame", {Size=UDim2.new(1,-8,0,70), BackgroundColor3=colors.card}, pages["Eggs (الأقوى)"])
                mk("UICorner",{CornerRadius=UDim.new(0,10)}, row)
                mk("UIStroke",{Color=colors.blue, Thickness=1, Transparency=0.5}, row)
                
                local img = mk("ImageLabel", {Size=UDim2.fromOffset(50,50), Position=UDim2.new(0,10,0.5,-25), BackgroundColor3=colors.bg, Image=egg.image, ScaleType=Enum.ScaleType.Crop}, row)
                mk("UICorner",{CornerRadius=UDim.new(0,8)}, img)
                mk("UIStroke",{Color=colors.cyan, Thickness=1.5}, img)
                
                local rankText = "#"..i.." | "..egg.name
                mk("TextLabel", {Size=UDim2.new(0.6,0,0,20), Position=UDim2.new(0,68,0,12), BackgroundTransparency=1, Text=rankText, TextColor3=colors.text, Font=Enum.Font.GothamBold, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}, row)
                mk("TextLabel", {Size=UDim2.new(0.6,0,0,20), Position=UDim2.new(0,68,0,36), BackgroundTransparency=1, Text="Dist: "..egg.dist.." | Score: "..egg.score, TextColor3=colors.cyan, Font=Enum.Font.GothamMedium, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left}, row)
                
                local btn = mk("TextButton", {Size=UDim2.fromOffset(70,36), Position=UDim2.new(1,-80,0.5,-18), BackgroundColor3=colors.blue, Text="Steal", TextColor3=colors.text, Font=Enum.Font.GothamBold, TextSize=13, BorderSizePixel=0}, row)
                mk("UICorner",{CornerRadius=UDim.new(0,8)}, btn)
                
                btn.MouseButton1Click:Connect(function()
                    btn.Text = "Wait..."
                    btn.BackgroundColor3 = colors.red
                    stealEgg(egg, function()
                        if btn and btn.Parent then
                            btn.Text = "Done ✓"
                            task.wait(1)
                            if btn and btn.Parent then
                                btn.Text = "Steal"
                                btn.BackgroundColor3 = colors.blue
                            end
                        end
                    end)
                end)
                
                table.insert(eggElements, row)
            end
        end
        pages["Eggs (الأقوى)"].CanvasSize = UDim2.new(0,0,0, #eggElements * 78)
    end
end)

-- ===== تبويب السرعة =====
local speedRow = mk("Frame", {Size=UDim2.new(1,-8,0,60), BackgroundColor3=colors.card}, pages["Speed (السرعة)"])
mk("UICorner",{CornerRadius=UDim.new(0,10)}, speedRow)
mk("UIStroke",{Color=colors.blue, Thickness=1, Transparency=0.5}, speedRow)

local speedLabel = mk("TextLabel", {Size=UDim2.new(1,-20,0,20), Position=UDim2.new(0,12,0,10), BackgroundTransparency=1, Text="Speed: 16", TextColor3=colors.text, Font=Enum.Font.GothamBold, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left}, speedRow)

local speedToggle = mk("TextButton", {Size=UDim2.fromOffset(80,30), Position=UDim2.new(1,-92,0,8), BackgroundColor3=colors.off, Text="OFF", TextColor3=colors.text, Font=Enum.Font.GothamBold, TextSize=13, BorderSizePixel=0}, speedRow)
mk("UICorner",{CornerRadius=UDim.new(0,8)}, speedToggle)

local sliderBG = mk("Frame", {Size=UDim2.new(1,-24,0,8), Position=UDim2.new(0,12,0,42), BackgroundColor3=colors.off, BorderSizePixel=0}, speedRow)
mk("UICorner",{CornerRadius=UDim.new(1,0)}, sliderBG)
local sliderFill = mk("Frame", {Size=UDim2.new(0,0,1,0), BackgroundColor3=colors.cyan, BorderSizePixel=0}, sliderBG)
mk("UICorner",{CornerRadius=UDim.new(1,0)}, sliderFill)
local sliderKnob = mk("Frame", {Size=UDim2.fromOffset(18,18), Position=UDim2.new(0,-9,0.5,-9), BackgroundColor3=colors.text, BorderSizePixel=0}, sliderBG)
mk("UICorner",{CornerRadius=UDim.new(1,0)}, sliderKnob)

local draggingSlider = false
local function updateSlider(x)
    local rel = math.clamp((x - sliderBG.AbsolutePosition.X) / sliderBG.AbsoluteSize.X, 0, 1)
    local val = math.floor(1 + (1000 - 1) * rel)
    sliderFill.Size = UDim2.new(rel, 0, 1, 0)
    sliderKnob.Position = UDim2.new(rel, -9, 0.5, -9)
    speedLabel.Text = "Speed: " .. val
    Config.SpeedValue = val
end

sliderBG.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = true
        updateSlider(input.Position.X)
    end
end)
UIS.InputChanged:Connect(function(input)
    if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateSlider(input.Position.X)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = false
    end
end)

speedToggle.MouseButton1Click:Connect(function()
    Config.SpeedEnabled = not Config.SpeedEnabled
    if Config.SpeedEnabled then
        speedToggle.Text = "ON"
        speedToggle.BackgroundColor3 = colors.red
    else
        speedToggle.Text = "OFF"
        speedToggle.BackgroundColor3 = colors.off
        local _, hum = getChar()
        if hum then hum.WalkSpeed = 16 end
    end
end)

-- فتح/قفل
local isOpen = false
toggleBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    main.Visible = isOpen
end)
closeBtn.MouseButton1Click:Connect(function()
    isOpen = false
    main.Visible = false
end)

-- سحب اللوحة
local drag1, start1, pos1
title.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        drag1 = true; start1 = i.Position; pos1 = main.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if drag1 and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = i.Position - start1
        main.Position = UDim2.new(pos1.X.Scale, pos1.X.Offset + d.X, pos1.Y.Scale, pos1.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then drag1 = false end
end)

-- سحب الزر
local drag2, start2, pos2
toggleBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        drag2 = true; start2 = i.Position; pos2 = toggleBtn.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if drag2 and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = i.Position - start2
        toggleBtn.Position = UDim2.new(pos2.X.Scale, pos2.X.Offset + d.X, pos2.Y.Scale, pos2.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then drag2 = false end
end)
