-- Auto Training + Auto Fish (+25 + Boost Event Switch + Auto Reset Camera/Tap2x) + Auto Secret + Auto Playtime + Auto Sell Unequipped
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local lp = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G
if env.AutoTrainingCleanup then pcall(env.AutoTrainingCleanup) end

local CONFIG_FILE = "AutoTraining_config.json"
local alive = true
local conns = {}
local dirty = false
local unpack = table.unpack or unpack

local function trim(s) return (tostring(s or ""):match("^%s*(.-)%s*$")) end
local function splitKeys(s)
    local t = {}
    for k in tostring(s or ""):gmatch("[^,]+") do
        k = trim(k):lower()
        if k ~= "" then t[#t + 1] = k end
    end
    return t
end
local function hit(str, keys)
    str = tostring(str or ""):lower()
    for _, k in ipairs(keys) do
        if str:find(k, 1, true) then return true end
    end
    return false
end

---------------------------------------------------------------- GUI (Landscape Split + Logo 'A')
local COL_BG = Color3.fromRGB(26, 26, 36)
local COL_PANEL = Color3.fromRGB(18, 18, 26)
local COL_BTN = Color3.fromRGB(46, 46, 62)
local COL_GREEN = Color3.fromRGB(40, 150, 60)
local COL_BLUE = Color3.fromRGB(55, 105, 200)
local COL_RED = Color3.fromRGB(200, 60, 55)

local gui = Instance.new("ScreenGui")
gui.Name = "AutoTrainingGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 998
local okp = false
if gethui then okp = pcall(function() gui.Parent = gethui() end) end
if not okp then okp = pcall(function() gui.Parent = game:GetService("CoreGui") end) end
if not okp then gui.Parent = lp:WaitForChild("PlayerGui") end

local function round(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = o
end

local FULL_W, FULL_H = 540, 330
local LOGO_SIZE = 44
local minimized = false

local main = Instance.new("Frame")
main.Size = UDim2.new(0, FULL_W, 0, FULL_H)
main.Position = UDim2.new(0.5, -FULL_W / 2, 0.5, -FULL_H / 2)
main.BackgroundColor3 = COL_BG
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
round(main, 12)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(70, 85, 130)
stroke.Thickness = 1.5
stroke.Parent = main

-- Tombol Logo 'A' saat Minimize
local logoBtn = Instance.new("TextButton")
logoBtn.Size = UDim2.new(1, 0, 1, 0)
logoBtn.BackgroundColor3 = COL_BLUE
logoBtn.Text = "A"
logoBtn.TextColor3 = Color3.new(1, 1, 1)
logoBtn.Font = Enum.Font.GothamBlack
logoBtn.TextSize = 22
logoBtn.Visible = false
logoBtn.ZIndex = 10
logoBtn.Parent = main
round(logoBtn, 12)

-- Header Bar
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 38)
header.BackgroundColor3 = Color3.fromRGB(34, 34, 48)
header.BorderSizePixel = 0
header.Parent = main
round(header, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -170, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "≡  Auto Training & Fish (+25)"
title.Parent = header

local function topBtn(text, col, xOff, w)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, 26)
    b.Position = UDim2.new(1, xOff, 0, 6)
    b.BackgroundColor3 = col
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.Parent = header
    round(b, 6)
    return b
end
local closeBtn = topBtn("X", COL_RED, -36, 28)
local minBtn = topBtn("-", COL_BTN, -70, 28)
local copyBtn = topBtn("Salin Log", COL_GREEN, -142, 64)

-- Drag halus
local dragging = false
local dragStart, startPos, movedDist = nil, nil, 0

local function attachDrag(handle, onTap)
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            movedDist = 0
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                if onTap and movedDist < 8 then
                    onTap()
                end
            end
        end
    end)
end

table.insert(conns, UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        movedDist = delta.Magnitude
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end))

attachDrag(header, nil)

-- Kontainer Kiri & Kanan
local leftPane = Instance.new("Frame")
leftPane.Size = UDim2.new(0, 315, 1, -46)
leftPane.Position = UDim2.new(0, 8, 0, 42)
leftPane.BackgroundTransparency = 1
leftPane.Parent = main

local rightPane = Instance.new("Frame")
rightPane.Size = UDim2.new(1, -335, 1, -46)
rightPane.Position = UDim2.new(0, 327, 0, 42)
rightPane.BackgroundColor3 = COL_PANEL
rightPane.BorderSizePixel = 0
rightPane.Parent = main
round(rightPane, 8)

local logTitle = Instance.new("TextLabel")
logTitle.Size = UDim2.new(1, -12, 0, 20)
logTitle.Position = UDim2.new(0, 6, 0, 2)
logTitle.BackgroundTransparency = 1
logTitle.Font = Enum.Font.GothamBold
logTitle.TextSize = 10
logTitle.TextXAlignment = Enum.TextXAlignment.Left
logTitle.TextColor3 = Color3.fromRGB(130, 175, 255)
logTitle.Text = "ACTIVITY LOG"
logTitle.Parent = rightPane

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, 0, 0, 28)
tabBar.Position = UDim2.new(0, 0, 0, 0)
tabBar.BackgroundTransparency = 1
tabBar.Parent = leftPane
local tabLay = Instance.new("UIListLayout")
tabLay.FillDirection = Enum.FillDirection.Horizontal
tabLay.Padding = UDim.new(0, 4)
tabLay.Parent = tabBar

local pages, tabBtns = {}, {}
local curPage

local function createPage(name)
    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.new(1, 0, 1, -34)
    p.Position = UDim2.new(0, 0, 0, 34)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ScrollBarThickness = 5
    p.CanvasSize = UDim2.new(0, 0, 0, 0)
    p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    p.Visible = false
    p.Parent = leftPane
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 5)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = p
    pages[name] = { frame = p, order = 0 }

    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 60, 1, 0)
    b.BackgroundColor3 = COL_BTN
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.Text = name
    b.Parent = tabBar
    round(b, 6)
    tabBtns[name] = b
    b.Activated:Connect(function()
        for n, pg in pairs(pages) do
            pg.shown = (n == name)
            pg.frame.Visible = (n == name)
            tabBtns[n].BackgroundColor3 = (n == name) and COL_BLUE or COL_BTN
        end
    end)
    return name
end

local function usePage(name) curPage = pages[name] end
local function nextOrder()
    curPage.order = curPage.order + 1
    return curPage.order
end

local function mkBtn(text, col)
    local b = Instance.new("TextButton")
    b.LayoutOrder = nextOrder()
    b.Size = UDim2.new(1, -8, 0, 30)
    b.BackgroundColor3 = col or COL_BTN
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.Text = text
    b.Parent = curPage.frame
    round(b, 8)
    return b
end

local function mkLabel(text)
    local l = Instance.new("TextLabel")
    l.LayoutOrder = nextOrder()
    l.Size = UDim2.new(1, -8, 0, 18)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamBold
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = Color3.fromRGB(120, 170, 255)
    l.Text = text
    l.Parent = curPage.frame
    return l
end

