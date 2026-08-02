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

local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local Players = cloneref(game:GetService("Players"))
local LocalPlayer = Players.LocalPlayer

local UI = {
	CommandBar = {},
	HUD = {},
	Capture = {},
	Settings = {},
	Picker = {},
	Autocorrect = {},
	AutoClicker = {},
	UiScaler = {},
}

UI._scaleTargets = {}
UI._excludeTargets = {}
UI._currentScale = 1

function UI.registerScaleTarget(guiRoot)
	local uiScale = NewInstance("UIScale")
	uiScale.Scale = UI._currentScale
	uiScale.Parent = guiRoot
	table.insert(UI._scaleTargets, uiScale)
	return uiScale
end

function UI.excludeFromScale(guiRoot)
	local counter = NewInstance("UIScale")
	counter.Scale = 1 / UI._currentScale
	counter.Parent = guiRoot
	table.insert(UI._excludeTargets, counter)
	return counter
end

function UI.getScale()
	return UI._currentScale
end

function UI.setScale(scale)
	scale = math.clamp(tonumber(scale) or 1, 0.5, 2.5)
	UI._currentScale = scale
	for _, uiScale in ipairs(UI._scaleTargets) do
		if uiScale and uiScale.Parent then
			uiScale.Scale = scale
		end
	end
	for _, counter in ipairs(UI._excludeTargets) do
		if counter and counter.Parent then
			counter.Scale = 1 / scale
		end
	end
	if UI.UiScaler.setSliderValue then
		UI.UiScaler.setSliderValue(scale)
	end
	if UI.onScaleChanged then
		UI.onScaleChanged(scale)
	end
	return scale
end
local function getGuiParent()
	local ok, res = pcall(function()
		return if type(gethui) == "function" then gethui() else cloneref(game:GetService("CoreGui"))
	end)
	if ok and res then
		return res
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function makeDraggable(frame, handle)
	handle = handle or frame

	local dragInput = nil
	local dragStart = nil
	local startPos = nil

	handle.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragInput = input
			dragStart = input.Position
			startPos = frame.Position
		end
	end)

	handle.InputChanged:Connect(function(input)
		if dragInput and input == dragInput then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input == dragInput then
			dragInput = nil
		end
	end)
end

local function makeResizeable(frame, handle, minSize, maxSize)
	handle = handle or frame
	minSize = minSize or Vector2.new(150, 100)
	maxSize = maxSize or Vector2.new(1000, 800)

	local resizeInput = nil
	local resizeStart = nil
	local startSize = nil

	handle.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			resizeInput = input
			resizeStart = input.Position
			startSize = frame.Size
		end
	end)

	handle.InputChanged:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			resizeInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if resizeInput and input == resizeInput then
			local delta = input.Position - resizeStart
			local newX = math.clamp(startSize.X.Offset + delta.X, minSize.X, maxSize.X)
			local newY = math.clamp(startSize.Y.Offset + delta.Y, minSize.Y, maxSize.Y)
			frame.Size = UDim2.new(startSize.X.Scale, newX, startSize.Y.Scale, newY)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input == resizeInput then
			resizeInput = nil
			resizeStart = nil
			startSize = nil
		end
	end)
end
local screenGui = NewInstance("ScreenGui", getGuiParent())
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
UI.screenGui = screenGui
UI.registerScaleTarget(screenGui)

local cmdFrame = NewInstance("Frame", screenGui)
cmdFrame.Size = UDim2.new(0, 0, 0, 48)
cmdFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
cmdFrame.AnchorPoint = Vector2.new(0.5, 0.5)
cmdFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
cmdFrame.ClipsDescendants = true
cmdFrame.Visible = false
NewInstance("UICorner", cmdFrame).CornerRadius = UDim.new(0, 24)
UI.CommandBar.frame = cmdFrame

UI.CommandBar.stroke = NewInstance("UIStroke", cmdFrame)
UI.CommandBar.stroke.Color = Color3.fromRGB(45, 45, 45)
UI.CommandBar.stroke.Thickness = 1.5

UI.CommandBar.icon = NewInstance("TextLabel", cmdFrame)
UI.CommandBar.icon.Size = UDim2.new(0, 36, 1, 0)
UI.CommandBar.icon.Position = UDim2.new(0, 8, 0, 0)
UI.CommandBar.icon.BackgroundTransparency = 1
UI.CommandBar.icon.Text = "⌘"
UI.CommandBar.icon.TextColor3 = Color3.fromRGB(160, 160, 160)
UI.CommandBar.icon.Font = Enum.Font.GothamBold
UI.CommandBar.icon.TextSize = 18

local inputBox = NewInstance("TextBox", cmdFrame)
inputBox.Size = UDim2.new(1, -50, 1, 0)
inputBox.Position = UDim2.new(0, 40, 0, 0)
inputBox.BackgroundTransparency = 1
inputBox.Text = ""
inputBox.TextColor3 = Color3.fromRGB(220, 220, 220)
inputBox.PlaceholderText = "Type a command..."
inputBox.PlaceholderColor3 = Color3.fromRGB(90, 90, 90)
inputBox.Font = Enum.Font.GothamSemibold
inputBox.TextSize = 15
inputBox.TextXAlignment = Enum.TextXAlignment.Left
UI.CommandBar.inputBox = inputBox

local suggFrame = NewInstance("Frame", screenGui)
suggFrame.Size = UDim2.new(0, 400, 0, 0)
suggFrame.Position = UDim2.new(0.5, 0, 0.5, -32)
suggFrame.AnchorPoint = Vector2.new(0.5, 1)
suggFrame.BackgroundTransparency = 1
suggFrame.Visible = false
UI.CommandBar.suggFrame = suggFrame

local suggLayout = NewInstance("UIListLayout", suggFrame)
suggLayout.Padding = UDim.new(0, 10)
suggLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local suggItems = {}
for i = 1, 6 do
	local item = NewInstance("TextButton", suggFrame)
	item.Size = UDim2.new(0, 165, 0, 30)
	item.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
	item.BackgroundTransparency = 0
	item.TextColor3 = Color3.fromRGB(255, 255, 255)
	item.Font = Enum.Font.GothamBold
	item.TextSize = 12
	item.TextXAlignment = Enum.TextXAlignment.Center
	item.AutoButtonColor = false
	item.Text = ""
	item.Visible = false
	item.LayoutOrder = i
	NewInstance("UICorner", item).CornerRadius = UDim.new(0, 7)

	local itemStroke = NewInstance("UIStroke", item)
	itemStroke.Color = Color3.fromRGB(45, 45, 45)
	itemStroke.Thickness = 1
	itemStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	suggItems[i] = item
end
UI.CommandBar.suggItems = suggItems

local hudSg = NewInstance("ScreenGui", getGuiParent())
hudSg.ResetOnSpawn = false
hudSg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
hudSg.Enabled = false
UI.HUD.sg = hudSg
UI.registerScaleTarget(hudSg)

function UI.buildValueRow(frame, speed, placeholder, tw, onValueChanged)
	local speedLabel = NewInstance("TextLabel", frame)
	speedLabel.Size = UDim2.new(0, 36, 0, 44)
	speedLabel.Position = UDim2.new(1, -60, 0, 0)
	speedLabel.BackgroundTransparency = 1
	speedLabel.Text = tostring(speed)
	speedLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
	speedLabel.Font = Enum.Font.GothamBold
	speedLabel.TextSize = 11
	speedLabel.TextXAlignment = Enum.TextXAlignment.Center
	speedLabel.TextYAlignment = Enum.TextYAlignment.Center
	local toggleBtn = NewInstance("TextButton", frame)
	toggleBtn.Size = UDim2.new(0, 22, 0, 22)
	toggleBtn.Position = UDim2.new(1, -26, 0, 11)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	toggleBtn.BorderSizePixel = 0
	toggleBtn.Text = "+"
	toggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.TextSize = 13
	toggleBtn.ZIndex = 5
	NewInstance("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)
	local inputRow = NewInstance("Frame", frame)
	inputRow.Size = UDim2.new(1, -16, 0, 38)
	inputRow.Position = UDim2.new(0, 8, 0, 50)
	inputRow.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
	inputRow.BorderSizePixel = 0
	inputRow.Visible = false
	NewInstance("UICorner", inputRow).CornerRadius = UDim.new(0, 8)
	NewInstance("UIStroke", inputRow).Color = Color3.fromRGB(60, 60, 80)
	local inputBox2 = NewInstance("TextBox", inputRow)
	inputBox2.Size = UDim2.new(1, -16, 1, -8)
	inputBox2.Position = UDim2.new(0, 8, 0, 4)
	inputBox2.BackgroundTransparency = 1
	inputBox2.Text = tostring(speed)
	inputBox2.TextColor3 = Color3.fromRGB(230, 230, 230)
	inputBox2.Font = Enum.Font.GothamBold
	inputBox2.TextSize = 15
	inputBox2.TextXAlignment = Enum.TextXAlignment.Center
	inputBox2.PlaceholderText = placeholder
	local expanded = false
	local function setExpanded(state)
		expanded = state
		toggleBtn.Text = state and "-" or "+"
		if state then
			TweenService:Create(frame, tw, {Size = UDim2.new(0, 130, 0, 98)}):Play()
			task.delay(0.15, function() inputRow.Visible = true end)
		else
			inputRow.Visible = false
			TweenService:Create(frame, tw, {Size = UDim2.new(0, 130, 0, 44)}):Play()
		end
	end
	inputBox2.FocusLost:Connect(function()
		local n = tonumber(inputBox2.Text)
		local v = n or inputBox2.Text
		speedLabel.Text = tostring(v)
		inputBox2.Text = tostring(v)
		onValueChanged(v)
	end)
	return toggleBtn, speedLabel, inputBox2, setExpanded, function() return expanded end
end
local buildValueRow = UI.buildValueRow

function UI.HUD.makeButton(label, startFn, yOff, placeholder, defaultSpd)
	local hasValue = placeholder ~= nil and defaultSpd ~= nil
	local speed = defaultSpd
	local tw = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
	local frame, stroke, nameLabel
	local built = false
	local setExpanded, getExpanded
	local function build()
		if built then return end
		built = true
		frame = NewInstance("Frame", hudSg)
		frame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
		frame.BorderSizePixel = 0
		frame.Active = true
		frame.Visible = false
		NewInstance("UICorner", frame).CornerRadius = UDim.new(0, 12)
		stroke = NewInstance("UIStroke", frame)
		stroke.Color = Color3.fromRGB(100, 100, 100)
		stroke.Thickness = 2
		nameLabel = NewInstance("TextLabel", frame)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = label
		nameLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 16
		if hasValue then
			frame.Size = UDim2.new(0, 130, 0, 44)
			frame.Position = UDim2.new(1, -146, 0, 20 + yOff)
			frame.ClipsDescendants = true
			nameLabel.Size = UDim2.new(1, -64, 0, 44)
			nameLabel.Position = UDim2.new(0, 10, 0, 0)
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.TextYAlignment = Enum.TextYAlignment.Center
			local toggleBtn, _, _, sExp, gExp = buildValueRow(frame, speed, placeholder, tw, function(v)
				speed = v
			end)
			setExpanded = sExp
			getExpanded = gExp
			local _th = false
			toggleBtn.Activated:Connect(function()
				_th = true
				setExpanded(not getExpanded())
			end)
			local clickArea = NewInstance("TextButton", frame)
			clickArea.Size = UDim2.new(1, -36, 0, 44)
			clickArea.BackgroundTransparency = 1
			clickArea.Text = ""
			clickArea.ZIndex = 2
			makeDraggable(frame, clickArea)
			clickArea.Activated:Connect(function()
				if _th then _th = false return end
				startFn(speed)
			end)
		else
			frame.Size = UDim2.new(0, 100, 0, 40)
			frame.Position = UDim2.new(1, -120, 0, 20 + yOff)
			nameLabel.Size = UDim2.new(1, 0, 1, 0)
			nameLabel.TextXAlignment = Enum.TextXAlignment.Center
			local clickArea = NewInstance("TextButton", frame)
			clickArea.Size = UDim2.new(1, -8, 1, -8)
			clickArea.Position = UDim2.new(0, 4, 0, 4)
			clickArea.BackgroundTransparency = 1
			clickArea.Text = ""
			clickArea.ZIndex = 2
			makeDraggable(frame, clickArea)
			clickArea.Activated:Connect(function()
				startFn()
			end)
		end
	end
	return {
		show = function() build(); frame.Visible = true end,
		hide = function()
			if not built then return end
			if hasValue and getExpanded() then setExpanded(false) end
			frame.Visible = false
		end,
		showOff = function() build(); frame.Visible = true end,
		destroy = function()
			if frame then frame:Destroy(); frame = nil end
			built = false
		end,
	}
end

function UI.HUD.makeToggle(startFn, stopFn, yOff, placeholder, defaultSpd, labelOn, labelOff)
	local hasValue = placeholder ~= nil and defaultSpd ~= nil
	local active = false
	local speed = defaultSpd
	local tw = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
	local frame, stroke, nameLabel, speedLabelRef, inputBoxRef
	local built = false
	local setExpanded, getExpanded
	local function build()
		if built then return end
		built = true
		frame = NewInstance("Frame", hudSg)
		frame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
		frame.BorderSizePixel = 0
		frame.Active = true
		frame.Visible = false
		NewInstance("UICorner", frame).CornerRadius = UDim.new(0, 12)
		stroke = NewInstance("UIStroke", frame)
		stroke.Color = Color3.fromRGB(80, 220, 120)
		stroke.Thickness = 2
		nameLabel = NewInstance("TextLabel", frame)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = labelOn
		nameLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 16
		if hasValue then
			frame.Size = UDim2.new(0, 130, 0, 44)
			frame.Position = UDim2.new(1, -146, 0, 20 + yOff)
			frame.ClipsDescendants = true
			nameLabel.Size = UDim2.new(1, -64, 0, 44)
			nameLabel.Position = UDim2.new(0, 10, 0, 0)
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.TextYAlignment = Enum.TextYAlignment.Center
			local toggleBtn, sLabel, iBox, sExp, gExp = buildValueRow(frame, speed, placeholder, tw, function(v)
				speed = v
				if active then startFn(speed) end
			end)
			speedLabelRef = sLabel
			inputBoxRef = iBox
			setExpanded = sExp
			getExpanded = gExp
			local _th = false
			toggleBtn.Activated:Connect(function()
				_th = true
				setExpanded(not getExpanded())
			end)
			local clickArea = NewInstance("TextButton", frame)
			clickArea.Size = UDim2.new(1, -36, 0, 44)
			clickArea.BackgroundTransparency = 1
			clickArea.Text = ""
			clickArea.ZIndex = 2
			makeDraggable(frame, clickArea)
			clickArea.Activated:Connect(function()
				if _th then _th = false return end
				active = not active
				local col = active and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(220, 70, 70)
				nameLabel.Text = active and labelOn or labelOff
				TweenService:Create(stroke, tw, {Color = col}):Play()
				TweenService:Create(nameLabel, tw, {TextColor3 = col}):Play()
				if active then startFn(speed) else stopFn() end
				if not active and getExpanded() then setExpanded(false) end
			end)
		else
			frame.Size = UDim2.new(0, 100, 0, 40)
			frame.Position = UDim2.new(1, -120, 0, 20 + yOff)
			nameLabel.Size = UDim2.new(1, 0, 1, 0)
			nameLabel.TextXAlignment = Enum.TextXAlignment.Center
			local clickArea = NewInstance("TextButton", frame)
			clickArea.Size = UDim2.new(1, -8, 1, -8)
			clickArea.Position = UDim2.new(0, 4, 0, 4)
			clickArea.BackgroundTransparency = 1
			clickArea.Text = ""
			clickArea.ZIndex = 2
			makeDraggable(frame, clickArea)
			clickArea.Activated:Connect(function()
				active = not active
				local col = active and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(220, 70, 70)
				nameLabel.Text = active and labelOn or labelOff
				TweenService:Create(stroke, tw, {Color = col}):Play()
				TweenService:Create(nameLabel, tw, {TextColor3 = col}):Play()
				if active then startFn() else stopFn() end
			end)
		end
	end
	return {
		show = function(spd)
			build()
			if hasValue and spd then
				speed = tonumber(spd) or spd
				if speedLabelRef then speedLabelRef.Text = tostring(speed) end
				if inputBoxRef then inputBoxRef.Text = tostring(speed) end
			end
			active = true
			frame.Visible = true
			stroke.Color = Color3.fromRGB(80, 220, 120)
			nameLabel.Text = labelOn
			nameLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
			startFn(hasValue and speed or nil)
		end,
		hide = function()
			if not built then return end
			active = false
			frame.Visible = false
			if hasValue and getExpanded() then setExpanded(false) end
			stopFn()
		end,
		showOff = function()
			build()
			active = false
			frame.Visible = true
			stroke.Color = Color3.fromRGB(220, 70, 70)
			nameLabel.Text = labelOff
			nameLabel.TextColor3 = Color3.fromRGB(220, 70, 70)
		end,
		destroy = function()
			if frame then frame:Destroy(); frame = nil end
			built = false
		end,
	}
end

do
	local parent = getGuiParent()
	local existing = parent:FindFirstChild("NNGui")
	if existing and existing:FindFirstChild("Capture") then
		existing:Destroy()
	end

	UI.Capture.gui = NewInstance("ScreenGui", parent)
	UI.Capture.gui.ResetOnSpawn = false
	UI.Capture.gui.DisplayOrder = 2147483647
	UI.registerScaleTarget(UI.Capture.gui)

	UI.Capture.button = NewInstance("TextButton", UI.Capture.gui)
	UI.Capture.button.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
	UI.Capture.button.BackgroundTransparency = 0.14
	UI.Capture.button.Position = UDim2.new(0.489, 0, 0, 0)
	UI.Capture.button.Size = UDim2.new(0, 32, 0, 33)
	UI.Capture.button.Font = Enum.Font.SourceSansBold
	UI.Capture.button.Text = "NN"
	UI.Capture.button.TextColor3 = Color3.new(1, 1, 1)
	UI.Capture.button.TextSize = 20
	UI.Capture.button.TextWrapped = true
	UI.Capture.button.ZIndex = 10
	NewInstance("UICorner", UI.Capture.button).CornerRadius = UDim.new(0.5, 0)

	makeDraggable(UI.Capture.button)

	UI.Capture.scale = NewInstance("UIScale", UI.Capture.button)

	UI.Capture.busy = false

	UI.Capture.button.Activated:Connect(function()
		if UI.Capture.busy then
			return
		end
		UI.Capture.busy = true

		local tweenPress = TweenService:Create(
			UI.Capture.scale,
			TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Scale = 0.78 }
		)
		local tweenRelease = TweenService:Create(
			UI.Capture.scale,
			TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }
		)

		tweenPress:Play()
		tweenPress.Completed:Wait()
		tweenRelease:Play()
		if UI.CommandBar.open then
			UI.CommandBar.open()
		end
		tweenRelease.Completed:Wait()

		UI.Capture.busy = false
	end)
