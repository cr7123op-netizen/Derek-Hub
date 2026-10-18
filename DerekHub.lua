--[[ Ouroboros | Steal An Egg | Open Source ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- إعدادات
local AutoSteal = false
local AutoHatch = false
local AutoButterfly = false
local Speed = 16
local Fly = false

-- دوال مساعدة
local function getChar()
    local char = LocalPlayer.Character
    return char, char and char:FindFirstChild("Humanoid"), char and char:FindFirstChild("HumanoidRootPart")
end

-- تعطيل الحماية (Anti-Cheat Bypass)
task.spawn(function()
    if getconnections then
        for _, conn in pairs(getconnections(LocalPlayer.CharacterAdded)) do
            local ok, src = pcall(debug.info, conn.Function, "s")
            if ok and type(src) == "string" and (src:find("Anti") or src:find("Kick") or src:find("Detect")) then
                pcall(function() conn:Disconnect() end)
            end
        end
    end
    -- منع الطرد
    if hookfunction and getrawmetatable then
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "Kick" then return nil end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end
end)

-- جلب البيض
local function getEggs()
    local eggs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and string.lower(obj.ActionText) == "steal" then
            local model = obj.Parent
            local pos = model:IsA("Model") and model:GetPivot().Position or model.Position
            table.insert(eggs, {model = model, prompt = obj, pos = pos, name = model.Name})
        end
    end
    return eggs
end

-- السرقة
local function stealEgg(egg)
    local char, hum, hrp = getChar()
    if not hum or not hrp or not egg.model.Parent then return end
    
    local oldCF = hrp.CFrame
    pcall(function()
        hrp.CFrame = CFrame.new(egg.pos + Vector3.new(0, 3, 0))
        task.wait(0.35)
        fireproximityprompt(egg.prompt)
        task.wait(0.35)
        hrp.CFrame = oldCF
    end)
end

-- واجهة
local function mk(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local gui = mk("ScreenGui", {Name="Ouroboros", ResetOnSpawn=false}, LocalPlayer:WaitForChild("PlayerGui"))

local btn = mk("TextButton", {Size=UDim2.fromOffset(50,50), Position=UDim2.new(0,20,0.5,0), BackgroundColor3=Color3.fromRGB(255,30,30), Text="O", TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBlack, TextSize=24}, gui)
mk("UICorner",{CornerRadius=UDim.new(1,0)}, btn)

local main = mk("Frame", {Size=UDim2.fromOffset(300,400), Position=UDim2.new(0.5,-150,0.5,-200), BackgroundColor3=Color3.fromRGB(20,20,25), Visible=false}, gui)
mk("UICorner",{CornerRadius=UDim.new(0,10)}, main)

local close = mk("TextButton", {Size=UDim2.fromOffset(30,30), Position=UDim2.new(1,-35,0,5), BackgroundColor3=Color3.fromRGB(255,30,30), Text="X", TextColor3=Color3.new(1,1,1)}, main)
mk("UICorner",{CornerRadius=UDim.new(0,6)}, close)

local eggsList = mk("ScrollingFrame", {Size=UDim2.new(1,-10,1,-50), Position=UDim2.new(0,5,0,40), BackgroundTransparency=1, CanvasSize=UDim2.new(0,0,0,0)}, main)
mk("UIListLayout", {Padding=UDim.new(0,5)}, eggsList)

btn.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)
close.MouseButton1Click:Connect(function() main.Visible = false end)

-- تحديث القائمة
task.spawn(function()
    while task.wait(1) do
        if main.Visible then
            for _, v in ipairs(eggsList:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
            local eggs = getEggs()
            for i, egg in ipairs(eggs) do
                local b = mk("TextButton", {Size=UDim2.new(1,0,0,40), BackgroundColor3=Color3.fromRGB(30,30,35), Text=egg.name, TextColor3=Color3.new(1,1,1), Font=Enum.Font.Gotham, TextSize=12}, eggsList)
                mk("UICorner",{CornerRadius=UDim.new(0,6)}, b)
                b.MouseButton1Click:Connect(function() stealEgg(egg) end)
            end
            eggsList.CanvasSize = UDim2.new(0,0,0, #eggs * 45)
        end
    end
end)
