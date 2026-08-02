local _registry = (type(getreg) == "function" and pcall(getreg) and getreg())
	or (type(debug) == "table" and type(debug.getregistry) == "function" and debug.getregistry())
	or getgenv()

_registry.__NN_private = _registry.__NN_private or {}
local _nnPrivate = _registry.__NN_private

if _nnPrivate.Loaded then return end
_nnPrivate.Loaded = true

if not game:IsLoaded() then game.Loaded:Wait() end

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

local _loadStart = os.clock()

local function safeLoad(url)
	local loader = (type(loadstring) == "function" and loadstring)
		or (type(load) == "function" and load)

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

		local reqFn = (type(request) == "function" and request)
			or (type(http_request) == "function" and http_request)
			or (type(syn) == "table" and type(syn.request) == "function" and syn.request)
			or (type(http) == "table" and type(http.request) == "function" and http.request)

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

local NNNotify, nnErr = safeLoad("https://raw.githubusercontent.com/isskkauww/Noname/refs/heads/main/NonameNotifications.lua")
if not NNNotify then
	warn("[Noname] Failed to load NonameNotifications module: " .. tostring(nnErr))
	return
end

local UI, uiErr = safeLoad("https://raw.githubusercontent.com/isskkauww/Noname/refs/heads/main/Noname-Ui.lua")
if not UI then
	warn("[Noname] Failed to load UI module: " .. tostring(uiErr))
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
local Vim = nil
pcall(function() Vim = cloneref(game:GetService("VirtualInputManager")) end)
local LocalPlayer = Players.LocalPlayer
local Camera = cloneref(workspace.CurrentCamera)
local cachedPlayers = {}
local noclipParts = {}
local nfvIsOn = {
	antiFling = false,
	antiInvis = false,
}
local aimlockGui = nil
local hitboxOriginals = {}
local loopBringTargets = {}
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
local Controls = require(cloneref(LocalPlayer:WaitForChild("PlayerScripts")):WaitForChild("PlayerModule")):GetControls()
local flyspeed = nil
local fpdh = workspace.FallenPartsDestroyHeight
local clipboard = type(setclipboard) == "function" and setclipboard or type(toclipboard) == "function" and toclipboard or type(set_clipboard) == "function" and set_clipboard
local writefile = type(writefile) == "function" and writefile or nil
local readfile = type(readfile) == "function" and readfile or nil
local isfile = type(isfile) == "function" and isfile or nil
local isfolder = type(isfolder) == "function" and isfolder or nil
local makefolder = type(makefolder) == "function" and makefolder or nil
local espOpts = { color = Color3.fromRGB(255, 80, 80), distance = false, health = false, chamsonly = false, colorByTeam = false, useCustomColor = false }
local espActive = false
local godmode = {
	mode = nil,
	origNI = nil,
	origNC = nil,
	humanoid = nil,
}
local cmdPrefix = ";"
local afkMode = nil
local uiScaleValue = 1

local hookapi = {
	hookmetamethod = type(hookmetamethod) == "function" and hookmetamethod or nil,
	hookfunction = (type(hookfunction) == "function" and hookfunction) or (type(replaceclosure) == "function" and replaceclosure) or (type(replacefunction) == "function" and replacefunction) or (type(hookfunc) == "function" and hookfunc) or (type(replacefunc) == "function" and replacefunc) or (type(detourfunction) == "function" and detourfunction) or (type(detour_function) == "function" and detour_function) or nil,
	getrawmetatable = type(getrawmetatable) == "function" and getrawmetatable or nil,
	setreadonly = type(setreadonly) == "function" and setreadonly or nil,
	newcclosure = type(newcclosure) == "function" and newcclosure or nil,
	setstackhidden = type(setstackhidden) == "function" and setstackhidden or nil,
	checkcaller = type(checkcaller) == "function" and checkcaller or nil,
}

-- notify
local function notify(icon, duration, title, text, button, button2)
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
	return setmetatable({
		_connected = true,
		_signal = signal,
		_fn = fn,
		_next = false,
	}, Connection)
end

function Connection:Disconnect()
	self._connected = false

	if self._signal._handlerListHead == self then
		self._signal._handlerListHead = self._next
	else
		local prev = self._signal._handlerListHead
		while prev and prev._next ~= self do
			prev = prev._next
		end
		if prev then
			prev._next = self._next
		end
	end
end

setmetatable(Connection, {
	__index = function(_, key)
		error(("Attempt to get Connection::%s (not a valid member)"):format(tostring(key)), 2)
	end,
	__newindex = function(_, key)
		error(("Attempt to set Connection::%s (not a valid member)"):format(tostring(key)), 2)
	end,
})

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({
		_handlerListHead = false,
	}, Signal)
end

function Signal:Connect(fn)
	local connection = Connection.new(self, fn)
	if self._handlerListHead then
		connection._next = self._handlerListHead
		self._handlerListHead = connection
	else
		self._handlerListHead = connection
	end
	return connection
end