end

function UI.buildCmdListGui()
	local cmdListFrame = NewInstance("Frame", screenGui)
	cmdListFrame.Size = UDim2.new(0, 300, 0, 380)
	cmdListFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	cmdListFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	cmdListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	cmdListFrame.Visible = false
	cmdListFrame.Active = true
	cmdListFrame.ClipsDescendants = true
	UI.excludeFromScale(cmdListFrame)
	NewInstance("UICorner", cmdListFrame).CornerRadius = UDim.new(0, 8)
	local sL = NewInstance("UIStroke", cmdListFrame)
	sL.Color = Color3.fromRGB(255, 255, 255)
	sL.Thickness = 1.3
	sL.Transparency = 0.25
	local titleBar = NewInstance("Frame", cmdListFrame)
	titleBar.Size = UDim2.new(1, 0, 0, 40)
	titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	titleBar.BorderSizePixel = 0
	NewInstance("UICorner", titleBar).CornerRadius = UDim.new(0, 8)
	local tFix = NewInstance("Frame", titleBar)
	tFix.Size = UDim2.new(1, 0, 0.5, 0)
	tFix.Position = UDim2.new(0, 0, 0.5, 0)
	tFix.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	tFix.BorderSizePixel = 0
	makeDraggable(cmdListFrame, titleBar)

	local cmdResizeHandle = NewInstance("Frame", cmdListFrame)
	cmdResizeHandle.Size = UDim2.new(0, 18, 0, 18)
	cmdResizeHandle.Position = UDim2.new(1, -18, 1, -18)
	cmdResizeHandle.BackgroundTransparency = 1
	cmdResizeHandle.Active = true
	cmdResizeHandle.ZIndex = 10
	local _cmdRhText = NewInstance("TextLabel", cmdResizeHandle)
	_cmdRhText.Size = UDim2.new(1, 0, 1, 0)
	_cmdRhText.BackgroundTransparency = 1
	_cmdRhText.Text = "↘"
	_cmdRhText.TextColor3 = Color3.fromRGB(150, 150, 150)
	_cmdRhText.TextTransparency = 0.15
	_cmdRhText.Font = Enum.Font.GothamBold
	_cmdRhText.TextSize = 14
	makeResizeable(cmdListFrame, cmdResizeHandle, Vector2.new(260, 280), Vector2.new(600, 700))
	local titleText = NewInstance("TextLabel", titleBar)
	titleText.Size = UDim2.new(1, -40, 1, 0)
	titleText.Position = UDim2.new(0, 15, 0, 0)
	titleText.BackgroundTransparency = 1
	titleText.Text = "Command List"
	titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleText.Font = Enum.Font.GothamBold
	titleText.TextSize = 16
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	local closeBtn = NewInstance("TextButton", titleBar)
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -35, 0, 5)
	closeBtn.BackgroundTransparency = 1
	closeBtn.Text = "❌"
	closeBtn.TextSize = 14
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	local cmdListSearch = NewInstance("TextBox", cmdListFrame)
	cmdListSearch.Size = UDim2.new(1, -20, 0, 28)
	cmdListSearch.Position = UDim2.new(0, 10, 0, 44)
	cmdListSearch.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	cmdListSearch.BorderSizePixel = 0
	cmdListSearch.PlaceholderText = "🔍 search command..."
	cmdListSearch.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
	cmdListSearch.Text = ""
	cmdListSearch.TextColor3 = Color3.fromRGB(220, 220, 220)
	cmdListSearch.Font = Enum.Font.GothamSemibold
	cmdListSearch.TextSize = 13
	cmdListSearch.ClearTextOnFocus = false
	NewInstance("UICorner", cmdListSearch).CornerRadius = UDim.new(0, 6)
	NewInstance("UIPadding", cmdListSearch).PaddingLeft = UDim.new(0, 8)
	local cmdListScroll = NewInstance("ScrollingFrame", cmdListFrame)
	cmdListScroll.Size = UDim2.new(1, -34, 1, -82)
	cmdListScroll.Position = UDim2.new(0, 10, 0, 78)
	cmdListScroll.BackgroundTransparency = 1
	cmdListScroll.ScrollBarThickness = 0
	cmdListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	cmdListScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	local listLayout = NewInstance("UIListLayout", cmdListScroll)
	listLayout.Padding = UDim.new(0, 5)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local cmdScrollTrack = NewInstance("Frame", cmdListFrame)
	cmdScrollTrack.Active = true
	cmdScrollTrack.Size = UDim2.new(0, 6, 1, -82)
	cmdScrollTrack.Position = UDim2.new(1, -16, 0, 78)
	cmdScrollTrack.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	cmdScrollTrack.BorderSizePixel = 0
	NewInstance("UICorner", cmdScrollTrack).CornerRadius = UDim.new(0, 4)

	local cmdScrollThumb = NewInstance("Frame", cmdScrollTrack)
	cmdScrollThumb.Active = true
	cmdScrollThumb.Size = UDim2.new(1, 0, 0, 30)
	cmdScrollThumb.Position = UDim2.new(0, 0, 0, 0)
	cmdScrollThumb.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
	cmdScrollThumb.BorderSizePixel = 0
	NewInstance("UICorner", cmdScrollThumb).CornerRadius = UDim.new(0, 4)
	local _cmdThumbStroke = NewInstance("UIStroke", cmdScrollThumb)
	_cmdThumbStroke.Color = Color3.fromRGB(255, 255, 255)
	_cmdThumbStroke.Thickness = 1
	_cmdThumbStroke.Transparency = 0.6

	local function _updateCmdScrollThumb()
		local canvasH = cmdListScroll.AbsoluteCanvasSize.Y
		local winH = cmdListScroll.AbsoluteWindowSize.Y
		local trackH = cmdScrollTrack.AbsoluteSize.Y
		if trackH <= 0 then return end
		if canvasH <= winH or canvasH <= 0 then
			cmdScrollThumb.Size = UDim2.new(1, 0, 1, 0)
			cmdScrollThumb.Position = UDim2.new(0, 0, 0, 0)
			return
		end
		local thumbH = math.clamp((winH / canvasH) * trackH, 20, trackH)
		local maxScroll = canvasH - winH
		local ratio = maxScroll > 0 and (cmdListScroll.CanvasPosition.Y / maxScroll) or 0
		cmdScrollThumb.Size = UDim2.new(1, 0, 0, thumbH)
		cmdScrollThumb.Position = UDim2.new(0, 0, 0, ratio * (trackH - thumbH))
	end

	cmdListScroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(_updateCmdScrollThumb)
	cmdListScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(_updateCmdScrollThumb)
	cmdListScroll:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(_updateCmdScrollThumb)
	cmdScrollTrack:GetPropertyChangedSignal("AbsoluteSize"):Connect(_updateCmdScrollThumb)

	local _cmdThumbDrag = false
	local _cmdThumbDragInput = nil
	local _cmdThumbDragStartY = 0
	local _cmdThumbStartOffset = 0
	cmdScrollThumb.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			_cmdThumbDrag = true
			_cmdThumbDragInput = input
			_cmdThumbDragStartY = input.Position.Y
			_cmdThumbStartOffset = cmdScrollThumb.Position.Y.Offset
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if _cmdThumbDrag and input == _cmdThumbDragInput then
			local trackH = cmdScrollTrack.AbsoluteSize.Y
			local thumbH = cmdScrollThumb.AbsoluteSize.Y
			local delta = input.Position.Y - _cmdThumbDragStartY
			local newY = math.clamp(_cmdThumbStartOffset + delta, 0, math.max(trackH - thumbH, 0))
			local range = trackH - thumbH
			local ratio = range > 0 and (newY / range) or 0

			local canvasH = cmdListScroll.AbsoluteCanvasSize.Y
			local winH = cmdListScroll.AbsoluteWindowSize.Y
			local maxScroll = math.max(canvasH - winH, 0)
			cmdListScroll.CanvasPosition = Vector2.new(0, ratio * maxScroll)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if _cmdThumbDrag and input == _cmdThumbDragInput then
			_cmdThumbDrag = false
			_cmdThumbDragInput = nil
		end
	end)

	task.defer(_updateCmdScrollThumb)

	closeBtn.Activated:Connect(function()
		TweenService:Create(cmdListFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
		task.delay(0.22, function() cmdListFrame.Visible = false end)
	end)

	return {
		frame = cmdListFrame,
		search = cmdListSearch,
		scroll = cmdListScroll,
		scrollTrack = cmdScrollTrack,
		scrollThumb = cmdScrollThumb,
		closeBtn = closeBtn,
		createRow = UI.buildCmdListRow,
	}
end

function UI.buildCmdListRow(parent)
	local row = NewInstance("Frame", parent)
	row.Size = UDim2.new(1, -10, 0, 25)
	row.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	row.BackgroundTransparency = 0.35
	row.BorderSizePixel = 0
	NewInstance("UICorner", row).CornerRadius = UDim.new(0, 5)
	local _rowPad = NewInstance("UIPadding", row)
	_rowPad.PaddingLeft = UDim.new(0, 4)
	_rowPad.PaddingRight = UDim.new(0, 4)

	local indexLabel = NewInstance("TextLabel", row)
	indexLabel.Size = UDim2.new(0, 22, 1, 0)
	indexLabel.Position = UDim2.new(0, 0, 0, 0)
	indexLabel.BackgroundTransparency = 1
	indexLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
	indexLabel.Font = Enum.Font.GothamSemibold
	indexLabel.TextSize = 14
	indexLabel.TextXAlignment = Enum.TextXAlignment.Left

	local scroller = NewInstance("ScrollingFrame", row)
	scroller.Size = UDim2.new(1, -22, 1, 0)
	scroller.Position = UDim2.new(0, 22, 0, 0)
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.ClipsDescendants = true
	scroller.ScrollingDirection = Enum.ScrollingDirection.X
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.X
	scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroller.ScrollBarThickness = 3
	scroller.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
	scroller.ScrollBarImageTransparency = 0.55

	local textLabel = NewInstance("TextLabel", scroller)
	textLabel.Size = UDim2.new(0, 0, 1, 0)
	textLabel.AutomaticSize = Enum.AutomaticSize.X
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.Font = Enum.Font.GothamSemibold
	textLabel.TextSize = 14
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextWrapped = false

	return {
		row = row,
		indexLabel = indexLabel,
		scroller = scroller,
		label = textLabel,
	}
end

function UI.buildUiScalerGui()
	if UI.UiScaler.frame then return UI.UiScaler end

	local scalerGui = NewInstance("ScreenGui", getGuiParent())
	scalerGui.ResetOnSpawn = false
	scalerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	scalerGui.IgnoreGuiInset = true

	local frame = NewInstance("Frame", scalerGui)
	frame.Size = UDim2.new(0, 260, 0, 118)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.Visible = false
	frame.Active = true
	frame.ClipsDescendants = true
	NewInstance("UICorner", frame).CornerRadius = UDim.new(0, 8)
	local sL = NewInstance("UIStroke", frame)
	sL.Color = Color3.fromRGB(255, 255, 255)
	sL.Thickness = 1.3
	sL.Transparency = 0.25

	local titleBar = NewInstance("Frame", frame)
	titleBar.Size = UDim2.new(1, 0, 0, 36)
	titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	titleBar.BorderSizePixel = 0
	NewInstance("UICorner", titleBar).CornerRadius = UDim.new(0, 8)
	local tFix = NewInstance("Frame", titleBar)
	tFix.Size = UDim2.new(1, 0, 0.5, 0)
	tFix.Position = UDim2.new(0, 0, 0.5, 0)
	tFix.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	tFix.BorderSizePixel = 0
	makeDraggable(frame, titleBar)

	local titleText = NewInstance("TextLabel", titleBar)
	titleText.Size = UDim2.new(1, -66, 1, 0)
	titleText.Position = UDim2.new(0, 33, 0, 0)
	titleText.BackgroundTransparency = 1
	titleText.Text = "UI Scaler"
	titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleText.Font = Enum.Font.GothamBold
	titleText.TextSize = 15
	titleText.TextXAlignment = Enum.TextXAlignment.Center

	local closeBtn = NewInstance("TextButton", titleBar)
	closeBtn.Size = UDim2.new(0, 28, 0, 28)
	closeBtn.Position = UDim2.new(1, -33, 0, 4)
	closeBtn.BackgroundTransparency = 1
	closeBtn.Text = "❌"
	closeBtn.TextSize = 13
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Activated:Connect(function()
		UI.UiScaler.close()
	end)

	local minV, maxV = 0.5, 2.5

	local valLbl = NewInstance("TextLabel", frame)
	valLbl.Size = UDim2.new(1, -24, 0, 22)
	valLbl.Position = UDim2.new(0, 12, 0, 44)
	valLbl.BackgroundTransparency = 1
	valLbl.Text = string.format("%.1fx", UI._currentScale)
	valLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	valLbl.Font = Enum.Font.GothamBold
	valLbl.TextSize = 14
	valLbl.TextXAlignment = Enum.TextXAlignment.Center

	local track = NewInstance("Frame", frame)
	track.Size = UDim2.new(1, -32, 0, 6)
	track.Position = UDim2.new(0, 16, 0, 78)
	track.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	track.BorderSizePixel = 0
	NewInstance("UICorner", track).CornerRadius = UDim.new(1, 0)

	local function pctFor(v)
		return math.clamp((v - minV) / (maxV - minV), 0, 1)
	end

	local pct0 = pctFor(UI._currentScale)
	local fill = NewInstance("Frame", track)
	fill.Size = UDim2.new(pct0, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(90, 160, 255)
	fill.BorderSizePixel = 0
	NewInstance("UICorner", fill).CornerRadius = UDim.new(1, 0)

	local knob = NewInstance("Frame", track)
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.Position = UDim2.new(pct0, -7, 0.5, -7)
	knob.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	knob.BorderSizePixel = 0
	NewInstance("UICorner", knob).CornerRadius = UDim.new(1, 0)

	local function setSliderValue(v)
		v = math.clamp(v, minV, maxV)
		local r = pctFor(v)
		valLbl.Text = string.format("%.1fx", v)
		fill.Size = UDim2.new(r, 0, 1, 0)
		knob.Position = UDim2.new(r, -7, 0.5, -7)
	end
	UI.UiScaler.setSliderValue = setSliderValue

	local hit = NewInstance("TextButton", track)
	hit.Size = UDim2.new(1, 0, 0, 20)
	hit.AnchorPoint = Vector2.new(0, 0.5)
	hit.Position = UDim2.new(0, 0, 0.5, 0)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.ZIndex = 3

	local function applyX(x)
		local r = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local val = math.floor((minV + (maxV - minV) * r) * 10 + 0.5) / 10
		UI.setScale(val)
	end

	local drag = false
	hit.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			drag = true
			applyX(i.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			applyX(i.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			drag = false
		end
	end)

	UI.UiScaler.gui = scalerGui
	UI.UiScaler.frame = frame

	local UIS_OPEN_SIZE = frame.Size
	frame.Visible = false

	local uisContent = {titleBar, valLbl, track}
	local function setUisContentVisible(v)
		for _, obj in ipairs(uisContent) do
			obj.Visible = v
		end
	end
	setUisContentVisible(false)

	function UI.UiScaler.open()
		scalerGui.Enabled = true
		frame.Visible = true
		frame.Size = UDim2.new(0, 0, 0, 0)
		setUisContentVisible(false)
		local tw = TweenService:Create(frame, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UIS_OPEN_SIZE})
		tw.Completed:Once(function()
			setUisContentVisible(true)
		end)
		tw:Play()
	end

	function UI.UiScaler.close()
		setUisContentVisible(false)
		TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
		task.delay(0.22, function()
			frame.Visible = false
			scalerGui.Enabled = false
		end)
	end

	function UI.UiScaler.toggle()
		if frame.Visible then
			UI.UiScaler.close()
		else
			UI.UiScaler.open()
		end
	end

	return UI.UiScaler
end

UI.buildUiScalerGui()

function UI.buildManagerGui(cfg)
	local sg2 = NewInstance("ScreenGui", getGuiParent())
	sg2.ResetOnSpawn = false
	sg2.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg2.IgnoreGuiInset = true
	UI.registerScaleTarget(sg2)
	local BZ = cfg.bz
	local mainFrame = NewInstance("Frame", sg2)
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	mainFrame.BorderSizePixel = 0
	mainFrame.Active = true
	mainFrame.Visible = false
	mainFrame.ClipsDescendants = true
	mainFrame.ZIndex = BZ
	NewInstance("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)
	local mStk = NewInstance("UIStroke", mainFrame)
	mStk.Color = cfg.accentColor
	mStk.Thickness = 1.2
	local tBar = NewInstance("Frame", mainFrame)
	tBar.Size = UDim2.new(1, 0, 0, 40)
	tBar.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
	tBar.BorderSizePixel = 0
	tBar.ZIndex = BZ + 1
	NewInstance("UICorner", tBar).CornerRadius = UDim.new(0, 14)
	local tFix = NewInstance("Frame", tBar)
	tFix.Size = UDim2.new(1, 0, 0.5, 0)
	tFix.Position = UDim2.new(0, 0, 0.5, 0)
	tFix.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
	tFix.BorderSizePixel = 0
	tFix.ZIndex = BZ + 1
	makeDraggable(mainFrame, tBar)
	local tIcon = NewInstance("TextLabel", tBar)
	tIcon.Size = UDim2.new(0, 34, 1, 0)
	tIcon.Position = UDim2.new(0, 12, 0, 0)
	tIcon.BackgroundTransparency = 1
	tIcon.Text = cfg.icon
	tIcon.TextColor3 = cfg.accentColor
	tIcon.Font = Enum.Font.GothamBold
	tIcon.TextSize = 16
	tIcon.ZIndex = BZ + 2
	local tTxt = NewInstance("TextLabel", tBar)
	tTxt.Size = UDim2.new(1, -90, 1, 0)
	tTxt.Position = UDim2.new(0, 42, 0, 0)
	tTxt.BackgroundTransparency = 1
	tTxt.Text = cfg.title
	tTxt.TextColor3 = Color3.fromRGB(240, 240, 240)
	tTxt.Font = Enum.Font.GothamBold
	tTxt.TextSize = 13
	tTxt.TextXAlignment = Enum.TextXAlignment.Left
	tTxt.ZIndex = BZ + 2
	local closeBtn = NewInstance("TextButton", tBar)
	closeBtn.Size = UDim2.new(0, 28, 0, 28)
	closeBtn.Position = UDim2.new(1, -36, 0.5, -14)
	closeBtn.BackgroundColor3 = Color3.fromRGB(55, 15, 15)
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 13
	closeBtn.AutoButtonColor = false
	closeBtn.ZIndex = BZ + 3
	NewInstance("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
	local cTw = TweenInfo.new(0.12)
	local ddList
	closeBtn.MouseEnter:Connect(function() TweenService:Create(closeBtn, cTw, {BackgroundColor3 = Color3.fromRGB(90, 20, 20)}):Play() end)
	closeBtn.MouseLeave:Connect(function() TweenService:Create(closeBtn, cTw, {BackgroundColor3 = Color3.fromRGB(55, 15, 15)}):Play() end)
	local hdiv = NewInstance("Frame", mainFrame)
	hdiv.Size = UDim2.new(1, -28, 0, 1)
	hdiv.Position = UDim2.new(0, 14, 0, 40)
	hdiv.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	hdiv.BorderSizePixel = 0
	hdiv.ZIndex = BZ + 1
	local cont = NewInstance("Frame", mainFrame)
	cont.Size = UDim2.new(1, -28, 1, -56)
	cont.Position = UDim2.new(0, 14, 0, 48)
	cont.BackgroundTransparency = 1
	cont.ZIndex = BZ + 1

	local managerContent = {tBar, hdiv, cont}
	local function setManagerContentVisible(v)
		for _, obj in ipairs(managerContent) do
			obj.Visible = v
		end
	end
	setManagerContentVisible(false)

	local function closeManager()
		cfg.guiOpenRef.v = false
		setManagerContentVisible(false)
		if ddList then ddList.Visible = false end
		TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
		task.delay(0.22, function() mainFrame.Visible = false end)
		if cfg.onCloseExtra then cfg.onCloseExtra() end
	end

	local DEFAULT_MANAGER_SIZE = UDim2.new(0, 396, 0, 220)

	local function openManager(targetSize)
		cfg.guiOpenRef.v = true
		mainFrame.Visible = true
		mainFrame.Size = UDim2.new(0, 0, 0, 0)
		setManagerContentVisible(false)
		local tw = TweenService:Create(mainFrame, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = targetSize or DEFAULT_MANAGER_SIZE})
		tw.Completed:Once(function()
			setManagerContentVisible(true)
		end)
		tw:Play()
	end

	local function toggleManager(targetSize)
		if cfg.guiOpenRef.v then
			closeManager()
		else
			openManager(targetSize)
		end
	end

	closeBtn.Activated:Connect(closeManager)
	local function mkField(lTxt, ph, x, y, w, green)
		local lbl = NewInstance("TextLabel", cont)
		lbl.Size = UDim2.new(0, w, 0, 14)
		lbl.Position = UDim2.new(0, x, 0, y)
		lbl.BackgroundTransparency = 1
		lbl.Text = lTxt
		lbl.TextColor3 = Color3.fromRGB(100, 100, 100)
		lbl.Font = Enum.Font.GothamSemibold
		lbl.TextSize = 11
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = BZ + 2
		local bx = NewInstance("TextBox", cont)
		bx.Size = UDim2.new(0, w, 0, 30)
		bx.Position = UDim2.new(0, x, 0, y + 16)
		bx.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
		bx.BorderSizePixel = 0
		bx.Text = ""
		bx.PlaceholderText = ph
		bx.PlaceholderColor3 = Color3.fromRGB(65, 65, 65)
		bx.TextColor3 = green and Color3.fromRGB(0, 210, 110) or Color3.fromRGB(200, 200, 200)
		bx.Font = green and Enum.Font.GothamBold or Enum.Font.GothamSemibold
		bx.TextSize = 13
		bx.TextXAlignment = green and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
		bx.ClearTextOnFocus = false
		bx.ZIndex = BZ + 2
		NewInstance("UICorner", bx).CornerRadius = UDim.new(0, 7)
		local bxSt = NewInstance("UIStroke", bx)
		bxSt.Color = green and Color3.fromRGB(0, 100, 55) or cfg.accentColor
		bxSt.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		NewInstance("UIPadding", bx).PaddingLeft = UDim.new(0, 8)
		return bx
	end
	local rowDiv = NewInstance("Frame", cont)
	rowDiv.Size = UDim2.new(1, 0, 0, 1)
	rowDiv.Position = UDim2.new(0, 0, 0, 50)
	rowDiv.BackgroundColor3 = Color3.fromRGB(30, 30, 48)
	rowDiv.BorderSizePixel = 0
	rowDiv.ZIndex = BZ + 1
	local cmdIn = mkField("Command", "e.g. fly, noclip, ws", 0, 0, 178)
	local argIn = mkField("Arg (optional)", "e.g. 120, all", 190, 0, 178)
	local extraIn = cfg.row2Left and cfg.row2Left(cont, BZ) or nil
	local ddAccent = cfg.ddAccentColor
	local ddLbl = NewInstance("TextLabel", cont)
	ddLbl.Size = UDim2.new(0, 178, 0, 14)
	ddLbl.Position = UDim2.new(0, 190, 0, 58)
	ddLbl.BackgroundTransparency = 1
	ddLbl.Text = cfg.ddLabel
	ddLbl.TextColor3 = Color3.fromRGB(100, 100, 100)
	ddLbl.Font = Enum.Font.GothamSemibold
	ddLbl.TextSize = 11
	ddLbl.TextXAlignment = Enum.TextXAlignment.Left
	ddLbl.ZIndex = BZ + 2
	local ddBtn = NewInstance("TextButton", cont)
	ddBtn.Size = UDim2.new(0, 178, 0, 30)
	ddBtn.Position = UDim2.new(0, 190, 0, 74)
	ddBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	ddBtn.BorderSizePixel = 0
	ddBtn.Text = "▾ " .. cfg.ddPlaceholder
	ddBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
	ddBtn.Font = Enum.Font.GothamSemibold
	ddBtn.TextSize = 12
	ddBtn.AutoButtonColor = false
	ddBtn.ZIndex = BZ + 2
	NewInstance("UICorner", ddBtn).CornerRadius = UDim.new(0, 7)
	local ddBStk = NewInstance("UIStroke", ddBtn)
	ddBStk.Color = ddAccent
	ddBStk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ddBtn.MouseEnter:Connect(function() TweenService:Create(ddBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(26, 26, 26)}):Play() end)
	ddBtn.MouseLeave:Connect(function() TweenService:Create(ddBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(18, 18, 18)}):Play() end)
	ddList = NewInstance("ScrollingFrame", sg2)
	ddList.Size = UDim2.new(0, 178, 0, 0)
	ddList.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
	ddList.BorderSizePixel = 0
	ddList.ScrollBarThickness = 3
	ddList.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
	ddList.CanvasSize = UDim2.new(0, 0, 0, 0)
	ddList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ddList.Visible = false
	ddList.ZIndex = BZ + 50
	NewInstance("UICorner", ddList).CornerRadius = UDim.new(0, 7)
	local ddLStk = NewInstance("UIStroke", ddList)
	ddLStk.Color = ddAccent
	ddLStk.Thickness = 1
	NewInstance("UIListLayout", ddList).Padding = UDim.new(0, 2)
	local ddOpen = false
	local selectedIdx = nil
	local function refreshDd()
		for _, ch in ipairs(ddList:GetChildren()) do
			if ch:IsA("TextButton") or ch:IsA("TextLabel") then ch:Destroy() end
		end
		local items = cfg.getItems()
		if #items == 0 then
			local emp = NewInstance("TextLabel", ddList)
			emp.Size = UDim2.new(1, 0, 0, 32)
			emp.BackgroundTransparency = 1
			emp.Text = cfg.ddEmptyText
			emp.TextColor3 = Color3.fromRGB(70, 70, 70)
			emp.Font = Enum.Font.GothamSemibold
			emp.TextSize = 11
			emp.ZIndex = BZ + 51
			return
		end
		for i2, item in ipairs(items) do
			local row = NewInstance("TextButton", ddList)
			row.Size = UDim2.new(1, 0, 0, 30)
			row.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			row.BorderSizePixel = 0
			row.AutoButtonColor = false
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.ZIndex = BZ + 51
			row.Font = Enum.Font.GothamSemibold
			row.TextSize = 11
			row.Text = " " .. cfg.getRowText(item)
			row.TextColor3 = Color3.fromRGB(200, 200, 200)
			NewInstance("UIPadding", row).PaddingLeft = UDim.new(0, 4)
			local cap = i2
			row.MouseEnter:Connect(function() TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(32, 32, 32)}):Play() end)
			row.MouseLeave:Connect(function() TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}):Play() end)
			row.Activated:Connect(function()
				selectedIdx = cap
				cfg.onDdSelect(item, cmdIn, argIn, extraIn, ddBtn)
				ddOpen = false
				TweenService:Create(ddList, TweenInfo.new(0.12, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 178, 0, 0)}):Play()
				task.delay(0.13, function() ddList.Visible = false end)
			end)
		end
	end
	local function closeDd()
		ddOpen = false
		TweenService:Create(ddList, TweenInfo.new(0.12, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 178, 0, 0)}):Play()
		task.delay(0.13, function() ddList.Visible = false end)
		ddBtn.Text = ddBtn.Text:gsub("▴", "▾")
	end
	ddBtn.Activated:Connect(function()
		ddOpen = not ddOpen
		if ddOpen then
			refreshDd()
			local absP = ddBtn.AbsolutePosition
			local absS = ddBtn.AbsoluteSize
			ddList.Position = UDim2.new(0, absP.X, 0, absP.Y + absS.Y + 4)
			local items = cfg.getItems()
			local listH = math.min(#items * 32 + 6, 160)
			if #items == 0 then listH = 36 end
			ddList.Size = UDim2.new(0, 178, 0, 0)
			ddList.Visible = true
			TweenService:Create(ddList, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 178, 0, listH)}):Play()
			ddBtn.Text = "▴ " .. cfg.ddPlaceholder
			ddBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
		else
			closeDd()
		end
	end)
	local function mkActBtn(txt, bgClr, strkClr, x, y)
		local ab = NewInstance("TextButton", cont)
		ab.Size = UDim2.new(0, 178, 0, 34)
		ab.Position = UDim2.new(0, x, 0, y)
		ab.BackgroundColor3 = bgClr
		ab.BorderSizePixel = 0
		ab.Text = txt
		ab.TextColor3 = Color3.fromRGB(235, 240, 255)
		ab.Font = Enum.Font.GothamBold
		ab.TextSize = 13
		ab.AutoButtonColor = false
		ab.ZIndex = BZ + 2
		NewInstance("UICorner", ab).CornerRadius = UDim.new(0, 9)
		local abSt = NewInstance("UIStroke", ab)
		abSt.Color = strkClr
		abSt.Thickness = 1.3
		abSt.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		local r2 = math.floor(bgClr.R * 255)
		local g2 = math.floor(bgClr.G * 255)
		local b2 = math.floor(bgClr.B * 255)
		ab.MouseEnter:Connect(function() TweenService:Create(ab, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(math.min(r2+18,255), math.min(g2+18,255), math.min(b2+18,255))}):Play() end)
		ab.MouseLeave:Connect(function() TweenService:Create(ab, TweenInfo.new(0.12), {BackgroundColor3 = bgClr}):Play() end)
		return ab
	end
	local addBtn = mkActBtn(cfg.addText, cfg.addBg, cfg.addStroke, 0, 118)
	local remBtn = mkActBtn(cfg.remText or "✕ Remove", Color3.fromRGB(42,8,8), Color3.fromRGB(185,40,40), 190, 118)
	local function setSelIdx(v) selectedIdx = v end
	local function getSelIdx() return selectedIdx end
	addBtn.Activated:Connect(function()
		local cmd = cmdIn.Text:lower():match("^%s*(.-)%s*$") or ""
		local arg = argIn.Text:match("^%s*(.-)%s*$") or ""
		local extra = extraIn and (extraIn.Text or "") or ""
		cfg.onAdd(cmd, arg, extra, ddBtn, setSelIdx, cmdIn, argIn, extraIn)
	end)
	remBtn.Activated:Connect(function()
		local cmd = cmdIn.Text:lower():match("^%s*(.-)%s*$") or ""
		local arg = argIn.Text:match("^%s*(.-)%s*$") or ""
		local extra = extraIn and (extraIn.Text or "") or ""
		cfg.onRemove(getSelIdx, setSelIdx, cmd, arg, extra, cmdIn, argIn, extraIn, ddBtn)
	end)
	cfg.mainFrameSetter(mainFrame)

	return {
		frame = mainFrame,
		open = openManager,
		close = closeManager,
		toggle = toggleManager,
	}
