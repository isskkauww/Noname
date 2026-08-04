local registry = (type(getreg) == "function" and pcall(getreg) and getreg()) or (type(debug) == "table" and type(debug.getregistry) == "function" and debug.getregistry()) or getgenv()

registry.__NN_private = registry.__NN_private or {}
local nnPrivate = registry.__NN_private

if nnPrivate.Loaded then return end
nnPrivate.Loaded = true

if not game:IsLoaded() then game.Loaded:Wait() end

-- only for rarely used variables
local rare = {
	fpdh = workspace.FallenPartsDestroyHeight,
	hitboxOriginals = {},
	uiScaleValue = 1,
	cmdPrefix = ";",
}

local cloneref = type(cloneref) == "function" and cloneref or function(x) return x end

local function SafeWord()
	local chars = {}
	for i = 1, 128 do
		chars[i] = string.char(math.random(128, 255))
	end
	return table.concat(chars)
end

local function NewInstance(className, parent)
	local inst = Instance.new(className)
	inst.Name = SafeWord()
	if parent then inst.Parent = parent end
	return inst
end

rare.loadStart = os.clock()

local function safeLoad(url)
	local loader = (type(loadstring) == "function" and loadstring) or (type(load) == "function" and load)

	if not loader then
		return nil, "This executor does not provide loadstring/load."
	end

	local function fetch(u)
		if type(game.HttpGet) == "function" then
			local ok, res = pcall(function() return game:HttpGet(u) end)
			if ok then return res end
		end

		local HttpService = cloneref(game:GetService("HttpService"))
		if type(HttpService.GetAsync) == "function" then
			local ok, res = pcall(function() return HttpService:GetAsync(u) end)
			if ok then return res end
		end

		local reqFn = (type(request) == "function" and request) or (type(http_request) == "function" and http_request) or (type(syn) == "table" and type(syn.request) == "function" and syn.request) or (type(http) == "table" and type(http.request) == "function" and http.request)

		if reqFn then
			local ok, res = pcall(function()
				return reqFn({ Url = u, Method = "GET" })
			end)
			if ok and res and res.Body then return res.Body end
		end

		return nil
	end

	local body = fetch(url)
	if not body then
		return nil, "Failed to fetch: " .. tostring(url) .. " (no working HTTP method found)."
	end

	local chunk, compileErr = loader(body)
	if not chunk then
		return nil, "Failed to compile script: " .. tostring(compileErr)
	end

	local ok, result = pcall(chunk)
	if not ok then
		return nil, "Error while running module: " .. tostring(result)
	end

	return result
end

local NNNotify
NNNotify, rare.nnErr = safeLoad("https://raw.githubusercontent.com/isskkauww/Noname/refs/heads/main/NonameNotifications.lua")
if not NNNotify then
	warn("[Noname] Failed to load NonameNotifications module: " .. tostring(rare.nnErr))
	return
end

local UI
UI, rare.uiErr = safeLoad("https://raw.githubusercontent.com/isskkauww/Noname/refs/heads/main/Noname-Ui.lua")
if not UI then
	warn("[Noname] Failed to load UI module: " .. tostring(rare.uiErr))
	return
end

-- Variables & Services
local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local Players = cloneref(game:GetService("Players"))
local HttpService = cloneref(game:GetService("HttpService"))
local TeleportService = cloneref(game:GetService("TeleportService"))
local GuiService = cloneref(game:GetService("GuiService"))
local Lighting = cloneref(game:GetService("Lighting"))
local Vim = nil
pcall(function() Vim = cloneref(game:GetService("VirtualInputManager")) end)
local LocalPlayer = Players.LocalPlayer
local Camera = cloneref(workspace.CurrentCamera)
local cachedPlayers = {}
local noclipParts = {}
local loopBringTargets = {}
local fpsbooster = nil
local func = {
	feat = {},
	esp = {},
	persist = {},
	build = {},
	init = {},
}
local flying = false
local bodyVelocity = nil
local bodyGyro = nil
local NNConn = {}
local Cmds = {}
local Controls = require(cloneref(LocalPlayer:WaitForChild("PlayerScripts")):WaitForChild("PlayerModule")):GetControls()
local flyspeed = nil
local execapi = {
	writefile = type(writefile) == "function" and writefile or nil,
	readfile = type(readfile) == "function" and readfile or nil,
	isfile = type(isfile) == "function" and isfile or nil,
	isfolder = type(isfolder) == "function" and isfolder or nil,
	makefolder = type(makefolder) == "function" and makefolder or nil,
	sethiddenproperty = (type(sethiddenproperty) == "function" and sethiddenproperty) or (type(set_hidden_property) == "function" and set_hidden_property) or (type(set_hidden_prop) == "function" and set_hidden_prop) or nil,
	clipboard = type(setclipboard) == "function" and setclipboard or type(toclipboard) == "function" and toclipboard or type(set_clipboard) == "function" and set_clipboard,
	setfpscap = type(setfpscap) == "function" and setfpscap or nil,
	hookmetamethod = type(hookmetamethod) == "function" and hookmetamethod or nil,
	hookfunction = (type(hookfunction) == "function" and hookfunction) or (type(replaceclosure) == "function" and replaceclosure) or (type(replacefunction) == "function" and replacefunction) or (type(hookfunc) == "function" and hookfunc) or (type(replacefunc) == "function" and replacefunc) or (type(detourfunction) == "function" and detourfunction) or (type(detour_function) == "function" and detour_function) or nil,
	getrawmetatable = type(getrawmetatable) == "function" and getrawmetatable or nil,
	setreadonly = type(setreadonly) == "function" and setreadonly or nil,
	newcclosure = type(newcclosure) == "function" and newcclosure or nil,
	setstackhidden = type(setstackhidden) == "function" and setstackhidden or nil,
	checkcaller = type(checkcaller) == "function" and checkcaller or nil,
	getgc = (type(getgc) == "function" and getgc) or (type(debug) == "table" and type(debug.getgc) == "function" and debug.getgc) or nil,
	getrenv = type(getrenv) == "function" and getrenv or nil,
}
local espOpts = { color = Color3.fromRGB(255, 80, 80), distance = false, health = false, chamsonly = false, colorByTeam = false, useCustomColor = false }
local ignoreTeamOpts = { silentaim = false, aimlock = false, hitbox = false, fling = false }
local afkMode = nil
local playerChar = LocalPlayer.Character
local playerHum = playerChar and playerChar:FindFirstChildOfClass("Humanoid")
local playerHRP = playerChar and playerChar:FindFirstChild("HumanoidRootPart")

-- notify
rare.nnSuppressNotify = false

local function notify(icon, duration, title, text, button, button2)
	if rare.nnSuppressNotify then return end
	local cfg = {
		Title = title or "Noname",
		Text = text or "",
		Duration = duration or 4,
		Icon = icon,
	}
	if button or button2 then
		local btns = {}
		if button then btns[#btns + 1] = button end
		if button2 then btns[#btns + 1] = button2 end
		cfg.Buttons = btns
	end
	if NNNotify then NNNotify(cfg) end
end

-- GoodSignal
local freeRunnerThread = nil

local function acquireRunnerThreadAndCallEventHandler(fn, ...)
	local acquiredRunnerThread = freeRunnerThread
	freeRunnerThread = nil
	fn(...)
	freeRunnerThread = acquiredRunnerThread
end

local function runEventHandlerInFreeThread()
	while true do
		acquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end

local Connection = {}
Connection.__index = Connection

function Connection.new(signal, fn)
	return setmetatable({ connected = true, signal = signal, fn = fn, next = false }, Connection)
end

function Connection:Disconnect()
	self.connected = false

	if self.signal.handlerListHead == self then
		self.signal.handlerListHead = self.next
	else
		local prev = self.signal.handlerListHead
		while prev and prev.next ~= self do
			prev = prev.next
		end
		if prev then
			prev.next = self.next
		end
	end
end

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ handlerListHead = false }, Signal)
end

function Signal:Connect(fn)
	local connection = Connection.new(self, fn)
	connection.next = self.handlerListHead
	self.handlerListHead = connection
	return connection
end

function Signal:DisconnectAll()
	self.handlerListHead = false
end

function Signal:Fire(...)
	local item = self.handlerListHead
	while item do
		if item.connected then
			if not freeRunnerThread then
				freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
				coroutine.resume(freeRunnerThread)
			end
			task.spawn(freeRunnerThread, item.fn, ...)
		end
		item = item.next
	end
end

function Signal:Wait()
	local waitingCoroutine = coroutine.running()
	local cn
	cn = self:Connect(function(...)
		cn:Disconnect()
		task.spawn(waitingCoroutine, ...)
	end)
	return coroutine.yield()
end

function Signal:Once(fn)
	local cn
	cn = self:Connect(function(...)
		if cn.connected then
			cn:Disconnect()
		end
		fn(...)
	end)
	return cn
end

-- cache
local PlayerAdded = Signal.new()
local PlayerRemoving = Signal.new()
local CharacterAdded = Signal.new()
local CharacterCached = Signal.new()

Players.PlayerAdded:Connect(function(player)
	cachedPlayers[player] = true
	PlayerAdded:Fire(player)
end)