local fields = {}
local function mkField(key, label, default)
    local row = Instance.new("Frame")
    row.LayoutOrder = nextOrder()
    row.Size = UDim2.new(1, -8, 0, 28)
    row.BackgroundTransparency = 1
    row.Parent = curPage.frame
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.54, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.Gotham
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = Color3.fromRGB(205, 205, 220)
    l.TextWrapped = true
    l.Text = label
    l.Parent = row
    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(0.46, 0, 1, 0)
    tb.Position = UDim2.new(0.54, 0, 0, 0)
    tb.BackgroundColor3 = COL_BTN
    tb.TextColor3 = Color3.new(1, 1, 1)
    tb.Font = Enum.Font.Gotham
    tb.TextSize = 11
    tb.ClearTextOnFocus = false
    tb.Text = default
    tb.Parent = row
    round(tb, 6)
    tb.FocusLost:Connect(function() dirty = true end)
    fields[key] = tb
    return tb
end

local state, toggleBtns, toggleLabels, onToggle = {}, {}, {}, {}
local function paintToggle(key)
    local on = state[key]
    toggleBtns[key].Text = toggleLabels[key] .. (on and "ON" or "OFF")
    toggleBtns[key].BackgroundColor3 = on and COL_GREEN or COL_BTN
end
local function setState(key, on, silent)
    state[key] = on
    paintToggle(key)
    if onToggle[key] then pcall(onToggle[key], on) end
    if not silent then dirty = true end
end
local function mkToggle(key, label, default)
    toggleLabels[key] = label .. ": "
    toggleBtns[key] = mkBtn("", COL_BTN)
    state[key] = default
    paintToggle(key)
    toggleBtns[key].Activated:Connect(function() setState(key, not state[key]) end)
end

-- Scrollable Log di Panel Kanan
local logScroll = Instance.new("ScrollingFrame")
logScroll.Size = UDim2.new(1, -10, 1, -26)
logScroll.Position = UDim2.new(0, 5, 0, 22)
logScroll.BackgroundTransparency = 1
logScroll.BorderSizePixel = 0
logScroll.Active = true
logScroll.ScrollingEnabled = true
logScroll.ScrollingDirection = Enum.ScrollingDirection.Y
logScroll.ElasticBehavior = Enum.ElasticBehavior.Always
logScroll.ScrollBarThickness = 5
logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
logScroll.Parent = rightPane

local logBox = Instance.new("TextLabel")
logBox.Size = UDim2.new(1, -8, 0, 20)
logBox.Position = UDim2.new(0, 2, 0, 0)
logBox.BackgroundTransparency = 1
logBox.TextColor3 = Color3.fromRGB(215, 220, 230)
logBox.Font = Enum.Font.Code
logBox.TextSize = 10
logBox.TextXAlignment = Enum.TextXAlignment.Left
logBox.TextYAlignment = Enum.TextYAlignment.Top
logBox.TextWrapped = true
logBox.Text = ""
logBox.Parent = logScroll

local lines = {}
local function updateLogCanvas()
    if not logScroll or not logScroll.Parent then return end
    local fullText = table.concat(lines, "\n")
    logBox.Text = fullText
    local availW = math.max(120, logScroll.AbsoluteWindowSize.X - 10)
    local bounds = TextService:GetTextSize(fullText, 10, Enum.Font.Code, Vector2.new(availW, 100000))
    local totalH = bounds.Y + 12
    logBox.Size = UDim2.new(1, -8, 0, totalH)
    logScroll.CanvasSize = UDim2.new(0, 0, 0, totalH)
    local maxScroll = math.max(0, totalH - logScroll.AbsoluteWindowSize.Y)
    logScroll.CanvasPosition = Vector2.new(0, maxScroll)
end