end

local C = {
    bg = Color3.fromRGB(12, 12, 12),
    bg2 = Color3.fromRGB(38, 38, 38),
    stroke = Color3.fromRGB(48, 48, 48),
    text = Color3.fromRGB(220, 220, 220),
    sub = Color3.fromRGB(95, 95, 95),
    accent = Color3.fromRGB(110, 180, 255),
    on = Color3.fromRGB(55, 200, 110),
    pill_bg = Color3.fromRGB(45, 45, 45),
    knob = Color3.fromRGB(90, 90, 90),
}
local TW_Q = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
local TW_IN = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local TW_OUT= TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local sg = NewInstance("ScreenGui", getGuiParent())
sg.ResetOnSpawn = false
sg.ZIndexBehavior= Enum.ZIndexBehavior.Sibling
sg.IgnoreGuiInset= true

local panel = NewInstance("Frame", sg)
panel.Size = UDim2.new(0, 420, 0, 480)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = C.bg
panel.BorderSizePixel = 0
panel.Visible = false
panel.ClipsDescendants = true
NewInstance("UICorner", panel).CornerRadius = UDim.new(0, 14)
local _ps = NewInstance("UIStroke", panel)
_ps.Color = Color3.fromRGB(255, 255, 255)
_ps.Thickness = 1.5

