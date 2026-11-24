--[[
BALL KUN HUB • MAHANAKHON v3.0
Client-side companion UI for PlaceId 104549080643413
Designed for Roblox Studio / an experience you own or are authorized to test.
This script does NOT invoke game remotes, bypass server checks, automate rewards,
or spoof job/race completion. Native game actions remain in the game's own UI.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local PLACE_ID = 104549080643413
-- อัปโหลดภาพพื้นหลังขึ้น Roblox แล้วใส่ Asset ID ที่นี่
local BACKGROUND_IMAGE = "rbxassetid://0"
if game.PlaceId ~= PLACE_ID then
    warn("[MAHANAKHON HUB] PlaceId mismatch. Expected:", PLACE_ID, "Got:", game.PlaceId)
end

local old = PlayerGui:FindFirstChild("MahanakhonHubV2")
if old then old:Destroy() end

local Theme = {
    bg = Color3.fromRGB(3, 12, 5),
    panel = Color3.fromRGB(5, 22, 10),
    panel2 = Color3.fromRGB(10, 42, 18),
    line = Color3.fromRGB(25, 210, 55),
    text = Color3.fromRGB(235, 242, 250),
    muted = Color3.fromRGB(145, 160, 180),
    accent = Color3.fromRGB(35, 255, 30),
    accent2 = Color3.fromRGB(0, 220, 150),
    danger = Color3.fromRGB(238, 86, 100),
    good = Color3.fromRGB(85, 205, 145),
}
local FONT = Enum.Font.Gotham
local State = {
    tab = "Overview",
    promptESP = false,
    vehicleESP = false,
    jobESP = false,
    miniStatus = true,
    scanBusy = false,
    highlights = {},
    waypoint = nil,
    lastScan = 0,
}
local Connections = {}

local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Connections, c)
    return c
end

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local loadingGui = make("ScreenGui", {
    Name = "BallKunLoading",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999,
}, PlayerGui)
local loading = make("Frame", {
    Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(2, 8, 3),
    BorderSizePixel = 0,
}, loadingGui)
local loadingTitle = make("TextLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.43),
    Size = UDim2.new(0.9, 0, 0, 58), BackgroundTransparency = 1,
    Text = "BALL KUN HUB", TextColor3 = Color3.fromRGB(35,255,30),
    Font = Enum.Font.GothamBlack, TextSize = 34,
}, loading)
make("TextLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.53),
    Size = UDim2.new(0.9, 0, 0, 34), BackgroundTransparency = 1,
    Text = "รอก่อนไอสลัด", TextColor3 = Color3.fromRGB(245,245,245),
    Font = Enum.Font.GothamBold, TextSize = 20,
}, loading)

-- Build the main interface under xpcall so an initialization error is visible
-- instead of leaving the loading screen stuck forever.
local loadingDetail

task.delay(15, function()
    if loadingGui and loadingGui.Parent then
        warn("[BALL KUN HUB] Loading watchdog: UI did not finish within 15 seconds.")
        loadingTitle.Text = "BALL KUN HUB - TIMEOUT"
        if loadingDetail then
            loadingDetail.Text = "ระบบเริ่มต้นนานเกินไป กรุณาตรวจสอบ Output ใน Roblox Studio"
        end
        task.delay(8, function()
            if loadingGui and loadingGui.Parent then loadingGui:Destroy() end
        end)
    end
end)

loadingDetail = make("TextLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.60),
    Size = UDim2.new(0.9, 0, 0, 54), BackgroundTransparency = 1,
    Text = "กำลังเริ่มต้นระบบ...", TextColor3 = Color3.fromRGB(180, 220, 180),
    Font = Enum.Font.Gotham, TextSize = 13, TextWrapped = true,
}, loading)