function Signal:DisconnectAll()
	self._handlerListHead = false
end

function Signal:Fire(...)
	local item = self._handlerListHead
	while item do
		if item._connected then
			if not freeRunnerThread then
				freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
				coroutine.resume(freeRunnerThread)
			end
			task.spawn(freeRunnerThread, item._fn, ...)
		end
		item = item._next
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
		if cn._connected then
			cn:Disconnect()
		end
		fn(...)
	end)
	return cn
end

setmetatable(Signal, {
	__index = function(_, key)
		error(("Attempt to get Signal::%s (not a valid member)"):format(tostring(key)), 2)
	end,
	__newindex = function(_, key)
		error(("Attempt to set Signal::%s (not a valid member)"):format(tostring(key)), 2)
	end,
})

-- cache
local PlayerAdded = Signal.new()
local PlayerRemoving = Signal.new()

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

local CharacterAdded = Signal.new()
LocalPlayer.CharacterAdded:Connect(function(char)
	CharacterAdded:Fire(char)
end)

-- NnBind
local _nnPrCnt = 0

local function _nnIsLive(conn)
	if conn == nil then return false end
	if type(conn) == "table" and type(conn._connected) == "boolean" then
		return conn._connected
	end
	local ok, res = pcall(function() return conn.Connected end)
	return ok and res == true
end

local function _nnPrune(name)
	local bucket = NNConn[name]
	if type(bucket) ~= "table" then
		NNConn[name] = nil
		return 0
	end
	local write = 1
	for i = 1, #bucket do
		if _nnIsLive(bucket[i]) then
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
	_nnPrune(name)
	local bucket = NNConn[name]
	if type(bucket) ~= "table" then
		bucket = {}
		NNConn[name] = bucket
	end
	table.insert(bucket, conn)
	_nnPrCnt += 1
	if _nnPrCnt % 128 == 0 then
		for key in NNConn do _nnPrune(key) end
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
	return _nnPrune(name) > 0
end
local Cmds = {}

-- Local Functions & Some Logic
local cmdFrame = UI.CommandBar.frame
local inputBox = UI.CommandBar.inputBox
local suggFrame = UI.CommandBar.suggFrame
local suggItems = UI.CommandBar.suggItems
local hudSg = UI.HUD.sg
local makeButtonHUD = UI.HUD.makeButton
local makeToggleHUD = UI.HUD.makeToggle

local clickingSugg = false
local closeCmd = nil

for i = 1, #suggItems do
	local item = suggItems[i]
	item.MouseButton1Down:Connect(function()
		clickingSugg = true
	end)
	item.Activated:Connect(function()
		local first = string.match(item.Text, "^([^/%s]+)")
		local hasArgs = string.find(item.Text, "%[") or string.find(item.Text, "%(")
		if hasArgs then
			inputBox.Text = first .. " "
			clickingSugg = false
			inputBox:CaptureFocus()
		else
			inputBox.Text = first
			clickingSugg = false
			closeCmd(first)
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
			stopEntry.fn()
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

closeCmd = function(input)
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
	if clickingSugg then
		return
	end
	local input = string.lower(inputBox.Text)
	if not enter then
		closeCmd(nil)
		return
	end
	closeCmd(input)
end))