local setSettingsContentVisible

local titleBar = NewInstance("Frame", panel)
titleBar.Active = true
titleBar.Size = UDim2.new(1, 0, 0, 46)
titleBar.BackgroundColor3 = C.bg
titleBar.BorderSizePixel = 0
NewInstance("UICorner", titleBar).CornerRadius = UDim.new(0, 14)
local _tbf = NewInstance("Frame", titleBar)
_tbf.Size = UDim2.new(1, 0, 0, 14)
_tbf.Position = UDim2.new(0, 0, 1, -14)
_tbf.BackgroundColor3 = C.bg
_tbf.BorderSizePixel = 0
local _tbs = NewInstance("UIStroke", titleBar)
_tbs.Color = C.stroke
_tbs.Thickness = 1
makeDraggable(panel, titleBar)

local resizeHandle = NewInstance("Frame", panel)
resizeHandle.Size = UDim2.new(0, 18, 0, 18)
resizeHandle.Position = UDim2.new(1, -18, 1, -18)
resizeHandle.BackgroundTransparency = 1
resizeHandle.Active = true
resizeHandle.ZIndex = 10
local _rhText = NewInstance("TextLabel", resizeHandle)
_rhText.Size = UDim2.new(1, 0, 1, 0)
_rhText.BackgroundTransparency = 1
_rhText.Text = "↘"
_rhText.TextColor3 = C.sub
_rhText.TextTransparency = 0.15
_rhText.Font = Enum.Font.GothamBold
_rhText.TextSize = 14
makeResizeable(panel, resizeHandle, Vector2.new(340, 360), Vector2.new(720, 820))