Players.PlayerRemoving:Connect(function(player)
	cachedPlayers[player] = nil
	PlayerRemoving:Fire(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	cachedPlayers[player] = true
end

LocalPlayer.CharacterAdded:Connect(function(char)
	CharacterAdded:Fire(char)
end)

CharacterAdded:Connect(function(char)
	playerChar = char
	playerHum = char:WaitForChild("Humanoid")
	playerHRP = char:WaitForChild("HumanoidRootPart")
	CharacterCached:Fire()
end)

-- NnBind
local nnPrCnt = 0

local function nnIsLive(conn)
	if conn == nil then return false end
	if type(conn) == "table" and type(conn.connected) == "boolean" then
		return conn.connected
	end
	local ok, res = pcall(function() return conn.Connected end)
	return ok and res == true
end

local function nnPrune(name)
	local bucket = NNConn[name]
	if type(bucket) ~= "table" then
		NNConn[name] = nil
		return 0
	end
	local write = 1
	for i = 1, #bucket do
		if nnIsLive(bucket[i]) then
			bucket[write] = bucket[i]
			write += 1
		end
	end
	for i = write, #bucket do bucket[i] = nil end
	local alive = write - 1
	if alive <= 0 then NNConn[name] = nil end
	return alive
end

local NnBind = {}

NnBind.connect = function(name, conn)
	if not name or not conn then return conn end
	nnPrune(name)
	local bucket = NNConn[name]
	if type(bucket) ~= "table" then
		bucket = {}
		NNConn[name] = bucket
	end
	table.insert(bucket, conn)
	nnPrCnt += 1
	if nnPrCnt % 128 == 0 then
		for key in NNConn do nnPrune(key) end
	end
	return conn
end

NnBind.disconnect = function(name)
	if not name then return end
	local bucket = NNConn[name]
	if type(bucket) == "table" then
		for _, conn in bucket do
			pcall(function()
				if conn and type(conn.Disconnect) == "function" then
					conn:Disconnect()
				end
			end)
		end
	end
	NNConn[name] = nil
end

NnBind.reconnect = function(name, conn)
	NnBind.disconnect(name)
	return NnBind.connect(name, conn)
end

NnBind.isConnected = function(name)
	if not name then return false end
	return nnPrune(name) > 0
end

-- Local Functions & Some Logic
local cmdFrame = UI.CommandBar.frame
local inputBox = UI.CommandBar.inputBox
local suggFrame = UI.CommandBar.suggFrame
local suggItems = UI.CommandBar.suggItems
local hudSg = UI.HUD.sg
local makeButtonHUD = UI.HUD.makeButton
local makeToggleHUD = UI.HUD.makeToggle

for i = 1, #suggItems do
	local item = suggItems[i]
	item.MouseButton1Down:Connect(function()
		rare.clickingSugg = true
	end)
	item.Activated:Connect(function()
		local first = string.match(item.Text, "^([^/%s]+)")
		local hasArgs = string.find(item.Text, "%[") or string.find(item.Text, "%(")
		if hasArgs then
			inputBox.Text = first .. " "
			rare.clickingSugg = false
			inputBox:CaptureFocus()
		else
			inputBox.Text = first
			rare.clickingSugg = false
			rare.closeCmd(first)
		end
	end)
end
local aliasLookup = {}
local cmdDisplayRows = {}

func.init.commandCaches = function()
	table.clear(aliasLookup)
	table.clear(cmdDisplayRows)
	local seen = {}
	for _, entry in ipairs(Cmds) do
		for _, alias in ipairs(entry.aliases) do
			aliasLookup[string.lower(alias)] = entry
		end
		local label = table.concat(entry.aliases, "/")
		if not seen[label] then
			seen[label] = true
			local mainName = entry.aliases[1]
			local suffix = ""
			if entry.args then suffix = suffix .. " <" .. entry.args .. ">" end
			if entry.args2 then suffix = suffix .. " <" .. entry.args2 .. ">" end
			if entry.args3 then suffix = suffix .. " <" .. entry.args3 .. ">" end
			if #entry.aliases > 1 then
				local aliasDisplay = {}
				for i = 2, #entry.aliases do aliasDisplay[#aliasDisplay + 1] = entry.aliases[i] end
				suffix = suffix .. " (" .. table.concat(aliasDisplay, ", ") .. ")"
			end
			cmdDisplayRows[#cmdDisplayRows + 1] = {
				entry = entry,
				label = label,
				lower = string.lower(label),
				display = suffix ~= "" and (mainName .. suffix) or mainName,
			}
		end
	end
end

local function updateSugg(txt)
	if txt == "" then
		suggFrame.Visible = false
		return
	end
	local count = 0
	local tl = #txt
	for _, row in ipairs(cmdDisplayRows) do
		for _, alias in ipairs(row.entry.aliases) do
			if string.sub(string.lower(alias), 1, tl) == txt then
				count += 1
				local displayText = row.display
				suggItems[count].Text = displayText
				suggItems[count].Size = UDim2.new(0, 150 + #displayText * 7, 0, 30)
				suggItems[count].Visible = true
				break
			end
		end
		if count >= 6 then
			break
		end
	end
	if count == 0 then
		suggFrame.Visible = false
		return
	end
	for i = count + 1, 6 do
		suggItems[i].Text = ""
		suggItems[i].Visible = false
	end
	suggFrame.Size = UDim2.new(0, 400, 0, count * 30 + (count - 1) * 10)
	suggFrame.Visible = true
end

local DC = {}

local hudMap = {}
local hudYOffset = 0
local dynamicHuds = {}

local function recalcHudOffset()
	local y = 0
	for _, h in pairs(dynamicHuds) do
		y += h.height or 50
	end
	hudYOffset = y
end

local function spawnHud(btnData)
	if type(btnData) ~= "table" then return end
	local alias = btnData.command
	if type(alias) ~= "string" then return end
	local argDefault = (btnData.arg and btnData.arg ~= "") and btnData.arg or nil
	local entry = aliasLookup[alias]
	if not entry or not entry.fn then return end
	local key = alias .. (argDefault and ("_" .. argDefault) or "")
	if dynamicHuds[key] then return end
	local label = alias:sub(1, 1):upper() .. alias:sub(2)
	local unEntry = aliasLookup["un" .. alias]
	local hud
	local function getArgPh(e)
		return e.args and e.args:match("^%s*(.-)%s*$") or nil
	end
	if unEntry and unEntry.fn then
		local ph = getArgPh(entry)
		local defVal = argDefault or entry.hudDefault or nil
		hud = makeToggleHUD(
			function(v) entry.fn(v or argDefault) end,
			unEntry.fn,
			hudYOffset, ph, defVal, label, label)
		hud.height = (ph and defVal) and 80 or 50
	else
		local ph = getArgPh(entry)
		local defVal = argDefault or entry.hudDefault or nil
		hud = makeButtonHUD(label,
			function(v) entry.fn(v or argDefault) end,
			hudYOffset, ph, defVal)
		hud.height = (ph and defVal) and 80 or 50
	end
	hudYOffset += hud.height
	hud.showOff()
	dynamicHuds[key] = hud
end

local function stripCommas(args)
	local result = {}
	for _, v in ipairs(args) do
		result[#result + 1] = v:gsub(",", "")
	end
	return result
end

local function levenshtein(a, b)
	local la, lb = #a, #b
	if la == 0 then return lb end
	if lb == 0 then return la end
	local row = {}
	for i = 0, lb do row[i] = i end
	for i = 1, la do
		local prev = i
		for j = 1, lb do
			local cost = a:sub(i, i) == b:sub(j, j) and 0 or 1
			local next = math.min(row[j] + 1, prev + 1, row[j - 1] + cost)
			row[j - 1] = prev
			prev = next
		end
		row[lb] = prev
	end
	return row[lb]
end

local function findClosestCmd(cmd)
	local best, bestDist = nil, math.huge
	for alias in pairs(aliasLookup) do
		local d = levenshtein(cmd, alias)
		if d < bestDist then
			bestDist = d
			best = alias
		end
	end
	local threshold = math.max(3, math.floor(#cmd / 2))
	return bestDist <= threshold and best or nil
end

local function runCommand(input)
	local args = {}
	for word in string.gmatch(input, "%S+") do
		args[#args + 1] = word
	end
	if #args == 0 then
		return
	end
	local cmd = args[1]
	local h = hudMap[cmd]
	if h then
		if h.action == "show" then h.hud.show(h.isSpeed and tonumber(args[2]) or nil)
		else h.hud.hide() end
		return
	end
	local entry = aliasLookup[cmd]
	if entry and entry.fn then
		local stopEntry = aliasLookup["un" .. cmd]
		if not stopEntry then
			stopEntry = aliasLookup["un" .. cmd:gsub("^lock", "unlock"):gsub("^loop", "unloop")]
		end
		if stopEntry and stopEntry.fn then
			rare.nnSuppressNotify = true
			stopEntry.fn()
			rare.nnSuppressNotify = false
		end
		entry.fn(table.unpack(args, 2))
	else
		local suggestion = findClosestCmd(cmd)
		if suggestion then
			UI.Autocorrect.show(cmd, suggestion, function(newInput)
				if newInput == nil then return end
				runCommand(newInput ~= "" and newInput or suggestion)
			end)
		end
	end
end
local cmdOpen = false

function UI.CommandBar.open()
	if cmdOpen then
		return
	end
	cmdOpen = true
	cmdFrame.Visible = true
	cmdFrame.Size = UDim2.new(0, 0, 0, 48)
	TweenService:Create(
		cmdFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0, 260, 0, 38) }
	):Play()
	task.delay(0.1, function()
		inputBox:CaptureFocus()
	end)
end

rare.closeCmd = function(input)
	if not cmdOpen then
		return
	end
	cmdOpen = false
	inputBox.Text = ""
	suggFrame.Visible = false
	TweenService:Create(
		cmdFrame,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Size = UDim2.new(0, 0, 0, 48) }
	):Play()
	task.delay(0.25, function()
		cmdFrame.Visible = false
	end)
	if input and input ~= "" then
		runCommand(input)
	end
end

NnBind.connect("cmd_inputText", inputBox:GetPropertyChangedSignal("Text"):Connect(function()
	local txt = string.lower(inputBox.Text)
	if string.find(txt, " ") then
		suggFrame.Visible = false
	else
		updateSugg(txt)
	end
end))

NnBind.connect("cmd_focusLost", inputBox.FocusLost:Connect(function(enter)
	if rare.clickingSugg then
		return
	end
	local input = string.lower(inputBox.Text)
	if not enter then
		rare.closeCmd(nil)
		return
	end
	rare.closeCmd(input)
end))

func.feat.loopwalkspeed = function(Speed)
	local function applyWalkSpeed(char)
		char = char or playerChar
		local hum = char and char:WaitForChild("Humanoid")
		if not hum then
			return
		end

		hum.WalkSpeed = Speed

		NnBind.reconnect("ws_changed", hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			if hum.WalkSpeed ~= Speed then
				hum.WalkSpeed = Speed
			end
		end))
	end

	applyWalkSpeed()

	NnBind.reconnect("ws_charAdded", CharacterAdded:Connect(applyWalkSpeed))
end

func.feat.noclip = function()
	notify("solar:ghost-bold", 3, "Noclip", "Noclip enabled.")
	local function hookCharacter(character)
		table.clear(noclipParts)

		for _, d in ipairs(character:GetDescendants()) do
			if d:IsA("BasePart") then
				noclipParts[d] = true
			end
		end

		NnBind.reconnect("noclip_added", character.DescendantAdded:Connect(function(d)
			if d:IsA("BasePart") then noclipParts[d] = true end
		end))

		NnBind.reconnect("noclip_removing", character.DescendantRemoving:Connect(function(d)
			noclipParts[d] = nil
		end))
	end

	if playerChar then
		hookCharacter(playerChar)
	end

	NnBind.reconnect("noclip_charAdded", CharacterAdded:Connect(function(character)
		hookCharacter(character)
	end))

	NnBind.reconnect("noclip_stepped", RunService.Stepped:Connect(function()
		for part in pairs(noclipParts) do
			part.CanCollide = false
		end
	end))
end

func.feat.invisible = function()
	local char = playerChar
	if not char then
		notify("lucide:eye-off", 4, "Invisible", "No character found.")
		return
	end
	local hum = playerHum
	local hrp = playerHRP
	if not hum or not hrp then
		notify("lucide:eye-off", 4, "Invisible", "No character found.")
		return
	end

	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part ~= hrp and part.Transparency == 0 then
			part.Transparency = 0.5
		end
	end

	notify("sfsymbols:eyeSlashFill", 3, "Invisible", "You are now invisible.")

	NnBind.reconnect("invis_transparency", RunService.Stepped:Connect(function()
		local c = playerChar
		if not c then return end
		for _, part in ipairs(c:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Transparency == 0 then
				part.Transparency = 0.5
			end
		end
	end))

	NnBind.reconnect("invis_heartbeat", RunService.Heartbeat:Connect(function()
		local c = playerChar
		local h = playerHum
		local r = playerHRP
		if not h or not r then return end

		local origCFrame = r.CFrame
		local origOffset = h.CameraOffset
		local underCFrame = origCFrame * CFrame.new(0, -200000, 0)

		r.CFrame = underCFrame
		h.CameraOffset = underCFrame:ToObjectSpace(CFrame.new(origCFrame.Position)).Position

		RunService.RenderStepped:Wait()

		r.CFrame = origCFrame
		h.CameraOffset = origOffset
	end))

	NnBind.reconnect("invis_charAdded", CharacterAdded:Connect(function()
		func.feat.invisible()
	end))
end

func.feat.fly = function(speed, vfly)
	flyspeed = speed * 25

	if flying then return end

	notify("sfsymbols:birdFill", 3, "Fly", "Flying enabled.")

	local character = playerChar or CharacterAdded:Wait()
	local humanoidRootPart = playerHRP or character:WaitForChild("HumanoidRootPart")
	local humanoid = playerHum or character:WaitForChild("Humanoid")

	humanoid.PlatformStand = not vfly
	flying = true

	if vfly then
		local function fixCamera()
			local hum = playerHum
			if hum and Camera.CameraSubject and Camera.CameraSubject.Name == "DriveSeat" then
				Camera.CameraSubject = hum
			end
		end
		NnBind.reconnect("fly_cameraSubject", Camera:GetPropertyChangedSignal("CameraSubject"):Connect(fixCamera))
		fixCamera()
	end

	bodyVelocity = NewInstance("BodyVelocity")
	bodyVelocity.Velocity = Vector3.new(0, 0, 0)
	bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	bodyVelocity.Parent = humanoidRootPart

	bodyGyro = NewInstance("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	bodyGyro.D = 50
	bodyGyro.Parent = humanoidRootPart

	NnBind.connect("fly_stepped", RunService.RenderStepped:Connect(function(dt)
		if not flying then return end

		local moveVector = Controls:GetMoveVector()
		local camCFrame = Camera.CFrame

		local direction = (camCFrame.RightVector * moveVector.X) + (camCFrame.LookVector * -moveVector.Z) + (Vector3.new(0, 1, 0) * moveVector.Y)

		if direction.Magnitude > 0 then
			bodyVelocity.Velocity = direction.Unit * flyspeed
		else
			bodyVelocity.Velocity = Vector3.new(0, 0, 0)
		end

		bodyGyro.CFrame = bodyGyro.CFrame:Lerp(camCFrame, math.min(1, dt * 5))
	end))
end

func.feat.unfly = function()
	flying = false
	notify("sfsymbols:birdFill", 3, "Fly", "Flying disabled.")

	if playerChar then
		local humanoid = playerHum
		if humanoid then
			humanoid.PlatformStand = false
		end
	end

	NnBind.disconnect("fly_cameraSubject")
	NnBind.disconnect("fly_stepped")

	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end
	if bodyGyro then
		bodyGyro:Destroy()
		bodyGyro = nil
	end
end

func.feat.startFc = function(speedArg)
	local speed = tonumber(speedArg) or 5

	if rare.fcPart then rare.fcPart:Destroy() end
	local part = NewInstance("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.CFrame = Camera.CFrame
	part.Parent = workspace
	rare.fcPart = part

	Camera.CameraType = Enum.CameraType.Custom
	Camera.CameraSubject = part

	local root = playerHRP
	if root then root.Anchored = true end

	NnBind.reconnect("fc_char", CharacterAdded:Connect(function()
		CharacterCached:Wait()
		if playerHRP then playerHRP.Anchored = true end
	end))

	NnBind.reconnect("fc_stepped", RunService.RenderStepped:Connect(function(dt)
		local mv = Controls:GetMoveVector()
		local move = (Camera.CFrame.LookVector * -mv.Z) + (Camera.CFrame.RightVector * mv.X)
		if move.X ~= 0 or move.Y ~= 0 or move.Z ~= 0 then
			part.CFrame = part.CFrame + move * (speed * 25 * dt)
		end
	end))

	notify("sfsymbols:camera", 3, "Freecam", "Enabled (speed " .. speed .. ").")
end

func.feat.stopFc = function()
	NnBind.disconnect("fc_stepped")
	NnBind.disconnect("fc_char")
	if rare.fcPart then
		rare.fcPart:Destroy()
		rare.fcPart = nil
	end
	Camera.CameraType = Enum.CameraType.Custom
	if playerHum then Camera.CameraSubject = playerHum end
	local root = playerHRP
	if root then root.Anchored = false end
	notify("sfsymbols:camera", 3, "Freecam", "Disabled.")
end

func.feat.enableAntiVoid = function()
	local function initVoidChar(char)
		local hum = char:WaitForChild("Humanoid")
		local root = char:WaitForChild("HumanoidRootPart")

		NnBind.reconnect("antivoid_health", hum.HealthChanged:Connect(function()
			if root.Position.Y <= rare.fpdh + 20 then
				hum.Health = hum.MaxHealth
			end
		end))
	end

	workspace.FallenPartsDestroyHeight = 0 / 0

	NnBind.reconnect("antivoid_fpdh", workspace:GetPropertyChangedSignal("FallenPartsDestroyHeight"):Connect(function()
		if workspace.FallenPartsDestroyHeight == workspace.FallenPartsDestroyHeight then
			workspace.FallenPartsDestroyHeight = 0 / 0
		end
	end))

	local char = playerChar or CharacterAdded:Wait()
	local root = playerHRP or char:WaitForChild("HumanoidRootPart")

	local platform = workspace:FindFirstChild("VoidPlatform")
	if not platform then
		platform = NewInstance("Part")
		platform.Size = Vector3.new(4000, 100, 4000)
		platform.Anchored = true
		platform.CanCollide = true
		platform.CanTouch = false
		platform.CanQuery = false
		platform.CastShadow = false
		platform.Material = Enum.Material.SmoothPlastic
		platform.Massless = true
		platform.TopSurface = Enum.SurfaceType.Smooth
		platform.BottomSurface = Enum.SurfaceType.Smooth
		platform.Parent = workspace
	end

	platform.Position = Vector3.new(root.Position.X, -5000, root.Position.Z)

	task.spawn(function()
		while true do
			task.wait(4)

			local currentPlatform = workspace:FindFirstChild("VoidPlatform")
			if not currentPlatform then
				break
			end

			if playerChar then
				local currentRoot = playerHRP
				if currentRoot then
					currentPlatform.Position = Vector3.new(currentRoot.Position.X, -5000, currentRoot.Position.Z)
				end
			end
		end
	end)

	NnBind.reconnect("antivoid_char", CharacterAdded:Connect(function(newChar)
		task.wait(0.1)
		initVoidChar(newChar)
	end))

	initVoidChar(char)

	notify("solar:shield-check-bold", 3, "AntiVoid", "Anti-void enabled.")
end

local function prefixMatch(...)
	local results = {}
	for _, name in ipairs({...}) do
		local lname = name:lower()
		local found = nil
		for p in pairs(cachedPlayers) do
			if p.Name:lower() == lname or p.DisplayName:lower() == lname then
				found = p
				break
			end
		end
		if not found then
			local len = #lname
			for p in pairs(cachedPlayers) do
				if string.sub(p.Name:lower(), 1, len) == lname or string.sub(p.DisplayName:lower(), 1, len) == lname then
					found = p
					break
				end
			end
		end
		if found then results[#results + 1] = found end
	end
	return table.unpack(results)
end

func.feat.fling = function(...)
	local targets = {...}
	if #targets == 0 then
		notify("lucide:triangle-alert", 4, "Fling", "No players specified to fling.")
		return
	end

	local Character = playerChar
	local Humanoid = playerHum
	local RootPart = Humanoid and Humanoid.RootPart

	if not (Character and Humanoid and RootPart) then
		notify("lucide:user-x", 4, "Fling", "Your character is not ready.")
		return
	end

	local oldPos = RootPart.Velocity:Dot(RootPart.Velocity) < 2500 and RootPart.CFrame or nil

	local function FPos(BasePart, Pos, Ang)
		RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
		Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
		RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
		RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
	end

	local function SFBasePart(BasePart, playerToFling, THumanoid, TRootPart)
		local Time = tick()
		local Angle = 0
		repeat
			if RootPart and THumanoid then
				local bvel = BasePart.Velocity
				if bvel:Dot(bvel) < 2500 then
					local bmag = bvel.Magnitude
					Angle = Angle + 100
					FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * bmag / 1.25, CFrame.Angles(math.rad(Angle), 0, 0)) task.wait()
					FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * bmag / 1.25, CFrame.Angles(math.rad(Angle), 0, 0)) task.wait()
					FPos(BasePart, CFrame.new( 2.25, 1.5, -2.25) + THumanoid.MoveDirection * bmag / 1.25, CFrame.Angles(math.rad(Angle), 0, 0)) task.wait()
					FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * bmag / 1.25, CFrame.Angles(math.rad(Angle), 0, 0)) task.wait()
					FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0)) task.wait()
					FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0)) task.wait()
				else
					FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0)) task.wait()
					FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0)) task.wait()
					FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0)) task.wait()
					if TRootPart then
						local mag = TRootPart.Velocity.Magnitude
						FPos(BasePart, CFrame.new(0, 1.5, mag / 1.25), CFrame.Angles(math.rad(90), 0, 0)) task.wait()
						FPos(BasePart, CFrame.new(0, -1.5, -mag / 1.25), CFrame.Angles(0, 0, 0)) task.wait()
						FPos(BasePart, CFrame.new(0, 1.5, mag / 1.25), CFrame.Angles(math.rad(90), 0, 0)) task.wait()
					end
					FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0)) task.wait()
					FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0)) task.wait()
					FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(-90), 0, 0)) task.wait()
					FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0)) task.wait()
				end
			else
				break
			end
		until BasePart.Velocity:Dot(BasePart.Velocity) > 250000 or BasePart.Parent ~= playerToFling.Character or playerToFling.Parent == nil or THumanoid.Sit or Humanoid.Health <= 0 or tick() > Time + 2
	end

	local BV = NewInstance("BodyVelocity", RootPart)
	BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
	BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

	for _, playerToFling in ipairs(targets) do
		if playerToFling == LocalPlayer then
			notify("lucide:triangle-alert", 4, "Fling", "Skipping self.")
			continue
		end

		local TCharacter = playerToFling.Character
		local THumanoid = TCharacter and TCharacter:FindFirstChildOfClass("Humanoid")
		local TRootPart = THumanoid and THumanoid.RootPart
		local THead = TCharacter and TCharacter:FindFirstChild("Head")
		local Accessory = TCharacter and TCharacter:FindFirstChildOfClass("Accessory")
		local Handle = Accessory and Accessory:FindFirstChild("Handle")

		if THumanoid and THumanoid.Sit then
			notify("lucide:triangle-alert", 4, "Fling", playerToFling.Name .. " is sitting.")
			continue
		end
		if not TCharacter or not TCharacter:FindFirstChildWhichIsA("BasePart") then
			notify("lucide:user-x", 4, "Fling", playerToFling.Name .. ": character not found.")
			continue
		end

		if THead then Camera.CameraSubject = THead
		elseif Handle then Camera.CameraSubject = Handle
		else Camera.CameraSubject = THumanoid end

		if TRootPart and THead then
			local d = TRootPart.CFrame.p - THead.CFrame.p
			if d:Dot(d) > 25 then SFBasePart(THead, playerToFling, THumanoid, TRootPart)
			else SFBasePart(TRootPart, playerToFling, THumanoid, TRootPart) end
		elseif TRootPart then
			SFBasePart(TRootPart, playerToFling, THumanoid, TRootPart)
		elseif THead then
			SFBasePart(THead, playerToFling, THumanoid, TRootPart)
		elseif Accessory and Handle then
			SFBasePart(Handle, playerToFling, THumanoid, TRootPart)
		else
			notify("lucide:triangle-alert", 4, "Fling", playerToFling.Name .. ": can't find a proper part.")
		end
	end

	BV:Destroy()
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
	Camera.CameraSubject = Humanoid
	notify("lucide:send", 3, "Fling", "Fling complete.")

	if oldPos then
		repeat
			RootPart.CFrame = oldPos * CFrame.new(0, 0.5, 0)
			Character:SetPrimaryPartCFrame(oldPos * CFrame.new(0, 0.5, 0))
			Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			for _, x in ipairs(Character:GetChildren()) do
				if x:IsA("BasePart") then
					x.Velocity = Vector3.new()
					x.RotVelocity = Vector3.new()
				end
			end
			task.wait()
		until (RootPart.Position - oldPos.p):Dot(RootPart.Position - oldPos.p) < 625
	end
end

local cmdListItems = {}

local populateCmdList

func.build.cmdList = function()
	if rare.cmdListFrame then return end
	local built = UI.buildCmdListGui()
	rare.cmdListFrame = built.frame
	rare.cmdListSearch = built.search
	rare.cmdListScroll = built.scroll
	rare.cmdListSearch:GetPropertyChangedSignal("Text"):Connect(function()
		populateCmdList(string.lower(rare.cmdListSearch.Text))
	end)
end

populateCmdList = function(filter)
	local i = 1
	for _, entry in ipairs(cmdDisplayRows) do
		local show = filter == nil or filter == "" or string.find(entry.lower, filter, 1, true)
		if show then
			local item = cmdListItems[i]
			if not item then
				item = UI.buildCmdListRow(rare.cmdListScroll)
				cmdListItems[i] = item
			end
			item.indexLabel.Text = i .. "."
			item.label.Text = entry.display
			item.row.LayoutOrder = i
			item.row.Visible = true
			i += 1
		end
	end
	for n = i, #cmdListItems do cmdListItems[n].row.Visible = false end
end

DC.openCommandList = function()
	func.build.cmdList()
	rare.cmdListSearch.Text = ""
	populateCmdList(nil)
	rare.cmdListFrame.Size = UDim2.new(0, 0, 0, 0)
	rare.cmdListFrame.Visible = true
	TweenService:Create(rare.cmdListFrame, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 300, 0, 380)}):Play()
end

-- keybind system
local keybinds = {}

local kbActiveStates = {}

func.persist.saveKeybinds = function()
	if not execapi.writefile then return end
	if execapi.isfolder and execapi.makefolder and not execapi.isfolder("Noname") then execapi.makefolder("Noname") end
	execapi.writefile("Noname/keybind.json", HttpService:JSONEncode(keybinds))
end

func.persist.loadKeybinds = function()
	if not execapi.readfile or not execapi.isfile or not execapi.isfile("Noname/keybind.json") then return end
	local raw = execapi.readfile("Noname/keybind.json")
	local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
	if ok and type(decoded) == "table" then keybinds = decoded end
end