local function logLine(s)
    lines[#lines + 1] = tostring(s)
    if #lines > 100 then table.remove(lines, 1) end
    pcall(updateLogCanvas)
end

copyBtn.Activated:Connect(function()
    if setclipboard then
        pcall(setclipboard, table.concat(lines, "\n"))
        logLine("(log disalin)")
    else
        logLine("setclipboard tidak tersedia")
    end
end)

local function setMinimized(min)
    minimized = min
    header.Visible = not min
    leftPane.Visible = not min
    rightPane.Visible = not min
    logoBtn.Visible = min
    if min then
        main.Size = UDim2.new(0, LOGO_SIZE, 0, LOGO_SIZE)
    else
        main.Size = UDim2.new(0, FULL_W, 0, FULL_H)
        task.defer(updateLogCanvas)
    end
end

minBtn.Activated:Connect(function() setMinimized(true) end)
attachDrag(logoBtn, function() setMinimized(false) end)

---------------------------------------------------------------- Isi menu (5 Tab)
createPage("Training")
createPage("Fishing")
createPage("Sell")
createPage("Rewards")
createPage("Config")

-- ===== Tab Training =====
usePage("Training")
mkToggle("train", "Auto Training", false)
mkToggle("trainGoZone", "Auto Menuju Training", true)
mkToggle("trainTeleport", "Gunakan Teleport (OFF=Jalan)", false)
local saveTrainPosBtn = mkBtn("Simpan Posisi Training (Relatif Base)", COL_BLUE)
local goTrainNowBtn = mkBtn("Pergi ke Training Sekarang", COL_BTN)
mkField("trainRelPos", "Offset Base Training (X,Y,Z)", "")
mkToggle("double", "Auto DoubleRep", false)
mkToggle("stopOnOff", "Kirim Stop saat OFF", true)
mkField("startName", "Remote Start", "StartTraining")
mkField("startArgs", "Argumen Start", "auto")
mkField("startEvery", "Ulang Start (dtk)", "5")
mkField("stopName", "Remote Stop", "StopTraining")
mkField("stopArgs", "Argumen Stop", "auto")
mkField("doubleName", "Remote DoubleRep", "DoubleRep")
mkField("doubleArgs", "Argumen DoubleRep", "auto")
mkField("doubleEvery", "DoubleRep (dtk)", "1")

-- ===== Tab Fishing =====
usePage("Fishing")
mkToggle("fish", "Auto Fish (+25 Cycle)", false)
mkLabel("Auto Fish Saat Boost Event")
mkToggle("boostFish", "Auto Fish Saat Boost Event", false)
mkField("boostFilter", "Filter Event (kosong=semua)", "")
mkToggle("fishGoSpot", "Auto ke Dermaga Garis Pink", true)
mkToggle("fishTeleport", "Gunakan Teleport (OFF=Jalan)", false)
local saveFishPosBtn = mkBtn("Simpan Posisi Fish (Relatif Base)", COL_BLUE)
local goFishNowBtn = mkBtn("Pergi ke Dermaga Fish Sekarang", COL_BTN)
mkField("fishRelPos", "Offset Base Fish (X,Y,Z)", "")
mkToggle("autoEquipRod", "Auto Equip Pancingan", true)
mkToggle("hideAnim", "Sembunyikan Bar & Animasi", true)
mkToggle("perfect", "Kunci +25 (Power = 1)", true)
mkField("castBeginName", "Remote CastBegin", "CastBegin")
mkField("castName", "Remote Cast", "Cast")
mkField("castPower", "Power cast (1 = +25)", "1")
mkField("castArg2", "Argumen ke-2 Cast", "1")
mkField("castGap", "Jeda Begin -> Cast", "0.6")
mkField("castEvery", "Jeda antar siklus", "1.2")

mkLabel("Secret Cast (Auto Stop)")
mkToggle("autoSecret", "Auto Secret Cast", true)
mkField("secretTarget", "Target Rarity", "SECRET")
mkField("secretStopName", "Remote Stop (opsional)", "")
mkField("secretStopArgs", "Argumen Secret", "auto")
mkField("secretDelay", "Jeda klik Stop (dtk)", "0.15")

mkLabel("Auto Claim / Tarik Pancing")
mkToggle("autoReel", "Auto ClaimCatch", true)
mkField("reelName", "Remote Claim", "ClaimCatch")
mkField("reelArgs", "Argumen Claim", "auto")
mkField("reelOffset", "Tambahan jeda FlightTime", "0.15")
mkField("reelAfter", "Fallback tunggu (dtk)", "5")
mkToggle("sendCastEnd", "Kirim CastEnd setelah claim", true)
mkToggle("watch", "Pantau event server", false)
mkField("watchKeys", "Filter event", "fish,bite,reel,catch,cast,claim,end,secret,spin,sell")
local castTestBtn = mkBtn("Tes 1 siklus penuh (+25)", COL_BLUE)
local claimNowBtn = mkBtn("Paksa ClaimCatch sekarang", COL_BTN)

-- ===== Tab Sell =====
usePage("Sell")
mkToggle("autoSell", "Auto Sell Tidak Dipakai", false)
mkToggle("sellSkipEquipped", "Lindungi EQUIPPED (Wajib)", true)
mkField("sellRemoteName", "Remote Sell", "SellBeast")
mkField("sellKeepRarity", "Jangan Jual Rarity (koma)", "Secret,Divine")
mkField("sellEvery", "Jual tiap (detik)", "8")
local sellNowBtn = mkBtn("Jual Semua Tidak Dipakai Sekarang", COL_BLUE)

-- ===== Tab Rewards =====
usePage("Rewards")
mkToggle("autoPlaytime", "Auto Claim Playtime", true)
mkField("ptRemoteName", "Remote Playtime", "Claim")
mkField("ptCategory", "Kategori Hadiah", "Gift")
mkField("ptSlots", "Jumlah Slot", "9")
mkField("ptEvery", "Cek & Claim (dtk)", "10")
local ptClaimNowBtn = mkBtn("Claim Semua Playtime Sekarang", COL_BLUE)

-- ===== Tab Config =====
usePage("Config")
mkToggle("afk", "Anti AFK", true)
mkToggle("autoLoad", "Auto load config", true)
local saveBtn = mkBtn("Simpan config sekarang", COL_BLUE)
local loadBtn = mkBtn("Muat config", COL_BLUE)
local delBtn = mkBtn("Hapus file config", COL_BTN)
mkLabel("Rekam argumen remote")
mkToggle("rec", "Rekam remote", false)
local scanBtn = mkBtn("Scan remote (ke log)", COL_BLUE)

local function showTab(name)
    for n, pg in pairs(pages) do
        pg.shown = (n == name)
        pg.frame.Visible = (n == name)
        tabBtns[n].BackgroundColor3 = (n == name) and COL_BLUE or COL_BTN
    end
end
showTab("Fishing")

---------------------------------------------------------------- Deteksi Boost Event di PlayerGui.HUD.Hud.Top.Boosts
local function getBoostsFolder()
    local pGui = lp:FindFirstChild("PlayerGui")
    if not pGui then return nil end
    local hud = pGui:FindFirstChild("HUD")
    if hud then
        local innerHud = hud:FindFirstChild("Hud") or hud
        local top = innerHud:FindFirstChild("Top")
        if top then
            local boosts = top:FindFirstChild("Boosts")
            if boosts then return boosts end
        end
    end
    return pGui:FindFirstChild("Boosts", true)
end

local function getActiveBoostEvent()
    local boosts = getBoostsFolder()
    if not boosts then return false, nil, nil end

    local filterKeys = splitKeys(fields.boostFilter.Text)
    for _, child in ipairs(boosts:GetChildren()) do
        if child:IsA("GuiObject") and child.Visible then
            local nm = child.Name
            local nmLow = nm:lower()
            if not nmLow:find("soon", 1, true) then
                if #filterKeys == 0 or hit(nmLow, filterKeys) then
                    local timeLbl = child:FindFirstChild("Time", true)
                    local timeTxt = (timeLbl and timeLbl:IsA("TextLabel")) and trim(timeLbl.Text) or ""
                    if timeLbl == nil or timeLbl.Visible then
                        if timeTxt ~= "0:00" and timeTxt ~= "00:00" then
                            return true, nm, timeTxt
                        end
                    end
                end
            end
        end
    end
    return false, nil, nil
end

---------------------------------------------------------------- Sistem Koordinat Relatif Terhadap Spawn Base Sendiri
local mySpawnCFrame = nil

local function detectMyBaseAnchor(referencePos)
    if lp.RespawnLocation and lp.RespawnLocation:IsA("BasePart") then
        mySpawnCFrame = lp.RespawnLocation.CFrame
        return mySpawnCFrame
    end

    local pNameLow = lp.Name:lower()
    local pDispLow = lp.DisplayName:lower()
    local pIdStr = tostring(lp.UserId)

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("StringValue") or obj:IsA("ObjectValue") or obj:IsA("IntValue") or obj:IsA("NumberValue") then
            local vStr = tostring(obj.Value):lower()
            if vStr == pNameLow or vStr == pDispLow or vStr == pIdStr or obj.Value == lp then
                local container = obj.Parent
                if container then
                    local sp = container:FindFirstChildWhichIsA("SpawnLocation", true)
                        or container:FindFirstChild("Base", true)
                        or container:FindFirstChild("Spawn", true)
                        or container:FindFirstChild("Floor", true)
                    if sp and sp:IsA("BasePart") then
                        mySpawnCFrame = sp.CFrame
                        return mySpawnCFrame
                    end
                end
            end
        end
    end

    local ref = referencePos or (lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and lp.Character.HumanoidRootPart.Position)
    if ref then
        local closestSpawn, bestDist = nil, math.huge
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("SpawnLocation") then
                local d = (obj.Position - ref).Magnitude
                if d < bestDist then
                    bestDist = d
                    closestSpawn = obj
                end
            end
        end
        if closestSpawn then
            mySpawnCFrame = closestSpawn.CFrame
            return mySpawnCFrame
        end
    end

    return mySpawnCFrame
end

table.insert(conns, lp.CharacterAdded:Connect(function(char)
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    if hrp then
        task.wait(0.25)
        detectMyBaseAnchor(hrp.Position)
    end
end))

local function encodeRelativeCFrame(hrp)
    local baseCF = detectMyBaseAnchor(hrp.Position)
    if not baseCF then return nil end
    local rel = baseCF:ToObjectSpace(hrp.CFrame)
    local _, yaw, _ = rel:ToOrientation()
    return string.format("%.2f, %.2f, %.2f, %.3f", rel.Position.X, rel.Position.Y, rel.Position.Z, yaw)
end

local function decodeRelativeToWorld(str)
    str = trim(str)
    if str == "" then return nil, nil end
    local nums = {}
    for n in str:gmatch("%-?%d+%.?%d*") do
        nums[#nums + 1] = tonumber(n)
    end
    if #nums < 3 then return nil, nil end

    local baseCF = detectMyBaseAnchor()
    if not baseCF then return nil, nil end

    local localOffset = Vector3.new(nums[1], nums[2], nums[3])
    local localYaw = nums[4] or 0
    local worldCF = baseCF:ToWorldSpace(CFrame.new(localOffset) * CFrame.Angles(0, localYaw, 0))
    local _, worldYaw, _ = worldCF:ToOrientation()
    return worldCF.Position, worldYaw
end

local function getTrainingTarget()
    local pos, yaw = decodeRelativeToWorld(fields.trainRelPos.Text)
    if pos then return pos, yaw end

    local baseCF = detectMyBaseAnchor()
    if baseCF then
        local bestPos, bestDist = nil, 150
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local nm = obj.Name:lower()
                local pNm = obj.Parent and obj.Parent.Name:lower() or ""
                if hit(nm, { "train", "gym", "workout", "rep", "powerzone", "lift" }) or hit(pNm, { "train", "gym", "workout" }) then
                    if obj.Size.X >= 4 and obj.Size.Z >= 4 then
                        local d = (obj.Position - baseCF.Position).Magnitude
                        if d < bestDist then
                            bestDist = d
                            bestPos = obj.Position + Vector3.new(0, (obj.Size.Y * 0.5) + 3, 0)
                        end
                    end
                end
            end
        end
        if bestPos then return bestPos, nil end
    end
    return nil, nil
end

local function getFishingTarget()
    local pos, yaw = decodeRelativeToWorld(fields.fishRelPos.Text)
    if pos then return pos, yaw, nil end

    local baseCF = detectMyBaseAnchor()
    local refPos = baseCF and baseCF.Position or (lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and lp.Character.HumanoidRootPart.Position) or Vector3.zero

    local waterPart, bestWaterDist = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local nm = obj.Name:lower()
            if (nm == "water" or nm:find("canal", 1, true) or nm:find("river", 1, true) or nm:find("fishwater", 1, true)) and obj.Size.Z > 30 then
                local d = (obj.Position - refPos).Magnitude
                if d < bestWaterDist then
                    bestWaterDist = d
                    waterPart = obj
                end
            end
        end
    end

    if waterPart then
        local edgeZ = waterPart.Position.Z - (waterPart.Size.Z * 0.5) - 4
        local standPos = Vector3.new(refPos.X, waterPart.Position.Y + (waterPart.Size.Y * 0.5) + 3, edgeZ)
        local lookAt = Vector3.new(refPos.X, standPos.Y, waterPart.Position.Z)
        return standPos, nil, lookAt
    end

    return nil, nil, nil
end

local function moveToTarget(targetPos, targetYaw, lookAtPos, useTeleport, tag)
    if not targetPos then
        logLine("[" .. tag .. "] posisi belum diset! Berdiri di titik target lalu tekan Simpan Posisi.")
        return false
    end
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return false end

    local dist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude
    if dist <= 3.5 then
        if lookAtPos then
            hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(lookAtPos.X, hrp.Position.Y, lookAtPos.Z))
        elseif targetYaw then
            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, targetYaw, 0)
        end
        return true
    end

    if useTeleport then
        local cf
        if lookAtPos then
            cf = CFrame.lookAt(targetPos, Vector3.new(lookAtPos.X, targetPos.Y, lookAtPos.Z))
        elseif targetYaw then
            cf = CFrame.new(targetPos) * CFrame.Angles(0, targetYaw, 0)
        else
            cf = CFrame.new(targetPos)
        end
        hrp.CFrame = cf
        logLine(string.format("[%s] teleport relatif ke (%.1f, %.1f, %.1f)", tag, targetPos.X, targetPos.Y, targetPos.Z))
        task.wait(0.25)
        return true
    else
        logLine(string.format("[%s] berjalan ke target (jarak %.1f stud)...", tag, dist))
        hum:MoveTo(targetPos)
        local t0 = os.clock()
        while alive and os.clock() - t0 < 12 do
            if not hrp or not hrp.Parent then break end
            local d = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude
            if d <= 3.5 then break end
            if math.floor((os.clock() - t0) * 10) % 15 == 0 then
                hum:MoveTo(targetPos)
            end
            task.wait(0.1)
        end
        if hrp and hrp.Parent then
            if lookAtPos then
                hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(lookAtPos.X, hrp.Position.Y, lookAtPos.Z))
            elseif targetYaw then
                hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, targetYaw, 0)
            end
        end
        return true
    end