local _ti = NewInstance("ImageLabel", titleBar)
_ti.Size = UDim2.new(0, 20, 0, 20)
_ti.Position = UDim2.new(0, 13, 0.5, -10)
_ti.BackgroundTransparency = 1
_ti.Image = "rbxassetid://80758916183665"
_ti.ImageColor3 = C.accent

local _tl = NewInstance("TextLabel", titleBar)
_tl.Size = UDim2.new(1, 0, 1, 0)
_tl.Position = UDim2.new(0, 0, 0, 0)
_tl.BackgroundTransparency = 1
_tl.Text = "Settings"
_tl.TextColor3 = C.text
_tl.Font = Enum.Font.GothamBold
_tl.TextSize = 14
_tl.TextXAlignment = Enum.TextXAlignment.Center

local _cb = NewInstance("ImageButton", titleBar)
_cb.Size = UDim2.new(0, 24, 0, 24)
_cb.Position = UDim2.new(1, -34, 0.5, -12)
_cb.BackgroundColor3 = C.bg
_cb.Image = "rbxassetid://110786993356448"
_cb.ImageColor3 = Color3.fromRGB(150, 150, 150)
_cb.BorderSizePixel = 0
_cb.Activated:Connect(function()
    setSettingsContentVisible(false)
    TweenService:Create(panel, TW_IN, { Size = UDim2.new(0, 420, 0, 0) }):Play()
    task.delay(0.24, function() panel.Visible = false end)
end)

local tabScroll = NewInstance("ScrollingFrame", panel)
tabScroll.Size = UDim2.new(1, -24, 0, 36)
tabScroll.Position = UDim2.new(0, 12, 0, 52)
tabScroll.BackgroundColor3 = C.bg
tabScroll.BorderSizePixel = 0
tabScroll.ScrollBarThickness = 0
tabScroll.ScrollingDirection = Enum.ScrollingDirection.X
tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
tabScroll.ClipsDescendants = true
NewInstance("UICorner", tabScroll).CornerRadius = UDim.new(0, 10)
NewInstance("UIStroke", tabScroll).Color = C.stroke
local _tabLayout = NewInstance("UIListLayout", tabScroll)
_tabLayout.FillDirection = Enum.FillDirection.Horizontal
_tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
_tabLayout.Padding = UDim.new(0, 4)
local _tabPad = NewInstance("UIPadding", tabScroll)
_tabPad.PaddingLeft = UDim.new(0, 4)
_tabPad.PaddingRight = UDim.new(0, 4)
_tabPad.PaddingTop = UDim.new(0, 4)
_tabPad.PaddingBottom = UDim.new(0, 4)

local contentScroll = NewInstance("ScrollingFrame", panel)
contentScroll.Size = UDim2.new(1, -48, 1, -104)
contentScroll.Position = UDim2.new(0, 12, 0, 98)
contentScroll.BackgroundTransparency = 1
contentScroll.BorderSizePixel = 0
contentScroll.ScrollBarThickness = 0
contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentScroll.ClipsDescendants = true

local scrollBar = NewInstance("Frame", panel)
scrollBar.Active = true
scrollBar.Size = UDim2.new(0, 20, 1, -104)
scrollBar.Position = UDim2.new(1, -32, 0, 98)
scrollBar.BackgroundTransparency = 1
scrollBar.BorderSizePixel = 0

local settingsContent = {titleBar, tabScroll, contentScroll, scrollBar}
setSettingsContentVisible = function(v)
    for _, obj in ipairs(settingsContent) do
        obj.Visible = v
    end
end
setSettingsContentVisible(false)

local scrollUpBtn = NewInstance("ImageButton", scrollBar)
scrollUpBtn.Size = UDim2.new(1, 0, 0, 20)
scrollUpBtn.Position = UDim2.new(0, 0, 0, 0)
scrollUpBtn.BackgroundColor3 = C.bg
scrollUpBtn.AutoButtonColor = false
scrollUpBtn.BorderSizePixel = 0
NewInstance("UICorner", scrollUpBtn).CornerRadius = UDim.new(0, 6)
NewInstance("UIStroke", scrollUpBtn).Color = Color3.fromRGB(255, 255, 255)
local scrollUpIcon = NewInstance("ImageLabel", scrollUpBtn)
scrollUpIcon.Size = UDim2.new(0, 12, 0, 12)
scrollUpIcon.Position = UDim2.new(0.5, -6, 0.5, -6)
scrollUpIcon.BackgroundTransparency = 1
scrollUpIcon.Image = "rbxassetid://122444883127455"
scrollUpIcon.ImageColor3 = C.sub

local scrollDownBtn = NewInstance("ImageButton", scrollBar)
scrollDownBtn.Size = UDim2.new(1, 0, 0, 20)
scrollDownBtn.Position = UDim2.new(0, 0, 1, -20)
scrollDownBtn.BackgroundColor3 = C.bg
scrollDownBtn.AutoButtonColor = false
scrollDownBtn.BorderSizePixel = 0
NewInstance("UICorner", scrollDownBtn).CornerRadius = UDim.new(0, 6)
NewInstance("UIStroke", scrollDownBtn).Color = Color3.fromRGB(255, 255, 255)
local scrollDownIcon = NewInstance("ImageLabel", scrollDownBtn)
scrollDownIcon.Size = UDim2.new(0, 12, 0, 12)
scrollDownIcon.Position = UDim2.new(0.5, -6, 0.5, -6)
scrollDownIcon.BackgroundTransparency = 1
scrollDownIcon.Image = "rbxassetid://134243273101015"
scrollDownIcon.ImageColor3 = C.sub

local scrollTrack = NewInstance("Frame", scrollBar)
scrollTrack.Active = true
scrollTrack.Size = UDim2.new(1, 0, 1, -44)
scrollTrack.Position = UDim2.new(0, 0, 0, 22)
scrollTrack.BackgroundColor3 = C.bg
scrollTrack.BorderSizePixel = 0
NewInstance("UICorner", scrollTrack).CornerRadius = UDim.new(0, 6)

local scrollThumb = NewInstance("Frame", scrollTrack)
scrollThumb.Active = true
scrollThumb.Size = UDim2.new(1, -4, 0, 30)
scrollThumb.Position = UDim2.new(0, 2, 0, 0)
scrollThumb.BackgroundColor3 = C.bg2
scrollThumb.BorderSizePixel = 0
NewInstance("UICorner", scrollThumb).CornerRadius = UDim.new(0, 5)
local _stStroke = NewInstance("UIStroke", scrollThumb)
_stStroke.Color = Color3.fromRGB(255, 255, 255)
_stStroke.Thickness = 1

local function _updateScrollThumb()
	local canvasH = contentScroll.AbsoluteCanvasSize.Y
	local winH = contentScroll.AbsoluteWindowSize.Y
	local trackH = scrollTrack.AbsoluteSize.Y
	if trackH <= 0 then return end
	if canvasH <= winH or canvasH <= 0 then
		scrollThumb.Size = UDim2.new(1, -4, 1, 0)
		scrollThumb.Position = UDim2.new(0, 2, 0, 0)
		return
	end
	local thumbH = math.clamp((winH / canvasH) * trackH, 20, trackH)
	local maxScroll = canvasH - winH
	local ratio = maxScroll > 0 and (contentScroll.CanvasPosition.Y / maxScroll) or 0
	scrollThumb.Size = UDim2.new(1, -4, 0, thumbH)
	scrollThumb.Position = UDim2.new(0, 2, 0, ratio * (trackH - thumbH))
end

contentScroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(_updateScrollThumb)
contentScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(_updateScrollThumb)
contentScroll:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(_updateScrollThumb)
scrollTrack:GetPropertyChangedSignal("AbsoluteSize"):Connect(_updateScrollThumb)

local function _scrollBy(delta)
	local canvasH = contentScroll.AbsoluteCanvasSize.Y
	local winH = contentScroll.AbsoluteWindowSize.Y
	local maxScroll = math.max(canvasH - winH, 0)
	local newY = math.clamp(contentScroll.CanvasPosition.Y + delta, 0, maxScroll)
	contentScroll.CanvasPosition = Vector2.new(0, newY)
end

local function _bindHoldRepeat(button, delta)
	local holding = false
	button.MouseButton1Down:Connect(function()
		holding = true
		_scrollBy(delta)
		task.spawn(function()
			task.wait(0.35)
			while holding do
				_scrollBy(delta)
				task.wait(0.05)
			end
		end)
	end)
	local function _release() holding = false end
	button.MouseButton1Up:Connect(_release)
	button.MouseLeave:Connect(_release)
end
_bindHoldRepeat(scrollUpBtn, -30)
_bindHoldRepeat(scrollDownBtn, 30)

local _thumbDrag = false
local _thumbDragInput = nil
local _thumbDragStartY = 0
local _thumbStartOffset = 0
scrollThumb.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		_thumbDrag = true
		_thumbDragInput = input
		_thumbDragStartY = input.Position.Y
		_thumbStartOffset = scrollThumb.Position.Y.Offset
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if _thumbDrag and input == _thumbDragInput then
		local trackH = scrollTrack.AbsoluteSize.Y
		local thumbH = scrollThumb.AbsoluteSize.Y
		local delta = input.Position.Y - _thumbDragStartY
		local newY = math.clamp(_thumbStartOffset + delta, 0, math.max(trackH - thumbH, 0))
		local range = trackH - thumbH
		local ratio = range > 0 and (newY / range) or 0

		local canvasH = contentScroll.AbsoluteCanvasSize.Y
		local winH = contentScroll.AbsoluteWindowSize.Y
		local maxScroll = math.max(canvasH - winH, 0)
		contentScroll.CanvasPosition = Vector2.new(0, ratio * maxScroll)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if _thumbDrag and input == _thumbDragInput then
		_thumbDrag = false
		_thumbDragInput = nil
	end
end)

task.defer(_updateScrollThumb)

local _pages = {}
local _tabBtns = {}
local _current = nil

local function _switchTab(name)
    if _current == name then return end
    _current = name
    for n, pg in pairs(_pages) do pg.Visible = n == name end
    for n, btn in pairs(_tabBtns) do
        if n == name then
            btn.BackgroundTransparency = 0
            btn.BackgroundColor3 = C.bg2
            btn.TextColor3 = C.text
        else
            btn.BackgroundTransparency = 1
            btn.TextColor3 = C.sub
        end
    end
end