func.init.keybindListener = function()
	NnBind.reconnect("keybind_input", UserInputService.InputBegan:Connect(function(input, gp)
		if gp or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		local keyName = input.KeyCode.Name:lower()
		for _, kb in ipairs(keybinds) do
			if kb.key and type(kb.key) == "string" and kb.command and type(kb.command) == "string" and kb.key:lower() == keyName then
				local cmd2 = kb.command
				local arg2 = (kb.arg and kb.arg ~= "") and kb.arg or nil
				local entry = aliasLookup[cmd2]
				if entry and entry.fn then
					local stopEntry = aliasLookup["un" .. cmd2]
					if not stopEntry then
						stopEntry = aliasLookup["un" .. cmd2:gsub("^lock", "unlock"):gsub("^loop", "unloop")]
					end
					if stopEntry and stopEntry.fn then
						if kbActiveStates[cmd2] then
							stopEntry.fn(); kbActiveStates[cmd2] = false
						else
							entry.fn(arg2); kbActiveStates[cmd2] = true
						end
					else
						entry.fn(arg2)
					end
				end
				break
			end
		end
	end))
end

-- Button system
local buttons = {}
func.persist.saveButtons = function()
	if not execapi.writefile then return end
	if execapi.isfolder and execapi.makefolder and not execapi.isfolder("Noname") then execapi.makefolder("Noname") end
	execapi.writefile("Noname/button.json", HttpService:JSONEncode(buttons))
end