end

saveTrainPosBtn.Activated:Connect(function()
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local encoded = encodeRelativeCFrame(hrp)
        if encoded then
            fields.trainRelPos.Text = encoded
            dirty = true
            logLine("[train] offset relatif base tersimpan: " .. encoded)
        else
            logLine("[train] gagal mendeteksi Spawn Base!")
        end
    end
end)

goTrainNowBtn.Activated:Connect(function()
    task.spawn(function()
        local pos, yaw = getTrainingTarget()
        moveToTarget(pos, yaw, nil, state.trainTeleport, "train")
    end)
end)

saveFishPosBtn.Activated:Connect(function()
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local encoded = encodeRelativeCFrame(hrp)
        if encoded then
            fields.fishRelPos.Text = encoded
            dirty = true
            logLine("[fish] offset relatif base tersimpan: " .. encoded)
        else
            logLine("[fish] gagal mendeteksi Spawn Base!")
        end
    end
end)

goFishNowBtn.Activated:Connect(function()
    task.spawn(function()
        local pos, yaw, lookAt = getFishingTarget()
        moveToTarget(pos, yaw, lookAt, state.fishTeleport, "fish")
    end)
end)

---------------------------------------------------------------- Config
local function canFile() return writefile ~= nil and readfile ~= nil and isfile ~= nil end
local function collect()
    local data = { fields = {}, toggles = {} }
    for k, tb in pairs(fields) do data.fields[k] = tb.Text end
    for k, v in pairs(state) do data.toggles[k] = v end
    return data
end
local function saveConfig(silent)
    if not canFile() then return false end
    local ok = pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(collect())) end)
    dirty = false
    if not silent then logLine(ok and "[config] tersimpan" or "[config] gagal simpan") end
    return ok
