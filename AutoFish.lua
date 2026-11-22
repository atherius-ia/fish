-- Auto Training + Auto Fish (+25) + Auto Secret Cast + Auto Playtime Gift 1-9 (Landscape Split UI + Logo Minimize)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
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

local FULL_W, FULL_H = 535, 330
local LOGO_SIZE = 44
local minimized = false

local main = Instance.new("Frame")
main.Size = UDim2.new(0, FULL_W, 0, FULL_H)
main.Position = UDim2.new(0, 16, 0.5, -FULL_H / 2)
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

-- Header Bar (Area geser lebar di bagian atas)
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

-- Drag halus untuk main frame & tombol Logo 'A' (membedakan geser vs klik)
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

-- Kontainer Kiri (Tab + Menu) & Kontainer Kanan (Log)
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
tabLay.Padding = UDim.new(0, 5)
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
    b.Size = UDim2.new(0, 75, 1, 0)
    b.BackgroundColor3 = COL_BTN
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
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
logScroll.ScrollBarThickness = 4
logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
logScroll.Parent = rightPane

local logBox = Instance.new("TextLabel")
logBox.Size = UDim2.new(1, -6, 0, 0)
logBox.Position = UDim2.new(0, 2, 0, 0)
logBox.AutomaticSize = Enum.AutomaticSize.Y
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
local function logLine(s)
    lines[#lines + 1] = tostring(s)
    if #lines > 120 then table.remove(lines, 1) end
    logBox.Text = table.concat(lines, "\n")
    task.spawn(function()
        task.wait()
        if logScroll and logScroll.Parent then
            logScroll.CanvasPosition = Vector2.new(0, math.max(0, logScroll.AbsoluteCanvasSize.Y - logScroll.AbsoluteWindowSize.Y + 20))
        end
    end)
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
    end
end

minBtn.Activated:Connect(function()
    setMinimized(true)
end)

attachDrag(logoBtn, function()
    setMinimized(false)
end)

---------------------------------------------------------------- Isi menu
createPage("Training")
createPage("Fishing")
createPage("Rewards")
createPage("Config")

-- ===== Tab Training =====
usePage("Training")
mkToggle("train", "Auto Training", false)
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
mkToggle("hideAnim", "Sembunyikan Bar & Animasi", true)
mkToggle("perfect", "Kunci +25 (Power = 1)", true)
mkField("castBeginName", "Remote CastBegin", "CastBegin")
mkField("castName", "Remote Cast", "Cast")
mkField("castPower", "Power cast (1 = +25)", "1")
mkField("castArg2", "Argumen ke-2 Cast", "1")
mkField("castGap", "Jeda Begin -> Cast", "0.6")
mkField("castEvery", "Jeda antar siklus", "1.5")

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
mkField("reelAfter", "Tunggu max claim (dtk)", "6")
mkToggle("sendCastEnd", "Kirim CastEnd setelah claim", true)
mkToggle("watch", "Pantau event server", false)
mkField("watchKeys", "Filter event", "fish,bite,reel,catch,cast,claim,end,secret,spin")
local castTestBtn = mkBtn("Tes 1 siklus penuh (+25)", COL_BLUE)
local claimNowBtn = mkBtn("Paksa ClaimCatch sekarang", COL_BTN)

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

---------------------------------------------------------------- Sembunyikan UI & Animasi Pancing
local hiddenGuis = {}
local function updateFishingVisuals()
    local pGui = lp:FindFirstChild("PlayerGui")
    if not pGui then return end

    if state.hideAnim then
        for _, obj in ipairs(pGui:GetDescendants()) do
            if not obj:IsDescendantOf(gui) then
                if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                    local t = obj.Text:lower()
                    if (t:find("tap to cast", 1, true) or t:match("^%+%d+$")) and not t:find("secret", 1, true) then
                        local root = obj
                        while root.Parent and root.Parent ~= pGui and not root.Parent:IsA("ScreenGui") do
                            root = root.Parent
                        end
                        if root:IsA("GuiObject") and root.Visible then
                            hiddenGuis[root] = true
                            root.Visible = false
                        end
                    end
                elseif obj:IsA("GuiObject") and hit(obj.Name, { "castbar", "powerbar", "fishingbar", "tapcast" }) then
                    if obj.Visible then
                        hiddenGuis[obj] = true
                        obj.Visible = false
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
        task.wait(0.25)
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

---------------------------------------------------------------- Rekam (Dual-Hook) & Scan remote
local function ser(v, depth)
    depth = depth or 0
    local t = typeof(v)
    if t == "string" then return '"' .. v .. '"' end
    if t == "Instance" then return v:GetFullName() end
    if t == "table" then
        if depth > 1 then return "{...}" end
        local parts, c = {}, 0
        for k, x in pairs(v) do
            c = c + 1
            if c > 6 then parts[#parts + 1] = "..." break end
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

---------------------------------------------------------------- Auto training
local wasTraining = false
task.spawn(function()
    local lastStart, lastDouble = -1e9, -1e9
    while alive do
        local now = os.clock()
        if state.train then
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
            logLine("[train] dihentikan")
        end
        task.wait(0.25)
    end
end)

---------------------------------------------------------------- Auto fish (+25 Full Cycle + Anti-Nil Cooldown)
local castCount = 0
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
    castCount = castCount + 1

    local okB, resB = callRemote(fields.castBeginName.Text, table.pack(), "fish")
    if not okB then return false end

    local gap = math.max(0.2, tonumber(fields.castGap.Text) or 0.6)
    task.wait(gap)

    local power = getCastPower()
    local a2 = parseArgs(fields.castArg2.Text, "")
    local args = table.pack(power)
    for i = 1, (a2.n or #a2) do args[i + 1] = a2[i] end
    args.n = 1 + (a2.n or #a2)

    local okC, resC = callRemote(fields.castName.Text, args, "fish")
    local info = (type(resC) == "table" and resC) or (type(resB) == "table" and resB) or nil
    logLine(string.format("[fish] #%d pwr=%s res=%s", castCount, tostring(power), ser(resC)))

    if okC and type(info) == "table" then
        local waitSec = tonumber(fields.reelAfter.Text) or 6
        if type(info.ReadyAt) == "number" then
            local diff = info.ReadyAt - os.time()
            if diff > 0 and diff < 30 then
                waitSec = diff + 0.35
            end
        end
        logLine(string.format("[fish] +25=%s | tunggu %.1f dtk", tostring(info.Bonus), waitSec))
        task.wait(math.max(0.5, waitSec))
        doClaimAndEnd()
        task.wait(0.8)
        return true
    end

    if okC and info == nil then
        logLine("[fish] cooldown (nil) -> tunggu 2 dtk...")
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
        if state.fish then
            local ok, err = pcall(castCycleOnce)
            if not ok then
                logLine("[fish] error: " .. tostring(err))
                task.wait(2)
            end
            local every = math.max(0.5, tonumber(fields.castEvery.Text) or 1.5)
            local t0 = os.clock()
            while alive and state.fish and os.clock() - t0 < every do task.wait(0.2) end
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
    logLine(on and "[fish] siklus +25 dimulai" or "[fish] dihentikan")
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
            for i = 1, math.min(a.n, 4) do parts[i] = ser(a[i]) end
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

-- Muat config otomatis jika tersedia
local saved = readConfig()
if saved then
    applyConfig(saved, true)
    if state.autoLoad then
        applyConfig(saved, false)
        logLine("[config] auto-load berhasil")
    end
end

-- Normalisasi huruf kapital 'Claim' & 'Gift' jika tersimpan huruf kecil
if trim(fields.ptRemoteName.Text):lower() == "auto" or trim(fields.ptRemoteName.Text):lower() == "claim" then
    fields.ptRemoteName.Text = "Claim"
end
if trim(fields.ptCategory.Text) == "" then
    fields.ptCategory.Text = "Gift"
end

logLine("Siap! Tap '-' untuk minimize ke logo A.")