function UI.Settings.tab(name)
    local btn = NewInstance("TextButton", tabScroll)
    btn.Size = UDim2.new(0, math.max(80, #name * 8 + 24), 1, 0)
    btn.BackgroundColor3 = C.bg2
    btn.BackgroundTransparency = 1
    btn.Text = name
    btn.TextColor3 = C.sub
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    NewInstance("UICorner", btn).CornerRadius = UDim.new(0, 7)
    _tabBtns[name] = btn

    local page = NewInstance("Frame", contentScroll)
    page.Size = UDim2.new(1, 0, 0, 0)
    page.AutomaticSize = Enum.AutomaticSize.Y
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.Visible = false
    local pl = NewInstance("UIListLayout", page)
    pl.Padding = UDim.new(0, 6)
    pl.SortOrder = Enum.SortOrder.LayoutOrder
    local _pp = NewInstance("UIPadding", page)
    _pp.PaddingLeft = UDim.new(0, 2)
    _pp.PaddingRight = UDim.new(0, 2)
    _pp.PaddingBottom = UDim.new(0, 6)
    _pages[name] = page

    btn.Activated:Connect(function() _switchTab(name) end)

    if _current == nil then _switchTab(name) end

    return page
end

function UI.Settings.section(page, label)
    local lbl = NewInstance("TextLabel", page)
    lbl.Size = UDim2.new(1, 0, 0, 26)
    lbl.BackgroundTransparency = 1
    lbl.Text = string.upper(label)
    lbl.TextColor3 = C.sub
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = 999
    local p = NewInstance("UIPadding", lbl)
    p.PaddingLeft = UDim.new(0, 4)
    return lbl
end

function UI.Settings.toggle(page, label, callback)
    local row = NewInstance("Frame", page)
    row.Size = UDim2.new(1, 0, 0, 46)
    row.BackgroundColor3 = C.bg
    row.BorderSizePixel = 0
    row.LayoutOrder = 999
    NewInstance("UICorner", row).CornerRadius = UDim.new(0, 10)
    local rs = NewInstance("UIStroke", row)
    rs.Color = C.stroke
    rs.Thickness = 1

    local lbl = NewInstance("TextLabel", row)
    lbl.Size = UDim2.new(1, -72, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = C.text
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local pillBg = NewInstance("Frame", row)
    pillBg.Size = UDim2.new(0, 38, 0, 20)
    pillBg.Position = UDim2.new(1, -52, 0.5, -10)
    pillBg.BackgroundColor3 = C.pill_bg
    pillBg.BorderSizePixel = 0
    NewInstance("UICorner", pillBg).CornerRadius = UDim.new(1, 0)

    local pill = NewInstance("Frame", pillBg)
    pill.Size = UDim2.new(0, 14, 0, 14)
    pill.Position = UDim2.new(0, 3, 0.5, -7)
    pill.BackgroundColor3 = C.knob
    pill.BorderSizePixel = 0
    NewInstance("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local btn = NewInstance("TextButton", row)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 2

    local state = false
    btn.Activated:Connect(function()
        state = not state
        if state then
            TweenService:Create(pillBg, TW_Q, { BackgroundColor3 = C.on }):Play()
            TweenService:Create(pill, TW_Q, { Position = UDim2.new(0, 21, 0.5, -7), BackgroundColor3 = Color3.fromRGB(255,255,255) }):Play()
        else
            TweenService:Create(pillBg, TW_Q, { BackgroundColor3 = C.pill_bg }):Play()
            TweenService:Create(pill, TW_Q, { Position = UDim2.new(0, 3, 0.5, -7), BackgroundColor3 = C.knob }):Play()
        end
        if callback then callback(state) end
    end)
    return row
end

function UI.Settings.input(page, label, placeholder, default, callback)
    local row = NewInstance("Frame", page)
    row.Size = UDim2.new(1, 0, 0, 46)
    row.BackgroundColor3 = C.bg
    row.BorderSizePixel = 0
    row.LayoutOrder = 999
    NewInstance("UICorner", row).CornerRadius = UDim.new(0, 10)
    local rs = NewInstance("UIStroke", row)
    rs.Color = C.stroke
    rs.Thickness = 1

    local lbl = NewInstance("TextLabel", row)
    lbl.Size = UDim2.new(0.5, -14, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = C.text
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local boxBg = NewInstance("Frame", row)
    boxBg.Size = UDim2.new(0.5, -24, 0, 30)
    boxBg.Position = UDim2.new(0.5, 0, 0.5, -15)
    boxBg.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    boxBg.BorderSizePixel = 0
    NewInstance("UICorner", boxBg).CornerRadius = UDim.new(0, 7)
    local boxStroke = NewInstance("UIStroke", boxBg)
    boxStroke.Color = C.stroke
    boxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local box = NewInstance("TextBox", boxBg)
    box.Size = UDim2.new(1, -16, 1, 0)
    box.Position = UDim2.new(0, 8, 0, 0)
    box.BackgroundTransparency = 1
    box.Text = default and tostring(default) or ""
    box.PlaceholderText = placeholder or ""
    box.PlaceholderColor3 = Color3.fromRGB(90, 90, 90)
    box.TextColor3 = C.text
    box.Font = Enum.Font.GothamSemibold
    box.TextSize = 13
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.ZIndex = 2

    box.Focused:Connect(function()
        TweenService:Create(boxStroke, TW_Q, { Color = C.accent }):Play()
    end)
    box.FocusLost:Connect(function(enterPressed)
        TweenService:Create(boxStroke, TW_Q, { Color = C.stroke }):Play()
        if callback then callback(box.Text, enterPressed) end
    end)

    return row, box
end

function UI.Settings.slider(page, label, min, max, default, callback)
    local row = NewInstance("Frame", page)
    row.Size = UDim2.new(1, 0, 0, 60)
    row.BackgroundColor3 = C.bg
    row.BorderSizePixel = 0
    row.LayoutOrder = 999
    NewInstance("UICorner", row).CornerRadius = UDim.new(0, 10)
    local rs = NewInstance("UIStroke", row)
    rs.Color = C.stroke
    rs.Thickness = 1

    local lbl = NewInstance("TextLabel", row)
    lbl.Size = UDim2.new(1, -70, 0, 24)
    lbl.Position = UDim2.new(0, 14, 0, 8)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = C.text
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local valLbl = NewInstance("TextLabel", row)
    valLbl.Size = UDim2.new(0, 55, 0, 24)
    valLbl.Position = UDim2.new(1, -69, 0, 8)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(default)
    valLbl.TextColor3 = C.accent
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 13
    valLbl.TextXAlignment = Enum.TextXAlignment.Right

    local track = NewInstance("Frame", row)
    track.Size = UDim2.new(1, -28, 0, 4)
    track.Position = UDim2.new(0, 14, 0, 44)
    track.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    track.BorderSizePixel = 0
    NewInstance("UICorner", track).CornerRadius = UDim.new(1, 0)

    local pct = (default - min) / math.max(max - min, 1)
    local fill = NewInstance("Frame", track)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = C.accent
    fill.BorderSizePixel = 0
    NewInstance("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = NewInstance("Frame", track)
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new(pct, -6, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    knob.BorderSizePixel = 0
    NewInstance("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function applyX(x)
        local r = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * r)
        valLbl.Text = tostring(val)
        fill.Size = UDim2.new(r, 0, 1, 0)
        knob.Position = UDim2.new(r, -6, 0.5, -6)
        if callback then callback(val) end
    end

    local drag = false
    local hit = NewInstance("TextButton", track)
    hit.Size = UDim2.new(1, 0, 8, 0)
    hit.AnchorPoint = Vector2.new(0, 0.5)
    hit.Position = UDim2.new(0, 0, 0.5, 0)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.ZIndex = 3
    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; applyX(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            applyX(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)
    return row
end

function UI.Settings.color(page, label, default, callback)
    local row = NewInstance("Frame", page)
    row.Size = UDim2.new(1, 0, 0, 46)
    row.BackgroundColor3 = C.bg
    row.BorderSizePixel = 0
    row.LayoutOrder = 999
    NewInstance("UICorner", row).CornerRadius = UDim.new(0, 10)
    NewInstance("UIStroke", row).Color = C.stroke

    local lbl = NewInstance("TextLabel", row)
    lbl.Size = UDim2.new(1, -80, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = C.text
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local swatch = NewInstance("TextButton", row)
    swatch.Size = UDim2.new(0, 30, 0, 22)
    swatch.Position = UDim2.new(1, -44, 0.5, -11)
    swatch.BackgroundColor3 = default or Color3.fromRGB(255, 80, 80)
    swatch.Text = ""
    swatch.BorderSizePixel = 0
    NewInstance("UICorner", swatch).CornerRadius = UDim.new(0, 7)
    local _ss = NewInstance("UIStroke", swatch)
    _ss.Color = Color3.fromRGB(70, 70, 70)
    _ss.Thickness = 1
    local initColor = default or Color3.fromRGB(255, 80, 80)
    local curH, curS, curV = Color3.toHSV(initColor)

    local cp = NewInstance("Frame", sg)
    cp.Size = UDim2.new(0, 200, 0, 230)
    cp.AnchorPoint = Vector2.new(0.5, 0.5)
    cp.BackgroundColor3 = C.bg
    cp.BorderSizePixel = 0
    cp.Visible = false
    cp.ZIndex = 20
    cp.ClipsDescendants = true
    NewInstance("UICorner", cp).CornerRadius = UDim.new(0, 10)
    local _cps = NewInstance("UIStroke", cp)
    _cps.Color = C.stroke
    _cps.Thickness = 1

    local cpTitle = NewInstance("Frame", cp)
    cpTitle.Active = true
    cpTitle.Size = UDim2.new(1, 0, 0, 36)
    cpTitle.BackgroundColor3 = C.bg
    cpTitle.BorderSizePixel = 0
    cpTitle.ZIndex = 21
    NewInstance("UICorner", cpTitle).CornerRadius = UDim.new(0, 10)
    local _ctf = NewInstance("Frame", cpTitle)
    _ctf.Size = UDim2.new(1, 0, 0, 10)
    _ctf.Position = UDim2.new(0, 0, 1, -10)
    _ctf.BackgroundColor3 = C.bg
    _ctf.BorderSizePixel = 0
    _ctf.ZIndex = 21

    local cpTitleLbl = NewInstance("TextLabel", cpTitle)
    cpTitleLbl.Size = UDim2.new(1, 0, 1, 0)
    cpTitleLbl.BackgroundTransparency = 1
    cpTitleLbl.Text = "Color Picker"
    cpTitleLbl.TextColor3 = C.text
    cpTitleLbl.Font = Enum.Font.GothamBold
    cpTitleLbl.TextSize = 12
    cpTitleLbl.TextXAlignment = Enum.TextXAlignment.Center
    cpTitleLbl.ZIndex = 22

    local openCp, closeCp

    local cpClose = NewInstance("ImageButton", cpTitle)
    cpClose.Size = UDim2.new(0, 20, 0, 20)
    cpClose.Position = UDim2.new(1, -26, 0.5, -10)
    cpClose.BackgroundColor3 = C.bg
    cpClose.Image = "rbxassetid://110786993356448"
    cpClose.ImageColor3 = Color3.fromRGB(150, 150, 150)
    cpClose.BorderSizePixel = 0
    cpClose.ZIndex = 23
    cpClose.Activated:Connect(function() closeCp() end)

    makeDraggable(cp, cpTitle)

    local svArea = NewInstance("Frame", cp)
    svArea.Size = UDim2.new(1, -16, 0, 120)
    svArea.Position = UDim2.new(0, 8, 0, 44)
    svArea.BackgroundColor3 = Color3.fromHSV(curH, 1, 1)
    svArea.BorderSizePixel = 0
    svArea.ZIndex = 21
    NewInstance("UICorner", svArea).CornerRadius = UDim.new(0, 7)

    local satOverlay = NewInstance("Frame", svArea)
    satOverlay.Size = UDim2.new(1, 0, 1, 0)
    satOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    satOverlay.BorderSizePixel = 0
    satOverlay.ZIndex = 22
    NewInstance("UICorner", satOverlay).CornerRadius = UDim.new(0, 7)
    local satGrad = NewInstance("UIGradient", satOverlay)
    satGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    satGrad.Rotation = 0

    local valOverlay = NewInstance("Frame", svArea)
    valOverlay.Size = UDim2.new(1, 0, 1, 0)
    valOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    valOverlay.BorderSizePixel = 0
    valOverlay.ZIndex = 23
    NewInstance("UICorner", valOverlay).CornerRadius = UDim.new(0, 7)
    local valGrad = NewInstance("UIGradient", valOverlay)
    valGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    })
    valGrad.Rotation = 90

    local svKnob = NewInstance("Frame", svArea)
    svKnob.Size = UDim2.new(0, 10, 0, 10)
    svKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    svKnob.Position = UDim2.new(curS, 0, 1 - curV, 0)
    svKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    svKnob.BorderSizePixel = 0
    svKnob.ZIndex = 25
    NewInstance("UICorner", svKnob).CornerRadius = UDim.new(1, 0)
    local svKnobStroke = NewInstance("UIStroke", svKnob)
    svKnobStroke.Color = Color3.fromRGB(30, 30, 30)
    svKnobStroke.Thickness = 1.5

    local svHit = NewInstance("TextButton", svArea)
    svHit.Size = UDim2.new(1, 0, 1, 0)
    svHit.BackgroundTransparency = 1
    svHit.Text = ""
    svHit.ZIndex = 24

    local hueBar = NewInstance("Frame", cp)
    hueBar.Size = UDim2.new(1, -16, 0, 14)
    hueBar.Position = UDim2.new(0, 8, 0, 172)
    hueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    hueBar.BorderSizePixel = 0
    hueBar.ZIndex = 21
    NewInstance("UICorner", hueBar).CornerRadius = UDim.new(1, 0)
    local hueGrad = NewInstance("UIGradient", hueBar)
    hueGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
    })

    local hueKnob = NewInstance("Frame", hueBar)
    hueKnob.Size = UDim2.new(0, 8, 1, 4)
    hueKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    hueKnob.Position = UDim2.new(curH, 0, 0.5, 0)
    hueKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    hueKnob.BorderSizePixel = 0
    hueKnob.ZIndex = 23
    NewInstance("UICorner", hueKnob).CornerRadius = UDim.new(0, 3)
    local hueKnobStroke = NewInstance("UIStroke", hueKnob)
    hueKnobStroke.Color = Color3.fromRGB(80, 80, 80)
    hueKnobStroke.Thickness = 1.5

    local hueHit = NewInstance("TextButton", hueBar)
    hueHit.Size = UDim2.new(1, 0, 0, 20)
    hueHit.AnchorPoint = Vector2.new(0, 0.5)
    hueHit.Position = UDim2.new(0, 0, 0.5, 0)
    hueHit.BackgroundTransparency = 1
    hueHit.Text = ""
    hueHit.ZIndex = 22

    local previewRow = NewInstance("Frame", cp)
    previewRow.Size = UDim2.new(1, -16, 0, 28)
    previewRow.Position = UDim2.new(0, 8, 0, 194)
    previewRow.BackgroundTransparency = 1
    previewRow.BorderSizePixel = 0
    previewRow.ZIndex = 21

    local previewSwatch = NewInstance("Frame", previewRow)
    previewSwatch.Size = UDim2.new(0, 28, 1, 0)
    previewSwatch.BackgroundColor3 = initColor
    previewSwatch.BorderSizePixel = 0
    previewSwatch.ZIndex = 22
    NewInstance("UICorner", previewSwatch).CornerRadius = UDim.new(0, 6)

    local hexLabel = NewInstance("TextLabel", previewRow)
    hexLabel.Size = UDim2.new(1, -38, 1, 0)
    hexLabel.Position = UDim2.new(0, 38, 0, 0)
    hexLabel.BackgroundTransparency = 1
    hexLabel.TextColor3 = C.sub
    hexLabel.Font = Enum.Font.GothamSemibold
    hexLabel.TextSize = 11
    hexLabel.TextXAlignment = Enum.TextXAlignment.Left
    hexLabel.ZIndex = 22

    local cpContent = {cpTitle, svArea, hueBar, previewRow}
    local function setCpContentVisible(v)
        for _, obj in ipairs(cpContent) do
            obj.Visible = v
        end
    end
    setCpContentVisible(false)

    closeCp = function()
        if not cp.Visible then return end
        setCpContentVisible(false)
        TweenService:Create(cp, TW_IN, { Size = UDim2.new(0, 0, 0, 0) }):Play()
        task.delay(0.22, function() cp.Visible = false end)
    end

    openCp = function()
        cp.Visible = true
        cp.Size = UDim2.new(0, 0, 0, 0)
        setCpContentVisible(false)
        local tw = TweenService:Create(cp, TW_OUT, { Size = UDim2.new(0, 200, 0, 230) })
        tw.Completed:Once(function()
            setCpContentVisible(true)
        end)
        tw:Play()
    end

    local function colorToHex(c)
        return string.format("#%02X%02X%02X",
            math.floor(c.R * 255),
            math.floor(c.G * 255),
            math.floor(c.B * 255))
    end

    local function updateAll()
        local c = Color3.fromHSV(curH, curS, curV)
        svArea.BackgroundColor3 = Color3.fromHSV(curH, 1, 1)
        svKnob.Position = UDim2.new(curS, 0, 1 - curV, 0)
        hueKnob.Position = UDim2.new(curH, 0, 0.5, 0)
        previewSwatch.BackgroundColor3 = c
        swatch.BackgroundColor3 = c
        hexLabel.Text = colorToHex(c)
        if callback then callback(c) end
    end

    hexLabel.Text = colorToHex(initColor)

    local svDrag = false
    local svDragInput = nil
    local function applySV(x, y)
        local pos = svArea.AbsolutePosition
        local sz = svArea.AbsoluteSize
        curS = math.clamp((x - pos.X) / sz.X, 0, 1)
        curV = 1 - math.clamp((y - pos.Y) / sz.Y, 0, 1)
        updateAll()
    end
    svHit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            svDrag = true; svDragInput = i; applySV(i.Position.X, i.Position.Y)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if svDrag and i == svDragInput then
            applySV(i.Position.X, i.Position.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if svDrag and i == svDragInput then
            svDrag = false
            svDragInput = nil
        end
    end)

    local hueDrag = false
    local hueDragInput = nil
    local function applyHue(x)
        local pos = hueBar.AbsolutePosition
        local sz = hueBar.AbsoluteSize
        curH = math.clamp((x - pos.X) / sz.X, 0, 1)
        updateAll()
    end
    hueHit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            hueDrag = true; hueDragInput = i; applyHue(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if hueDrag and i == hueDragInput then
            applyHue(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if hueDrag and i == hueDragInput then
            hueDrag = false
            hueDragInput = nil
        end
    end)

    swatch.Activated:Connect(function()
        if cp.Visible then
            closeCp()
            return
        end
        local panelPos = panel.AbsolutePosition
        local panelSz = panel.AbsoluteSize
        cp.Position = UDim2.new(0,
            panelPos.X + panelSz.X / 2,
            0,
            panelPos.Y + panelSz.Y / 2)
        openCp()
    end)
    return row, swatch
end

function UI.Settings.open()
    if panel.Visible then return end
    panel.Visible = true
    panel.Size = UDim2.new(0, 420, 0, 0)
    setSettingsContentVisible(false)
    local tw = TweenService:Create(panel, TW_OUT, { Size = UDim2.new(0, 420, 0, 480) })
    tw.Completed:Once(function()
        setSettingsContentVisible(true)
    end)
    tw:Play()
end

do
	local pickerOpen = false

	local BTN_W = 148
	local BTN_GAP = 14
	local SIDE_PAD = 32

	local pickerSg = NewInstance("ScreenGui", getGuiParent())
	pickerSg.ResetOnSpawn = false
	pickerSg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	pickerSg.IgnoreGuiInset = true
	UI.registerScaleTarget(pickerSg)

	local overlay = NewInstance("Frame", pickerSg)
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.ZIndex = 20
	overlay.Visible = false

	local pickerFrame = NewInstance("Frame", overlay)
	pickerFrame.Size = UDim2.new(0, 0, 0, 0)
	pickerFrame.Position = UDim2.new(0.5, 0, 0.42, 0)
	pickerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	pickerFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
	pickerFrame.ClipsDescendants = true
	pickerFrame.ZIndex = 21
	NewInstance("UICorner", pickerFrame).CornerRadius = UDim.new(0, 16)

	local pfStroke = NewInstance("UIStroke", pickerFrame)
	pfStroke.Color = Color3.fromRGB(255, 255, 255)
	pfStroke.Thickness = 1.5

	local pfGrad = NewInstance("UIGradient", pickerFrame)
	pfGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 30)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 13, 18)),
	})
	pfGrad.Rotation = 90

	local titleLabel = NewInstance("TextLabel", pickerFrame)
	titleLabel.Size = UDim2.new(1, 0, 0, 36)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = ""
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.ZIndex = 22

	local closeBtn = NewInstance("TextButton", pickerFrame)
	closeBtn.Size = UDim2.new(0, 26, 0, 26)
	closeBtn.Position = UDim2.new(1, -32, 0, 5)
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.BackgroundColor3 = Color3.fromRGB(50, 15, 15)
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 13
	closeBtn.AutoButtonColor = false
	closeBtn.ZIndex = 26
	NewInstance("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

	local cTw = TweenInfo.new(0.12)
	closeBtn.MouseEnter:Connect(function()
		TweenService:Create(closeBtn, cTw, {BackgroundColor3 = Color3.fromRGB(90, 20, 20)}):Play()
	end)
	closeBtn.MouseLeave:Connect(function()
		TweenService:Create(closeBtn, cTw, {BackgroundColor3 = Color3.fromRGB(50, 15, 15)}):Play()
	end)

	local pickerDivider = NewInstance("Frame", pickerFrame)
	pickerDivider.Size = UDim2.new(1, -32, 0, 1)
	pickerDivider.Position = UDim2.new(0, 16, 0, 36)
	pickerDivider.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	pickerDivider.BorderSizePixel = 0
	pickerDivider.ZIndex = 22

	local btnContainer = NewInstance("Frame", pickerFrame)
	btnContainer.Size = UDim2.new(1, -32, 0, 70)
	btnContainer.Position = UDim2.new(0, 16, 0, 45)
	btnContainer.BackgroundTransparency = 1
	btnContainer.ZIndex = 22

	local bLayout = NewInstance("UIListLayout", btnContainer)
	bLayout.FillDirection = Enum.FillDirection.Horizontal
	bLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	bLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	bLayout.Padding = UDim.new(0, 14)

	local subtitleLabel = NewInstance("TextLabel", pickerFrame)
	subtitleLabel.Size = UDim2.new(1, 0, 0, 20)
	subtitleLabel.Position = UDim2.new(0, 0, 1, -22)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = ""
	subtitleLabel.TextColor3 = Color3.fromRGB(60, 60, 80)
	subtitleLabel.Font = Enum.Font.Gotham
	subtitleLabel.TextSize = 10
	subtitleLabel.ZIndex = 22

	local function makePickerBtn(parent, label, sub, accent)
		local btn = NewInstance("TextButton", parent)
		btn.Size = UDim2.new(0, 148, 0, 62)
		btn.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
		btn.AutoButtonColor = false
		btn.Text = ""
		btn.ZIndex = 23
		NewInstance("UICorner", btn).CornerRadius = UDim.new(0, 12)

		local stroke = NewInstance("UIStroke", btn)
		stroke.Color = accent
		stroke.Thickness = 1.2

		local lbl = NewInstance("TextLabel", btn)
		lbl.Size = UDim2.new(1, 0, 0, 28)
		lbl.Position = UDim2.new(0, 0, 0, 8)
		lbl.BackgroundTransparency = 1
		lbl.Text = label
		lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 12
		lbl.ZIndex = 24

		local subLbl = NewInstance("TextLabel", btn)
		subLbl.Size = UDim2.new(1, -16, 0, 18)
		subLbl.Position = UDim2.new(0, 8, 0, 34)
		subLbl.BackgroundTransparency = 1
		subLbl.Text = sub
		subLbl.TextColor3 = Color3.fromRGB(120, 120, 140)
		subLbl.Font = Enum.Font.Gotham
		subLbl.TextSize = 10
		subLbl.ZIndex = 24

		local bar = NewInstance("Frame", btn)
		bar.Size = UDim2.new(1, -24, 0, 2)
		bar.Position = UDim2.new(0, 12, 1, -10)
		bar.BackgroundColor3 = accent
		bar.BorderSizePixel = 0
		bar.ZIndex = 24
		NewInstance("UICorner", bar).CornerRadius = UDim.new(1, 0)

		local tw = TweenInfo.new(0.15)
		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, tw, {BackgroundColor3 = Color3.fromRGB(24, 24, 36)}):Play()
			TweenService:Create(stroke, tw, {Thickness = 2}):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, tw, {BackgroundColor3 = Color3.fromRGB(18, 18, 26)}):Play()
			TweenService:Create(stroke, tw, {Thickness = 1.2}):Play()
		end)

		return btn
	end

	function UI.Picker.show(pickerDef, callback)
		if pickerOpen then return end
		pickerOpen = true

		titleLabel.Text = pickerDef.title or ""
		subtitleLabel.Text = pickerDef.subtitle or ""

		for _, c in ipairs(btnContainer:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end

		local items = {}
		for _, def in ipairs(pickerDef.buttons) do
			local b = makePickerBtn(btnContainer, def.label, def.sub, def.accent)
			items[#items + 1] = {btn = b, value = def.value}
		end

		local n = #pickerDef.buttons
		local targetSize = UDim2.new(0, n * BTN_W + (n - 1) * BTN_GAP + SIDE_PAD, 0, 140)
		overlay.Visible = true
		pickerFrame.Size = UDim2.new(0, 0, 0, 0)
		TweenService:Create(overlay, TweenInfo.new(0.2), {BackgroundTransparency = 0.6}):Play()
		TweenService:Create(pickerFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = targetSize}):Play()

		local conns = {}
		local function pick(value)
			if not pickerOpen then return end
			pickerOpen = false
			for _, c in ipairs(conns) do c:Disconnect() end
			TweenService:Create(overlay, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
			TweenService:Create(pickerFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
			task.delay(0.28, function()
				overlay.Visible = false
				callback(value)
			end)
		end

		conns[#conns + 1] = closeBtn.Activated:Connect(function() pick(nil) end)
		for _, item in ipairs(items) do
			local v = item.value
			conns[#conns + 1] = item.btn.Activated:Connect(function() pick(v) end)
		end
	end
end

do
	local acGui = NewInstance("ScreenGui", getGuiParent())
	acGui.ResetOnSpawn = false
	acGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	acGui.Enabled = false
	UI.AutoClicker.gui = acGui
	UI.registerScaleTarget(acGui)

	local MainFrame = NewInstance("Frame", acGui)
	MainFrame.Size = UDim2.new(0, 180, 0, 195)
	MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	MainFrame.BorderSizePixel = 0
	MainFrame.Active = true
	MainFrame.ClipsDescendants = true
	UI.AutoClicker.frame = MainFrame

	NewInstance("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

	local MainFrame_Stroke = NewInstance("UIStroke", MainFrame)
	MainFrame_Stroke.Color = Color3.fromRGB(255, 255, 255)
	MainFrame_Stroke.Thickness = 2
	MainFrame_Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local TitleLabel = NewInstance("TextLabel", MainFrame)
	TitleLabel.Size = UDim2.new(1, 0, 0, 30)
	TitleLabel.Position = UDim2.new(0, 0, 0, 0)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Text = "AUTO CLICKER"
	TitleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	TitleLabel.Font = Enum.Font.GothamBold
	TitleLabel.TextSize = 14

	makeDraggable(MainFrame, TitleLabel)

	local CloseButton = NewInstance("TextButton", MainFrame)
	CloseButton.Size = UDim2.new(0, 30, 0, 30)
	CloseButton.Position = UDim2.new(1, -30, 0, 0)
	CloseButton.BackgroundTransparency = 1
	CloseButton.Text = "❌"
	CloseButton.TextSize = 11
	CloseButton.TextColor3 = Color3.fromRGB(200, 200, 200)
	CloseButton.Font = Enum.Font.GothamBold
	CloseButton.BorderSizePixel = 0
	UI.AutoClicker.closeButton = CloseButton

	local Divider = NewInstance("Frame", MainFrame)
	Divider.Size = UDim2.new(1, 0, 0, 1)
	Divider.Position = UDim2.new(0, 0, 0, 30)
	Divider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	Divider.BorderSizePixel = 0

	local ModeButton = NewInstance("TextButton", MainFrame)
	ModeButton.Size = UDim2.new(0.9, 0, 0, 25)
	ModeButton.Position = UDim2.new(0.05, 0, 0, 40)
	ModeButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	ModeButton.Text = "Mode: Mobile"
	ModeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	ModeButton.Font = Enum.Font.GothamSemibold
	ModeButton.TextSize = 13
	ModeButton.BorderSizePixel = 0
	UI.AutoClicker.modeButton = ModeButton

	NewInstance("UICorner", ModeButton).CornerRadius = UDim.new(0, 6)

	local ModeButton_Stroke = NewInstance("UIStroke", ModeButton)
	ModeButton_Stroke.Color = Color3.fromRGB(100, 100, 100)
	ModeButton_Stroke.Thickness = 1
	ModeButton_Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local DelayBox = NewInstance("TextBox", MainFrame)
	DelayBox.Size = UDim2.new(0.9, 0, 0, 25)
	DelayBox.Position = UDim2.new(0.05, 0, 0, 72)
	DelayBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	DelayBox.Text = "0.3"
	DelayBox.PlaceholderText = "Delay (0.3)"
	DelayBox.TextColor3 = Color3.fromRGB(220, 220, 220)
	DelayBox.Font = Enum.Font.GothamSemibold
	DelayBox.TextSize = 13
	DelayBox.BorderSizePixel = 0
	DelayBox.ClearTextOnFocus = false
	UI.AutoClicker.delayBox = DelayBox

	NewInstance("UICorner", DelayBox).CornerRadius = UDim.new(0, 6)

	local DelayBox_Stroke = NewInstance("UIStroke", DelayBox)
	DelayBox_Stroke.Color = Color3.fromRGB(60, 60, 80)
	DelayBox_Stroke.Thickness = 1
	DelayBox_Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local TargetButton = NewInstance("TextButton", MainFrame)
	TargetButton.Size = UDim2.new(0.9, 0, 0, 32)
	TargetButton.Position = UDim2.new(0.05, 0, 0, 105)
	TargetButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	TargetButton.Text = "Set Target"
	TargetButton.TextColor3 = Color3.fromRGB(220, 220, 220)
	TargetButton.Font = Enum.Font.GothamSemibold
	TargetButton.TextSize = 13
	TargetButton.BorderSizePixel = 0
	UI.AutoClicker.targetButton = TargetButton

	NewInstance("UICorner", TargetButton).CornerRadius = UDim.new(0, 6)

	local ToggleButton = NewInstance("TextButton", MainFrame)
	ToggleButton.Size = UDim2.new(0.9, 0, 0, 36)
	ToggleButton.Position = UDim2.new(0.05, 0, 0, 145)
	ToggleButton.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
	ToggleButton.Text = "OFF"
	ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	ToggleButton.Font = Enum.Font.GothamBold
	ToggleButton.TextSize = 18
	ToggleButton.BorderSizePixel = 0
	UI.AutoClicker.toggleButton = ToggleButton

	NewInstance("UICorner", ToggleButton).CornerRadius = UDim.new(0, 6)

	local ToggleButton_Stroke = NewInstance("UIStroke", ToggleButton)
	ToggleButton_Stroke.Color = Color3.fromRGB(220, 70, 70)
	ToggleButton_Stroke.Thickness = 1.5
	ToggleButton_Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UI.AutoClicker.toggleStroke = ToggleButton_Stroke

	local TargetDot = NewInstance("Frame", acGui)
	TargetDot.Size = UDim2.new(0, 14, 0, 14)
	TargetDot.BackgroundColor3 = Color3.fromRGB(80, 220, 120)
	TargetDot.AnchorPoint = Vector2.new(0.5, 0.5)
	TargetDot.Visible = false
	TargetDot.BorderSizePixel = 0
	UI.AutoClicker.targetDot = TargetDot

	NewInstance("UICorner", TargetDot).CornerRadius = UDim.new(0, 99)

	local TargetDot_Stroke = NewInstance("UIStroke", TargetDot)
	TargetDot_Stroke.Color = Color3.fromRGB(0, 0, 0)
	TargetDot_Stroke.Thickness = 1
	TargetDot_Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local AC_OPEN_SIZE = MainFrame.Size
	MainFrame.Visible = false

	local acContent = {TitleLabel, CloseButton, Divider, ModeButton, DelayBox, TargetButton, ToggleButton}
	local function setContentVisible(v)
		for _, obj in ipairs(acContent) do
			obj.Visible = v
		end
	end
	setContentVisible(false)

	function UI.AutoClicker.open()
		acGui.Enabled = true
		MainFrame.Visible = true
		MainFrame.Size = UDim2.new(0, 0, 0, 0)
		setContentVisible(false)
		local tw = TweenService:Create(MainFrame, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = AC_OPEN_SIZE})
		tw.Completed:Once(function()
			setContentVisible(true)
		end)
		tw:Play()
	end

	function UI.AutoClicker.close()
		setContentVisible(false)
		TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
		task.delay(0.22, function()
			MainFrame.Visible = false
			acGui.Enabled = false
		end)
	end
end

do
	local acOpen = false

	local acSg = NewInstance("ScreenGui", getGuiParent())
	acSg.ResetOnSpawn = false
	acSg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	acSg.IgnoreGuiInset = true
	UI.registerScaleTarget(acSg)

	local overlay = NewInstance("Frame", acSg)
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.ZIndex = 20
	overlay.Visible = false

	local acFrame = NewInstance("Frame", overlay)
	acFrame.Size = UDim2.new(0, 0, 0, 0)
	acFrame.Position = UDim2.new(0.5, 0, 0.42, 0)
	acFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	acFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
	acFrame.ClipsDescendants = true
	acFrame.ZIndex = 21
	NewInstance("UICorner", acFrame).CornerRadius = UDim.new(0, 16)

	local acStroke = NewInstance("UIStroke", acFrame)
	acStroke.Color = Color3.fromRGB(255, 255, 255)
	acStroke.Thickness = 1.5

	local acGrad = NewInstance("UIGradient", acFrame)
	acGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 30)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 13, 18)),
	})
	acGrad.Rotation = 90

	local acTitle = NewInstance("TextLabel", acFrame)
	acTitle.Size = UDim2.new(1, 0, 0, 36)
	acTitle.Position = UDim2.new(0, 0, 0, 0)
	acTitle.BackgroundTransparency = 1
	acTitle.Text = "Noname"
	acTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	acTitle.Font = Enum.Font.GothamBold
	acTitle.TextSize = 13
	acTitle.TextXAlignment = Enum.TextXAlignment.Center
	acTitle.ZIndex = 22

	local acClose = NewInstance("TextButton", acFrame)
	acClose.Size = UDim2.new(0, 26, 0, 26)
	acClose.Position = UDim2.new(1, -32, 0, 5)
	acClose.AnchorPoint = Vector2.new(1, 0)
	acClose.BackgroundColor3 = Color3.fromRGB(50, 15, 15)
	acClose.Text = "❌"
	acClose.TextColor3 = Color3.fromRGB(255, 80, 80)
	acClose.Font = Enum.Font.GothamBold
	acClose.TextSize = 11
	acClose.AutoButtonColor = false
	acClose.ZIndex = 26
	NewInstance("UICorner", acClose).CornerRadius = UDim.new(0, 8)

	local cTw = TweenInfo.new(0.12)
	acClose.MouseEnter:Connect(function()
		TweenService:Create(acClose, cTw, {BackgroundColor3 = Color3.fromRGB(90, 20, 20)}):Play()
	end)
	acClose.MouseLeave:Connect(function()
		TweenService:Create(acClose, cTw, {BackgroundColor3 = Color3.fromRGB(50, 15, 15)}):Play()
	end)

	local acDivider = NewInstance("Frame", acFrame)
	acDivider.Size = UDim2.new(1, -32, 0, 1)
	acDivider.Position = UDim2.new(0, 16, 0, 36)
	acDivider.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	acDivider.BorderSizePixel = 0
	acDivider.ZIndex = 22

	local acLine1 = NewInstance("TextLabel", acFrame)
	acLine1.Size = UDim2.new(1, -32, 0, 22)
	acLine1.Position = UDim2.new(0, 16, 0, 46)
	acLine1.BackgroundTransparency = 1
	acLine1.Text = ""
	acLine1.TextColor3 = Color3.fromRGB(200, 80, 80)
	acLine1.Font = Enum.Font.Gotham
	acLine1.TextSize = 11
	acLine1.TextXAlignment = Enum.TextXAlignment.Left
	acLine1.TextTruncate = Enum.TextTruncate.AtEnd
	acLine1.ZIndex = 22

	local acLine2 = NewInstance("TextLabel", acFrame)
	acLine2.Size = UDim2.new(1, -32, 0, 20)
	acLine2.Position = UDim2.new(0, 16, 0, 66)
	acLine2.BackgroundTransparency = 1
	acLine2.Text = ""
	acLine2.TextColor3 = Color3.fromRGB(160, 160, 180)
	acLine2.Font = Enum.Font.Gotham
	acLine2.TextSize = 11
	acLine2.TextXAlignment = Enum.TextXAlignment.Left
	acLine2.ZIndex = 22

	local acBox = NewInstance("TextBox", acFrame)
	acBox.Size = UDim2.new(1, -32, 0, 30)
	acBox.Position = UDim2.new(0, 16, 0, 94)
	acBox.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	acBox.Text = ""
	acBox.PlaceholderText = "type here..."
	acBox.PlaceholderColor3 = Color3.fromRGB(70, 70, 90)
	acBox.TextColor3 = Color3.fromRGB(220, 220, 220)
	acBox.Font = Enum.Font.GothamSemibold
	acBox.TextSize = 12
	acBox.TextXAlignment = Enum.TextXAlignment.Left
	acBox.ClearTextOnFocus = false
	acBox.BorderSizePixel = 0
	acBox.ZIndex = 22
	NewInstance("UICorner", acBox).CornerRadius = UDim.new(0, 8)

	local acBoxPad = NewInstance("UIPadding", acBox)
	acBoxPad.PaddingLeft = UDim.new(0, 10)

	local acBoxStroke = NewInstance("UIStroke", acBox)
	acBoxStroke.Color = Color3.fromRGB(50, 50, 70)
	acBoxStroke.Thickness = 1
	acBoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local acSubmit = NewInstance("TextButton", acFrame)
	acSubmit.Size = UDim2.new(1, -32, 0, 30)
	acSubmit.Position = UDim2.new(0, 16, 0, 132)
	acSubmit.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
	acSubmit.Text = "Submit"
	acSubmit.TextColor3 = Color3.fromRGB(200, 200, 255)
	acSubmit.Font = Enum.Font.GothamBold
	acSubmit.TextSize = 12
	acSubmit.AutoButtonColor = false
	acSubmit.BorderSizePixel = 0
	acSubmit.ZIndex = 22
	NewInstance("UICorner", acSubmit).CornerRadius = UDim.new(0, 8)

	local acSubmitStroke = NewInstance("UIStroke", acSubmit)
	acSubmitStroke.Color = Color3.fromRGB(60, 60, 100)
	acSubmitStroke.Thickness = 1
	acSubmitStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local sTw = TweenInfo.new(0.12)
	acSubmit.MouseEnter:Connect(function()
		TweenService:Create(acSubmit, sTw, {BackgroundColor3 = Color3.fromRGB(45, 45, 75)}):Play()
		TweenService:Create(acSubmitStroke, sTw, {Color = Color3.fromRGB(100, 100, 180)}):Play()
	end)
	acSubmit.MouseLeave:Connect(function()
		TweenService:Create(acSubmit, sTw, {BackgroundColor3 = Color3.fromRGB(30, 30, 50)}):Play()
		TweenService:Create(acSubmitStroke, sTw, {Color = Color3.fromRGB(60, 60, 100)}):Play()
	end)

	local OPEN_SIZE = UDim2.new(0, 320, 0, 178)

	function UI.Autocorrect.show(wrongCmd, suggestion, callback)
		if acOpen then return end
		acOpen = true

		acLine1.Text = 'command "' .. wrongCmd .. '" doesn\'t exist'
		acLine2.Text = 'did you mean "' .. suggestion .. '"?'
		acBox.Text = ""

		overlay.Visible = true
		acFrame.Size = UDim2.new(0, 0, 0, 0)
		TweenService:Create(overlay, TweenInfo.new(0.2), {BackgroundTransparency = 0.6}):Play()
		TweenService:Create(acFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = OPEN_SIZE}):Play()

		local conns = {}
		local function close(result)
			if not acOpen then return end
			acOpen = false
			for _, c in ipairs(conns) do c:Disconnect() end
			TweenService:Create(overlay, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
			TweenService:Create(acFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
			task.delay(0.28, function()
				overlay.Visible = false
				callback(result)
			end)
		end

		conns[#conns + 1] = acClose.Activated:Connect(function() close(nil) end)
		conns[#conns + 1] = acSubmit.Activated:Connect(function()
			close(acBox.Text)
		end)
		conns[#conns + 1] = acBox.FocusLost:Connect(function(enter)
			if enter then
				close(acBox.Text)
			end
		end)
	end
end

return UI