end
local function readConfig()
    if not canFile() then return nil end
    local ok, data = pcall(function()
        if not isfile(CONFIG_FILE) then return nil end
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    return (ok and type(data) == "table") and data or nil
end
local function applyConfig(data, onlyAutoLoadFlag)
    if type(data) ~= "table" then return end
    local tg = data.toggles or {}
    if onlyAutoLoadFlag then
        if tg.autoLoad ~= nil then setState("autoLoad", tg.autoLoad == true, true) end
        return
    end
    for k, v in pairs(data.fields or {}) do
        if fields[k] and type(v) == "string" then fields[k].Text = v end
    end
    for k, v in pairs(tg) do
        if state[k] ~= nil and type(v) == "boolean" then setState(k, v, true) end
    end
end

saveBtn.Activated:Connect(function() saveConfig(false) end)
loadBtn.Activated:Connect(function()
    local data = readConfig()
    if data then applyConfig(data, false) logLine("[config] dimuat") end
end)
delBtn.Activated:Connect(function()
    if canFile() and delfile then
        pcall(function() if isfile(CONFIG_FILE) then delfile(CONFIG_FILE) end end)
        logLine("[config] file dihapus")
    end
end)
task.spawn(function()
    while alive do
        task.wait(3)
        if dirty and canFile() then saveConfig(true) end
    end
end)

---------------------------------------------------------------- Sembunyikan Bar Vertikal, GOOD!, & Animasi Pancing
local hiddenGuis = {}
local hiddenScreenGuis = {}

local function isCastUiText(t)
    t = trim(t):lower()
    if t == "" or t:find("secret", 1, true) then return false end
    if t:find("tap to cast", 1, true) then return true end
    if t:match("^%+%d+$") then return true end
    if t == "good!" or t == "perfect!" or t == "great!" or t == "bad!" or t == "miss!" then return true end
    return false
end

local function updateFishingVisuals()
    local pGui = lp:FindFirstChild("PlayerGui")
    if not pGui then return end

    if state.hideAnim then
        for _, obj in ipairs(pGui:GetDescendants()) do
            if not obj:IsDescendantOf(gui) then
                local matched = false
                if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                    matched = isCastUiText(obj.Text)
                elseif obj:IsA("GuiObject") and hit(obj.Name, { "castbar", "powerbar", "fishingbar", "tapcast", "meter", "gauge" }) then
                    if not hit(obj.Name, { "secret", "health", "hp", "stamina" }) then
                        matched = true
                    end
                end

                if matched then
                    local root = obj
                    while root.Parent and root.Parent ~= pGui and not root.Parent:IsA("ScreenGui") do
                        local pName = root.Parent.Name:lower()
                        if hit(pName, { "hud", "main", "top", "bottom", "hotbar", "sidebar" }) then
                            break
                        end
                        root = root.Parent
                    end

                    if root:IsA("GuiObject") and root.Visible then
                        hiddenGuis[root] = true
                        root.Visible = false
                    end

                    local sGui = obj:FindFirstAncestorWhichIsA("ScreenGui")
                    if sGui and sGui.Enabled and not hiddenScreenGuis[sGui] then
                        local hasMainHud = false
                        for _, child in ipairs(sGui:GetDescendants()) do
                            if child:IsA("TextLabel") then
                                local ct = child.Text:lower()
                                if ct:find("power", 1, true) or ct:find("trade", 1, true) or ct:find("eggs", 1, true) then
                                    hasMainHud = true
                                    break
                                end
                            end
                        end
                        if not hasMainHud then
                            hiddenScreenGuis[sGui] = true
                            sGui.Enabled = false
                        end
                    end
                end
            end
        end

        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                if hit(track.Name, { "cast", "fish", "rod", "throw" }) then
                    pcall(function() track:Stop(0) end)
                end
            end
        end
    else
        for obj in pairs(hiddenGuis) do
            if obj and obj.Parent then
                pcall(function() obj.Visible = true end)
            end
        end
        hiddenGuis = {}
        for sGui in pairs(hiddenScreenGuis) do
            if sGui and sGui.Parent then
                pcall(function() sGui.Enabled = true end)
            end
        end
        hiddenScreenGuis = {}
    end
end

onToggle.hideAnim = function(on)
    updateFishingVisuals()
    logLine(on and "[visual] bar & animasi disembunyikan" or "[visual] bar & animasi ditampilkan")
end

task.spawn(function()
    while alive do
        if state.hideAnim then
            pcall(updateFishingVisuals)
        end
        task.wait(0.1)
    end
end)

---------------------------------------------------------------- Remote (Case-Insensitive)
local remoteCache = {}
local function getAllRemoteContainers()
    return {
        ReplicatedStorage,
        lp:FindFirstChild("PlayerGui"),
        StarterGui
    }
end

local function getRemote(name)
    name = trim(name)
    if name == "" then return nil end
    local r = remoteCache[name]
    if r and r.Parent then return r end
    local targetLower = name:lower()
    for _, root in ipairs(getAllRemoteContainers()) do
        if root then
            local found = root:FindFirstChild(name, true)
            if not found then
                for _, d in ipairs(root:GetDescendants()) do
                    if (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) and d.Name:lower() == targetLower then
                        found = d
                        break
                    end
                end
            end
            if found and (found:IsA("RemoteEvent") or found:IsA("RemoteFunction")) then
                remoteCache[name] = found
                return found
            end
        end
    end
    return nil
end

local captured = {}
local function parseArgs(text, remoteName)
    text = trim(text)
    if text == "" or text:lower() == "auto" then
        local c = captured[remoteName]
        if c then return c end
        return table.pack()
    end
    local out, n = {}, 0
    for tok in text:gmatch("[^,]+") do
        tok = trim(tok)
        local v
        if tok:lower() == "nil" then v = nil
        elseif tok:lower() == "true" then v = true
        elseif tok:lower() == "false" then v = false
        elseif tonumber(tok) then v = tonumber(tok)
        else v = tok:gsub("^[\"'](.*)[\"']$", "%1") end
        n = n + 1
        out[n] = v
    end
    out.n = n
    return out
end

local function callRemote(name, args, tag, silentMissing)
    local r = getRemote(name)
    if not r then
        if not silentMissing then
            logLine("[" .. tag .. "] remote '" .. tostring(name) .. "' tidak ditemukan")
        end
        return false, nil
    end
    local n = args.n or #args
    if r:IsA("RemoteEvent") then
        local ok, err = pcall(function() r:FireServer(unpack(args, 1, n)) end)
        if not ok and not silentMissing then logLine("[" .. tag .. "] gagal: " .. tostring(err)) end
        return ok, nil
    end
    local done, ok, res = false, false, nil
    task.spawn(function()
        ok, res = pcall(function() return r:InvokeServer(unpack(args, 1, n)) end)
        done = true
    end)
    local t0 = os.clock()
    while not done and os.clock() - t0 < 4 do task.wait(0.05) end
    if not done then
        if not silentMissing then logLine("[" .. tag .. "] " .. tostring(name) .. " timeout (4 dtk)") end
        return false, nil
    end
    if not ok and not silentMissing then logLine("[" .. tag .. "] gagal: " .. tostring(res)) end
    return ok, res
end

local function fire(name, argText, tag)
    return callRemote(name, parseArgs(argText, trim(name)), tag)
end

---------------------------------------------------------------- Reset Kamera & Auto Tap 2x di Ruang Kosong Saat Keluar Fishing
local function tapEmptySpace(times)
    times = times or 2
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(800, 450)
    -- Titik ruang kosong di kuadran kanan atas layar (aman dari tombol HUD/menu)
    local tapX = vp.X * 0.72
    local tapY = vp.Y * 0.28

    for _ = 1, times do
        if VirtualInputManager then
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(tapX, tapY, 0, true, game, 1)
                task.wait(0.04)
                VirtualInputManager:SendMouseButtonEvent(tapX, tapY, 0, false, game, 1)
            end)
        elseif VirtualUser then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(tapX, tapY))
            end)
        end
        task.wait(0.14)
    end
end

local function exitFishingVisualState()
    -- 1. Hentikan status lemparan pancing di server & lepas alat pancing
    callRemote("CastEnd", table.pack(), "end", true)
    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum:UnequipTools() end)
    end

    -- 2. Kembalikan kamera dari kamera kanal fishing ke kamera karakter normal
    local cam = workspace.CurrentCamera
    if cam and hum then
        pcall(function()
            cam.CameraSubject = hum
            cam.CameraType = Enum.CameraType.Custom
        end)
    end

    -- 3. Tap 2x di ruang kosong layar untuk memicu client game keluar dari mode UI/kamera fishing
    task.wait(0.15)
    tapEmptySpace(2)
    logLine("[visual] reset kamera fishing + tap 2x selesai")
end