local buildOK, buildError = xpcall(function()
local gui = make("ScreenGui", {
    Name = "MahanakhonHubV2",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)

local root = make("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(760, 510),
    BackgroundColor3 = Theme.bg,
    BorderSizePixel = 0,
}, gui)
make("UICorner", {CornerRadius = UDim.new(0, 14)}, root)
make("UIStroke", {Color = Theme.line, Thickness = 1}, root)
local backgroundArt = make("ImageLabel", {
    Name = "BALLKUN_Background",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Image = BACKGROUND_IMAGE,
    ImageTransparency = 0.48,
    ScaleType = Enum.ScaleType.Crop,
    ZIndex = 0,
}, root)
make("UICorner", {CornerRadius = UDim.new(0, 14)}, backgroundArt)
local scale = make("UIScale", {Scale = 1}, root)
local side, content, brand, subtitle

local function updateScale()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local v = cam.ViewportSize
    if v.X < 650 then
        root.Size = UDim2.new(0.96, 0, 0.86, 0)
        scale.Scale = 1
        if side then side.Position = UDim2.fromOffset(8, 70); side.Size = UDim2.new(0, 112, 1, -80) end
        if content then content.Position = UDim2.fromOffset(128, 70); content.Size = UDim2.new(1, -136, 1, -80) end
        if brand then brand.TextSize = 13 end
        if subtitle then subtitle.TextSize = 8 end
    else
        root.Size = UDim2.fromOffset(760, 510)
        scale.Scale = math.clamp(math.min(v.X / 900, v.Y / 650), 0.72, 1)
        if side then side.Position = UDim2.fromOffset(12, 72); side.Size = UDim2.new(0, 164, 1, -86) end
        if content then content.Position = UDim2.fromOffset(188, 72); content.Size = UDim2.new(1, -200, 1, -86) end
        if brand then brand.TextSize = 17 end
        if subtitle then subtitle.TextSize = 9 end
    end
end
updateScale()
connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), function()
    local cam = Workspace.CurrentCamera
    if cam then
        connect(cam:GetPropertyChangedSignal("ViewportSize"), updateScale)
    end
    updateScale()
end)
if Workspace.CurrentCamera then
    connect(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), updateScale)
end

local top = make("Frame", {
    Size = UDim2.new(1, 0, 0, 58),
    BackgroundColor3 = Theme.panel,
    BorderSizePixel = 0,
}, root)
make("UICorner", {CornerRadius = UDim.new(0, 14)}, top)
make("Frame", {
    Position = UDim2.new(0, 0, 1, -14),
    Size = UDim2.new(1, 0, 0, 14),
    BackgroundColor3 = Theme.panel,
    BorderSizePixel = 0,
}, top)

brand = make("TextLabel", {
    Position = UDim2.fromOffset(20, 8),
    Size = UDim2.fromOffset(260, 23),
    BackgroundTransparency = 1,
    Text = "BALL KUN  /  มหานคร",
    TextColor3 = Theme.text,
    Font = Enum.Font.GothamBold,
    TextSize = 17,
    TextXAlignment = Enum.TextXAlignment.Left,
}, top)
subtitle = make("TextLabel", {
    Position = UDim2.fromOffset(21, 31),
    Size = UDim2.fromOffset(300, 16),
    BackgroundTransparency = 1,
    Text = "บอลคุง ไงหนู  •  รุ่นทดลอง",
    TextColor3 = Theme.muted,
    Font = FONT,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
}, top)

local close = make("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -14, 0.5, 0),
    Size = UDim2.fromOffset(34, 32),
    BackgroundColor3 = Color3.fromRGB(55, 35, 45),
    Text = "×",
    TextColor3 = Theme.text,
    Font = FONT,
    TextSize = 22,
    AutoButtonColor = true,
}, top)
make("UICorner", {CornerRadius = UDim.new(0, 8)}, close)