func.persist.loadButtons = function()
	if not execapi.readfile or not execapi.isfile or not execapi.isfile("Noname/button.json") then return end
	local raw = execapi.readfile("Noname/button.json")
	local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
	if ok and type(decoded) == "table" then
		table.clear(buttons)
		for _, bd in ipairs(decoded) do
			if type(bd) == "table" and type(bd.command) == "string" then
				buttons[#buttons + 1] = {command = bd.command, arg = type(bd.arg) == "string" and bd.arg or ""}
			end
		end
	end
end

func.persist.saveSettings = function()
	if not execapi.writefile then return end
	if execapi.isfolder and execapi.makefolder and not execapi.isfolder("Noname") then execapi.makefolder("Noname") end
	local c = espOpts.color
	execapi.writefile("Noname/Noname_Settings.json", HttpService:JSONEncode({
		esp_color = { r = math.floor(c.R * 255), g = math.floor(c.G * 255), b = math.floor(c.B * 255) },
		esp_distance = espOpts.distance,
		esp_health = espOpts.health,
		esp_chamsonly = espOpts.chamsonly,
		esp_colorByTeam = espOpts.colorByTeam,
		esp_useCustomColor = espOpts.useCustomColor,
		cmd_prefix = rare.cmdPrefix,
		ui_scale = rare.uiScaleValue,
		ignoreteam_silentaim = ignoreTeamOpts.silentaim,
		ignoreteam_aimlock = ignoreTeamOpts.aimlock,
		ignoreteam_hitbox = ignoreTeamOpts.hitbox,
		ignoreteam_fling = ignoreTeamOpts.fling,
	}))
end

func.persist.loadSettings = function()
	if not execapi.readfile or not execapi.isfile or not execapi.isfile("Noname/Noname_Settings.json") then return end
	local raw = execapi.readfile("Noname/Noname_Settings.json")
	local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
	if not ok or type(decoded) ~= "table" then return end
	if type(decoded.esp_color) == "table" then
		local cc = decoded.esp_color
		espOpts.color = Color3.fromRGB(cc.r or 255, cc.g or 80, cc.b or 80)
	end
	if type(decoded.esp_distance) == "boolean" then espOpts.distance = decoded.esp_distance end
	if type(decoded.esp_health) == "boolean" then espOpts.health = decoded.esp_health end
	if type(decoded.esp_chamsonly) == "boolean" then espOpts.chamsonly = decoded.esp_chamsonly end
	if type(decoded.esp_colorByTeam) == "boolean" then espOpts.colorByTeam = decoded.esp_colorByTeam end
	if type(decoded.esp_useCustomColor) == "boolean" then espOpts.useCustomColor = decoded.esp_useCustomColor end
	if type(decoded.cmd_prefix) == "string" and decoded.cmd_prefix ~= "" then rare.cmdPrefix = decoded.cmd_prefix end
	if type(decoded.ui_scale) == "number" then rare.uiScaleValue = decoded.ui_scale end
	if type(decoded.ignoreteam_silentaim) == "boolean" then ignoreTeamOpts.silentaim = decoded.ignoreteam_silentaim end
	if type(decoded.ignoreteam_aimlock) == "boolean" then ignoreTeamOpts.aimlock = decoded.ignoreteam_aimlock end
	if type(decoded.ignoreteam_hitbox) == "boolean" then ignoreTeamOpts.hitbox = decoded.ignoreteam_hitbox end
	if type(decoded.ignoreteam_fling) == "boolean" then ignoreTeamOpts.fling = decoded.ignoreteam_fling end
end

func.build.managerGui = UI.buildManagerGui

local kbGuiOpen = {v = false}

func.build.keybindGui = function()
	local capturing = false
	rare.kbManager = func.build.managerGui({
		sgName = "keybindpanel",
		bz = 100,
		title = "KEYBIND MANAGER",
		icon = "⌨",
		accentColor = Color3.fromRGB(255, 255, 255),
		guiOpenRef = kbGuiOpen,
		mainFrameSetter = function(f) rare.kbMainFrame = f end,
		row2Left = function(cont, BZ)
			local lbl = NewInstance("TextLabel", cont)
			lbl.Size = UDim2.new(0, 178, 0, 14)
			lbl.Position = UDim2.new(0, 0, 0, 58)
			lbl.BackgroundTransparency = 1
			lbl.Text = "Keybind"
			lbl.TextColor3 = Color3.fromRGB(100, 100, 100)
			lbl.Font = Enum.Font.GothamSemibold
			lbl.TextSize = 11
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.ZIndex = BZ + 2
			local keyIn = NewInstance("TextButton", cont)
			keyIn.Size = UDim2.new(0, 178, 0, 30)
			keyIn.Position = UDim2.new(0, 0, 0, 74)
			keyIn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
			keyIn.BorderSizePixel = 0
			keyIn.Text = "Click to set key"
			keyIn.TextColor3 = Color3.fromRGB(0, 210, 110)
			keyIn.Font = Enum.Font.GothamBold
			keyIn.TextSize = 13
			keyIn.TextXAlignment = Enum.TextXAlignment.Center
			keyIn.AutoButtonColor = false
			keyIn.ZIndex = BZ + 2
			NewInstance("UICorner", keyIn).CornerRadius = UDim.new(0, 7)
			local keyStk = NewInstance("UIStroke", keyIn)
			keyStk.Color = Color3.fromRGB(0, 100, 55)
			keyStk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			keyIn.Activated:Connect(function()
				if capturing then return end
				capturing = true
				keyIn.Text = "▶ press any key..."
				keyIn.TextColor3 = Color3.fromRGB(200, 200, 200)
				keyStk.Color = Color3.fromRGB(80, 80, 80)
			end)
			UserInputService.InputBegan:Connect(function(inp, gp2)
				if capturing and not gp2 and inp.UserInputType == Enum.UserInputType.Keyboard then
					keyIn.Text = inp.KeyCode.Name
					keyIn.TextColor3 = Color3.fromRGB(0, 210, 110)
					keyStk.Color = Color3.fromRGB(0, 100, 55)
					capturing = false
				end
			end)
			return keyIn
		end,
		ddLabel = "Saved Keybind",
		ddPlaceholder = "Select keybind",
		ddAccentColor = Color3.fromRGB(185, 40, 40),
		ddEmptyText = "No keybind saved yet",
		getItems = function() return keybinds end,
		getRowText = function(kb)
			local argPart = (kb.arg and kb.arg ~= "") and (" " .. kb.arg) or ""
			return "[" .. kb.key:upper() .. "] → " .. kb.command .. argPart
		end,
		onDdSelect = function(kb, cmdIn, argIn, extraIn, ddBtn)
			cmdIn.Text = kb.command
			argIn.Text = kb.arg or ""
			extraIn.Text = kb.key
			local argShow = (kb.arg and kb.arg ~= "") and (" " .. kb.arg) or ""
			ddBtn.Text = "✔ [" .. kb.key:upper() .. "] " .. kb.command .. argShow
			ddBtn.TextColor3 = Color3.fromRGB(0, 210, 110)
		end,
		addText = "Add Keybind",
		addBg = Color3.fromRGB(4, 38, 18),
		addStroke = Color3.fromRGB(0, 185, 80),
		remText = "Delete Keybind",
		onAdd = function(cmd, arg, extra, ddBtn, setSelIdx, cmdIn, argIn, extraIn)
			local key3 = extra:lower():match("^%s*(.-)%s*$") or ""
			if cmd == "" or key3 == "" then return end
			if not aliasLookup[cmd] then return end
			for i3 = #keybinds, 1, -1 do
				if keybinds[i3].key:lower() == key3 then table.remove(keybinds, i3) end
			end
			keybinds[#keybinds + 1] = {key = key3, command = cmd, arg = arg}
			func.persist.saveKeybinds()
			func.init.keybindListener()
			setSelIdx(nil)
			cmdIn.Text = ""
			argIn.Text = ""
			extraIn.Text = "Click to set key"
			ddBtn.Text = "▾ Select keybind"
			ddBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
		end,
		onRemove = function(getSelIdx, setSelIdx, cmd, arg, extra, cmdIn, argIn, extraIn, ddBtn)
			local removed = false
			local selIdx = getSelIdx()
			if selIdx and keybinds[selIdx] then
				local kb4 = keybinds[selIdx]
				kbActiveStates[kb4.command] = nil
				table.remove(keybinds, selIdx)
				setSelIdx(nil)
				removed = true
			else
				local key4 = extra:lower():match("^%s*(.-)%s*$") or ""
				for i4 = #keybinds, 1, -1 do
					if keybinds[i4].key:lower() == key4 then
						kbActiveStates[keybinds[i4].command] = nil
						table.remove(keybinds, i4)
						removed = true
						break
					end
				end
			end
			if removed then
				if not execapi.writefile then return end
				execapi.writefile("Noname/keybind.json", HttpService:JSONEncode(keybinds))
				func.init.keybindListener()
				cmdIn.Text = ""
				argIn.Text = ""
				extraIn.Text = "Click to set key"
				ddBtn.Text = "▾ Select keybind"
				ddBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
			end
		end,
	})
end

DC.openKeybindGui = function()
	if not rare.kbMainFrame then func.build.keybindGui() end
	rare.kbManager.toggle()
end

local btnGuiOpen = {v = false}

func.build.commandButtonGui = function()
	rare.btnManager = func.build.managerGui({
		sgName = "NNButtonPanel",
		bz = 102,
		title = "BUTTON MANAGER",
		icon = "⊞",
		accentColor = Color3.fromRGB(255, 255, 255),
		guiOpenRef = btnGuiOpen,
		mainFrameSetter = function(f) rare.btnMainFrame = f end,
		row2Left = nil,
		ddLabel = "Saved Button",
		ddPlaceholder = "Select button",
		ddAccentColor = Color3.fromRGB(185, 40, 40),
		ddEmptyText = "No button saved yet",
		getItems = function() return buttons end,
		getRowText = function(b)
			local argPart = (b.arg and b.arg ~= "") and (" [" .. b.arg .. "]") or ""
			local e2 = aliasLookup[b.command]
			local tag = (not (b.arg and b.arg ~= "")) and (e2 and ((e2.args or e2.hud == "speed") and " [arg]" or aliasLookup["un" .. b.command] and " [tog]" or " [btn]") or "") or ""
			return b.command .. argPart .. tag
		end,
		onDdSelect = function(b, cmdIn, argIn, _, ddBtn)
			cmdIn.Text = b.command
			argIn.Text = b.arg or ""
			local argShow = (b.arg and b.arg ~= "") and (" " .. b.arg) or ""
			ddBtn.Text = "✔ " .. b.command .. argShow
			ddBtn.TextColor3 = Color3.fromRGB(0, 210, 110)
		end,
		addText = "Add Button",
		addBg = Color3.fromRGB(4, 38, 18),
		addStroke = Color3.fromRGB(0, 185, 80),
		remText = "Delete Button",
		onAdd = function(cmd, arg, _, ddBtn, setSelIdx, cmdIn, argIn, _2)
			if cmd == "" then return end
			if not aliasLookup[cmd] then return end
			local key3 = cmd .. (arg ~= "" and ("_" .. arg) or "")
			for i3 = #buttons, 1, -1 do
				local bk = buttons[i3].command .. ((buttons[i3].arg and buttons[i3].arg ~= "") and ("_" .. buttons[i3].arg) or "")
				if bk == key3 then table.remove(buttons, i3) end
			end
			if dynamicHuds[key3] then dynamicHuds[key3].destroy(); dynamicHuds[key3] = nil; recalcHudOffset() end
			buttons[#buttons + 1] = {command = cmd, arg = arg}
			func.persist.saveButtons()
			spawnHud({command = cmd, arg = arg})
			setSelIdx(nil)
			cmdIn.Text = ""
			argIn.Text = ""
			ddBtn.Text = "▾ Select button"
			ddBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
		end,
		onRemove = function(getSelIdx, setSelIdx, cmd, arg, _, cmdIn, argIn, _2, ddBtn)
			local removed = false
			local selIdx = getSelIdx()
			if selIdx and buttons[selIdx] then
				local b4 = buttons[selIdx]
				local key4 = b4.command .. ((b4.arg and b4.arg ~= "") and ("_" .. b4.arg) or "")
				if dynamicHuds[key4] then dynamicHuds[key4].destroy(); dynamicHuds[key4] = nil end
				table.remove(buttons, selIdx)
				setSelIdx(nil)
				removed = true
			else
				local key4 = cmd .. (arg ~= "" and ("_" .. arg) or "")
				for i4 = #buttons, 1, -1 do
					local bk = buttons[i4].command .. ((buttons[i4].arg and buttons[i4].arg ~= "") and ("_" .. buttons[i4].arg) or "")
					if bk == key4 then
						if dynamicHuds[key4] then dynamicHuds[key4].destroy(); dynamicHuds[key4] = nil end
						table.remove(buttons, i4)
						removed = true
						break
					end
				end
			end
			if removed then
				func.persist.saveButtons()
				cmdIn.Text = ""
				argIn.Text = ""
				ddBtn.Text = "▾ Select button"
				ddBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
			end
		end,
	})
end

DC.commandButton = function()
	if not rare.btnMainFrame then func.build.commandButtonGui() end
	rare.btnManager.toggle()
end

local espObjects = {}

local espFolder = NewInstance("Folder")
espFolder.Parent = workspace

func.esp.clearAll = function()
	rare.espActive = false
	NnBind.disconnect("esp_playerAdded")
	NnBind.disconnect("esp_playerRemoving")
	for player in pairs(cachedPlayers) do
		NnBind.disconnect("esp_charAdded_" .. player.Name)
		NnBind.disconnect("esp_charRemoving_" .. player.Name)
	end
	for _, obj in pairs(espObjects) do
		if obj.playerName then
			NnBind.disconnect("esp_hp_" .. obj.playerName)
			NnBind.disconnect("esp_dist_" .. obj.playerName)
			NnBind.disconnect("esp_namedist_" .. obj.playerName)
			NnBind.disconnect("esp_hpdist_" .. obj.playerName)
			NnBind.disconnect("esp_ddtype_" .. obj.playerName)
		end
	end
	for _, child in ipairs(espFolder:GetChildren()) do
		child:Destroy()
	end
	table.clear(espObjects)
end

local function getESPColor(player, char)
	if espOpts.useCustomColor then
		return espOpts.color
	end
	if espOpts.colorByTeam and player.Team then
		return player.TeamColor.Color
	end

	local lr = playerHRP
	local tr = char and char:FindFirstChild("HumanoidRootPart")
	if lr and tr then
		local delta = lr.Position - tr.Position
		local distSq = delta:Dot(delta)
		if distSq > 10000 then
			return Color3.fromRGB(0, 255, 0)
		elseif distSq >= 2500 then
			return Color3.fromRGB(255, 165, 0)
		else
			return Color3.fromRGB(255, 0, 0)
		end
	end
	return Color3.fromRGB(255, 80, 80)
end

func.esp.apply = function(player, color, opts)
	opts = opts or {}

	local char = player.Character
	if not char then return end

	local initialColor = getESPColor(player, char)

	local highlight = NewInstance("Highlight")
	highlight.Adornee = char
	highlight.FillColor = initialColor
	highlight.OutlineColor = initialColor
	highlight.FillTransparency = 0.7
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = espFolder

	local billboard = nil
	local lbl = nil
	local cachedHp = nil
	local cachedDist = nil

	local function rebuildLabel()
		if not lbl then return end
		local lines = { player.Name }
		if cachedHp then lines[#lines + 1] = "HP: " .. cachedHp end
		if cachedDist then lines[#lines + 1] = cachedDist .. "m" end
		lbl.Text = table.concat(lines, "\n")
	end

	if not opts.chamsonly then
		local adornPart = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
		if adornPart then
			local lineCount = 1 + (opts.health and 1 or 0) + (opts.distance and 1 or 0)

			billboard = NewInstance("BillboardGui")
			billboard.Adornee = adornPart
			billboard.AlwaysOnTop = true
			billboard.Size = UDim2.new(0, 120, 0, lineCount * 20)
			billboard.StudsOffset = Vector3.new(0, 2.5, 0)
			billboard.Parent = espFolder

			lbl = NewInstance("TextLabel")
			lbl.Size = UDim2.new(1, 0, 1, 0)
			lbl.AnchorPoint = Vector2.new(0.5, 0.5)
			lbl.Position = UDim2.new(0.5, 0, 0.5, 0)
			lbl.BackgroundTransparency = 1
			lbl.Font = Enum.Font.SourceSansBold
			lbl.TextScaled = true
			lbl.TextColor3 = initialColor
			lbl.Text = player.Name
			lbl.Parent = billboard
			NewInstance("UIStroke", lbl)

			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
				NnBind.reconnect("esp_ddtype_" .. player.Name, hum:GetPropertyChangedSignal("DisplayDistanceType"):Connect(function()
					if hum.DisplayDistanceType ~= Enum.HumanoidDisplayDistanceType.Subject then
						hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
					end
				end))

				hum.NameDisplayDistance = 0
				NnBind.reconnect("esp_namedist_" .. player.Name, hum:GetPropertyChangedSignal("NameDisplayDistance"):Connect(function()
					if hum.NameDisplayDistance ~= 0 then
						hum.NameDisplayDistance = 0
					end
				end))

				if opts.health then
					cachedHp = math.floor(hum.Health)
					rebuildLabel()
					NnBind.reconnect("esp_hp_" .. player.Name, hum.HealthChanged:Connect(function(hp)
						cachedHp = math.floor(hp)
						rebuildLabel()
					end))

					hum.HealthDisplayDistance = 0
					NnBind.reconnect("esp_hpdist_" .. player.Name, hum:GetPropertyChangedSignal("HealthDisplayDistance"):Connect(function()
						if hum.HealthDisplayDistance ~= 0 then
							hum.HealthDisplayDistance = 0
						end
					end))
				end
			end
		end
	end

	if needsRenderStepped then
		NnBind.reconnect("esp_dist_" .. player.Name, RunService.RenderStepped:Connect(function()
			local lr = playerHRP
			local tr = char:FindFirstChild("HumanoidRootPart")
			if not (lr and tr) then return end
			local delta = lr.Position - tr.Position
			local distSq = delta:Dot(delta)
			if opts.distance and lbl then
				cachedDist = string.format("%.0f", math.sqrt(distSq))
				rebuildLabel()
			end
			if not espOpts.useCustomColor and not espOpts.colorByTeam then
				local newColor = distSq > 10000 and Color3.fromRGB(0, 255, 0) or distSq >= 2500 and Color3.fromRGB(255, 165, 0) or Color3.fromRGB(255, 0, 0)
				if highlight.FillColor ~= newColor then
					highlight.FillColor = newColor
					highlight.OutlineColor = newColor
					if lbl then lbl.TextColor3 = newColor end
				end
			end
		end))
	end

	espObjects[char] = {
		highlight = highlight,
		billboard = billboard,
		playerName = player.Name,
	}
end

func.feat.enableESPAll = function()
	rare.espActive = true

	local function cleanChar(char)
		local obj = espObjects[char]
		if not obj then return end
		if obj.playerName then
			NnBind.disconnect("esp_hp_" .. obj.playerName)
			NnBind.disconnect("esp_dist_" .. obj.playerName)
			NnBind.disconnect("esp_namedist_" .. obj.playerName)
			NnBind.disconnect("esp_hpdist_" .. obj.playerName)
			NnBind.disconnect("esp_ddtype_" .. obj.playerName)
		end
		if obj.highlight then obj.highlight:Destroy() end
		if obj.billboard then obj.billboard:Destroy() end
		espObjects[char] = nil
	end

	NnBind.reconnect("esp_playerAdded", PlayerAdded:Connect(function(player)
		if player == LocalPlayer then return end
		NnBind.reconnect("esp_charAdded_" .. player.Name, player.CharacterAdded:Connect(function()
			task.wait()
			func.esp.apply(player, espOpts.color, espOpts)
		end))
		NnBind.reconnect("esp_charRemoving_" .. player.Name, player.CharacterRemoving:Connect(function(oldChar)
			cleanChar(oldChar)
		end))
		if player.Character then
			func.esp.apply(player, espOpts.color, espOpts)
		end
	end))

	NnBind.reconnect("esp_playerRemoving", PlayerRemoving:Connect(function(player)
		NnBind.disconnect("esp_charAdded_" .. player.Name)
		NnBind.disconnect("esp_charRemoving_" .. player.Name)
		if player.Character then cleanChar(player.Character) end
	end))

	for player in pairs(cachedPlayers) do
		if player == LocalPlayer then continue end
		NnBind.reconnect("esp_charAdded_" .. player.Name, player.CharacterAdded:Connect(function()
			task.wait()
			func.esp.apply(player, espOpts.color, espOpts)
		end))
		NnBind.reconnect("esp_charRemoving_" .. player.Name, player.CharacterRemoving:Connect(function(oldChar)
			cleanChar(oldChar)
		end))
		if player.Character then
			func.esp.apply(player, espOpts.color, espOpts)
		end
	end

	notify("solar:eye-bold", 3, "ESP", "ESP applied to all players.")
end

func.feat.enableInstantPP = function()
	local function apply(v)
		if v:IsA("ProximityPrompt") then
			v.HoldDuration = 0
		end
	end
	for _, v in ipairs(workspace:GetDescendants()) do apply(v) end
	NnBind.reconnect("ipp_added", workspace.DescendantAdded:Connect(apply))
	notify("sfsymbols:handTapFill", 3, "InstantPP", "Instant proximity prompts enabled.")
end

func.feat.unwatch = function()
	NnBind.disconnect("watch_removing")
	NnBind.disconnect("watch_character")

	if not playerChar then
		notify("lucide:triangle-alert", 4, "Watch", "LocalPlayer character not found. Waiting for character...")
	end

	Camera.CameraSubject = playerHum or (playerChar and playerChar:FindFirstChildOfClass("Humanoid"))
	notify("sfsymbols:eyes", 3, "Watch", "Stopped watching.")
end

func.feat.watch = function(player)
	local function updateCamera(character)
		Camera.CameraSubject = character:WaitForChild("Humanoid")
	end

	if player.Character then
		updateCamera(player.Character)
		notify("sfsymbols:eyes", 3, "Watch", "Now watching " .. player.Name .. ".")
	else
		notify("lucide:user-x", 4, "Watch", player.Name .. " has no character yet. Waiting for spawn...")
	end

	NnBind.reconnect("watch_character", player.CharacterAdded:Connect(updateCamera))

	NnBind.reconnect("watch_removing", PlayerRemoving:Connect(function(removedPlayer)
		if removedPlayer == player then
			notify("lucide:log-out", 4, "Watch", player.Name .. " has left the game. Reverting camera.")
			func.feat.unwatch()
		end
	end))
end

do
	local acMode = "Mobile"
	local acDelay = 0.3
	local acTargetX, acTargetY = nil, nil
	local acActive = false
	local acSettingTarget = false
	local acInputConn = nil

	local modeButton = UI.AutoClicker.modeButton
	local delayBox = UI.AutoClicker.delayBox
	local targetButton = UI.AutoClicker.targetButton
	local toggleButton = UI.AutoClicker.toggleButton
	local toggleStroke = UI.AutoClicker.toggleStroke
	local targetDot = UI.AutoClicker.targetDot
	local closeButton = UI.AutoClicker.closeButton

	func.feat.autoclickStart = function()
		if acActive then return end
		if not acTargetX or not acTargetY then
			notify("lucide:triangle-alert", 4, "AutoClicker", "Set a target position first.")
			return
		end
		acActive = true
		task.spawn(function()
			local inset = GuiService:GetGuiInset()
			local x = acTargetX + inset.X
			local y = acTargetY + inset.Y
			while acActive do
				if Vim then
					if acMode == "Mobile" then
						Vim:SendTouchEvent(999, 0, x, y)
						task.wait()
						Vim:SendTouchEvent(999, 2, x, y)
					else
						Vim:SendMouseButtonEvent(x, y, 0, true, game, 1)
						task.wait()
						Vim:SendMouseButtonEvent(x, y, 0, false, game, 1)
					end
				end
				task.wait(acDelay)
			end
		end)
	end

	func.feat.autoclickStop = function()
		acActive = false
	end

	modeButton.Activated:Connect(function()
		acMode = (acMode == "Mobile") and "PC" or "Mobile"
		modeButton.Text = "Mode: " .. acMode
	end)

	delayBox.FocusLost:Connect(function()
		local n = tonumber(delayBox.Text)
		if n and n >= 0 then
			acDelay = n
			delayBox.Text = tostring(n)
		else
			delayBox.Text = tostring(acDelay)
		end
	end)

targetButton.Activated:Connect(function()
	if acSettingTarget then return end
	acSettingTarget = true
	targetButton.Text = "Click anywhere..."

	if acInputConn then acInputConn:Disconnect() end
	acInputConn = UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			acTargetX = input.Position.X
			acTargetY = input.Position.Y
			targetDot.Position = UDim2.new(0, acTargetX, 0, acTargetY)
			targetDot.Visible = true
			targetButton.Text = "Set Target"
			acSettingTarget = false
			acInputConn:Disconnect()
			acInputConn = nil
		end
	end)
end)

	toggleButton.Activated:Connect(function()
		if acActive then
			func.feat.autoclickStop()
			toggleButton.Text = "OFF"
			toggleButton.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
			toggleStroke.Color = Color3.fromRGB(220, 70, 70)
		else
			func.feat.autoclickStart()
			if acActive then
				toggleButton.Text = "ON"
				toggleButton.BackgroundColor3 = Color3.fromRGB(70, 200, 100)
				toggleStroke.Color = Color3.fromRGB(70, 200, 100)
			end
		end
	end)

	closeButton.Activated:Connect(function()
		func.feat.autoclickStop()
		UI.AutoClicker.close()
	end)
end

local function setProp(inst, prop, val)
	if inst[prop] ~= val then
		inst[prop] = val
	end
end

local function safesetprop(inst, prop, val)
	if inst[prop] == val then return end
	if execapi.sethiddenproperty then
		if not pcall(execapi.sethiddenproperty, inst, prop, val) then
			pcall(function() inst[prop] = val end)
		end
	else
		pcall(function() inst[prop] = val end)
	end
end

local function safehook(object, metamethod, hook, useCheckcaller)
	local original
	local function proxy(...)
		if useCheckcaller and execapi.checkcaller and execapi.checkcaller() then
			return original(...)
		end
		return hook(...)
	end
	local wrappedHook = execapi.newcclosure and execapi.newcclosure(proxy) or proxy
	if execapi.setstackhidden then
		execapi.setstackhidden(wrappedHook, true)
	end

	if execapi.hookmetamethod then
		original = execapi.hookmetamethod(object, metamethod, wrappedHook)
		return original
	end

	if not execapi.getrawmetatable then
		notify("lucide:triangle-alert", 4, "safehook", "Executor does not support metamethod hooking.")
		return nil
	end
	local mt = execapi.getrawmetatable(object)
	if not mt then
		notify("lucide:triangle-alert", 4, "safehook", "Executor does not support metamethod hooking.")
		return nil
	end

	if execapi.hookfunction then
		original = execapi.hookfunction(mt[metamethod], wrappedHook)
		return original
	end

	original = mt[metamethod]
	if execapi.setreadonly then
		execapi.setreadonly(mt, false)
	end
	mt[metamethod] = wrappedHook
	if execapi.setreadonly then
		execapi.setreadonly(mt, true)
	end
	return original
end

local function safeunhook(object, metamethod, original)
	if not original then return false end

	if execapi.hookmetamethod then
		execapi.hookmetamethod(object, metamethod, original)
		return true
	end

	if not execapi.getrawmetatable then return false end
	local mt = execapi.getrawmetatable(object)
	if not mt then return false end

	if execapi.hookfunction then
		execapi.hookfunction(mt[metamethod], original)
		return true
	end

	if execapi.setreadonly then
		execapi.setreadonly(mt, false)
	end
	mt[metamethod] = original
	if execapi.setreadonly then
		execapi.setreadonly(mt, true)
	end
	return true
end

local function predictPosition(part)
	local cameraPos = Camera.CFrame.Position
	local direction = part.Position - cameraPos
	local length = direction.Magnitude
	if length < 1e-3 then return part.Position end
	local directionUnit = direction / length
	local right = directionUnit:Cross(Vector3.yAxis)
	local rightLength = right.Magnitude
	if rightLength < 1e-3 then return part.Position end
	right /= rightLength
	return part.Position + right * part.AssemblyLinearVelocity:Dot(right) * 0.1
end

local function getGuiParent()
	return pcall(gethui) and gethui() or pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
end

func.feat.godmode = function(mode)
	rare.god_mode = (mode == "hook") and "hook" or "nohook"

	local hum = playerHum
	if not hum then
		notify("lucide:triangle-alert", 4, "GodMode", "No character found.")
		return
	end

	local function applyGodmode(m, h)
		local function healCheck()
			if h.Health < h.MaxHealth then
				h.Health = h.MaxHealth
			end
		end

		if h.BreakJointsOnDeath then
			h.BreakJointsOnDeath = false
		end
		if h:GetState() == Enum.HumanoidStateType.Dead then
			h:ChangeState(Enum.HumanoidStateType.Running)
		end
		h:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
		healCheck()

		NnBind.reconnect("gm_stateChanged", h.StateChanged:Connect(function(_, newState)
			if newState == Enum.HumanoidStateType.Dead then
				healCheck()
				h:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
				h:ChangeState(Enum.HumanoidStateType.Running)
			end
		end))

		if m == "hook" then
			if type(getnamecallmethod) ~= "function" then
				notify("lucide:triangle-alert", 4, "GodMode", "Hook failed, falling back to nohook.")
				m = "nohook"
			else
				rare.god_hum = h

				if not rare.god_origNI or not rare.god_origNC then
					rare.god_origNI = safehook(game, "__newindex", function(self, key, value)
						if rare.god_mode == "hook" and rare.god_hum and self == rare.god_hum then
							if key == "Health" and type(value) == "number" and value <= 0 then return end
							if key == "MaxHealth" and type(value) == "number" and value < rare.god_hum.MaxHealth then return end
							if key == "BreakJointsOnDeath" and value == true then return end
							if key == "Parent" and value == nil then return end
						end
						return rare.god_origNI(self, key, value)
					end, true)

					rare.god_origNC = safehook(game, "__namecall", function(self, ...)
						if rare.god_mode == "hook" then
							local method = getnamecallmethod()
							if rare.god_hum and self == rare.god_hum then
								if method == "ChangeState" then
									local st = ...
									if st == Enum.HumanoidStateType.Dead then return end
								end
								if method == "SetStateEnabled" then
									local st, en = ...
									if st == Enum.HumanoidStateType.Dead and en == true then return end
								end
								if method == "Destroy" then return end
							end
							if self == playerChar and method == "BreakJoints" then return end
						end
						return rare.god_origNC(self, ...)
					end, true)

					if not rare.god_origNI or not rare.god_origNC then
						notify("lucide:triangle-alert", 4, "GodMode", "Hook failed, falling back to nohook.")
						m = "nohook"
					end
				end
			end
		end

		if m == "nohook" then
			NnBind.reconnect("gm_healthChanged",
				h.HealthChanged:Connect(healCheck))
			NnBind.reconnect("gm_health",
				h:GetPropertyChangedSignal("Health"):Connect(healCheck))
			NnBind.reconnect("gm_maxHealth",
				h:GetPropertyChangedSignal("MaxHealth"):Connect(healCheck))
			NnBind.reconnect("gm_breakJoints",
				h:GetPropertyChangedSignal("BreakJointsOnDeath"):Connect(function()
					if h.BreakJointsOnDeath then
						h.BreakJointsOnDeath = false
					end
				end))
		end
	end

	applyGodmode(rare.god_mode, hum)
	notify("sfsymbols:heartFill", 3, "GodMode", "Enabled (" .. (rare.god_mode or "nohook") .. ").")

	NnBind.reconnect("gm_charAdded", CharacterAdded:Connect(function()
		CharacterCached:Wait()
		if playerHum then applyGodmode(rare.god_mode, playerHum) end
	end))
end

do
	local nvfParts = {}
	local nvfHooksActive = false

	func.feat.antinvisfling = function(AntiInvis, AntiFling)
		local wasActive = nvfHooksActive
		rare.antiInvis = AntiInvis
		rare.antiFling = AntiFling

		if not AntiInvis and not AntiFling then
			NnBind.disconnect("nvf_playerAdded")
			for player in pairs(cachedPlayers) do
				NnBind.disconnect("nvf_charAdded_" .. player.Name)
				NnBind.disconnect("nvf_added_" .. player.Name)
			end
			for part in pairs(nvfParts) do
				NnBind.disconnect("antiinvis_" .. part:GetDebugId())
			end
			table.clear(nvfParts)
			nvfHooksActive = false
			return
		end

		if wasActive then
			for part in pairs(nvfParts) do
				if rare.antiInvis and part.Name ~= "HumanoidRootPart" then
					part.Transparency = 0
					NnBind.reconnect("antiinvis_" .. part:GetDebugId(), part:GetPropertyChangedSignal("Transparency"):Connect(function()
						if rare.antiInvis and part.Transparency ~= 0 then part.Transparency = 0 end
					end))
				else
					NnBind.disconnect("antiinvis_" .. part:GetDebugId())
				end
			end
			return
		end

		local function hookPart(part)
			if not part:IsA("BasePart") then return end
			nvfParts[part] = true

			if rare.antiFling then
				part.CanCollide = false
			end

			if rare.antiInvis and part.Name ~= "HumanoidRootPart" then
				part.Transparency = 0
				NnBind.reconnect("antiinvis_" .. part:GetDebugId(), part:GetPropertyChangedSignal("Transparency"):Connect(function()
					if rare.antiInvis and part.Transparency ~= 0 then part.Transparency = 0 end
				end))
			end
		end

		local function hookCharacter(character, player)
			for _, d in ipairs(character:GetDescendants()) do
				hookPart(d)
			end
			NnBind.reconnect("nvf_added_" .. player.Name, character.DescendantAdded:Connect(hookPart))
		end

		for player in pairs(cachedPlayers) do
			if player == LocalPlayer then continue end
			if player.Character then
				hookCharacter(player.Character, player)
			end
			NnBind.reconnect("nvf_charAdded_" .. player.Name, player.CharacterAdded:Connect(function(char)
				hookCharacter(char, player)
			end))
		end

		NnBind.reconnect("nvf_playerAdded", PlayerAdded:Connect(function(player)
			if player == LocalPlayer then return end
			if player.Character then
				hookCharacter(player.Character, player)
			end
			NnBind.reconnect("nvf_charAdded_" .. player.Name, player.CharacterAdded:Connect(function(char)
				hookCharacter(char, player)
			end))
		end))

		nvfHooksActive = true
	end
end

func.feat.antiAfk = function(mode)
	afkMode = mode
	if mode ~= nil then
		notify("geist:cursor-click", 3, "Anti-AFK", "Enabled (" .. tostring(mode) .. ").")
	end
	task.spawn(function()
		while afkMode do
			task.wait(60)
			if Vim then
				if afkMode == "Mobile" then
					Vim:SendTouchEvent(998, 0, 100, 100)
					task.wait(0.1)
					Vim:SendTouchEvent(998, 2, 100, 100)
				else
					Vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
					task.wait(0.1)
					Vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
				end
			else
				if playerHum then playerHum:ChangeState(Enum.HumanoidStateType.Jumping) end
			end
		end
	end)
end

-- Cmd
local Cmd = {}

function Cmd.add(aliases, opts)
	opts = opts or {}
	local entry = { aliases = aliases }
	for k, v in pairs(opts) do
		entry[k] = v
	end
	Cmds[#Cmds + 1] = entry
end

Cmd.add({"walkspeed", "ws"}, {
	args = "speed",
	fn = function(speed)
		speed = tonumber(speed)
		if not speed then return end
		if playerChar then
			local humanoid = playerHum
			if humanoid then
				humanoid.WalkSpeed = speed
				notify("sfsymbols:figureWalk", 3, "WalkSpeed", "Set to " .. tostring(speed))
			end
		end
	end
})

Cmd.add({"loopwalkspeed", "loopws", "lws"}, {
	args = "speed",
	fn = function(speed)
		func.feat.loopwalkspeed(tonumber(speed))
		notify("geist:loader-circle", 3, "LoopWalkSpeed", "Looping at " .. tostring(speed))
	end,
})

Cmd.add({"unloopwalkspeed", "unloopws", "unlws"}, {
	fn = function()
		NnBind.disconnect("ws_changed")
		NnBind.disconnect("ws_charAdded")
		notify("geist:loader-circle", 3, "LoopWalkSpeed", "Loop stopped.")
	end,
})

Cmd.add({"tpwalkspeed", "tpwalk"}, {
	args = "speed",
	fn = function(speed)
		speed = tonumber(speed) or 1
		local stepRate = 1 / 60
		local maxSteps = 3
		local accumulator = 0
		notify("sfsymbols:hareFill", 3, "TpWalkSpeed", "TP walk set to " .. tostring(speed))
		NnBind.reconnect("tpwalk", RunService.Heartbeat:Connect(function(deltaTime)
			accumulator = math.min(accumulator + (tonumber(deltaTime) or 0), stepRate * maxSteps)
			local humanoid = playerHum
			if not humanoid or not playerChar or humanoid.MoveDirection.Magnitude <= 0 then return end
			local steps = 0
			while accumulator >= stepRate and steps < maxSteps do
				playerChar:TranslateBy(humanoid.MoveDirection * speed * stepRate * 10)
				accumulator -= stepRate
				steps += 1
			end
		end))
	end,
})

Cmd.add({"untpwalkspeed", "untpwalk"}, {
	fn = function()
		NnBind.disconnect("tpwalk")
		notify("sfsymbols:tortoiseFill", 3, "TpWalkSpeed", "TP walk stopped.")
	end,
})

Cmd.add({"jumppower", "jp"}, {
	args = "power",
	fn = function(power)
		power = tonumber(power)
		if not power then return end
		if playerChar then
			local humanoid = playerHum
			if humanoid then
				humanoid.JumpPower = power
				notify("sfsymbols:arrowUpCircleFill", 3, "JumpPower", "Set to " .. tostring(power))
			end
		end
	end
})

Cmd.add({"loopjumppower", "loopjp"}, {
	args = "power",
	fn = function(power)
		power = tonumber(power)
		if not power then return end
		local function apply(char)
			char = char or playerChar
			local hum = char and char:WaitForChild("Humanoid")
			if not hum then return end
			hum.JumpPower = power
			NnBind.reconnect("jp_changed", hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
				if hum.JumpPower ~= power then hum.JumpPower = power end
			end))
		end
		apply()
		NnBind.reconnect("jp_charAdded", CharacterAdded:Connect(apply))
		notify("geist:loader-circle", 3, "LoopJumpPower", "Looping at " .. tostring(power))
	end,
})

Cmd.add({"unloopjumppower", "unloopjp"}, {
	fn = function()
		NnBind.disconnect("jp_changed")
		NnBind.disconnect("jp_charAdded")
		notify("geist:loader-circle", 3, "LoopJumpPower", "Loop stopped.")
	end,
})

Cmd.add({"resetchar", "respawn", "reset"}, {
	fn = function()
		local hum = playerHum
		if not hum then
			notify("lucide:triangle-alert", 4, "Reset", "No character found.")
			return
		end
		notify("lucide:refresh-cw", 3, "Reset", "Resetting character...")
		hum.Health = 0
		hum:Destroy()
	end,
})

Cmd.add({"CopyAttribute", "CopyAttr", "Attribute", "Attr"}, {
	fn = function()
		local char = playerChar or CharacterAdded:Wait()
		local collected = {}

		for _, src in ipairs({ LocalPlayer, char }) do
			for name, value in pairs(src:GetAttributes()) do
				if collected[name] == nil then
					collected[name] = value
				end
			end
		end

		if not next(collected) then
			notify("lucide:triangle-alert", 4, "CopyAttribute", "No attributes found.")
			return
		end

		local lines = { "[Attributes]" }
		for name, value in pairs(collected) do
			lines[#lines + 1] = name .. " = " .. tostring(value) .. " [" .. typeof(value) .. "]"
		end

		local result = table.concat(lines, "\n")

		if execapi.clipboard then
			execapi.clipboard(result)
			notify("craft:clipboard-stroke", 3, "CopyAttribute", "Attributes copied to clipboard.")
		else
			print(result)
			notify("lucide:triangle-alert", 4, "CopyAttribute", "Clipboard API not available — printed to console.")
		end
	end,
})

Cmd.add({"copyposition", "copypos", "cpos"}, {
	args = "playername",
	fn = function(name)
		local targetHRP

		if name and name ~= "" then
			local targets = {prefixMatch(name)}
			if #targets == 0 then
				notify("lucide:user-x", 4, "CopyPos", "Player not found.")
				return
			end
			targetHRP = targets[1].Character and targets[1].Character:FindFirstChild("HumanoidRootPart")
			if not targetHRP then
				notify("lucide:triangle-alert", 4, "CopyPos", targets[1].Name .. " has no character.")
				return
			end
		else
			targetHRP = playerHRP
			if not targetHRP then
				notify("lucide:triangle-alert", 4, "CopyPos", "Your character was not found.")
				return
			end
		end

		local pos = targetHRP.Position
		local str = string.format("%.3f, %.3f, %.3f", pos.X, pos.Y, pos.Z)

		if execapi.clipboard then
			execapi.clipboard(str)
			notify("craft:clipboard-stroke", 3, "CopyPos", "Position copied: " .. str)
		else
			print("Position: " .. str)
			notify("lucide:triangle-alert", 4, "CopyPos", "Clipboard API not available — printed to console.")
		end
	end,
})

Cmd.add({"fly"}, {
	args = "speed",
	fn = function(speed)
		func.feat.fly(tonumber(speed) or 1, false)
	end,
	hud = "toggle",
	hudPlaceholder = "speed",
	hudDefault = 1,
	hudLabelOn = "fly",
	hudLabelOff = "unfly",
	hudOn = {"fly"},
	hudOff = {"unfly"},
	hudStart = "startFly",
	hudStop = "stopFly",
})

DC.startFly = function(speed) func.feat.fly(tonumber(speed) or 1, false) end
DC.stopFly = func.feat.unfly

Cmd.add({"unfly"}, {
	fn = func.feat.unfly,
})

Cmd.add({"vehiclefly", "vfly"}, {
	args = "speed",
	fn = function(speed)
		func.feat.fly(tonumber(speed) or 1, true)
		notify("craft:rocket-stroke", 3, "Vehicle Fly", "Vehicle fly enabled.")
	end,
	hud = "toggle",
	hudPlaceholder = "speed",
	hudDefault = 1,
	hudLabelOn = "vfly",
	hudLabelOff = "unvfly",
	hudOn = {"vehiclefly", "vfly"},
	hudOff = {"unvehiclefly", "unvfly"},
	hudStart = "startVfly",
	hudStop = "stopVfly",
})

DC.startVfly = function(speed) func.feat.fly(tonumber(speed) or 1, true) end
DC.stopVfly = func.feat.unfly

Cmd.add({"unvehiclefly", "unvfly"}, {
	fn = function()
		func.feat.unfly()
		notify("craft:rocket-stroke", 3, "Vehicle Fly", "Vehicle fly disabled.")
	end,
})

Cmd.add({"freecam", "fc"}, {
	args = "speed",
	fn = function(speed) func.feat.startFc(tonumber(speed)) end,
	hud = "toggle",
	hudPlaceholder = "speed",
	hudDefault = 5,
	hudLabelOn = "freecam",
	hudLabelOff = "unfreecam",
	hudOn = {"freecam", "fc"},
	hudOff = {"unfreecam", "unfc"},
	hudStart = "startFc",
	hudStop = "stopFc",
})

DC.startFc = function(speed) func.feat.startFc(tonumber(speed)) end
DC.stopFc = func.feat.stopFc

Cmd.add({"unfreecam", "unfc"}, {
	fn = func.feat.stopFc,
})

Cmd.add({"freeze"}, {
	fn = function()
		local character = playerChar
		if not character then return end
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end
		notify("lucide:snowflake", 3, "Freeze", "Character frozen.")
	end,
	hud = "toggle",
	hudLabelOn = "freeze",
	hudLabelOff = "unfreeze",
	hudOn = {"freeze"},
	hudOff = {"unfreeze"},
	hudStart = "startFreeze",
	hudStop = "stopFreeze",
})

DC.startFreeze = function()
	local character = playerChar
	if not character then return end
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
end
DC.stopFreeze = function()
	local character = playerChar
	if not character then return end
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end
end

Cmd.add({"unfreeze"}, {
	fn = function()
		local character = playerChar
		if not character then return end
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
			end
		end
		notify("sfsymbols:flameFill", 3, "Freeze", "Character unfrozen.")
	end,
})

Cmd.add({"noclip", "nc"}, {
	fn = func.feat.noclip,
})

Cmd.add({"unnoclip", "clip", "unnc"}, {
	fn = function()
		NnBind.disconnect("noclip_added")
		NnBind.disconnect("noclip_removing")
		NnBind.disconnect("noclip_charAdded")
		NnBind.disconnect("noclip_stepped")
		for part in pairs(noclipParts) do
			part.CanCollide = true
		end
		table.clear(noclipParts)
		notify("solar:ghost-bold", 3, "Noclip", "Noclip disabled.")
	end,
})

Cmd.add({"invisible", "invis"}, {
	fn = func.feat.invisible,
})

Cmd.add({"uninvisible", "uninvis"}, {
	fn = function()
		NnBind.disconnect("invis_transparency")
		NnBind.disconnect("invis_heartbeat")
		NnBind.disconnect("invis_charAdded")

		local char = playerChar
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.Transparency == 0.5 then
					part.Transparency = 0
				end
			end
		end
		notify("sfsymbols:eyeFill", 3, "Invisible", "Visibility restored.")
	end,
})

Cmd.add({"antiinvisible", "antiinvis", "avis"}, {
	fn = function()
		func.feat.antinvisfling(true, rare.antiFling)
		notify("gravity:eye", 3, "AntiInvis", "Anti-invisible enabled.")
	end,
})

Cmd.add({"unantiinvisible", "unantiinvis", "unavis"}, {
	fn = function()
		func.feat.antinvisfling(false, rare.antiFling)
		notify("gravity:eye-slash", 3, "AntiInvis", "Anti-invisible disabled.")
	end,
})

Cmd.add({"antifling"}, {
	fn = function()
		func.feat.antinvisfling(rare.antiInvis, true)
		notify("gravity:shield", 3, "AntiFling", "Anti-fling enabled.")
	end,
})

Cmd.add({"unantifling"}, {
	fn = function()
		func.feat.antinvisfling(rare.antiInvis, false)
		notify("gravity:shield", 3, "AntiFling", "Anti-fling disabled.")
	end,
})

Cmd.add({"GameId"}, {
	fn = function()
		local id = tostring(game.GameId)
		if execapi.clipboard then
			execapi.clipboard(id)
			notify("craft:clipboard-stroke", 3, "GameId", "Universe ID copied: " .. id)
		else
			print("Universe ID: " .. id)
			notify("lucide:triangle-alert", 4, "GameId", "Clipboard API not available — printed to console.")
		end
	end,
})

Cmd.add({"PlaceId"}, {
	fn = function()
		local id = tostring(game.PlaceId)
		if execapi.clipboard then
			execapi.clipboard(id)
			notify("craft:clipboard-stroke", 3, "PlaceId", "Place ID copied: " .. id)
		else
			print("Place ID: " .. id)
			notify("lucide:triangle-alert", 4, "PlaceId", "Clipboard API not available — printed to console.")
		end
	end,
})

Cmd.add({"jobid"}, {
	fn = function()
		local id = tostring(game.JobId)
		if execapi.clipboard then
			execapi.clipboard(id)
			notify("craft:clipboard-stroke", 3, "JobId", "Job ID copied: " .. id)
		else
			print("Job ID: " .. id)
			notify("lucide:triangle-alert", 4, "JobId", "Clipboard API not available — printed to console.")
		end
	end,
})

Cmd.add({"joinplaceid"}, {
	args = "placeid",
	fn = function(placeId)
		placeId = tonumber(placeId)
		if not placeId then return end
		notify("sfsymbols:doorLeftHandOpen", 3, "JoinPlaceId", "Joining place " .. tostring(placeId) .. "...")
		TeleportService:Teleport(placeId, LocalPlayer)
	end,
})

Cmd.add({"joinjobid"}, {
	args = "jobid",
	fn = function(jobId)
		if not jobId then return end
		notify("geist:database", 3, "JoinJobId", "Joining server " .. tostring(jobId) .. "...")
		TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
	end,
})

Cmd.add({"antivoid"}, {
	fn = func.feat.enableAntiVoid,
})

Cmd.add({"unantivoid"}, {
	fn = function()
		NnBind.disconnect("antivoid_health")
		NnBind.disconnect("antivoid_fpdh")
		NnBind.disconnect("antivoid_char")
		local platform = workspace:FindFirstChild("VoidPlatform")
		if platform then
			platform:Destroy()
		end
		workspace.FallenPartsDestroyHeight = rare.fpdh
		notify("solar:shield-check-bold", 3, "AntiVoid", "Anti-void disabled.")
	end,
})

Cmd.add({"fixcam", "fixcamera"}, {
	fn = function()
		Camera.CameraType = Enum.CameraType.Custom
		Camera.CameraSubject = playerHum or playerChar
		LocalPlayer.CameraMode = Enum.CameraMode.Classic
		LocalPlayer.CameraMinZoomDistance = 0.5
		LocalPlayer.CameraMaxZoomDistance = 1e7
		notify("geist:external", 3, "FixCam", "Camera fixed.")
	end,
})

Cmd.add({"minzoom"}, {
	args = "value",
	fn = function(value)
		value = tonumber(value)
		if not value then return end
		LocalPlayer.CameraMinZoomDistance = value
		notify("lucide:zoom-in", 3, "MinZoom", "Set to " .. tostring(value))
	end,
})

Cmd.add({"maxzoom"}, {
	args = "value",
	fn = function(value)
		value = tonumber(value)
		if not value then return end
		LocalPlayer.CameraMaxZoomDistance = value
		notify("lucide:zoom-out", 3, "MaxZoom", "Set to " .. tostring(value))
	end,
})

Cmd.add({"loopminzoom"}, {
	args = "value",
	fn = function(value)
		value = tonumber(value)
		if not value then return end
		LocalPlayer.CameraMinZoomDistance = value
		NnBind.reconnect("loopminzoom", LocalPlayer:GetPropertyChangedSignal("CameraMinZoomDistance"):Connect(function()
			if LocalPlayer.CameraMinZoomDistance ~= value then
				LocalPlayer.CameraMinZoomDistance = value
			end
		end))
		notify("lucide:zoom-in", 3, "LoopMinZoom", "Looping at " .. tostring(value))
	end,
})

Cmd.add({"unloopminzoom"}, {
	fn = function()
		NnBind.disconnect("loopminzoom")
		notify("lucide:zoom-in", 3, "LoopMinZoom", "Loop stopped.")
	end,
})

Cmd.add({"loopmaxzoom"}, {
	args = "value",
	fn = function(value)
		value = tonumber(value)
		if not value then return end
		LocalPlayer.CameraMaxZoomDistance = value
		NnBind.reconnect("loopmaxzoom", LocalPlayer:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(function()
			if LocalPlayer.CameraMaxZoomDistance ~= value then
				LocalPlayer.CameraMaxZoomDistance = value
			end
		end))
		notify("lucide:zoom-out", 3, "LoopMaxZoom", "Looping at " .. tostring(value))
	end,
})

Cmd.add({"unloopmaxzoom"}, {
	fn = function()
		NnBind.disconnect("loopmaxzoom")
		notify("lucide:zoom-out", 3, "LoopMaxZoom", "Loop stopped.")
	end,
})

Cmd.add({"selfkick", "sk"}, {
	fn = function()
		notify("geist:external", 3, "SelfKick", "Kicking yourself...")
		LocalPlayer:Kick("You have been banned.\n\nReason: Exploiting\n\nAppeal at: www.roblox.com/appeal")
	end,
})

Cmd.add({"commands", "cmds"}, {
	fn = function() if DC.openCommandList then DC.openCommandList() end end,
})

Cmd.add({"keybind", "kb"}, {
	fn = function() if DC.openKeybindGui then DC.openKeybindGui() end end,
})

Cmd.add({"commandbutton", "button"}, {
	fn = function() if DC.commandButton then DC.commandButton() end end,
})

Cmd.add({"esp", "espplayers", "playeresp"}, {
	args = "playername",
	args2 = "playername2",
	fn = function(...)
		local names = {}
		for _, n in ipairs(stripCommas({...})) do
			if n then names[#names + 1] = n:lower() end
		end
		if #names == 0 then
			notify("lucide:triangle-alert", 4, "ESP", "No players specified.")
			return
		end
		if names[1] == "all" then
			func.feat.enableESPAll()
			return
		end
		local targets = {prefixMatch(table.unpack(names))}
		if #targets > 0 then
			for _, target in ipairs(targets) do
				if target.Character then
					func.esp.apply(target, espOpts.color, espOpts)
				end
			end
			notify("solar:eye-bold", 3, "ESP", "ESP applied.")
		else
			notify("lucide:user-x", 4, "ESP", "Player not found.")
		end
	end,
})

Cmd.add({"espall", "allesp", "espallplayers"}, {
	fn = func.feat.enableESPAll,
})

Cmd.add({"unesp"}, {
	fn = function()
		func.esp.clearAll()
		notify("solar:eye-closed-bold", 3, "ESP", "ESP removed.")
	end,
})

Cmd.add({"instantproximityprompt", "instantpp", "ipp"}, {
	fn = func.feat.enableInstantPP,
})

Cmd.add({"uninstantproximityprompt", "uninstantpp", "unipp"}, {
	fn = function()
		NnBind.disconnect("ipp_added")
		notify("sfsymbols:handTapFill", 3, "InstantPP", "Instant proximity prompts disabled.")
	end,
})

Cmd.add({"fling"}, {
	args = "playername",
	args2 = "playername2",
	fn = function(...)
		local names = {}
		for _, n in ipairs(stripCommas({...})) do
			if n then names[#names + 1] = n:lower() end
		end
		if #names == 0 then
			notify("lucide:triangle-alert", 4, "Fling", "No players specified to fling.")
			return
		end
		if names[1] == "all" then
			local targets = {}
			for p in pairs(cachedPlayers) do
				if p ~= LocalPlayer and not (ignoreTeamOpts.fling and LocalPlayer.Team and p.Team == LocalPlayer.Team) then
					targets[#targets + 1] = p
				end
			end
			func.feat.fling(table.unpack(targets))
			return
		end
		local targets = {prefixMatch(table.unpack(names))}
		if #targets > 0 then
			func.feat.fling(table.unpack(targets))
		else
			notify("lucide:user-x", 4, "Fling", "Player not found.")
		end
	end,
})

Cmd.add({"walkfling", "wf"}, {
	args = "power",
	fn = function(power)
		power = tonumber(power) or 100000
		local powers = power * 3
		local cachedParts = {}

		local function cacheParts(char)
			table.clear(cachedParts)
			for _, name in ipairs({"HumanoidRootPart", "Head"}) do
				local part = char:WaitForChild(name, 3)
				if part and part:IsA("BasePart") then
					cachedParts[#cachedParts + 1] = part
				end
			end
		end

		if playerChar then
			cacheParts(playerChar)
		end

		NnBind.reconnect("walkfling_charAdded", CharacterAdded:Connect(function(char)
			cacheParts(char)
		end))

		NnBind.reconnect("walkfling_heartbeat", RunService.Heartbeat:Connect(function()
			if #cachedParts == 0 then return end
			for _, part in ipairs(cachedParts) do
				task.spawn(function()
					local v = part.Velocity
					part.Velocity = v * power + Vector3.new(powers, powers, powers)
					RunService.RenderStepped:Wait()
					part.Velocity = v
				end)
			end
		end))
		notify("sfsymbols:wind", 3, "WalkFling", "Walk fling enabled.")
	end,
})

Cmd.add({"unwalkfling", "unwf"}, {
	fn = function()
		NnBind.disconnect("walkfling_heartbeat")
		NnBind.disconnect("walkfling_charAdded")
		notify("sfsymbols:wind", 3, "WalkFling", "Walk fling disabled.")
	end,
})

Cmd.add({"Reach"}, {
	args = "Size",
	fn = function(size)
		size = tonumber(size) or 12
		local tool = playerChar and playerChar:FindFirstChildOfClass("Tool")
		if not tool or not tool:FindFirstChild("Handle") then
			notify("lucide:triangle-alert", 4, "Reach", "No tool equipped.")
			return
		end
		local handle = tool.Handle
		if not tool:FindFirstChild("OGSize3") then
			NewInstance("Vector3Value", tool)
			tool.OGSize3.Value = handle.Size
		end
		if not handle:FindFirstChild("FunTIMES") then
			NewInstance("SelectionBox", handle)
			handle.FunTIMES.Adornee = handle
			handle.FunTIMES.Transparency = 0
			handle.FunTIMES.Color3 = Color3.fromRGB(255, 0, 0)
		end
		handle.Massless = true
		handle.Size = Vector3.new(size, size, size)
		notify("geist:arrow-circle-up", 3, "Reach", "Reach set to " .. tostring(size))
	end,
})

Cmd.add({"Unreach"}, {
	fn = function()
		local tool = playerChar and playerChar:FindFirstChildOfClass("Tool") or LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
		if not tool or not tool:FindFirstChild("Handle") then return end
		local handle = tool.Handle
		if tool:FindFirstChild("OGSize3") then
			handle.Size = tool.OGSize3.Value
		end
		if handle:FindFirstChild("FunTIMES") then
			handle.FunTIMES:Destroy()
		end
		handle.Massless = false
		notify("geist:arrow-circle-up", 3, "Reach", "Reach removed.")
	end,
})

Cmd.add({"watch", "view", "spectate"}, {
	args = "playername",
	fn = function(name)
		if not name then return end
		local targets = {prefixMatch(name)}
		if #targets > 0 then
			func.feat.watch(targets[1])
		else
			notify("lucide:user-x", 4, "Watch", "Player not found.")
		end
	end,
})

Cmd.add({"unwatch", "unview", "unspectate"}, {
	fn = func.feat.unwatch,
})

Cmd.add({"fov"}, {
	args = "value",
	fn = function(value)
		value = tonumber(value)
		if not value then return end
		Camera.FieldOfView = value
		notify("craft:camera-lens-snap-01-stroke", 3, "FOV", "Set to " .. tostring(value))
	end,
})

Cmd.add({"teleport", "tp", "goto"}, {
	args = "playername / x,y,z",
	fn = function(...)
		local args = {...}
		if #args == 0 then return end

		local hrp = playerHRP
		if not hrp then
			notify("lucide:triangle-alert", 4, "Teleport", "Character not found.")
			return
		end

		local raw = table.concat(args, ",")
		local hasLetter = raw:match("%a") ~= nil

		if not hasLetter then
			local nums = {}
			for n in raw:gmatch("[%-%.%d]+") do
				nums[#nums + 1] = tonumber(n)
			end
			if #nums < 3 then
				notify("lucide:triangle-alert", 4, "Teleport", "Invalid coordinates.")
				return
			end
			hrp.CFrame = CFrame.new(nums[1], nums[2], nums[3])
			notify("craft:gps-01-stroke", 3, "Teleport", string.format("Teleported to %.1f, %.1f, %.1f", nums[1], nums[2], nums[3]))
		else
			local targets = {prefixMatch(args[1])}
			if #targets == 0 then
				notify("lucide:user-x", 4, "Teleport", "Player not found.")
				return
			end
			local targetHRP = targets[1].Character and targets[1].Character:FindFirstChild("HumanoidRootPart")
			if not targetHRP then
				notify("lucide:triangle-alert", 4, "Teleport", targets[1].Name .. " has no character.")
				return
			end
			hrp.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
			notify("craft:gps-01-stroke", 3, "Teleport", "Teleported to " .. targets[1].Name .. ".")
		end
	end,
})

Cmd.add({"infinitejump", "infjump"}, {
	fn = function()
		local lastJump = 0
		NnBind.reconnect("ij_jumped", UserInputService.JumpRequest:Connect(function()
			local hum = playerHum
			if not hum then
				notify("lucide:triangle-alert", 3, "Infinite Jump", "No character found.")
				return
			end
			local now = tick()
			if now - lastJump < 0.05 then return end
			lastJump = now
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end))
		notify("sfsymbols:arrowUpAndDownCircleFill", 3, "Infinite Jump", "Enabled.")
	end,
})

Cmd.add({"uninfinitejump", "uninfjump"}, {
	fn = function()
		NnBind.disconnect("ij_jumped")
		notify("sfsymbols:arrowUpAndDownCircleFill", 3, "Infinite Jump", "Disabled.")
	end,
})

Cmd.add({"rejoin", "rj"}, {
	fn = function()
		notify("lucide:refresh-cw", 3, "Rejoin", "Rejoining...")
		task.wait(0.5)
		TeleportService:Teleport(game.PlaceId, LocalPlayer)
	end,
})

Cmd.add({"serverhop", "shop"}, {
	fn = function()
		notify("lucide:server", 3, "Serverhop", "Finding server...")
		local ok, res = pcall(function()
			return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
		end)
		if not ok or not res or not res.data then
			notify("lucide:triangle-alert", 4, "Serverhop", "Failed to fetch server list.")
			return
		end
		for _, server in ipairs(res.data) do
			if server.id ~= game.JobId and server.playing < server.maxPlayers then
				TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
				return
			end
		end
		notify("lucide:triangle-alert", 4, "Serverhop", "No available server found.")
	end,
})

Cmd.add({"smallserverhop", "sshop"}, {
	fn = function()
		notify("lucide:server", 3, "SmallServerHop", "Finding small server...")

		local best = nil
		local cursor = ""
		local pages = 0
		local maxPages = 2

		repeat
			local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
			if cursor ~= "" then
				url = url .. "&cursor=" .. cursor
			end

			local ok, res = pcall(function()
				return HttpService:JSONDecode(game:HttpGet(url))
			end)

			if not ok or not res or not res.data then
				break
			end

			for _, server in ipairs(res.data) do
				if server.id ~= game.JobId and server.playing < server.maxPlayers then
					if not best or server.playing < best.playing then
						best = server
					end
				end
			end

			cursor = res.nextPageCursor or ""
			pages += 1
		until cursor == "" or pages >= maxPages

		if best then
			TeleportService:TeleportToPlaceInstance(game.PlaceId, best.id, LocalPlayer)
		else
			notify("lucide:triangle-alert", 4, "SmallServerHop", "No small server found.")
		end
	end,
})

Cmd.add({"settings"}, {
	fn = function()
		UI.Settings.open()
	end,
})

Cmd.add({"autoclicker", "autoclick"}, {
	fn = function()
		UI.AutoClicker.open()
	end,
})

Cmd.add({"admin"}, {
	fn = function()
		NnBind.reconnect("admin_chat", LocalPlayer.Chatted:Connect(function(msg)
			if msg:sub(1, 1) ~= rare.cmdPrefix then return end
			runCommand(msg:sub(2))
		end))
		notify("geist:code-bracket", 3, "Admin", "Chat commands enabled.")
	end,
})

Cmd.add({"unadmin"}, {
	fn = function()
		NnBind.disconnect("admin_chat")
		notify("geist:code-bracket", 3, "Admin", "Chat commands disabled.")
	end,
})

Cmd.add({"antikick"}, {
	fn = function()
		if rare.antikick_orig then return end
		rare.antikick_orig = safehook(game, "__namecall", function(self, ...)
			if getnamecallmethod() == "Kick" and self == LocalPlayer then
				task.wait(9e9)
			end
			return rare.antikick_orig(self, ...)
		end, true)
		notify("sfsymbols:checkmarkShieldFill", 3, "AntiKick", "Anti-kick enabled.")
	end,
})
Cmd.add({"unantikick"}, {
	fn = function()
		if not rare.antikick_orig then return end
		safeunhook(game, "__namecall", rare.antikick_orig)
		rare.antikick_orig = nil
		notify("sfsymbols:xmarkShieldFill", 3, "AntiKick", "Anti-kick disabled.")
	end,
})

Cmd.add({"godmode", "god"}, {
	fn = function(mode)
		mode = mode and mode:lower()
		if mode == "hook" or mode == "nohook" then
			func.feat.godmode(mode)
			return
		end
		UI.Picker.show({
			title = "Godmode",
			subtitle = "Select protection method",
			buttons = {
				{
					label = "Hook",
					sub = "Hook-Based",
					accent = Color3.fromRGB(255, 160, 50),
					value = "hook",
				},
				{
					label = "No Hook",
					sub = "Signals-Based",
					accent = Color3.fromRGB(80, 180, 255),
					value = "nohook",
				},
			},
		}, function(value)
			if value then func.feat.godmode(value) end
		end)
	end,
})

Cmd.add({"ungodMode", "ungod"}, {
	fn = function()
		NnBind.disconnect("gm_healthChanged")
		NnBind.disconnect("gm_health")
		NnBind.disconnect("gm_maxHealth")
		NnBind.disconnect("gm_breakJoints")
		NnBind.disconnect("gm_stateChanged")
		NnBind.disconnect("gm_charAdded")

		rare.god_mode = nil

		if rare.god_origNI then
			safeunhook(game, "__newindex", rare.god_origNI)
			rare.god_origNI = nil
		end
		if rare.god_origNC then
			safeunhook(game, "__namecall", rare.god_origNC)
			rare.god_origNC = nil
		end
		rare.god_hum = nil

		local hum = playerHum
		if hum then
			hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
			hum.BreakJointsOnDeath = true
		end
		notify("sfsymbols:heartSlashFill", 3, "GodMode", "Disabled.")
	end,
})

Cmd.add({"tptool", "clicktp"}, {
    fn = function()
        local mouse = LocalPlayer:GetMouse()
        local tool = NewInstance("Tool")
        tool.ToolTip = "Click/Tap to teleport"
        tool.RequiresHandle = false
        tool.Activated:Connect(function()
            local hrp = playerHRP
            if hrp then hrp.CFrame = mouse.Hit end
        end)
        tool.Parent = LocalPlayer.Backpack
        notify("sfsymbols:handPointUpLeftFill", 3, "TpTool", "Click-TP tool added to backpack.")
    end,
})

Cmd.add({"untptool", "unclicktp"}, {
    fn = function()
        local tool = LocalPlayer.Backpack:FindFirstChild("tptool") or (playerChar and playerChar:FindFirstChild("tptool"))
        if tool then
            tool:Destroy()
            notify("sfsymbols:handPointUpLeftFill", 3, "TpTool", "Click-TP tool removed.")
        end
    end,
})

Cmd.add({"spin"}, {
	args = "speed",
	fn = function(speed)
		speed = tonumber(speed) or 50
		local hrp = playerHRP
		local hum = playerHum
		if hum then hum.AutoRotate = false end

		local function applySpin(newHrp)
			if rare.spinBav then rare.spinBav:Destroy() end
			rare.spinBav = NewInstance("BodyAngularVelocity")
			rare.spinBav.MaxTorque = Vector3.new(0, math.huge, 0)
			rare.spinBav.AngularVelocity = Vector3.new(0, speed, 0)
			rare.spinBav.Parent = newHrp
		end

		applySpin(hrp)
		notify("sfsymbols:rotateRightFill", 3, "Spin", "Spin enabled.")

		NnBind.reconnect("spin_charAdded", CharacterAdded:Connect(function(newChar)
			local newHrp = newChar:WaitForChild("HumanoidRootPart")
			hum = newChar:WaitForChild("Humanoid")
			hum.AutoRotate = false
			applySpin(newHrp)
		end))
	end,
})

Cmd.add({"unspin"}, {
	fn = function()
		NnBind.disconnect("spin_charAdded")
		if rare.spinBav then
     rare.spinBav:Destroy()
     rare.spinBav = nil end
		local hum = playerHum
		if hum then hum.AutoRotate = true end
		notify("sfsymbols:rotateLeftFill", 3, "Spin", "Spin disabled.")
	end,
})

Cmd.add({"antiafk", "aafk"}, {
	fn = function(mode)
		mode = mode and mode:lower()
		if mode == "mobile" or mode == "pc" then
			func.feat.antiAfk(mode == "mobile" and "Mobile" or "PC")
			return
		end
		UI.Picker.show({
			title = "Anti-AFK",
			subtitle = "Select your device mode",
			buttons = {
				{
					label = "Mobile",
					sub = "Touch-based simulation",
					accent = Color3.fromRGB(80, 200, 120),
					value = "Mobile",
				},
				{
					label = "PC",
					sub = "Keyboard-based simulation",
					accent = Color3.fromRGB(80, 160, 255),
					value = "PC",
				},
			},
		}, function(value)
			if value then func.feat.antiAfk(value) end
		end)
	end,
})

Cmd.add({"unantiafk", "unaafk"}, {
	fn = function()
		func.feat.antiAfk(nil)
		notify("geist:cursor-click", 3, "Anti-AFK", "Disabled.")
	end,
})

Cmd.add({"uiscale", "uscale", "guiscale", "gscale"}, {
	fn = function()
		UI.UiScaler.toggle()
	end,
})

Cmd.add({"aimlock"}, {
	args = "fov",
	fn = function(fovArg)
		local fovRadius = tonumber(fovArg) or 150

		UI.Picker.show({
			title = "AIMLOCK",
			subtitle = "Select target part",
			buttons = {
				{
					label = "HEAD",
					sub = "Lock to head",
					accent = Color3.fromRGB(0, 170, 255),
					value = "Head",
				},
				{
					label = "HRP",
					sub = "Lock to HumanoidRootPart",
					accent = Color3.fromRGB(160, 80, 255),
					value = "HumanoidRootPart",
				},
			},
		}, function(targetPartName)
			if not targetPartName then return end

			if rare.aimlockGui then
				rare.aimlockGui:Destroy()
				rare.aimlockGui = nil
			end

			local lockedTarget = nil
			local charCache = {}

			local function getAimPart(char)
				if not char then return nil end
				return char:FindFirstChild(targetPartName) or char:FindFirstChild("HumanoidRootPart")
			end

			for player in pairs(cachedPlayers) do
				if player == LocalPlayer then continue end
				if player.Character then
					charCache[player] = player.Character
				end
				NnBind.reconnect("aimlock_charadded_" .. player.UserId, player.CharacterAdded:Connect(function(char)
					charCache[player] = char
					if lockedTarget and not lockedTarget.Parent then
						lockedTarget = nil
					end
				end))
			end

			NnBind.reconnect("aimlock_playeradded", PlayerAdded:Connect(function(player)
				if player.Character then
					charCache[player] = player.Character
				end
				NnBind.reconnect("aimlock_charadded_" .. player.UserId, player.CharacterAdded:Connect(function(char)
					charCache[player] = char
					if lockedTarget and not lockedTarget.Parent then
						lockedTarget = nil
					end
				end))
			end))

			NnBind.reconnect("aimlock_playerremoving", PlayerRemoving:Connect(function(player)
				if lockedTarget == charCache[player] then
					lockedTarget = nil
				end
				charCache[player] = nil
				NnBind.disconnect("aimlock_charadded_" .. player.UserId)
			end))

			Camera.CameraType = Enum.CameraType.Track
			notify("sfsymbols:target", 3, "Aimlock", "Aimlock enabled (" .. targetPartName .. ").")

			NnBind.reconnect("aimlock_camtype", Camera:GetPropertyChangedSignal("CameraType"):Connect(function()
				local ct = Camera.CameraType
				if ct ~= Enum.CameraType.Scriptable and ct ~= Enum.CameraType.Track then
					Camera.CameraType = Enum.CameraType.Track
				end
			end))

			rare.aimlockGui = NewInstance("ScreenGui")
			rare.aimlockGui.ResetOnSpawn = false
			rare.aimlockGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			rare.aimlockGui.IgnoreGuiInset = true
			rare.aimlockGui.Parent = getGuiParent()

			local circle = NewInstance("Frame")
			circle.BackgroundTransparency = 1
			circle.BorderSizePixel = 0
			circle.Size = UDim2.fromOffset(fovRadius * 2, fovRadius * 2)
			circle.AnchorPoint = Vector2.new(0.5, 0.5)
			circle.Position = UDim2.fromScale(0.5, 0.5)
			circle.Parent = rare.aimlockGui

			local corner = NewInstance("UICorner")
			corner.CornerRadius = UDim.new(1, 0)
			corner.Parent = circle

			local stroke = NewInstance("UIStroke")
			stroke.Color = Color3.fromRGB(255, 255, 255)
			stroke.Thickness = 1
			stroke.Parent = circle

			NnBind.reconnect("aimlock_stepped", RunService.RenderStepped:Connect(function()
				local vp = Camera.ViewportSize
				local screenCenter = Vector2.new(vp.X / 2, vp.Y / 2)

				if lockedTarget then
					local char = lockedTarget
					local hum = char:FindFirstChildOfClass("Humanoid")
					local hrp = char:FindFirstChild("HumanoidRootPart")
					local aimPart = getAimPart(char)

					if not hum or hum.Health <= 0 or not hrp or not aimPart then
						lockedTarget = nil
					else
						local screenPos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
						if not onScreen then
							lockedTarget = nil
						else
							local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
							if screenDist > fovRadius then
								lockedTarget = nil
							else
								local obscuring = Camera:GetPartsObscuringTarget({aimPart.Position}, {playerChar, char})
								if #obscuring > 0 then
									lockedTarget = nil
								end
							end
						end
					end
				end

				if not lockedTarget then
					local bestDist = math.huge

					for player, char in pairs(charCache) do
						local hum = char:FindFirstChildOfClass("Humanoid")
						if not hum or hum.Health <= 0 then continue end
						if ignoreTeamOpts.aimlock and LocalPlayer.Team and player.Team == LocalPlayer.Team then continue end

						local hrp = char:FindFirstChild("HumanoidRootPart")
						if not hrp then continue end

						local aimPart = getAimPart(char)
						if not aimPart then continue end

						local screenPos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
						if not onScreen then continue end

						local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
						if screenDist > fovRadius then continue end

						local obscuring = Camera:GetPartsObscuringTarget({aimPart.Position}, {playerChar, char})
						if #obscuring > 0 then continue end

						if screenDist < bestDist then
							bestDist = screenDist
							lockedTarget = char
						end
					end
				end

				if lockedTarget then
					local aimPart = getAimPart(lockedTarget)
					if aimPart then
						Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, predictPosition(aimPart))
					end
				end
			end))
		end)
	end,
})

Cmd.add({"unaimlock"}, {
	fn = function()
		NnBind.disconnect("aimlock_stepped")
		NnBind.disconnect("aimlock_camtype")
		NnBind.disconnect("aimlock_playeradded")
		NnBind.disconnect("aimlock_playerremoving")
		for player in pairs(cachedPlayers) do
			NnBind.disconnect("aimlock_charadded_" .. player.UserId)
		end
		if rare.aimlockGui then
			rare.aimlockGui:Destroy()
			rare.aimlockGui = nil
		end
		notify("sfsymbols:target", 3, "Aimlock", "Aimlock disabled.")
	end,
})

Cmd.add({"SilentAim", "SA"}, {
	args = "[near/fov] [radius]",
	fn = function(modeArg, radiusArg)
		if rare.saActive then return end

		local isNear = not modeArg or modeArg ~= "fov"
		local fov = tonumber(radiusArg) or 120

		UI.Picker.show({
			title = "SILENT AIM",
			subtitle = "Select target part",
			buttons = {
				{ label = "HEAD", sub = "Aim at head", accent = Color3.fromRGB(0, 170, 255), value = "Head" },
				{ label = "HRP", sub = "Aim at HumanoidRootPart", accent = Color3.fromRGB(160, 80, 255), value = "HumanoidRootPart" },
			},
		}, function(targetPart)
			if not targetPart then return end

			local mouse = LocalPlayer:GetMouse()
			local saTarget = nil

			NnBind.reconnect("sa_candidates", RunService.Heartbeat:Connect(function()
				local best, bestDist = nil, math.huge

				if isNear then
					local myRoot = playerHRP
					if not myRoot then saTarget = nil return end

					for player in pairs(cachedPlayers) do
						if player == LocalPlayer then continue end
						if ignoreTeamOpts.silentaim and LocalPlayer.Team and player.Team == LocalPlayer.Team then continue end
						local char = player.Character
						if not char then continue end
						local hum = char:FindFirstChildOfClass("Humanoid")
						if not hum or hum.Health <= 0 then continue end
						local part = char:FindFirstChild(targetPart) or char:FindFirstChild("HumanoidRootPart")
						if not part then continue end
						local delta = part.Position - myRoot.Position
						local dist = delta:Dot(delta)
						if dist < bestDist then bestDist = dist best = part end
					end
				else
					local mp = UserInputService:GetMouseLocation()
					local fovR2 = fov * fov

					for player in pairs(cachedPlayers) do
						if player == LocalPlayer then continue end
						if ignoreTeamOpts.silentaim and LocalPlayer.Team and player.Team == LocalPlayer.Team then continue end
						local char = player.Character
						if not char then continue end
						local hum = char:FindFirstChildOfClass("Humanoid")
						if not hum or hum.Health <= 0 then continue end
						local part = char:FindFirstChild(targetPart) or char:FindFirstChild("HumanoidRootPart")
						if not part then continue end
						local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
						if not onScreen then continue end
						local delta = Vector2.new(sp.X, sp.Y) - mp
						local d2 = delta:Dot(delta)
						if d2 < fovR2 and d2 < bestDist then bestDist = d2 best = part end
					end
				end

				saTarget = best
			end))

			rare.saHookOriginal = safehook(game, "__index", function(self, key)
				if self == mouse and rare.saHookOriginal and (key == "Hit" or key == "Target" or key == "UnitRay") then
					local target = saTarget
					if target and target.Parent then
						local pos = predictPosition(target)
						local dir = pos - Camera.CFrame.Position
						local mag = dir.Magnitude
						dir = mag > 1e-3 and dir / mag or Camera.CFrame.LookVector
						if key == "Target" then return target end
						if key == "Hit" then return CFrame.new(pos, pos + dir) end
						if key == "UnitRay" then return Ray.new(Camera.CFrame.Position, dir * 5000) end
					end
				end
				return rare.saHookOriginal(self, key)
			end, true)

			if not rare.saHookOriginal then
				notify("lucide:triangle-alert", 4, "SilentAim", "Hook failed — metamethod hooking not supported.")
				NnBind.disconnect("sa_candidates")
				return
			end

			rare.saActive = true

			if not isNear then
				rare.saGui = NewInstance("ScreenGui")
            rare.saGui.IgnoreGuiInset = true
				rare.saGui.ResetOnSpawn = false
				rare.saGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
				rare.saGui.Parent = getGuiParent()

				local circle = NewInstance("Frame")
				circle.BackgroundTransparency = 1
				circle.BorderSizePixel = 0
				circle.Size = UDim2.fromOffset(fov * 2, fov * 2)
				circle.AnchorPoint = Vector2.new(0.5, 0.5)
				circle.Position = UDim2.fromOffset(0, 0)
				circle.Visible = false
				circle.Parent = rare.saGui
				rare.saCircle = circle

				local corner = NewInstance("UICorner")
				corner.CornerRadius = UDim.new(1, 0)
				corner.Parent = circle

				local stroke = NewInstance("UIStroke")
				stroke.Color = Color3.fromRGB(255, 255, 255)
				stroke.Thickness = 1
				stroke.Parent = circle

				local holding = false

				NnBind.reconnect("sa_mouse", RunService.RenderStepped:Connect(function()
					if holding and rare.saCircle then
						local mp = UserInputService:GetMouseLocation()
						rare.saCircle.Position = UDim2.fromOffset(mp.X, mp.Y)
					end
				end))

				NnBind.reconnect("sa_press", UserInputService.InputBegan:Connect(function(input, gpe)
					if gpe then return end
					local t = input.UserInputType
					if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
						holding = true
						if rare.saCircle then rare.saCircle.Visible = true end
					end
				end))

				NnBind.reconnect("sa_release", UserInputService.InputEnded:Connect(function(input)
					local t = input.UserInputType
					if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
						holding = false
						if rare.saCircle then rare.saCircle.Visible = false end
					end
				end))
			end

			notify("sfsymbols:target", 3, "SilentAim", "Enabled (" .. targetPart .. ", " .. (isNear and "near" or "fov " .. fov) .. ").")
		end)
	end,
})

Cmd.add({"UnSilentAim", "UnSA"}, {
	fn = function()
		if rare.saHookOriginal then
			safeunhook(game, "__index", rare.saHookOriginal)
			rare.saHookOriginal = nil
		end
		if rare.saGui then
			rare.saGui:Destroy()
			rare.saGui = nil
		end
		rare.saCircle = nil
		rare.saActive = false
		NnBind.disconnect("sa_candidates")
		NnBind.disconnect("sa_mouse")
		NnBind.disconnect("sa_press")
		NnBind.disconnect("sa_release")
		notify("sfsymbols:target", 3, "SilentAim", "Silent aim disabled.")
	end,
})

Cmd.add({"hitbox", "hb"}, {
	args = "size",
	args2 = "transparency",
	fn = function(sizeArg, transArg)
		local size = tonumber(sizeArg) or 10
		local hitboxSize = Vector3.new(size, size, size)
		local transparency = tonumber(transArg) or 0.7

		for player in pairs(cachedPlayers) do
			if player == LocalPlayer then continue end
			if ignoreTeamOpts.hitbox and LocalPlayer.Team and player.Team == LocalPlayer.Team then continue end
			if player.Character then
				local hrp = player.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					rare.hitboxOriginals[player.Character] = hrp.Size
					hrp.Size = hitboxSize
					hrp.Transparency = transparency
					hrp.CanCollide = false
					NnBind.reconnect("hitbox_sizechanged_" .. tostring(hrp), hrp:GetPropertyChangedSignal("Size"):Connect(function()
						if hrp.Size ~= hitboxSize then hrp.Size = hitboxSize end
					end))
					NnBind.reconnect("hitbox_transchanged_" .. tostring(hrp), hrp:GetPropertyChangedSignal("Transparency"):Connect(function()
						if hrp.Transparency ~= transparency then hrp.Transparency = transparency end
					end))
					NnBind.reconnect("hitbox_cancollidechanged_" .. tostring(hrp), hrp:GetPropertyChangedSignal("CanCollide"):Connect(function()
						if hrp.CanCollide then hrp.CanCollide = false end
					end))
				end
			end
			NnBind.reconnect("hitbox_charadded_" .. player.UserId, player.CharacterAdded:Connect(function(char)
				if ignoreTeamOpts.hitbox and LocalPlayer.Team and player.Team == LocalPlayer.Team then return end
				local hrp = char:WaitForChild("HumanoidRootPart")
				rare.hitboxOriginals[char] = hrp.Size
				hrp.Size = hitboxSize
				hrp.Transparency = transparency
				hrp.CanCollide = false
				NnBind.reconnect("hitbox_sizechanged_" .. tostring(hrp), hrp:GetPropertyChangedSignal("Size"):Connect(function()
					if hrp.Size ~= hitboxSize then hrp.Size = hitboxSize end
				end))
				NnBind.reconnect("hitbox_transchanged_" .. tostring(hrp), hrp:GetPropertyChangedSignal("Transparency"):Connect(function()
					if hrp.Transparency ~= transparency then hrp.Transparency = transparency end
				end))
				NnBind.reconnect("hitbox_cancollidechanged_" .. tostring(hrp), hrp:GetPropertyChangedSignal("CanCollide"):Connect(function()
					if hrp.CanCollide then hrp.CanCollide = false end
				end))
			end))
		end

		NnBind.reconnect("hitbox_playeradded", PlayerAdded:Connect(function(player)
			if ignoreTeamOpts.hitbox and LocalPlayer.Team and player.Team == LocalPlayer.Team then return end
			if player.Character then
				local hrp = player.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					rare.hitboxOriginals[player.Character] = hrp.Size
					hrp.Size = hitboxSize
					hrp.Transparency = transparency
					hrp.CanCollide = false
					NnBind.reconnect("hitbox_sizechanged_" .. tostring(hrp), hrp:GetPropertyChangedSignal("Size"):Connect(function()
						if hrp.Size ~= hitboxSize then hrp.Size = hitboxSize end
					end))
					NnBind.reconnect("hitbox_transchanged_" .. tostring(hrp), hrp:GetPropertyChangedSignal("Transparency"):Connect(function()
						if hrp.Transparency ~= transparency then hrp.Transparency = transparency end
					end))
					NnBind.reconnect("hitbox_cancollidechanged_" .. tostring(hrp), hrp:GetPropertyChangedSignal("CanCollide"):Connect(function()
						if hrp.CanCollide then hrp.CanCollide = false end
					end))
				end
			end
			NnBind.reconnect("hitbox_charadded_" .. player.UserId, player.CharacterAdded:Connect(function(char)
				local hrp = char:WaitForChild("HumanoidRootPart")
				rare.hitboxOriginals[char] = hrp.Size
				hrp.Size = hitboxSize
				hrp.Transparency = transparency
				hrp.CanCollide = false
				NnBind.reconnect("hitbox_sizechanged_" .. tostring(hrp), hrp:GetPropertyChangedSignal("Size"):Connect(function()
					if hrp.Size ~= hitboxSize then hrp.Size = hitboxSize end
				end))
				NnBind.reconnect("hitbox_transchanged_" .. tostring(hrp), hrp:GetPropertyChangedSignal("Transparency"):Connect(function()
					if hrp.Transparency ~= transparency then hrp.Transparency = transparency end
				end))
				NnBind.reconnect("hitbox_cancollidechanged_" .. tostring(hrp), hrp:GetPropertyChangedSignal("CanCollide"):Connect(function()
					if hrp.CanCollide then hrp.CanCollide = false end
				end))
			end))
		end))

		NnBind.reconnect("hitbox_playerremoving", PlayerRemoving:Connect(function(player)
			NnBind.disconnect("hitbox_charadded_" .. player.UserId)
			if player.Character then
				local hrp = player.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					NnBind.disconnect("hitbox_sizechanged_" .. tostring(hrp))
					NnBind.disconnect("hitbox_transchanged_" .. tostring(hrp))
					NnBind.disconnect("hitbox_cancollidechanged_" .. tostring(hrp))
				end
			end
		end))

		notify("lucide:box", 3, "Hitbox", "Hitbox set to " .. tostring(size) .. ".")
	end,
})

Cmd.add({"unhitbox", "unhb"}, {
	fn = function()
		NnBind.disconnect("hitbox_playeradded")
		NnBind.disconnect("hitbox_playerremoving")
		for player in pairs(cachedPlayers) do
			NnBind.disconnect("hitbox_charadded_" .. player.UserId)
			if player ~= LocalPlayer and player.Character then
				local hrp = player.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					NnBind.disconnect("hitbox_sizechanged_" .. tostring(hrp))
					NnBind.disconnect("hitbox_transchanged_" .. tostring(hrp))
					NnBind.disconnect("hitbox_cancollidechanged_" .. tostring(hrp))
					if rare.hitboxOriginals[player.Character] then
						hrp.Size = rare.hitboxOriginals[player.Character]
					end
					hrp.Transparency = 1
					hrp.CanCollide = false
				end
			end
		end
		table.clear(rare.hitboxOriginals)
		notify("lucide:boxes", 3, "Hitbox", "Hitbox removed.")
	end,
})

Cmd.add({"cbring", "clientbring", "clientb"}, {
	args = "playername / all",
	fn = function(...)
		local myHrp = playerHRP
		if not myHrp then return end

		local names = {...}
		local targets = {}
		if #names == 0 or names[1]:lower() == "all" then
			for player in pairs(cachedPlayers) do
				if player ~= LocalPlayer then targets[#targets + 1] = player end
			end
		else
			targets = {prefixMatch(table.unpack(names))}
		end

		for _, player in ipairs(targets) do
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = myHrp.CFrame * CFrame.new(0, 0, -5)
			end
		end
		notify("sfsymbols:person2Fill", 3, "CBring", "Brought players to you.")
	end,
})

Cmd.add({"loopcbring", "loopclientb", "loppclientb", "loopclientbring", "lcbring"}, {
	args = "playername / all",
	fn = function(...)
		local names = {...}
		if #names == 0 or names[1]:lower() == "all" then
			for player in pairs(cachedPlayers) do
				if player ~= LocalPlayer then loopBringTargets[player] = true end
			end
		else
			for _, player in ipairs({prefixMatch(table.unpack(names))}) do
				loopBringTargets[player] = true
			end
		end

		NnBind.reconnect("loopcbring_heartbeat", RunService.Heartbeat:Connect(function()
			local myHrp = playerHRP
			if not myHrp then return end

			for player in pairs(loopBringTargets) do
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					hrp.CFrame = myHrp.CFrame * CFrame.new(0, 0, -5)
				end
			end
		end))
		notify("sfsymbols:person2Fill", 3, "LoopCBring", "Loop bring enabled.")
	end,
})

Cmd.add({"unloopcbring", "unloopclientb", "unloopcientb", "unlcbring", "unlclientb", "uncbring"}, {
	args = "playername / all",
	fn = function(...)
		local names = {...}
		if #names == 0 or names[1]:lower() == "all" then
			NnBind.disconnect("loopcbring_heartbeat")
			table.clear(loopBringTargets)
		else
			for _, player in ipairs({prefixMatch(table.unpack(names))}) do
				loopBringTargets[player] = nil
			end
			if not next(loopBringTargets) then
				NnBind.disconnect("loopcbring_heartbeat")
			end
		end
		notify("sfsymbols:person2Fill", 3, "LoopCBring", "Loop bring disabled.")
	end,
})

Cmd.add({"fpsbooster", "lowgraphics", "boostfps", "lowg", "antilag"}, {
	fn = function()
		if fpsbooster then return end
		fpsbooster = true

		if execapi.setfpscap then execapi.setfpscap(0) end

		local terrain = workspace.Terrain
		local rs = settings().Rendering
		local TargetQuality = Enum.QualityLevel.Level01

		rs.QualityLevel = TargetQuality
		rs.EagerBulkExecution = true
		rs.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01

		Lighting.GlobalShadows = false
		Lighting.FogEnd = 9e9
		Lighting.FogStart = 9e9
		Lighting.EnvironmentDiffuseScale = 0
		Lighting.EnvironmentSpecularScale = 0
		Lighting.Technology = Enum.Technology.Compatibility

		workspace.GlobalWind = Vector3.zero
		workspace.LevelOfDetail = Enum.ModelLevelOfDetail.Disabled
		workspace.InterpolationThrottling = Enum.InterpolationThrottlingMode.Enabled

		if execapi.sethiddenproperty then
			pcall(execapi.sethiddenproperty, workspace, "StreamingEnabled", true)
			pcall(execapi.sethiddenproperty, terrain, "Decoration", false)
		end

		terrain.WaterReflectance = 0
		terrain.WaterWaveSize = 0
		terrain.WaterWaveSpeed = 0

		for _, obj in ipairs(Lighting:GetChildren()) do
			obj:Destroy()
		end

		NnBind.reconnect("fpsboost_lightingchildadded", Lighting.ChildAdded:Connect(function(obj)
			obj:Destroy()
		end))

		NnBind.reconnect("fpsboost_QualityLevel", rs:GetPropertyChangedSignal("QualityLevel"):Connect(function() setProp(rs, "QualityLevel", TargetQuality) end))
		NnBind.reconnect("fpsboost_EagerBulkExecution", rs:GetPropertyChangedSignal("EagerBulkExecution"):Connect(function() setProp(rs, "EagerBulkExecution", true) end))
		NnBind.reconnect("fpsboost_MeshPartDetailLevel", rs:GetPropertyChangedSignal("MeshPartDetailLevel"):Connect(function() setProp(rs, "MeshPartDetailLevel", Enum.MeshPartDetailLevel.Level01) end))
		NnBind.reconnect("fpsboost_GlobalShadows", Lighting:GetPropertyChangedSignal("GlobalShadows"):Connect(function() setProp(Lighting, "GlobalShadows", false) end))
		NnBind.reconnect("fpsboost_FogEnd", Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function() setProp(Lighting, "FogEnd", 9e9) end))
		NnBind.reconnect("fpsboost_FogStart", Lighting:GetPropertyChangedSignal("FogStart"):Connect(function() setProp(Lighting, "FogStart", 9e9) end))
		NnBind.reconnect("fpsboost_EnvironmentDiffuseScale", Lighting:GetPropertyChangedSignal("EnvironmentDiffuseScale"):Connect(function() setProp(Lighting, "EnvironmentDiffuseScale", 0) end))
		NnBind.reconnect("fpsboost_EnvironmentSpecularScale", Lighting:GetPropertyChangedSignal("EnvironmentSpecularScale"):Connect(function() setProp(Lighting, "EnvironmentSpecularScale", 0) end))
		NnBind.reconnect("fpsboost_Technology", Lighting:GetPropertyChangedSignal("Technology"):Connect(function() setProp(Lighting, "Technology", Enum.Technology.Compatibility) end))
		NnBind.reconnect("fpsboost_WaterReflectance", terrain:GetPropertyChangedSignal("WaterReflectance"):Connect(function() setProp(terrain, "WaterReflectance", 0) end))
		NnBind.reconnect("fpsboost_WaterWaveSize", terrain:GetPropertyChangedSignal("WaterWaveSize"):Connect(function() setProp(terrain, "WaterWaveSize", 0) end))
		NnBind.reconnect("fpsboost_WaterWaveSpeed", terrain:GetPropertyChangedSignal("WaterWaveSpeed"):Connect(function() setProp(terrain, "WaterWaveSpeed", 0) end))
		NnBind.reconnect("fpsboost_GlobalWind", workspace:GetPropertyChangedSignal("GlobalWind"):Connect(function() setProp(workspace, "GlobalWind", Vector3.zero) end))
		NnBind.reconnect("fpsboost_LevelOfDetail", workspace:GetPropertyChangedSignal("LevelOfDetail"):Connect(function() setProp(workspace, "LevelOfDetail", Enum.ModelLevelOfDetail.Disabled) end))
		NnBind.reconnect("fpsboost_InterpolationThrottling", workspace:GetPropertyChangedSignal("InterpolationThrottling"):Connect(function() setProp(workspace, "InterpolationThrottling", Enum.InterpolationThrottlingMode.Enabled) end))

		local SmoothPlastic = Enum.Material.SmoothPlastic
		local optimized = setmetatable({}, {__mode = "k"})

		local function optimize(obj)
			if optimized[obj] then return end
			optimized[obj] = true
			local class = obj.ClassName
			if class == "ParticleEmitter" then
				obj.Rate = 0
				obj.Enabled = false
			elseif class == "Trail" or class == "Beam" or class == "Fire" or class == "Smoke" or class == "Sparkles" then
				obj.Enabled = false
			elseif class == "PointLight" or class == "SpotLight" or class == "SurfaceLight" then
				obj.Enabled = false
			elseif class == "Decal" then
				obj.Transparency = 1
			elseif class == "Texture" then
				obj.Transparency = 1
				obj.StudsPerTileU = 512
				obj.StudsPerTileV = 512
			elseif class == "SurfaceAppearance" then
				obj:Destroy()
			elseif obj:IsA("BasePart") then
				obj.Material = SmoothPlastic
				obj.Reflectance = 0
			end
		end

		for _, obj in ipairs(workspace:GetDescendants()) do
			optimize(obj)
		end

		NnBind.reconnect("fpsboost_descendantadded", workspace.DescendantAdded:Connect(optimize))

		notify("lucide:zap", 4, "FPS Booster", "Low graphics applied. Rejoin to restore.")
	end,
})

Cmd.add({"fullbright", "fulfb", "fb"}, {
	fn = function()
		Lighting.GlobalShadows = false
		Lighting.ClockTime = 12
		Lighting.Brightness = 2
		Lighting.Ambient = Color3.fromRGB(128, 128, 128)

		notify("lucide:sun", 3, "Fullbright", "Fullbright applied.")
	end,
})

Cmd.add({"loopfullbright", "loopfb", "lfb"}, {
	fn = function()
		Lighting.GlobalShadows = false
		Lighting.ClockTime = 12
		Lighting.Brightness = 2
		Lighting.Ambient = Color3.fromRGB(128, 128, 128)

		NnBind.reconnect("loopfb_GlobalShadows", Lighting:GetPropertyChangedSignal("GlobalShadows"):Connect(function() setProp(Lighting, "GlobalShadows", false) end))
		NnBind.reconnect("loopfb_ClockTime", Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function() setProp(Lighting, "ClockTime", 12) end))
		NnBind.reconnect("loopfb_Brightness", Lighting:GetPropertyChangedSignal("Brightness"):Connect(function() setProp(Lighting, "Brightness", 2) end))
		NnBind.reconnect("loopfb_Ambient", Lighting:GetPropertyChangedSignal("Ambient"):Connect(function() setProp(Lighting, "Ambient", Color3.fromRGB(128, 128, 128)) end))

		notify("lucide:sun", 3, "LoopFullbright", "Loop fullbright enabled.")
	end,
})

Cmd.add({"unloopfullbright", "unloopfb", "unlfb"}, {
	fn = function()
		NnBind.disconnect("loopfb_GlobalShadows")
		NnBind.disconnect("loopfb_ClockTime")
		NnBind.disconnect("loopfb_Brightness")
		NnBind.disconnect("loopfb_Ambient")

		notify("lucide:sun", 3, "LoopFullbright", "Loop fullbright disabled.")
	end,
})

Cmd.add({"nofog", "nf"}, {
	fn = function()
		Lighting.FogEnd = 9e9
		Lighting.FogStart = 9e9
		for _, obj in ipairs(Lighting:GetChildren()) do
			if obj:IsA("Atmosphere") then
				obj.Density = 0
				obj.Offset = 0
			end
		end
		notify("lucide:cloud-off", 3, "NoFog", "Fog removed.")
	end,
})

Cmd.add({"loopnofog", "lnofog", "lnf", "loopnf"}, {
	fn = function()
		rare.nofog_fogEnd = Lighting.FogEnd
		rare.nofog_fogStart = Lighting.FogStart

		local atm = Lighting:FindFirstChildOfClass("Atmosphere")
		rare.nofog_atmDensity = atm and atm.Density or nil
		rare.nofog_atmOffset = atm and atm.Offset or nil

		Lighting.FogEnd = 9e9
		Lighting.FogStart = 9e9

		NnBind.reconnect("loopnofog_FogEnd", Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function() setProp(Lighting, "FogEnd", 9e9) end))
		NnBind.reconnect("loopnofog_FogStart", Lighting:GetPropertyChangedSignal("FogStart"):Connect(function() setProp(Lighting, "FogStart", 9e9) end))

		if atm then
			atm.Density = 0
			atm.Offset = 0
			NnBind.reconnect("loopnofog_AtmDensity", atm:GetPropertyChangedSignal("Density"):Connect(function() setProp(atm, "Density", 0) end))
			NnBind.reconnect("loopnofog_AtmOffset", atm:GetPropertyChangedSignal("Offset"):Connect(function() setProp(atm, "Offset", 0) end))
		end

		notify("lucide:cloud-off", 3, "LoopNoFog", "Loop no fog enabled.")
	end,
})

Cmd.add({"unloopnofog", "unlnofog", "unlnf", "unloopnf", "unnf"}, {
	fn = function()
		NnBind.disconnect("loopnofog_FogEnd")
		NnBind.disconnect("loopnofog_FogStart")
		NnBind.disconnect("loopnofog_AtmDensity")
		NnBind.disconnect("loopnofog_AtmOffset")

		if rare.nofog_fogEnd ~= nil then Lighting.FogEnd = rare.nofog_fogEnd end
		if rare.nofog_fogStart ~= nil then Lighting.FogStart = rare.nofog_fogStart end

		local atm = Lighting:FindFirstChildOfClass("Atmosphere")
		if atm then
			if rare.nofog_atmDensity ~= nil then atm.Density = rare.nofog_atmDensity end
			if rare.nofog_atmOffset ~= nil then atm.Offset = rare.nofog_atmOffset end
		end

		rare.nofog_fogEnd = nil
		rare.nofog_fogStart = nil
		rare.nofog_atmDensity = nil
		rare.nofog_atmOffset = nil

		notify("lucide:cloud-off", 3, "LoopNoFog", "Loop no fog disabled.")
	end,
})

Cmd.add({"follow", "stalk", "walk"}, {
	args = "playername",
	fn = function(name)
		if not name then
			notify("lucide:triangle-alert", 4, "Follow", "No player specified.")
			return
		end
		local target = select(1, prefixMatch(name))
		if not target then
			notify("lucide:user-x", 4, "Follow", "Player not found.")
			return
		end

		rare.followActive = true

		NnBind.reconnect("follow_render", RunService.RenderStepped:Connect(function()
			local hum = playerHum
			local hrp = playerHRP
			local targetChar = target.Character
			local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

			if not hum or not hrp or not targetHRP then return end
			if (hrp.Position - targetHRP.Position).Magnitude < 4 then return end

			hum:MoveTo(targetHRP.Position)
		end))

		notify("lucide:user-check", 3, "Follow", "Following " .. target.Name .. ".")
	end,
})

Cmd.add({"unfollow"}, {
	fn = function()
		rare.followActive = nil
		NnBind.disconnect("follow_render")
		if playerHum and playerHRP then
			playerHum:MoveTo(playerHRP.Position)
		end
		notify("lucide:user-check", 3, "Follow", "Follow stopped.")
	end,
})

Cmd.add({"adonisbypass", "bypassadonis", "badonis", "adonisb"}, {
	fn = function() -- skidded from nameless admin lol
		task.spawn(function()
			local getgc = execapi.getgc
			local hookfunction = execapi.hookfunction
			local newcclosure = execapi.newcclosure or function(f) return f end
			local getrenv = execapi.getrenv
			local debugInfo = getrenv and getrenv().debug and getrenv().debug.info

			if not (getgc and hookfunction and getrenv and debugInfo) then
				notify("lucide:shield-off", 3, "Adonis Bypass", "Required exploit functions not available.")
				return
			end

			local DetectedMeth, KillMeth
			local AdonisFound = false

			for _, value in getgc(true) do
				if typeof(value) == "table" then
					local hasDetected = typeof(rawget(value, "Detected")) == "function"
					local hasKill = typeof(rawget(value, "Kill")) == "function"
					local hasVars = rawget(value, "Variables") ~= nil
					local hasProcess = rawget(value, "Process") ~= nil

					if hasDetected or (hasKill and hasVars and hasProcess) then
						AdonisFound = true
						break
					end
				end
			end

			if not AdonisFound then
				notify("lucide:shield-off", 3, "Adonis Bypass", "Adonis not found in this server.")
				return
			end

			for _, value in getgc(true) do
				if typeof(value) == "table" then
					local detected = rawget(value, "Detected")
					local kill = rawget(value, "Kill")

					if typeof(detected) == "function" and not DetectedMeth then
						DetectedMeth = detected
						hookfunction(DetectedMeth, function(methodName, methodFunc)
							return true
						end)
						notify("lucide:shield-check", 3, "Adonis Bypass", "Hooked Adonis detection.")
					end

					if rawget(value, "Variables") and rawget(value, "Process") and typeof(kill) == "function" and not KillMeth then
						KillMeth = kill
						hookfunction(KillMeth, function() end)
						notify("lucide:shield-check", 3, "Adonis Bypass", "Hooked Adonis kill method.")
					end
				end
			end

			if DetectedMeth and debugInfo then
				local hook
				hook = hookfunction(debugInfo, newcclosure(function(...)
					local functionName = ...
					if functionName == DetectedMeth then
						return coroutine.yield(coroutine.running())
					end
					return hook(...)
				end))
			end

			notify("lucide:shield", 4, "Adonis Bypass", "Bypass active.")
		end)
	end,
})

func.init.commandCaches()

UI.onScaleChanged = function(scale)
	rare.uiScaleValue = scale
	func.persist.saveSettings()
end

func.persist.loadSettings()
UI.setScale(rare.uiScaleValue)

-- General Settings Tab
rare.generalPage = UI.Settings.tab("General")
UI.Settings.input(rare.generalPage, "Command Prefix", "e.g. ;", rare.cmdPrefix, function(val)
	if val ~= "" then
		rare.cmdPrefix = val:sub(1, 1)
		func.persist.saveSettings()
	end
end)

UI.Settings.section(rare.generalPage, "Ignore Team")
UI.Settings.toggle(rare.generalPage, "SilentAim Ignore Team", function(v)
	ignoreTeamOpts.silentaim = v
	func.persist.saveSettings()
end)
UI.Settings.toggle(rare.generalPage, "Aimlock Ignore Team", function(v)
	ignoreTeamOpts.aimlock = v
	func.persist.saveSettings()
end)
UI.Settings.toggle(rare.generalPage, "Hitbox Ignore Team", function(v)
	ignoreTeamOpts.hitbox = v
	func.persist.saveSettings()
end)
UI.Settings.toggle(rare.generalPage, "Fling Ignore Team", function(v)
	ignoreTeamOpts.fling = v
	func.persist.saveSettings()
end)

-- ESP Settings Tab
rare.espPage = UI.Settings.tab("ESP")
UI.Settings.color(rare.espPage, "Custom ESP Color", espOpts.color, function(c)
	espOpts.color = c
	func.persist.saveSettings()
	if rare.espActive then
		func.esp.clearAll()
		func.feat.enableESPAll()
	end
end)
UI.Settings.toggle(rare.espPage, "Use Custom ESP Color", function(v)
	espOpts.useCustomColor = v
	func.persist.saveSettings()
	if rare.espActive then
		func.esp.clearAll()
		func.feat.enableESPAll()
	end
end)
UI.Settings.toggle(rare.espPage, "ESP Color By Team", function(v)
	espOpts.colorByTeam = v
	func.persist.saveSettings()
	if rare.espActive then
		func.esp.clearAll()
		func.feat.enableESPAll()
	end
end)
UI.Settings.toggle(rare.espPage, "Distance Label", function(v)
	espOpts.distance = v
	func.persist.saveSettings()
	if rare.espActive then
		func.esp.clearAll()
		func.feat.enableESPAll()
	end
end)
UI.Settings.toggle(rare.espPage, "Health Label", function(v)
	espOpts.health = v
	func.persist.saveSettings()
	if rare.espActive then
		func.esp.clearAll()
		func.feat.enableESPAll()
	end
end)
UI.Settings.toggle(rare.espPage, "Chams Only", function(v)
	espOpts.chamsonly = v
	func.persist.saveSettings()
	if rare.espActive then
		func.esp.clearAll()
		func.feat.enableESPAll()
	end
end)

func.persist.loadKeybinds()
func.init.keybindListener()
func.persist.loadButtons()
for _, bd in ipairs(buttons) do spawnHud(bd) end
for _, entry in ipairs(Cmds) do
	if entry.hud then
		local alias0 = entry.aliases[1]
		local label = entry.hudLabel or (alias0:sub(1, 1):upper() .. alias0:sub(2))
		local ph = entry.hudPlaceholder or nil
		local defVal = entry.hudDefault or nil
		local hasValue = ph ~= nil and defVal ~= nil
		local hud = nil
		if entry.hud == "button" then
			hud = makeButtonHUD(label,
				function(v) if DC[entry.hudStart] then DC[entry.hudStart](v) end end,
				hudYOffset, ph, defVal)
		elseif entry.hud == "toggle" then
			hud = makeToggleHUD(
				function(v) if DC[entry.hudStart] then DC[entry.hudStart](v) end end,
				function() if DC[entry.hudStop] then DC[entry.hudStop]() end end,
				hudYOffset, ph, defVal, entry.hudLabelOn, entry.hudLabelOff)
		end
		if hud then
			hudYOffset += hasValue and 80 or 50
			if entry.hudOn then
				local ons = type(entry.hudOn) == "table" and entry.hudOn or {entry.hudOn}
				for _, a in ipairs(ons) do
					hudMap[a] = {hud = hud, action = "show", isSpeed = hasValue}
				end
			end
			if entry.hudOff then
				local offs = type(entry.hudOff) == "table" and entry.hudOff or {entry.hudOff}
				for _, a in ipairs(offs) do
					hudMap[a] = {hud = hud, action = "hide"}
				end
			end
		end
	end
end

hudSg.Enabled = true

if NNNotify then
	NNNotify({
		Title = "Noname",
		Text = "Time take to load: " .. string.format("%.2f", os.clock() - rare.loadStart) .. "s",
		Duration = 4,
		Icon = "lucide:cpu",
	})
end