---------------------------------------------------------------- Auto Sell Unequipped
local function clickGuiObj(btn)
    if not btn or not btn:IsA("GuiObject") then return false end
    local clicked = false
    if btn:IsA("GuiButton") then
        if firesignal then
            pcall(function() firesignal(btn.Activated) clicked = true end)
            pcall(function() firesignal(btn.MouseButton1Click) clicked = true end)
        end
    end
    if not clicked and VirtualInputManager then
        local pos = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
            task.wait(0.03)
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
            clicked = true
        end)
    end
    return clicked
end

local function sellUnequippedItems(manual)
    local pGui = lp:FindFirstChild("PlayerGui")
    if not pGui then return end

    local keepKeys = splitKeys(fields.sellKeepRarity.Text)
    local rName = trim(fields.sellRemoteName.Text)
    if rName == "" then rName = "SellBeast" end

    local soldCount = 0
    local skippedEquipped = 0
    local skippedRarity = 0

    for _, obj in ipairs(pGui:GetDescendants()) do
        if not obj:IsDescendantOf(gui) and (obj:IsA("TextButton") or obj:IsA("TextLabel")) then
            local txt = trim(obj.Text)
            if txt:match("^Sell%s+%$") then
                local btn = obj:IsA("GuiButton") and obj or obj:FindFirstAncestorWhichIsA("GuiButton")
                local row = (btn or obj).Parent
                while row and row ~= pGui and not row:IsA("ScrollingFrame") and not row:IsA("ScreenGui") do
                    local hasRank = false
                    for _, c in ipairs(row:GetDescendants()) do
                        if c:IsA("TextLabel") and trim(c.Text):match("^#%d+$") then
                            hasRank = true
                            break
                        end
                    end
                    if hasRank then break end
                    row = row.Parent
                end

                if row and row:IsA("GuiObject") and row.Visible then
                    local isEquipped = false
                    local isProtectedRarity = false
                    local foundUid = nil

                    if row.Name:match("^%d+$") then
                        foundUid = row.Name
                    end
                    for _, attrVal in pairs(row:GetAttributes()) do
                        local sAttr = tostring(attrVal)
                        if sAttr:match("^%d+$") then
                            foundUid = sAttr
                            break
                        end
                    end

                    for _, c in ipairs(row:GetDescendants()) do
                        if c:IsA("TextLabel") and c.Visible then
                            local ct = trim(c.Text):lower()
                            if ct == "equipped" or ct:find("equipped", 1, true) then
                                isEquipped = true
                            end
                            if #keepKeys > 0 and hit(ct, keepKeys) then
                                isProtectedRarity = true
                            end
                        end
                    end

                    if state.sellSkipEquipped and isEquipped then
                        skippedEquipped = skippedEquipped + 1
                    elseif isProtectedRarity then
                        skippedRarity = skippedRarity + 1
                    else
                        local soldThis = false
                        if foundUid then
                            local okS = callRemote(rName, table.pack(foundUid), "sell", true)
                            if okS then soldThis = true end
                        end
                        if not soldThis and btn and btn.Visible then
                            if clickGuiObj(btn) then
                                soldThis = true
                            end
                        end
                        if soldThis then
                            soldCount = soldCount + 1
                            task.wait(0.08)
                        end
                    end
                end
            end
        end
    end

    if manual or soldCount > 0 then
        logLine(string.format("[sell] terjual=%d | aman(equipped)=%d | aman(rarity)=%d", soldCount, skippedEquipped, skippedRarity))
    end
end

sellNowBtn.Activated:Connect(function()
    task.spawn(function() sellUnequippedItems(true) end)
end)

task.spawn(function()
    task.wait(3)
    while alive do
        if state.autoSell then
            pcall(function() sellUnequippedItems(false) end)
        end
        local every = math.max(2, tonumber(fields.sellEvery.Text) or 8)
        local t0 = os.clock()
        while alive and os.clock() - t0 < every do
            task.wait(0.5)
        end
    end
end)