side = make("ScrollingFrame", {
    Position = UDim2.fromOffset(12, 72),
    Size = UDim2.new(0, 164, 1, -86),
    BackgroundColor3 = Theme.panel,
    BorderSizePixel = 0,
}, root)
make("UICorner", {CornerRadius = UDim.new(0, 10)}, side)
local sideLayout = make("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, side)
make("UIPadding", {
    PaddingTop = UDim.new(0, 12),
    PaddingLeft = UDim.new(0, 9),
    PaddingRight = UDim.new(0, 9),
}, side)

content = make("Frame", {
    Position = UDim2.fromOffset(188, 72),
    Size = UDim2.new(1, -200, 1, -86),
    BackgroundTransparency = 1,
}, root)

local pageTitle = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundTransparency = 1,
    Text = "ภาพรวม",
    TextColor3 = Theme.text,
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextXAlignment = Enum.TextXAlignment.Left,
}, content)
local pageDesc = make("TextLabel", {
    Position = UDim2.fromOffset(0, 30),
    Size = UDim2.new(1, 0, 0, 20),
    BackgroundTransparency = 1,
    Text = "สถานะเกมและเครื่องมือหลัก",
    TextColor3 = Theme.muted,
    Font = FONT,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
}, content)
local pageBody = make("ScrollingFrame", {
    Position = UDim2.fromOffset(0, 58),
    Size = UDim2.new(1, 0, 1, -58),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Theme.accent,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, content)
make("UIListLayout", {
    Padding = UDim.new(0, 9),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, pageBody)

local function clearPage()
    for _, child in ipairs(pageBody:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end
end

local function card(title, desc)
    local f = make("Frame", {
        Size = UDim2.new(1, -6, 0, 76),
        BackgroundColor3 = Theme.panel,
        BorderSizePixel = 0,
    }, pageBody)
    make("UICorner", {CornerRadius = UDim.new(0, 9)}, f)
    make("UIStroke", {Color = Theme.line, Thickness = 1}, f)
    make("TextLabel", {
        Position = UDim2.fromOffset(13, 9),
        Size = UDim2.new(1, -26, 0, 21),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, f)
    make("TextLabel", {
        Position = UDim2.fromOffset(13, 33),
        Size = UDim2.new(1, -26, 0, 34),
        BackgroundTransparency = 1,
        Text = desc,
        TextColor3 = Theme.muted,
        Font = FONT,
        TextSize = 10,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, f)
    return f
end

local function button(parent, label, callback, width)
    local b = make("TextButton", {
        Size = UDim2.fromOffset(width or 120, 30),
        BackgroundColor3 = Theme.panel2,
        Text = label,
        TextColor3 = Theme.text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 10,
        AutoButtonColor = true,
    }, parent)
    make("UICorner", {CornerRadius = UDim.new(0, 7)}, b)
    make("UIStroke", {Color = Theme.line, Thickness = 1}, b)
    connect(b.Activated, callback)
    return b
end

local function rowCard(title, desc, actionText, callback)
    local f = card(title, desc)
    local b = button(f, actionText, callback, 112)
    b.AnchorPoint = Vector2.new(1, 1)
    b.Position = UDim2.new(1, -10, 1, -9)
    return f, b
end

local function setStatus(text)
    subtitle.Text = "บอลคุง ไงหนู  •  " .. tostring(text)
end

local function getCharacter()
    return LocalPlayer.Character
end

local function getRootPart()
    local ch = getCharacter()
    return ch and ch:FindFirstChild("HumanoidRootPart")
end

local function countDescendants(rootObj, predicate)
    local n = 0
    for _, obj in ipairs(rootObj:GetDescendants()) do
        if predicate(obj) then n += 1 end
    end
    return n
end

local function removeHighlights(prefix)
    for obj, h in pairs(State.highlights) do
        if h and h.Parent and (not prefix or h.Name:sub(1, #prefix) == prefix) then
            h:Destroy()
            State.highlights[obj] = nil
        end
    end
end

local function addHighlight(obj, name, color)
    if not obj or not obj.Parent or State.highlights[obj] then return end
    if obj:IsA("Attachment") then obj = obj.Parent end
    if not obj or not (obj:IsA("BasePart") or obj:IsA("Model")) then return end
    local h = Instance.new("Highlight")
    h.Name = name
    h.Adornee = obj
    h.FillColor = color
    h.OutlineColor = color
    h.FillTransparency = 0.78
    h.OutlineTransparency = 0.08
    h.DepthMode = Enum.HighlightDepthMode.Occluded
    h.Parent = gui
    State.highlights[obj] = h
end

local function clearWaypoint()
    if State.waypoint then State.waypoint:Destroy() State.waypoint = nil end
end

local function markWaypoint(part, label)
    clearWaypoint()
    if not part then return end
    local a = Instance.new("BillboardGui")
    a.Name = "LocalWaypoint"
    a.Size = UDim2.fromOffset(150, 36)
    a.StudsOffset = Vector3.new(0, 3, 0)
    a.AlwaysOnTop = true
    a.Adornee = part
    a.Parent = gui
    local t = make("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.bg,
        BackgroundTransparency = 0.12,
        Text = "◆  " .. label,
        TextColor3 = Theme.accent,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
    }, a)
    make("UICorner", {CornerRadius = UDim.new(0, 8)}, t)
    State.waypoint = a
end

local function scanWorld()
    if State.scanBusy then return nil end
    State.scanBusy = true
    local result = {prompts = {}, vehicles = {}, jobs = {}, landmarks = {}}
    local ok, err = pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                table.insert(result.prompts, obj)
                local p = obj.Parent
                local path = p and p:GetFullName() or ""
                local low = string.lower(path .. " " .. obj.Name)
                if string.find(low, "job") or string.find(low, "delivery") or string.find(low, "rider") then
                    table.insert(result.jobs, obj)
                end
            elseif obj:IsA("VehicleSeat") or obj:IsA("Seat") then
                local p = obj.Parent
                if p and (string.find(string.lower(p:GetFullName()), "vehicle") or string.find(string.lower(p.Name), "car") or string.find(string.lower(p.Name), "bike")) then
                    table.insert(result.vehicles, p)
                end
            end
        end
    end)
    State.scanBusy = false
    if not ok then warn("[MAHANAKHON HUB] scan error:", err) end
    State.lastScan = os.clock()
    return result
end

local function nearestPrompt()
    local hrp = getRootPart()
    if not hrp then return nil end
    local best, bestDist
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local part = obj.Parent
            if part and part:IsA("Attachment") then part = part.Parent end
            if part and part:IsA("BasePart") then
                local d = (hrp.Position - part.Position).Magnitude
                if not bestDist or d < bestDist then best, bestDist = obj, d end
            end
        end
    end
    return best, bestDist
end

local function makeToggle(parent, title, desc, initial, changed)
    local f = card(title, desc)
    local b
    b = button(f, initial and "เปิด" or "ปิด", function()
        initial = not initial
        b.Text = initial and "เปิด" or "ปิด"
        b.BackgroundColor3 = initial and Theme.accent or Theme.panel2
        changed(initial)
    end, 72)
    b.AnchorPoint = Vector2.new(1, 1)
    b.Position = UDim2.new(1, -10, 1, -9)
    b.BackgroundColor3 = initial and Theme.accent or Theme.panel2
    return b
end

local function renderOverview()
    clearPage()
    local avatarCard = make("Frame", {
        Size = UDim2.new(1, -6, 0, 154),
        BackgroundColor3 = Theme.panel,
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
    }, pageBody)
    make("UICorner", {CornerRadius = UDim.new(0, 10)}, avatarCard)
    make("UIStroke", {Color = Theme.accent, Thickness = 1}, avatarCard)
    make("TextLabel", {
        Position = UDim2.fromOffset(12, 9), Size = UDim2.new(1, -24, 0, 20),
        BackgroundTransparency = 1, Text = "👤 ตัวละครผู้เล่น 3 มิติ",
        TextColor3 = Theme.text, Font = Enum.Font.GothamBold, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, avatarCard)
    local viewport = make("ViewportFrame", {
        Position = UDim2.new(0.5, -53, 0, 32), Size = UDim2.fromOffset(106, 112),
        BackgroundColor3 = Theme.panel2, BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
    }, avatarCard)
    make("UICorner", {CornerRadius = UDim.new(0, 8)}, viewport)
    local avatar = getCharacter()
    if avatar then
        local clone = avatar:Clone()
        for _, item in ipairs(clone:GetDescendants()) do
            if item:IsA("Script") or item:IsA("LocalScript") then item:Destroy() end
        end
        clone.Parent = viewport
        local world = Instance.new("WorldModel")
        world.Parent = viewport
        clone.Parent = world
        local rootPart = clone:FindFirstChild("HumanoidRootPart")
        if rootPart then
            clone:PivotTo(CFrame.new(0, 0, 0))
            local cam = Instance.new("Camera")
            cam.CFrame = CFrame.new(Vector3.new(0, 2.2, 6), Vector3.new(0, 1.5, 0))
            cam.Parent = viewport
            viewport.CurrentCamera = cam
        end
    end
    local ch = getCharacter()
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    local hrp = getRootPart()
    local pos = hrp and hrp.Position
    card("👤 สถานะผู้เล่น", string.format(
        "Player: %s  |  Health: %s  |  Speed: %s\nPosition: %s",
        LocalPlayer.Name,
        hum and math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) or "N/A",
        hum and math.floor(hum.WalkSpeed) or "N/A",
        pos and string.format("%.0f, %.0f, %.0f", pos.X, pos.Y, pos.Z) or "N/A"
    ))
    rowCard("🔎 สำรวจโลก", "ตรวจหาจุดกด งาน และเบาะยานพาหนะที่มองเห็นได้", "สแกน", function()
        local r = scanWorld()
        if r then
            setStatus(string.format("SCAN %d PROMPTS / %d VEHICLE SEATS", #r.prompts, #r.vehicles))
            renderOverview()
        end
    end)
    rowCard("📍 จุดกดที่ใกล้ที่สุด", "ปักหมุดจุดกดที่อยู่ใกล้ที่สุด โดยไม่กดใช้งานแทนผู้เล่น", "ปักหมุด", function()
        local p, d = nearestPrompt()
        if p then
            local part = p.Parent
            if part and part:IsA("Attachment") then part = part.Parent end
            if part and part:IsA("BasePart") then markWaypoint(part, p.ActionText ~= "" and p.ActionText or p.Name) end
            setStatus("NEAREST PROMPT " .. math.floor(d or 0) .. " STUDS")
        else
            setStatus("NO PROMPT FOUND")
        end
    end)
    rowCard("🧹 ล้างหมุด", "ลบหมุดที่สร้างไว้บนหน้าจอ", "ล้าง", function()
        clearWaypoint()
        setStatus("MARKER CLEARED")
    end)
    card("🧩 ระบบที่ตรวจพบ", "ตรวจพบหมวดงานส่งของ งานทั่วไป แข่งขัน โรงรถ แต่งรถ ECU ดูแลรถ สินค้า ลูกสูบ ป้าย หมวก ไดโน แผนที่ ภารกิจ และรางวัล ฮับนี้อ่านข้อมูลที่เครื่องมองเห็นเท่านั้น")
end

local function renderJobs()
    clearPage()
    card("📦 งานและส่งของ", "ไฟล์สำรวจเกมพบระบบส่งของและงานต่าง ๆ การเริ่ม รับ หรือส่งงานให้ดำเนินการผ่านหน้าจอเกมตามปกติ")
    rowCard("📱 แอปส่งของ", "ตรวจหาแอปส่งของจากหน้าจอโทรศัพท์ในเกม", "ค้นหาแอป", function()
        local phone = PlayerGui:FindFirstChild("Phone")
        local app = phone and phone:FindFirstChild("Dock", true)
        local delivery = app and app:FindFirstChild("delivery", true)
        if delivery and delivery:IsA("GuiButton") then
            setStatus("DELIVERY APP FOUND")
            delivery:CaptureFocus()
        else
            setStatus("OPEN PHONE UI MANUALLY")
        end
    end)
    rowCard("📦 ตู้รับงาน", "ค้นหาและปักหมุดตำแหน่งตู้รับงานเมื่อโหลดเข้ามาแล้ว", "ค้นหาตู้", function()
        local root = Workspace:FindFirstChild("Map")
        local locker = root and root:FindFirstChild("JobLockers", true)
        local prompt = locker and locker:FindFirstChild("LockerPrompt", true)
        local part = prompt and prompt.Parent
        if part and part:IsA("Attachment") then part = part.Parent end
        if part and part:IsA("BasePart") then
            markWaypoint(part, "DELIVERY LOCKER")
            setStatus("LOCKER FOUND")
        else
            setStatus("LOCKER NOT STREAMED")
        end
    end)
    rowCard("📋 สถานะงานส่งของ", "อ่านข้อมูลสถานะงานที่เครื่องมองเห็นได้", "รีเฟรช", function()
        local found = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "DeliveryState" or obj.Name == "DeliveryJob" or obj.Name == "DeliveryArrived" then
                table.insert(found, obj:GetFullName() .. " = " .. tostring(obj.Value or obj:GetAttribute("Value") or "present"))
            end
        end
        setStatus(#found > 0 and ("FOUND " .. #found .. " STATE OBJECTS") or "STATE NOT EXPOSED LOCALLY")
        if #found > 0 then print("[MAHANAKHON HUB] Delivery state:\n" .. table.concat(found, "\n")) end
    end)
    card("🛡️ ข้อจำกัดการทำงาน", "ไม่สร้างยอดงานปลอม ไม่เรียกคำสั่งเซิร์ฟเวอร์ และไม่กดรับรางวัลอัตโนมัติ")
end

local function renderVehicles()
    clearPage()
    card("🏍️ ระบบยานพาหนะ", "พบระบบรถยนต์ PCX160 โรงรถ ร้านแต่งรถ ECU ดูแลรถ รายละเอียดรถ และไดโน การเปลี่ยนค่าที่บันทึกกับเซิร์ฟเวอร์ให้ใช้เมนูในเกม")
    makeToggle(pageBody, "💡 ไฮไลต์เบาะรถ", "ไฮไลต์เบาะรถที่มองเห็นได้บนหน้าจอ", State.vehicleESP, function(on)
        State.vehicleESP = on
        removeHighlights("VehicleESP")
        if on then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("VehicleSeat") then addHighlight(obj, "VehicleESP", Theme.accent2) end
            end
        end
    end)
    rowCard("🚘 หน้าต่างโรงรถ", "ตรวจสอบว่าหน้าต่างโรงรถของเกมเปิดอยู่หรือไม่", "CHECK", function()
        local g = PlayerGui:FindFirstChild("GarageWindow")
        setStatus(g and "GARAGE UI FOUND" or "OPEN GARAGE IN GAME")
    end)
    rowCard("🧽 หน้าต่างดูแลรถ", "ตรวจสอบหน้าต่างดูแลรถของเกม", "CHECK", function()
        local v = PlayerGui:FindFirstChild("VehicleCare")
        setStatus(v and "VEHICLE CARE FOUND" or "VEHICLE CARE NOT OPEN")
    end)
    rowCard("🧹 ล้างไฮไลต์รถ", "ลบไฮไลต์ที่สร้างไว้บนหน้าจอ", "CLEAR", function()
        removeHighlights("VehicleESP")
        State.vehicleESP = false
        setStatus("VEHICLE MARKERS CLEARED")
    end)
end

local function renderRace()
    clearPage()
    card("🏁 แข่งขันและสนาม", "พบระบบแข่งขัน ตัวนับถอยหลัง และคิวดวล การเข้าร่วมและผลการแข่งขันยังควบคุมโดยระบบเกม")
    rowCard("🔎 ตรวจหน้าต่างแข่ง", "ตรวจหาหน้าต่างการแข่งขันที่มองเห็นได้", "สแกน", function()
        local hits = {}
        for _, obj in ipairs(PlayerGui:GetDescendants()) do
            local n = string.lower(obj.Name)
            if string.find(n, "race") or string.find(n, "countdown") or string.find(n, "duel") then
                table.insert(hits, obj:GetFullName())
            end
        end
        setStatus(#hits > 0 and ("RACE UI " .. #hits .. " ITEMS") or "NO RACE UI OPEN")
        for _, v in ipairs(hits) do print("[RACE UI]", v) end
    end)
    rowCard("📍 ตำแหน่งผู้เล่น", "แสดงตำแหน่งปัจจุบันในคอนโซล", "บันทึก", function()
        local p = getRootPart()
        if p then print("[MAHANAKHON HUB] Position:", p.Position) setStatus("POSITION LOGGED") else setStatus("CHARACTER NOT READY") end
    end)
end

local function renderFarm()
    clearPage()
    card("🌾 ฟาร์มและสินค้า", "พบระบบตรวจฟาร์ม เก็บสินค้า ลูกสูบ และโฟลเดอร์ที่เกี่ยวข้อง หน้านี้ใช้ค้นหาและปักหมุดข้อมูลที่มองเห็นได้เท่านั้น")
    makeToggle(pageBody, "🌾 ไฮไลต์จุดงาน / ฟาร์ม", "ไฮไลต์จุดกดที่เกี่ยวข้องกับงาน ฟาร์ม ส่งของ หรือสินค้า", State.jobESP, function(on)
        State.jobESP = on
        removeHighlights("JobESP")
        if on then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    local path = string.lower(obj:GetFullName())
                    if string.find(path, "job") or string.find(path, "farm") or string.find(path, "delivery") or string.find(path, "cargo") then
                        addHighlight(obj.Parent, "JobESP", Theme.good)
                    end
                end
            end
        end
    end)
    rowCard("📦 สแกนสินค้า", "ค้นหาโมเดลและจุดกดที่เกี่ยวข้องกับสินค้า", "สแกน", function()
        local n = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local s = string.lower(obj.Name .. " " .. obj:GetFullName())
            if string.find(s, "cargo") or string.find(s, "piston") then
                n += 1
            end
        end
        setStatus("CARGO / PISTON MATCHES: " .. n)
    end)
    rowCard("🧹 ล้างหมุดฟาร์ม", "ลบไฮไลต์งานและฟาร์ม", "CLEAR", function()
        removeHighlights("JobESP")
        State.jobESP = false
        setStatus("FARM MARKERS CLEARED")
    end)
end

local function renderMap()
    clearPage()
    card("🗺️ แผนที่อัจฉริยะ", "แผนที่ใช้ Workspace/Map และอาจโหลดวัตถุบางส่วนเมื่อเข้าใกล้พื้นที่เท่านั้น")
    makeToggle(pageBody, "✨ ไฮไลต์จุดกด", "ไฮไลต์จุดกดทั้งหมดที่โหลดอยู่ในขณะนี้", State.promptESP, function(on)
        State.promptESP = on
        removeHighlights("PromptESP")
        if on then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then addHighlight(obj.Parent, "PromptESP", Theme.accent) end
            end
        end
    end)
    rowCard("🗺️ สแกนแผนที่", "นับจุดกด เบาะรถ และวัตถุในแผนที่ที่โหลดอยู่", "สแกน", function()
        local r = scanWorld()
        if r then
            local map = Workspace:FindFirstChild("Map")
            local descendants = map and #map:GetDescendants() or 0
            setStatus(string.format("MAP %d / PROMPTS %d / SEATS %d", descendants, #r.prompts, #r.vehicles))
        end
    end)
    rowCard("🧹 ล้างหมุดแผนที่", "ลบไฮไลต์จุดกดและหมุดนำทาง", "CLEAR", function()
        removeHighlights("PromptESP")
        clearWaypoint()
        State.promptESP = false
        setStatus("MAP MARKERS CLEARED")
    end)
end

local mini -- created below; forward declaration for Tools page

local function renderTools()
    clearPage()
    card("🧰 เครื่องมือในเครื่อง", "เครื่องมือด้านล่างทำงานเฉพาะหน้าจอผู้เล่น ไม่แก้ไขค่าการเล่นที่เซิร์ฟเวอร์ควบคุม")
    makeToggle(pageBody, "📊 สถานะย่อ", "แสดงแผงสถานะผู้เล่นขนาดเล็ก", State.miniStatus, function(on)
        State.miniStatus = on
        mini.Visible = on
    end)
    rowCard("👤 รีเฟรชตัวละคร", "อ่านข้อมูลตัวละครและพลังชีวิตอีกครั้ง", "รีเฟรช", function()
        local ch = getCharacter()
        local h = ch and ch:FindFirstChildOfClass("Humanoid")
        setStatus(h and ("HP " .. math.floor(h.Health)) or "CHARACTER NOT READY")
    end)
    rowCard("🧹 ล้างข้อมูลชั่วคราว", "ลบหมุดและไฮไลต์ทั้งหมดที่ฮับนี้สร้างไว้", "CLEAN", function()
        removeHighlights()
        clearWaypoint()
        State.promptESP, State.vehicleESP, State.jobESP = false, false, false
        setStatus("LOCAL MARKERS CLEARED")
    end)
    rowCard("⏻ ปิดฮับ", "ยกเลิกการเชื่อมต่อและปิดหน้าต่างฮับ", "UNLOAD", function()
        for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
        removeHighlights()
        clearWaypoint()
        gui:Destroy()
    end)
end

local function renderSettings()
    clearPage()
    card("⚙️ ตั้งค่าหน้าตา", "เลือกสีหลักของ UI ได้ทันที และลากแถบด้านบนเพื่อย้ายตำแหน่งหน้าต่าง")
    local themeCard = card("🌈 สีธีม", "เลือกสีที่ต้องการ")
    local palettes = {
        {"เขียวนีออน", Color3.fromRGB(35,255,30), Color3.fromRGB(0,220,150)},
        {"ฟ้าน้ำทะเล", Color3.fromRGB(0,210,255), Color3.fromRGB(40,120,255)},
        {"ม่วง", Color3.fromRGB(180,80,255), Color3.fromRGB(100,70,220)},
        {"แดง", Color3.fromRGB(255,65,75), Color3.fromRGB(255,130,30)},
        {"ทอง", Color3.fromRGB(255,190,35), Color3.fromRGB(255,115,20)},
    }
    for i, palette in ipairs(palettes) do
        local b = button(themeCard, palette[1], function()
            Theme.accent, Theme.accent2 = palette[2], palette[3]
            backgroundArt.ImageTransparency = 0.48
            for _, nav in pairs(navButtons) do
                nav.BackgroundColor3 = nav.Name == State.tab and Theme.accent or Theme.panel2
            end
            pageBody.ScrollBarImageColor3 = Theme.accent
            setStatus("เปลี่ยนสีธีมแล้ว")
        end, 82)
        b.Position = UDim2.fromOffset(12 + ((i-1)%3)*88, 43 + math.floor((i-1)/3)*36)
        b.BackgroundColor3 = palette[2]
        b.TextColor3 = Color3.fromRGB(8, 12, 8)
    end
    themeCard.Size = UDim2.new(1, -6, 0, 120)
    rowCard("รีเซ็ตหน้าต่าง", "ย้ายหน้าต่างกลับมากึ่งกลางหน้าจอ", "จัดกลาง", function()
        root.Position = UDim2.fromScale(0.5, 0.5)
        setStatus("WINDOW CENTERED")
    end)
    rowCard("👁️ ซ่อน / แสดง UI", "กด RightControl เพื่อซ่อนหรือแสดงหน้าต่าง", "เข้าใจแล้ว", function()
        setStatus("RIGHT CTRL TOGGLE")
    end)
    card("👑 เกี่ยวกับฮับ", "BALL KUN HUB • MAHANAKHON v3.0  |  PlaceId 104549080643413\nClient-side companion. No remote invocation or server-side bypass.")
end

local pages = {
    Overview = {renderOverview, "Live player status and quick tools"},
    Jobs = {renderJobs, "Delivery, work and job discovery"},
    Vehicles = {renderVehicles, "Garage, bike, car and tuning"},
    Race = {renderRace, "Race interface and track utilities"},
    Farm = {renderFarm, "Farm checks, cargo and piston discovery"},
    Map = {renderMap, "Adaptive map and local markers"},
    Tools = {renderTools, "Local utilities and cleanup"},
    Settings = {renderSettings, "Interface and hub settings"},
}
local navButtons = {}

local tabThai = {
    Overview = "🏠 ภาพรวม", Jobs = "📦 งาน / ส่งของ", Vehicles = "🏍️ รถและแต่งรถ",
    Race = "🏁 แข่งขัน", Farm = "🌾 ฟาร์ม", Map = "🗺️ แผนที่",
    Tools = "🧰 เครื่องมือ", Settings = "⚙️ ตั้งค่า"
}
local descThai = {
    Overview = "สถานะผู้เล่นและเครื่องมือหลัก",
    Jobs = "ระบบงานและการส่งของ",
    Vehicles = "โรงรถ รถยนต์ มอเตอร์ไซค์ และการแต่งรถ",
    Race = "ข้อมูลการแข่งขันและสนาม",
    Farm = "ตรวจสอบฟาร์ม สินค้า และจุดทำงาน",
    Map = "แผนที่และจุดที่ตรวจพบ",
    Tools = "เครื่องมือใช้งานเฉพาะเครื่อง",
    Settings = "ปรับแต่งหน้าตาและการใช้งาน"
}
local function showTab(name)
    if not pages[name] then return end
    State.tab = name
    pageTitle.Text = tabThai[name] or name
    pageDesc.Text = descThai[name] or pages[name][2]
    for n, b in pairs(navButtons) do
        b.BackgroundColor3 = n == name and Theme.accent or Theme.panel2
        b.TextColor3 = n == name and Theme.bg or Theme.text
    end
    pages[name][1]()
end

local tabNames = {"Overview", "Jobs", "Vehicles", "Race", "Farm", "Map", "Tools", "Settings"}
for i, name in ipairs(tabNames) do
    local b = make("TextButton", {
        Name = name,
        Size = UDim2.new(1, -2, 0, 38),
        BackgroundColor3 = Theme.panel2,
        Text = name,
        TextColor3 = Theme.text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = true,
        LayoutOrder = i,
    }, side)
    make("UICorner", {CornerRadius = UDim.new(0, 7)}, b)
    make("UIPadding", {PaddingLeft = UDim.new(0, 12)}, b)
    navButtons[name] = b
    connect(b.Activated, function() showTab(name) end)
end

mini = make("Frame", {
    Name = "MiniStatus",
    Position = UDim2.new(1, -220, 0, 14),
    Size = UDim2.fromOffset(205, 58),
    BackgroundColor3 = Theme.panel,
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
    Visible = State.miniStatus,
}, gui)
make("UICorner", {CornerRadius = UDim.new(0, 9)}, mini)
make("UIStroke", {Color = Theme.line, Thickness = 1}, mini)
local miniText = make("TextLabel", {
    Position = UDim2.fromOffset(10, 7),
    Size = UDim2.new(1, -20, 1, -14),
    BackgroundTransparency = 1,
    Text = "BALL KUN HUB  •  พร้อมใช้งาน",
    TextColor3 = Theme.accent,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
}, mini)

-- Drag window from top bar.
local dragging, dragStart, startPos
connect(top.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = root.Position
    end
end)
connect(UserInputService.InputChanged, function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

connect(UserInputService.InputBegan, function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightControl then
        root.Visible = not root.Visible
    end
end)
connect(close.Activated, function() root.Visible = false end)

-- Lightweight status refresh; no repeated Workspace scans.
local tickAccum = 0
connect(RunService.Heartbeat, function(dt)
    tickAccum += dt
    if tickAccum < 0.5 then return end
    tickAccum = 0
    local ch = getCharacter()
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    local hrp = getRootPart()
    if hum and hrp then
        miniText.Text = string.format("MAHANAKHON HUB  •  READY\nHP %d/%d  |  SPD %d  |  %.0f, %.0f, %.0f",
            math.floor(hum.Health), math.floor(hum.MaxHealth), math.floor(hum.WalkSpeed),
            hrp.Position.X, hrp.Position.Y, hrp.Position.Z)
    else
        miniText.Text = "กำลังรอตัวละคร..."
    end
end)

connect(LocalPlayer.CharacterAdded, function()
    task.wait(1)
    setStatus("CHARACTER READY")
end)

showTab("Overview")
setStatus("พร้อมใช้งาน")
task.delay(2.6, function()
    if loadingGui and loadingGui.Parent then loadingGui:Destroy() end
end)
print("[BALL KUN HUB] Loaded v3.0 for PlaceId", PLACE_ID)

end, function(err)
    return debug.traceback(tostring(err), 2)
end)

if not buildOK then
    warn("[BALL KUN HUB] UI initialization failed:\n" .. tostring(buildError))
    loadingTitle.Text = "BALL KUN HUB - ERROR"
    loadingTitle.TextColor3 = Color3.fromRGB(255, 90, 90)
    loadingDetail.Text = "เกิดข้อผิดพลาดตอนสร้าง UI\nดูรายละเอียดใน Output ของ Roblox Studio"
    loadingDetail.TextColor3 = Color3.fromRGB(255, 170, 170)
    task.delay(12, function()
        if loadingGui and loadingGui.Parent then loadingGui:Destroy() end
    end)
end