func.feat.loopwalkspeed = function(Speed)
	local function applyWalkSpeed(char)
		char = char or LocalPlayer.Character
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

	if LocalPlayer.Character then
		hookCharacter(LocalPlayer.Character)
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
	local char = LocalPlayer.Character
	if not char then
		notify("lucide:eye-off", 4, "Invisible", "No character found.")
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then
		notify("lucide:eye-off", 4, "Invisible", "No character found.")
		return
	end

	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part ~= hrp and part.Transparency == 0 then
			part.Transparency = 0.5
		end
	end

	NnBind.reconnect("invis_transparency", RunService.Stepped:Connect(function()
		local c = LocalPlayer.Character
		if not c then return end
		for _, part in ipairs(c:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Transparency == 0 then
				part.Transparency = 0.5
			end
		end
	end))

	NnBind.reconnect("invis_heartbeat", RunService.Heartbeat:Connect(function()
		local c = LocalPlayer.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		local r = c and c:FindFirstChild("HumanoidRootPart")
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

	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	local humanoid = character:WaitForChild("Humanoid")

	humanoid.PlatformStand = not vfly
	flying = true

	if vfly then
		local function fixCamera()
			local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
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

		local direction = (camCFrame.RightVector * moveVector.X)
			+ (camCFrame.LookVector * -moveVector.Z)
			+ (Vector3.new(0, 1, 0) * moveVector.Y)

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

	local character = LocalPlayer.Character
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
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

func.feat.enableAntiVoid = function()
	local function initVoidChar(char)
		local hum = char:WaitForChild("Humanoid")
		local root = char:WaitForChild("HumanoidRootPart")

		NnBind.reconnect("antivoid_health", hum.HealthChanged:Connect(function()
			if root.Position.Y <= fpdh + 20 then
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

	local char = LocalPlayer.Character or CharacterAdded:Wait()
	local root = char:WaitForChild("HumanoidRootPart")

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

			local currentChar = LocalPlayer.Character
			if currentChar then
				local currentRoot = currentChar:FindFirstChild("HumanoidRootPart")
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
				if string.sub(p.Name:lower(), 1, len) == lname
					or string.sub(p.DisplayName:lower(), 1, len) == lname then
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

	local Character = LocalPlayer.Character
	local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
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
		until BasePart.Velocity:Dot(BasePart.Velocity) > 250000
			or BasePart.Parent ~= playerToFling.Character
			or playerToFling.Parent == nil
			or THumanoid.Sit
			or Humanoid.Health <= 0
			or tick() > Time + 2
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

local cmdListFrame = nil
local cmdListScroll = nil
local cmdListSearch = nil
local cmdListItems = {}

local populateCmdList

func.build.cmdList = function()
	if cmdListFrame then return end
	local built = UI.buildCmdListGui()
	cmdListFrame = built.frame
	cmdListSearch = built.search
	cmdListScroll = built.scroll
	cmdListSearch:GetPropertyChangedSignal("Text"):Connect(function()
		populateCmdList(string.lower(cmdListSearch.Text))
	end)
end

populateCmdList = function(filter)
	local i = 1
	for _, entry in ipairs(cmdDisplayRows) do
		local show = filter == nil or filter == "" or string.find(entry.lower, filter, 1, true)
		if show then
			local item = cmdListItems[i]
			if not item then
				item = UI.buildCmdListRow(cmdListScroll)
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
	cmdListSearch.Text = ""
	populateCmdList(nil)
	cmdListFrame.Size = UDim2.new(0, 0, 0, 0)
	cmdListFrame.Visible = true
	TweenService:Create(cmdListFrame, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 300, 0, 380)}):Play()
end

-- keybind system
local keybinds = {}

local kbActiveStates = {}

func.persist.saveKeybinds = function()
	if not writefile then return end
	if isfolder and makefolder and not isfolder("Noname") then makefolder("Noname") end
	writefile("Noname/keybind.json", HttpService:JSONEncode(keybinds))
end

func.persist.loadKeybinds = function()
	if not readfile or not isfile or not isfile("Noname/keybind.json") then return end
	local raw = readfile("Noname/keybind.json")
	local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
	if ok and type(decoded) == "table" then keybinds = decoded end
end

func.init.keybindListener = function()
	NnBind.reconnect("keybind_input", UserInputService.InputBegan:Connect(function(input, gp)
		if gp or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		local keyName = input.KeyCode.Name:lower()
		for _, kb in ipairs(keybinds) do
			if kb.key and type(kb.key) == "string"
				and kb.command and type(kb.command) == "string"
				and kb.key:lower() == keyName then
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
	if not writefile then return end
	if isfolder and makefolder and not isfolder("Noname") then makefolder("Noname") end
	writefile("Noname/button.json", HttpService:JSONEncode(buttons))
end

func.persist.loadButtons = function()
	if not readfile or not isfile or not isfile("Noname/button.json") then return end
	local raw = readfile("Noname/button.json")
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
	if not writefile then return end
	if isfolder and makefolder and not isfolder("Noname") then makefolder("Noname") end
	local c = espOpts.color
	writefile("Noname/Noname_Settings.json", HttpService:JSONEncode({
		esp_color = { r = math.floor(c.R * 255), g = math.floor(c.G * 255), b = math.floor(c.B * 255) },
		esp_distance = espOpts.distance,
		esp_health = espOpts.health,
		esp_chamsonly = espOpts.chamsonly,
		esp_colorByTeam = espOpts.colorByTeam,
		esp_useCustomColor = espOpts.useCustomColor,
		cmd_prefix = cmdPrefix,
		ui_scale = uiScaleValue,
	}))
end

func.persist.loadSettings = function()
	if not readfile or not isfile or not isfile("Noname/Noname_Settings.json") then return end
	local raw = readfile("Noname/Noname_Settings.json")
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
	if type(decoded.cmd_prefix) == "string" and decoded.cmd_prefix ~= "" then cmdPrefix = decoded.cmd_prefix end
	if type(decoded.ui_scale) == "number" then uiScaleValue = decoded.ui_scale end
end

func.build.managerGui = UI.buildManagerGui

local kbGuiOpen = {v = false}
local kbMainFrame = nil
local kbManager = nil

func.build.keybindGui = function()
	local capturing = false
	kbManager = func.build.managerGui({
		sgName = "keybindpanel",
		bz = 100,
		title = "KEYBIND MANAGER",
		icon = "⌨",
		accentColor = Color3.fromRGB(255, 255, 255),
		guiOpenRef = kbGuiOpen,
		mainFrameSetter = function(f) kbMainFrame = f end,
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
				if not writefile then return end
				writefile("Noname/keybind.json", HttpService:JSONEncode(keybinds))
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
	if not kbMainFrame then func.build.keybindGui() end
	kbManager.toggle()
end

local btnGuiOpen = {v = false}
local btnMainFrame = nil
local btnManager = nil

func.build.commandButtonGui = function()
	btnManager = func.build.managerGui({
		sgName = "NNButtonPanel",
		bz = 102,
		title = "BUTTON MANAGER",
		icon = "⊞",
		accentColor = Color3.fromRGB(255, 255, 255),
		guiOpenRef = btnGuiOpen,
		mainFrameSetter = function(f) btnMainFrame = f end,
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
	if not btnMainFrame then func.build.commandButtonGui() end
	btnManager.toggle()
end

local espObjects = {}

local espFolder = NewInstance("Folder")
espFolder.Parent = workspace

func.esp.clearAll = function()
	espActive = false
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

	local lc = LocalPlayer.Character
	local lr = lc and lc:FindFirstChild("HumanoidRootPart")
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
		local adornPart = char:FindFirstChild("Head")
		             or char:FindFirstChild("HumanoidRootPart")
		if adornPart then
			local lineCount = 1
				+ (opts.health and 1 or 0)
				+ (opts.distance and 1 or 0)

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
			local lc = LocalPlayer.Character
			local lr = lc and lc:FindFirstChild("HumanoidRootPart")
			local tr = char:FindFirstChild("HumanoidRootPart")
			if not (lr and tr) then return end
			local delta = lr.Position - tr.Position
			local distSq = delta:Dot(delta)
			if opts.distance and lbl then
				cachedDist = string.format("%.0f", math.sqrt(distSq))
				rebuildLabel()
			end
			if not espOpts.useCustomColor and not espOpts.colorByTeam then
				local newColor = distSq > 10000 and Color3.fromRGB(0, 255, 0)
					or distSq >= 2500 and Color3.fromRGB(255, 165, 0)
					or Color3.fromRGB(255, 0, 0)
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
	espActive = true

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
end

func.feat.enableInstantPP = function()
	local function apply(v)
		if v:IsA("ProximityPrompt") then
			v.HoldDuration = 0
		end
	end
	for _, v in ipairs(workspace:GetDescendants()) do apply(v) end
	NnBind.reconnect("ipp_added", workspace.DescendantAdded:Connect(apply))
end

func.feat.unwatch = function()
	NnBind.disconnect("watch_removing")
	NnBind.disconnect("watch_character")

	if not LocalPlayer.Character then
		notify("lucide:triangle-alert", 4, "Watch", "LocalPlayer character not found. Waiting for character...")
	end

	local character = LocalPlayer.Character or CharacterAdded:Wait()
	Camera.CameraSubject = character:FindFirstChildOfClass("Humanoid")
end

func.feat.watch = function(player)
	local function updateCamera(character)
		Camera.CameraSubject = character:WaitForChild("Humanoid")
	end

	if player.Character then
		updateCamera(player.Character)
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
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
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

local function safehook(object, metamethod, hook, useCheckcaller)
	local original
	local function proxy(...)
		if useCheckcaller and hookapi.checkcaller and hookapi.checkcaller() then
			return original(...)
		end
		return hook(...)
	end
	local wrappedHook = hookapi.newcclosure and hookapi.newcclosure(proxy) or proxy
	if hookapi.setstackhidden then
		hookapi.setstackhidden(wrappedHook, true)
	end

	if hookapi.hookmetamethod then
		original = hookapi.hookmetamethod(object, metamethod, wrappedHook)
		return original
	end

	if not hookapi.getrawmetatable then
		notify("lucide:triangle-alert", 4, "safehook", "Executor does not support metamethod hooking.")
		return nil
	end
	local mt = hookapi.getrawmetatable(object)
	if not mt then
		notify("lucide:triangle-alert", 4, "safehook", "Executor does not support metamethod hooking.")
		return nil
	end

	if hookapi.hookfunction then
		original = hookapi.hookfunction(mt[metamethod], wrappedHook)
		return original
	end

	original = mt[metamethod]
	if hookapi.setreadonly then
		hookapi.setreadonly(mt, false)
	end
	mt[metamethod] = wrappedHook
	if hookapi.setreadonly then
		hookapi.setreadonly(mt, true)
	end
	return original
end

local function safeunhook(object, metamethod, original)
	if not original then return false end

	if hookapi.hookmetamethod then
		hookapi.hookmetamethod(object, metamethod, original)
		return true
	end

	if not hookapi.getrawmetatable then return false end
	local mt = hookapi.getrawmetatable(object)
	if not mt then return false end

	if hookapi.hookfunction then
		hookapi.hookfunction(mt[metamethod], original)
		return true
	end

	if hookapi.setreadonly then
		hookapi.setreadonly(mt, false)
	end
	mt[metamethod] = original
	if hookapi.setreadonly then
		hookapi.setreadonly(mt, true)
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

func.feat.godmode = function(mode)
	godmode.mode = (mode == "hook") and "hook" or "nohook"

	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
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
				godmode.humanoid = h

				if not godmode.origNI or not godmode.origNC then
					godmode.origNI = safehook(game, "__newindex", function(self, key, value)
						if godmode.mode == "hook" and godmode.humanoid and self == godmode.humanoid then
							if key == "Health" and type(value) == "number" and value <= 0 then return end
							if key == "MaxHealth" and type(value) == "number" and value < godmode.humanoid.MaxHealth then return end
							if key == "BreakJointsOnDeath" and value == true then return end
							if key == "Parent" and value == nil then return end
						end
						return godmode.origNI(self, key, value)
					end, true)

					godmode.origNC = safehook(game, "__namecall", function(self, ...)
						if godmode.mode == "hook" then
							local method = getnamecallmethod()
							if godmode.humanoid and self == godmode.humanoid then
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
							local char = LocalPlayer.Character
							if char and self == char and method == "BreakJoints" then return end
						end
						return godmode.origNC(self, ...)
					end, true)

					if not godmode.origNI or not godmode.origNC then
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

	applyGodmode(godmode.mode, hum)

	NnBind.reconnect("gm_charAdded", CharacterAdded:Connect(function(newChar)
		task.wait(0.1)
		local newHum = newChar:FindFirstChildOfClass("Humanoid")
		if newHum then applyGodmode(godmode.mode, newHum) end
	end))
end

do
	local nvfParts = {}
	local nvfHooksActive = false

	func.feat.antinvisfling = function(AntiInvis, AntiFling)
		local wasActive = nvfHooksActive
		nfvIsOn.antiInvis = AntiInvis
		nfvIsOn.antiFling = AntiFling

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
				if nfvIsOn.antiInvis and part.Name ~= "HumanoidRootPart" then
					part.Transparency = 0
					NnBind.reconnect("antiinvis_" .. part:GetDebugId(), part:GetPropertyChangedSignal("Transparency"):Connect(function()
						if nfvIsOn.antiInvis and part.Transparency ~= 0 then part.Transparency = 0 end
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

			if nfvIsOn.antiFling then
				part.CanCollide = false
			end

			if nfvIsOn.antiInvis and part.Name ~= "HumanoidRootPart" then
				part.Transparency = 0
				NnBind.reconnect("antiinvis_" .. part:GetDebugId(), part:GetPropertyChangedSignal("Transparency"):Connect(function()
					if nfvIsOn.antiInvis and part.Transparency ~= 0 then part.Transparency = 0 end
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
				local char = LocalPlayer.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
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
		local char = LocalPlayer.Character
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = speed
			end
		end
	end
})

Cmd.add({"loopwalkspeed", "loopws", "lws"}, {
	args = "speed",
	fn = function(speed)
		func.feat.loopwalkspeed(tonumber(speed))
	end,
})

Cmd.add({"unloopwalkspeed", "unloopws", "unlws"}, {
	fn = function()
		NnBind.disconnect("ws_changed")
		NnBind.disconnect("ws_charAdded")
	end,
})

Cmd.add({"tpwalkspeed", "tpwalk"}, {
	args = "speed",
	fn = function(speed)
		speed = tonumber(speed) or 1
		local stepRate = 1 / 60
		local maxSteps = 3
		local accumulator = 0
		NnBind.reconnect("tpwalk", RunService.Heartbeat:Connect(function(deltaTime)
			accumulator = math.min(accumulator + (tonumber(deltaTime) or 0), stepRate * maxSteps)
			local char = LocalPlayer.Character
			local humanoid = char and char:FindFirstChildOfClass("Humanoid")
			if not humanoid or not char or humanoid.MoveDirection.Magnitude <= 0 then return end
			local steps = 0
			while accumulator >= stepRate and steps < maxSteps do
				char:TranslateBy(humanoid.MoveDirection * speed * stepRate * 10)
				accumulator -= stepRate
				steps += 1
			end
		end))
	end,
})

Cmd.add({"untpwalkspeed", "untpwalk"}, {
	fn = function()
		NnBind.disconnect("tpwalk")
	end,
})

Cmd.add({"jumppower", "jp"}, {
	args = "power",
	fn = function(power)
		power = tonumber(power)
		if not power then return end
		local char = LocalPlayer.Character
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.JumpPower = power
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
			char = char or LocalPlayer.Character
			local hum = char and char:WaitForChild("Humanoid")
			if not hum then return end
			hum.JumpPower = power
			NnBind.reconnect("jp_changed", hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
				if hum.JumpPower ~= power then hum.JumpPower = power end
			end))
		end
		apply()
		NnBind.reconnect("jp_charAdded", CharacterAdded:Connect(apply))
	end,
})

Cmd.add({"unloopjumppower", "unloopjp"}, {
	fn = function()
		NnBind.disconnect("jp_changed")
		NnBind.disconnect("jp_charAdded")
	end,
})

Cmd.add({"resetchar", "respawn", "reset"}, {
	fn = function()
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then
			notify("lucide:triangle-alert", 4, "Reset", "No character found.")
			return
		end
		hum.Health = 0
		hum:Destroy()
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
			local char = LocalPlayer.Character
			targetHRP = char and char:FindFirstChild("HumanoidRootPart")
			if not targetHRP then
				notify("lucide:triangle-alert", 4, "CopyPos", "Your character was not found.")
				return
			end
		end

		local pos = targetHRP.Position
		local str = string.format("%.3f, %.3f, %.3f", pos.X, pos.Y, pos.Z)

		if clipboard then
			clipboard(str)
		else
			print("Position: " .. str)
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
	fn = func.feat.unfly,
})

Cmd.add({"freeze"}, {
	fn = function()
		local character = LocalPlayer.Character
		if not character then return end
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end
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
	local character = LocalPlayer.Character
	if not character then return end
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
end
DC.stopFreeze = function()
	local character = LocalPlayer.Character
	if not character then return end
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end
end

Cmd.add({"unfreeze"}, {
	fn = function()
		local character = LocalPlayer.Character
		if not character then return end
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
			end
		end
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

		local char = LocalPlayer.Character
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.Transparency == 0.5 then
					part.Transparency = 0
				end
			end
		end
	end,
})

Cmd.add({"antiinvisible", "antiinvis", "avis"}, {
	fn = function() func.feat.antinvisfling(true, nfvIsOn.antiFling) end,
})

Cmd.add({"unantiinvisible", "unantiinvis", "unavis"}, {
	fn = function() func.feat.antinvisfling(false, nfvIsOn.antiFling) end,
})

Cmd.add({"antifling"}, {
	fn = function() func.feat.antinvisfling(nfvIsOn.antiInvis, true) end,
})

Cmd.add({"unantifling"}, {
	fn = function() func.feat.antinvisfling(nfvIsOn.antiInvis, false) end,
})

Cmd.add({"GameId"}, {
	fn = function()
		local id = tostring(game.GameId)
		if clipboard then
			clipboard(id)
		else
			print("Universe ID: " .. id)
		end
	end,
})

Cmd.add({"PlaceId"}, {
	fn = function()
		local id = tostring(game.PlaceId)
		if clipboard then
			clipboard(id)
		else
			print("Place ID: " .. id)
		end
	end,
})

Cmd.add({"jobid"}, {
	fn = function()
		local id = tostring(game.JobId)
		if clipboard then
			clipboard(id)
		else
			print("Job ID: " .. id)
		end
	end,
})

Cmd.add({"joinplaceid"}, {
	args = "placeid",
	fn = function(placeId)
		placeId = tonumber(placeId)
		if not placeId then return end
		TeleportService:Teleport(placeId, LocalPlayer)
	end,
})

Cmd.add({"joinjobid"}, {
	args = "jobid",
	fn = function(jobId)
		if not jobId then return end
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
		workspace.FallenPartsDestroyHeight = fpdh
	end,
})

Cmd.add({"fixcam", "fixcamera"}, {
	fn = function()
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		Camera.CameraType = Enum.CameraType.Custom
		Camera.CameraSubject = hum or char
		LocalPlayer.CameraMode = Enum.CameraMode.Classic
		LocalPlayer.CameraMinZoomDistance = 0.5
		LocalPlayer.CameraMaxZoomDistance = 1e7
	end,
})

Cmd.add({"minzoom"}, {
	args = "value",
	fn = function(value)
		value = tonumber(value)
		if not value then return end
		LocalPlayer.CameraMinZoomDistance = value
	end,
})

Cmd.add({"maxzoom"}, {
	args = "value",
	fn = function(value)
		value = tonumber(value)
		if not value then return end
		LocalPlayer.CameraMaxZoomDistance = value
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
	end,
})

Cmd.add({"unloopminzoom"}, {
	fn = function()
		NnBind.disconnect("loopminzoom")
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
	end,
})

Cmd.add({"unloopmaxzoom"}, {
	fn = function()
		NnBind.disconnect("loopmaxzoom")
	end,
})

Cmd.add({"selfkick", "sk"}, {
	fn = function()
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
		else
			notify("lucide:user-x", 4, "ESP", "Player not found.")
		end
	end,
})

Cmd.add({"espall", "allesp", "espallplayers"}, {
	fn = func.feat.enableESPAll,
})

Cmd.add({"unesp"}, {
	fn = func.esp.clearAll,
})

Cmd.add({"instantproximityprompt", "instantpp", "ipp"}, {
	fn = func.feat.enableInstantPP,
})

Cmd.add({"uninstantproximityprompt", "uninstantpp", "unipp"}, {
	fn = function()
		NnBind.disconnect("ipp_added")
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
				if p ~= LocalPlayer then targets[#targets + 1] = p end
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

		if LocalPlayer.Character then
			cacheParts(LocalPlayer.Character)
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
	end,
})

Cmd.add({"unwalkfling", "unwf"}, {
	fn = function()
		NnBind.disconnect("walkfling_heartbeat")
		NnBind.disconnect("walkfling_charAdded")
	end,
})

Cmd.add({"unwalkfling", "unwf"}, {
	fn = function()
		NnBind.disconnect("walkfling_heartbeat")
		NnBind.disconnect("walkfling_charAdded")
	end,
})

Cmd.add({"unwalkfling", "unwf"}, {
	fn = function()
		NnBind.disconnect("walkfling_heartbeat")
	end,
})

Cmd.add({"Reach"}, {
	args = "Size",
	fn = function(size)
		size = tonumber(size) or 12
		local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
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
	end,
})

Cmd.add({"Unreach"}, {
	fn = function()
		local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
			or LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
		if not tool or not tool:FindFirstChild("Handle") then return end
		local handle = tool.Handle
		if tool:FindFirstChild("OGSize3") then
			handle.Size = tool.OGSize3.Value
		end
		if handle:FindFirstChild("FunTIMES") then
			handle.FunTIMES:Destroy()
		end
		handle.Massless = false
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
	end,
})

Cmd.add({"teleport", "tp", "goto"}, {
	args = "playername / x,y,z",
	fn = function(...)
		local args = {...}
		if #args == 0 then return end

		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
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
		end
	end,
})

Cmd.add({"infinitejump", "infjump"}, {
	fn = function()
		local lastJump = 0
		NnBind.reconnect("ij_jumped", UserInputService.JumpRequest:Connect(function()
			local char = LocalPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if not hum then
				notify("lucide:triangle-alert", 3, "Infinite Jump", "No character found.")
				return
			end
			local now = tick()
			if now - lastJump < 0.05 then return end
			lastJump = now
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end))
	end,
})

Cmd.add({"uninfinitejump", "uninfjump"}, {
	fn = function()
		NnBind.disconnect("ij_jumped")
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
			return HttpService:JSONDecode(
				game:HttpGet(
					"https://games.roblox.com/v1/games/"
					.. game.PlaceId
					.. "/servers/Public?sortOrder=Asc&limit=100"
				)
			)
		end)
		if not ok or not res or not res.data then
			notify("lucide:triangle-alert", 4, "Serverhop", "Failed to fetch server list.")
			return
		end
		for _, server in ipairs(res.data) do
			if server.id ~= game.JobId and server.playing < server.maxPlayers then
				TeleportService:TeleportToPlaceInstance(
					game.PlaceId, server.id, LocalPlayer
				)
				return
			end
		end
		notify("lucide:triangle-alert", 4, "Serverhop", "No available server found.")
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
			if msg:sub(1, 1) ~= cmdPrefix then return end
			runCommand(msg:sub(2))
		end))
	end,
})

Cmd.add({"unadmin"}, {
	fn = function()
		NnBind.disconnect("admin_chat")
	end,
})

do
	local old
	Cmd.add({"antikick"}, {
		fn = function()
			if old then return end
			old = safehook(game, "__namecall", function(self, ...)
				if getnamecallmethod() == "Kick" and self == LocalPlayer then
					task.wait(9e9)
				end
				return old(self, ...)
			end, true)
		end,
	})
	Cmd.add({"unantikick"}, {
		fn = function()
			if not old then return end
			safeunhook(game, "__namecall", old)
			old = nil
		end,
	})
end

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

		godmode.mode = nil

		if godmode.origNI then
			safeunhook(game, "__newindex", godmode.origNI)
			godmode.origNI = nil
		end
		if godmode.origNC then
			safeunhook(game, "__namecall", godmode.origNC)
			godmode.origNC = nil
		end
		godmode.humanoid = nil

		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
			hum.BreakJointsOnDeath = true
		end
	end,
})

Cmd.add({"tptool", "clicktp"}, {
    fn = function()
        local mouse = LocalPlayer:GetMouse()
        local tool = NewInstance("Tool")
        tool.ToolTip = "Click/Tap to teleport"
        tool.RequiresHandle = false
        tool.Activated:Connect(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = mouse.Hit end
        end)
        tool.Parent = LocalPlayer.Backpack
    end,
})

Cmd.add({"untptool", "unclicktp"}, {
    fn = function()
        local tool = LocalPlayer.Backpack:FindFirstChild("tptool")
            or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("tptool"))
        if tool then tool:Destroy() end
    end,
})

Cmd.add({"spin"}, {
	args = "speed",
	fn = function(speed)
		speed = tonumber(speed) or 3
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum.AutoRotate = false end

		local function applySpin(newHrp)
			local existing = newHrp:FindFirstChild("NnSpinBAV")
			if existing then existing:Destroy() end
			local bav = NewInstance("BodyAngularVelocity")
			bav.MaxTorque = Vector3.new(0, math.huge, 0)
			bav.AngularVelocity = Vector3.new(0, math.rad(360) * speed, 0)
			bav.Parent = newHrp
		end

		applySpin(hrp)

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
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local bav = hrp:FindFirstChild("NnSpinBAV")
			if bav then bav:Destroy() end
		end
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum.AutoRotate = true end
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

			if aimlockGui then
				aimlockGui:Destroy()
				aimlockGui = nil
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

			NnBind.reconnect("aimlock_camtype", Camera:GetPropertyChangedSignal("CameraType"):Connect(function()
				local ct = Camera.CameraType
				if ct ~= Enum.CameraType.Scriptable and ct ~= Enum.CameraType.Track then
					Camera.CameraType = Enum.CameraType.Track
				end
			end))

			local guiParent = pcall(gethui) and gethui()
				or pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")
				or LocalPlayer:WaitForChild("PlayerGui")

			aimlockGui = NewInstance("ScreenGui")
			aimlockGui.ResetOnSpawn = false
			aimlockGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			aimlockGui.IgnoreGuiInset = true
			aimlockGui.Parent = guiParent

			local circle = NewInstance("Frame")
			circle.BackgroundTransparency = 1
			circle.BorderSizePixel = 0
			circle.Size = UDim2.fromOffset(fovRadius * 2, fovRadius * 2)
			circle.AnchorPoint = Vector2.new(0.5, 0.5)
			circle.Position = UDim2.fromScale(0.5, 0.5)
			circle.Parent = aimlockGui

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
								local obscuring = Camera:GetPartsObscuringTarget(
									{aimPart.Position},
									{LocalPlayer.Character, char}
								)
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

						local hrp = char:FindFirstChild("HumanoidRootPart")
						if not hrp then continue end

						local aimPart = getAimPart(char)
						if not aimPart then continue end

						local screenPos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
						if not onScreen then continue end

						local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
						if screenDist > fovRadius then continue end

						local obscuring = Camera:GetPartsObscuringTarget(
							{aimPart.Position},
							{LocalPlayer.Character, char}
						)
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
						Camera.CFrame = CFrame.lookAt(
							Camera.CFrame.Position,
							predictPosition(aimPart)
						)
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
		if aimlockGui then
			aimlockGui:Destroy()
			aimlockGui = nil
		end
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
			if player.Character then
				local hrp = player.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					hitboxOriginals[player.Character] = hrp.Size
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
				hitboxOriginals[char] = hrp.Size
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
			if player.Character then
				local hrp = player.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					hitboxOriginals[player.Character] = hrp.Size
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
				hitboxOriginals[char] = hrp.Size
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
					if hitboxOriginals[player.Character] then
						hrp.Size = hitboxOriginals[player.Character]
					end
					hrp.Transparency = 1
					hrp.CanCollide = false
				end
			end
		end
		table.clear(hitboxOriginals)
	end,
})

Cmd.add({"cbring", "clientbring", "clientb"}, {
	args = "playername / all",
	fn = function(...)
		local myChar = LocalPlayer.Character
		local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
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
			local myChar = LocalPlayer.Character
			local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
			if not myHrp then return end

			for player in pairs(loopBringTargets) do
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					hrp.CFrame = myHrp.CFrame * CFrame.new(0, 0, -5)
				end
			end
		end))
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
	end,
})

func.init.commandCaches()

UI.onScaleChanged = function(scale)
	uiScaleValue = scale
	func.persist.saveSettings()
end

func.persist.loadSettings()
UI.setScale(uiScaleValue)

-- General Settings Tab
local _generalPage = UI.Settings.tab("General")
UI.Settings.input(_generalPage, "Command Prefix", "e.g. ;", cmdPrefix, function(val)
	if val ~= "" then
		cmdPrefix = val:sub(1, 1)
		func.persist.saveSettings()
	end
end)

-- ESP Settings Tab
local _espPage = UI.Settings.tab("ESP")
UI.Settings.color(_espPage, "Custom ESP Color", espOpts.color, function(c)
	espOpts.color = c
	func.persist.saveSettings()
	if espActive then
		func.esp.clearAll()
		func.feat.enableESPAll()
	end
end)
UI.Settings.toggle(_espPage, "Use Custom ESP Color", function(v)
	espOpts.useCustomColor = v
	func.persist.saveSettings()
	if espActive then
		func.esp.clearAll()
		func.feat.enableESPAll()
	end
end)
UI.Settings.toggle(_espPage, "ESP Color By Team", function(v)
	espOpts.colorByTeam = v
	func.persist.saveSettings()
	if espActive then
		func.esp.clearAll()
		func.feat.enableESPAll()
	end
end)
UI.Settings.toggle(_espPage, "Distance Label", function(v)
	espOpts.distance = v
	func.persist.saveSettings()
	if espActive then
		func.esp.clearAll()
		func.feat.enableESPAll()
	end
end)
UI.Settings.toggle(_espPage, "Health Label", function(v)
	espOpts.health = v
	func.persist.saveSettings()
	if espActive then
		func.esp.clearAll()
		func.feat.enableESPAll()
	end
end)
UI.Settings.toggle(_espPage, "Chams Only", function(v)
	espOpts.chamsonly = v
	func.persist.saveSettings()
	if espActive then
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
		Text = "Time take to load: " .. string.format("%.2f", os.clock() - _loadStart) .. "s",
		Duration = 4,
		Icon = "lucide:cpu",
	})
end