---------------------------------------------------------------- Auto Claim Playtime Reward: Claim("Gift", 1..9)
local function claimAllPlaytime(manual)
    local rName = trim(fields.ptRemoteName.Text)
    if rName == "" or rName:lower() == "auto" or rName:lower() == "claim" then
        rName = "Claim"
    end
    local category = trim(fields.ptCategory.Text)
    if category == "" then category = "Gift" end

    local maxSlots = math.clamp(tonumber(fields.ptSlots.Text) or 9, 1, 20)
    local claimedSlots = {}

    for i = 1, maxSlots do
        local ok, res = callRemote(rName, table.pack(category, i), "playtime", false)
        if ok and res ~= nil and res ~= false then
            local isFail = (type(res) == "table" and (res.Success == false or res.ok == false or res.Error ~= nil))
            if not isFail then
                claimedSlots[#claimedSlots + 1] = tostring(i)
            end
        end
        task.wait(0.05)
    end

    if manual or #claimedSlots > 0 then
        local status = (#claimedSlots > 0)
            and ("klaim slot [" .. table.concat(claimedSlots, ", ") .. "]!")
            or "belum ada yang siap"
        logLine(string.format("[playtime] %s('%s', 1-%d) -> %s", rName, category, maxSlots, status))
    end
end

ptClaimNowBtn.Activated:Connect(function()
    task.spawn(function() claimAllPlaytime(true) end)
end)

task.spawn(function()
    task.wait(2)
    while alive do
        if state.autoPlaytime then
            pcall(function() claimAllPlaytime(false) end)
        end
        local every = math.max(3, tonumber(fields.ptEvery.Text) or 10)
        local t0 = os.clock()
        while alive and os.clock() - t0 < every do
            task.wait(0.5)
        end
    end
end)

---------------------------------------------------------------- Auto Secret Cast
local lastSecretClick = 0
task.spawn(function()
    while alive do
        if state.autoSecret then
            local pGui = lp:FindFirstChild("PlayerGui")
            if pGui then
                local foundStopBtn = nil
                local hasSecretBanner = false
                local targetWord = trim(fields.secretTarget.Text):lower()
                local targetVisible = (targetWord == "")

                for _, obj in ipairs(pGui:GetDescendants()) do
                    if not obj:IsDescendantOf(gui) and (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Visible then
                        local txt = obj.Text:lower()
                        if txt:find("secret cast", 1, true) or txt:find("spin is what you catch", 1, true) then
                            hasSecretBanner = true
                        end
                        if txt:find("tap to stop", 1, true) then
                            foundStopBtn = obj:IsA("GuiButton") and obj or obj:FindFirstAncestorWhichIsA("GuiButton") or obj
                        end
                        if targetWord ~= "" and txt:find(targetWord, 1, true) then
                            local midY = workspace.CurrentCamera and (workspace.CurrentCamera.ViewportSize.Y * 0.5) or 300
                            local objY = obj.AbsolutePosition.Y + (obj.AbsoluteSize.Y * 0.5)
                            if math.abs(objY - midY) < 45 then
                                targetVisible = true
                            end
                        end
                    end
                end

                if hasSecretBanner and foundStopBtn and (os.clock() - lastSecretClick) > 0.35 then
                    local sRemote = trim(fields.secretStopName.Text)
                    if sRemote ~= "" then
                        fire(sRemote, fields.secretStopArgs.Text, "secret")
                        lastSecretClick = os.clock()
                        logLine("[secret] remote stop dikirim")
                    elseif targetVisible then
                        local delay = math.max(0, tonumber(fields.secretDelay.Text) or 0.15)
                        if delay > 0 then task.wait(delay) end
                        clickGuiObj(foundStopBtn)
                        if VirtualInputManager and workspace.CurrentCamera then
                            local vp = workspace.CurrentCamera.ViewportSize
                            pcall(function()
                                VirtualInputManager:SendMouseButtonEvent(vp.X * 0.5, vp.Y * 0.72, 0, true, game, 1)
                                task.wait(0.03)
                                VirtualInputManager:SendMouseButtonEvent(vp.X * 0.5, vp.Y * 0.72, 0, false, game, 1)
                            end)
                        end
                        lastSecretClick = os.clock()
                        logLine("[secret] TAP TO STOP ditekan!")
                    end
                end
            end
        end
        task.wait(0.05)
    end
end)

---------------------------------------------------------------- Serializer Lengkap
local function ser(v, depth)
    depth = depth or 0
    local t = typeof(v)
    if t == "string" then return '"' .. v .. '"' end
    if t == "Instance" then return v:GetFullName() end
    if t == "table" then
        if depth > 2 then return "{...}" end
        local parts, c = {}, 0
        for k, x in pairs(v) do
            c = c + 1
            if c > 12 then parts[#parts + 1] = "..." break end
            parts[#parts + 1] = tostring(k) .. "=" .. ser(x, depth + 1)
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    return tostring(v)
end

local hooked = false
local oldNamecall, oldFireServer, oldInvokeServer
local pending = {}

local function recordCall(remoteObj, argsPack)
    if not state.rec then return end
    if typeof(remoteObj) ~= "Instance" then return end
    local rName = remoteObj.Name
    if rName == "DoubleRep" or rName == "StartTraining" then return end
    pending[#pending + 1] = { name = rName, args = argsPack }
end

local function installHook()
    if hooked then return true end
    local anyHooked = false

    if hookmetamethod and getnamecallmethod then
        local okh = pcall(function()
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                if state.rec then
                    local method = getnamecallmethod()
                    if method == "FireServer" or method == "InvokeServer" then
                        recordCall(self, table.pack(...))
                    end
                end
                return oldNamecall(self, ...)
            end)
        end)
        if okh then anyHooked = true end
    end

    if hookfunction then
        pcall(function()
            local dummyEvent = Instance.new("RemoteEvent")
            oldFireServer = hookfunction(dummyEvent.FireServer, function(self, ...)
                recordCall(self, table.pack(...))
                return oldFireServer(self, ...)
            end)
            anyHooked = true
        end)
        pcall(function()
            local dummyFunc = Instance.new("RemoteFunction")
            oldInvokeServer = hookfunction(dummyFunc.InvokeServer, function(self, ...)
                recordCall(self, table.pack(...))
                return oldInvokeServer(self, ...)
            end)
            anyHooked = true
        end)
    end

    if not anyHooked then
        logLine("[rekam] tidak didukung executor")
        return false
    end
    hooked = true
    return true
end

onToggle.rec = function(on)
    if on then
        if installHook() then
            logLine("[rekam] aktif (semua remote).")
        else
            state.rec = false
            paintToggle("rec")
        end
    else
        logLine("[rekam] mati")
    end
end

task.spawn(function()
    while alive do
        if #pending > 0 then
            local batch = pending
            pending = {}
            for _, p in ipairs(batch) do
                captured[p.name] = p.args
                local parts = {}
                for i = 1, p.args.n do parts[i] = ser(p.args[i]) end
                logLine(string.format("[rekam] %s(%s)", p.name, table.concat(parts, ", ")))
            end
        end
        task.wait(0.3)
    end
end)

scanBtn.Activated:Connect(function()
    task.spawn(function()
        logLine("== SCAN REMOTE ==")
        local count = 0
        for _, root in ipairs(getAllRemoteContainers()) do
            if root then
                for _, d in ipairs(root:GetDescendants()) do
                    if (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) and not d:IsDescendantOf(gui) then
                        count = count + 1
                        logLine(string.format("[%s] %s", d:IsA("RemoteEvent") and "E" or "F", d.Name))
                    end
                end
            end
        end
        logLine("Total: " .. tostring(count))
    end)
end)

---------------------------------------------------------------- Koordinator Boost Event <-> Auto Training / Auto Fish
local boostEventActive = false
local lastLoggedEventName = nil

task.spawn(function()
    while alive do
        if state.boostFish then
            local active, evName, timeTxt = getActiveBoostEvent()
            if active and not boostEventActive then
                boostEventActive = true
                lastLoggedEventName = evName
                logLine(string.format("[event] BOOST AKTIF: %s (%s) -> beralih ke Auto Fish!", tostring(evName), tostring(timeTxt)))
            elseif not active and boostEventActive then
                boostEventActive = false
                logLine(string.format("[event] BOOST SELESAI: %s -> keluar mode fishing & kembali ke Training!", tostring(lastLoggedEventName or "")))
                lastLoggedEventName = nil
                -- Bersihkan kamera & visual mode fishing (CastEnd + Unequip + Camera Custom + Tap 2x)
                exitFishingVisualState()
            end
        else
            if boostEventActive then
                boostEventActive = false
                lastLoggedEventName = nil
                exitFishingVisualState()
            end
        end
        task.wait(0.4)
    end
end)

onToggle.boostFish = function(on)
    logLine(on and "[event] Auto Fish saat Boost Event: AKTIF" or "[event] Auto Fish saat Boost Event: MATI")
    if not on and not state.fish then
        task.spawn(exitFishingVisualState)
    end
end

---------------------------------------------------------------- Auto training (Dijeda Otomatis Saat Boost Event Fish Berjalan)
local wasTraining = false
onToggle.train = function(on)
    if on and state.trainGoZone and not (state.boostFish and boostEventActive) then
        task.spawn(function()
            local pos, yaw = getTrainingTarget()
            moveToTarget(pos, yaw, nil, state.trainTeleport, "train")
        end)
    end
end

task.spawn(function()
    local lastStart, lastDouble = -1e9, -1e9
    while alive do
        local now = os.clock()
        local shouldRunTrain = state.train and not (state.boostFish and boostEventActive)

        if shouldRunTrain then
            if not wasTraining then
                -- Pastikan visual fishing sudah bersih saat memulai ulang Training
                exitFishingVisualState()
                if state.trainGoZone then
                    local pos, yaw = getTrainingTarget()
                    moveToTarget(pos, yaw, nil, state.trainTeleport, "train")
                end
                logLine("[train] berjalan...")
            end
            wasTraining = true
            local every = math.max(0.5, tonumber(fields.startEvery.Text) or 5)
            if now - lastStart >= every then
                lastStart = now
                fire(fields.startName.Text, fields.startArgs.Text, "train")
            end
            if state.double then
                local dEvery = math.max(0.2, tonumber(fields.doubleEvery.Text) or 1)
                if now - lastDouble >= dEvery then
                    lastDouble = now
                    fire(fields.doubleName.Text, fields.doubleArgs.Text, "double")
                end
            end
        elseif wasTraining then
            wasTraining = false
            if state.stopOnOff then fire(fields.stopName.Text, fields.stopArgs.Text, "stop") end
            logLine(state.train and "[train] dijeda sementara (event fish aktif)" or "[train] dihentikan")
        end
        task.wait(0.25)
    end
end)

---------------------------------------------------------------- Auto fish (Manual ON atau Otomatis Saat Boost Event)
local castCount = 0

local function shouldFishNow()
    return alive and (state.fish or (state.boostFish and boostEventActive))
end

local function ensureRodEquipped()
    if not state.autoEquipRod then return true end
    local char = lp.Character
    if not char then return false end
    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool then return true end

    local bp = lp:FindFirstChild("Backpack")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if bp and hum then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                hum:EquipTool(tool)
                logLine("[fish] equip: " .. tool.Name)
                task.wait(0.25)
                return true
            end
        end
    end
    return false
end

local function getCastPower()
    if state.perfect then
        return tonumber(fields.castPower.Text) or 1
    end
    return 0.8
end

local function doClaimAndEnd()
    if state.autoReel and trim(fields.reelName.Text) ~= "" then
        local okR, resR = fire(fields.reelName.Text, fields.reelArgs.Text, "claim")
        logLine(string.format("[claim] ok=%s hasil=%s", tostring(okR), ser(resR)))
    end
    if state.sendCastEnd then
        callRemote("CastEnd", table.pack(), "end")
    end
end

local function castCycleOnce()
    if not shouldFishNow() then return false end

    if state.fishGoSpot then
        local pos, yaw, lookAt = getFishingTarget()
        moveToTarget(pos, yaw, lookAt, state.fishTeleport, "fish")
    end
    if not shouldFishNow() then return false end

    castCount = castCount + 1
    ensureRodEquipped()

    local okB, resB = callRemote(fields.castBeginName.Text, table.pack(), "fish")
    if not okB or not shouldFishNow() then return false end

    local gap = math.max(0.2, tonumber(fields.castGap.Text) or 0.6)
    task.wait(gap)
    if not shouldFishNow() then return false end

    local power = getCastPower()
    local a2 = parseArgs(fields.castArg2.Text, "")
    local args = table.pack(power)
    for i = 1, (a2.n or #a2) do args[i + 1] = a2[i] end
    args.n = 1 + (a2.n or #a2)

    local okC, resC = callRemote(fields.castName.Text, args, "fish")
    local info = (type(resC) == "table" and resC) or (type(resB) == "table" and resB) or nil

    logLine(string.format("[fish] #%d pwr=%s ok=%s hasil=%s", castCount, tostring(power), tostring(okC), ser(info)))

    if okC and type(info) == "table" then
        local waitSec = tonumber(fields.reelAfter.Text) or 5
        local offset = tonumber(fields.reelOffset.Text) or 0.15

        if type(info.FlightTime) == "number" and info.FlightTime > 0 then
            waitSec = info.FlightTime + offset
        elseif type(info.ReadyAt) == "number" then
            local diff = info.ReadyAt - os.time()
            if diff > 0 and diff < 30 then
                waitSec = diff + offset
            end
        end

        local tagSecret = info.Secret and " [SECRET!]" or ""
        logLine(string.format("[fish]%s %s | Bonus=%s | tunggu %.2f dtk...", tagSecret, tostring(info.Rarity or ""), tostring(info.Bonus), waitSec))

        -- Tunggu bertahap agar bisa langsung dibatalkan jika boost event selesai di tengah jalan
        local tWait = os.clock()
        local targetWait = math.max(0.3, waitSec)
        while alive and (os.clock() - tWait) < targetWait do
            if not shouldFishNow() then
                callRemote("CastEnd", table.pack(), "end", true)
                return false
            end
            task.wait(0.1)
        end

        doClaimAndEnd()
        task.wait(0.6)
        return true
    end

    if okC and info == nil then
        logLine("[fish] hasil nil -> reset status & tunggu 2 dtk...")
        if state.sendCastEnd then
            callRemote("CastEnd", table.pack(), "end")
        end
        task.wait(2)
        return false
    end

    return okC
end

task.spawn(function()
    while alive do
        if shouldFishNow() then
            local ok, err = pcall(castCycleOnce)
            if not ok then
                logLine("[fish] error: " .. tostring(err))
                task.wait(2)
            end
            local every = math.max(0.5, tonumber(fields.castEvery.Text) or 1.2)
            local t0 = os.clock()
            while shouldFishNow() and os.clock() - t0 < every do
                task.wait(0.2)
            end
        else
            task.wait(0.3)
        end
    end
end)

castTestBtn.Activated:Connect(function()
    task.spawn(function()
        local ok, err = pcall(castCycleOnce)
        if not ok then logLine("[tes] error: " .. tostring(err)) end
    end)
end)

claimNowBtn.Activated:Connect(function()
    task.spawn(doClaimAndEnd)
end)

onToggle.fish = function(on)
    logLine(on and "[fish] menuju dermaga & mulai siklus +25" or "[fish] dihentikan")
    if not on and not (state.boostFish and boostEventActive) then
        task.spawn(exitFishingVisualState)
    end
end

---------------------------------------------------------------- Pantau event server
local watchConns = {}
local function disconnectWatch()
    for _, c in ipairs(watchConns) do pcall(function() c:Disconnect() end) end
    watchConns = {}
end
local function hookEvent(ev)
    local okc, c = pcall(function()
        return ev.OnClientEvent:Connect(function(...)
            if not state.watch then return end
            local keys = splitKeys(fields.watchKeys.Text)
            if #keys > 0 and not hit(ev.Name, keys) then return end
            local a = table.pack(...)
            local parts = {}
            for i = 1, math.min(a.n, 6) do parts[i] = ser(a[i]) end
            logLine(string.format("[event] %s(%s)", ev.Name, table.concat(parts, ", ")))
        end)
    end)
    if okc then watchConns[#watchConns + 1] = c end
end
onToggle.watch = function(on)
    disconnectWatch()
    if not on then logLine("[event] pantau mati") return end
    for _, root in ipairs(getAllRemoteContainers()) do
        if root then
            for _, d in ipairs(root:GetDescendants()) do
                if d:IsA("RemoteEvent") and not d:IsDescendantOf(gui) then hookEvent(d) end
            end
        end
    end
    logLine("[event] memantau RemoteEvent...")
end

---------------------------------------------------------------- Anti AFK
table.insert(conns, lp.Idled:Connect(function()
    if not state.afk then return end
    pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new(0, 0)) end)
end))

---------------------------------------------------------------- Tutup
local function cleanup()
    alive = false
    state.rec = false
    state.watch = false
    state.hideAnim = false
    updateFishingVisuals()
    disconnectWatch()
    if dirty then saveConfig(true) end
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function() gui:Destroy() end)
    env.AutoTrainingCleanup = nil
end
closeBtn.Activated:Connect(cleanup)
env.AutoTrainingCleanup = cleanup

-- Deteksi awal jangkar Spawn Base
detectMyBaseAnchor()

-- Muat config otomatis jika tersedia
local saved = readConfig()
if saved then
    applyConfig(saved, true)
    if state.autoLoad then
        applyConfig(saved, false)
        logLine("[config] auto-load berhasil")
    end
end

if trim(fields.ptRemoteName.Text):lower() == "auto" or trim(fields.ptRemoteName.Text):lower() == "claim" then
    fields.ptRemoteName.Text = "Claim"
end
if trim(fields.ptCategory.Text) == "" then
    fields.ptCategory.Text = "Gift"
end

logLine("Siap! Auto reset kamera + tap 2x aktif saat boost selesai.")
