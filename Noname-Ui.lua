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
local GuiService = cloneref(game:GetService("GuiService"))

local UI = {
	CommandBar = {},
	HUD = {},
	Capture = {},
	Picker = {},
	Autocorrect = {},
	AutoClicker = {},
	UiScaler = {},
}

UI.scaleTargets = {}
UI.excludeTargets = {}
UI.currentScale = 1

function UI.registerScaleTarget(guiRoot)
	local uiScale = NewInstance("UIScale")
	uiScale.Scale = UI.currentScale
	uiScale.Parent = guiRoot
	table.insert(UI.scaleTargets, uiScale)
	return uiScale
end

function UI.excludeFromScale(guiRoot)
	local counter = NewInstance("UIScale")
	counter.Scale = 1 / UI.currentScale
	counter.Parent = guiRoot
	table.insert(UI.excludeTargets, counter)
	return counter
end

function UI.getScale()
	return UI.currentScale
end

function UI.setScale(scale)
	scale = math.clamp(tonumber(scale) or 1, 0.5, 2.5)
	UI.currentScale = scale
	for _, uiScale in ipairs(UI.scaleTargets) do
		if uiScale and uiScale.Parent then
			uiScale.Scale = scale
		end
	end
	for _, counter in ipairs(UI.excludeTargets) do
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

	local connections = {}

	local dragInput = nil
	local dragStart = nil
	local startPos = nil
	local startAbsPos = nil
	local screenGui = nil

	connections[#connections + 1] = handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
			dragStart = input.Position
			startPos = frame.Position
			startAbsPos = frame.AbsolutePosition

			screenGui = frame
			while screenGui and not screenGui:IsA("ScreenGui") do
				screenGui = screenGui.Parent
			end
		end
	end)

	connections[#connections + 1] = handle.InputChanged:Connect(function(input)
		if dragInput and input == dragInput then
			local delta = input.Position - dragStart
			local desiredAbsX = startAbsPos.X + delta.X
			local desiredAbsY = startAbsPos.Y + delta.Y

			local viewportSize = workspace.CurrentCamera.ViewportSize
			local topLeftInset = GuiService:GetGuiInset()

			local minX, minY = 0, 0
			local maxX = viewportSize.X - frame.AbsoluteSize.X
			local maxY = viewportSize.Y - frame.AbsoluteSize.Y
			if not (screenGui and screenGui.IgnoreGuiInset) then
				minY = -topLeftInset.Y
			end

			local clampedAbsX = (minX > maxX) and minX or math.clamp(desiredAbsX, minX, maxX)
			local clampedAbsY = (minY > maxY) and minY or math.clamp(desiredAbsY, minY, maxY)

			frame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + (clampedAbsX - startAbsPos.X),
				startPos.Y.Scale,
				startPos.Y.Offset + (clampedAbsY - startAbsPos.Y)
			)
		end
	end)

	connections[#connections + 1] = UserInputService.InputEnded:Connect(function(input)
		if input == dragInput then
			dragInput = nil
		end
	end)

	return connections
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

function UI.buildValueRow(frame, value, placeholder, tw, onValueChanged)
	local valueLabel = NewInstance("TextLabel", frame)
	valueLabel.Size = UDim2.new(0, 36, 0, 44)
	valueLabel.Position = UDim2.new(1, -60, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(value)
	valueLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextSize = 11
	valueLabel.TextXAlignment = Enum.TextXAlignment.Center
	valueLabel.TextYAlignment = Enum.TextYAlignment.Center
	valueLabel.TextWrapped = false
	valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
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
	inputBox2.Text = tostring(value)
	inputBox2.TextColor3 = Color3.fromRGB(230, 230, 230)
	inputBox2.Font = Enum.Font.GothamBold
	inputBox2.TextSize = 15
	inputBox2.TextXAlignment = Enum.TextXAlignment.Center
	inputBox2.TextWrapped = false
	inputBox2.TextTruncate = Enum.TextTruncate.AtEnd
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
		valueLabel.Text = tostring(v)
		inputBox2.Text = tostring(v)
		onValueChanged(v)
	end)
	return toggleBtn, valueLabel, inputBox2, setExpanded, function() return expanded end
end

local buildValueRow = UI.buildValueRow

function UI.HUD.makeButton(label, startFn, yOff, placeholder, defaultValue)
	local hasValue = placeholder ~= nil and defaultValue ~= nil
	local value = defaultValue
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
			local toggleBtn, _, _, sExp, gExp = buildValueRow(frame, value, placeholder, tw, function(v)
				value = v
			end)
			setExpanded = sExp
			getExpanded = gExp
			local th = false
			toggleBtn.Activated:Connect(function()
				th = true
				setExpanded(not getExpanded())
			end)
			local clickArea = NewInstance("TextButton", frame)
			clickArea.Size = UDim2.new(1, -36, 0, 44)
			clickArea.BackgroundTransparency = 1
			clickArea.Text = ""
			clickArea.ZIndex = 2
			makeDraggable(frame, clickArea)
			clickArea.Activated:Connect(function()
				if th then th = false return end
				startFn(value)
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

function UI.HUD.makeToggle(startFn, stopFn, yOff, placeholder, defaultValue, labelOn, labelOff)
	local hasValue = placeholder ~= nil and defaultValue ~= nil
	local active = false
	local value = defaultValue
	local tw = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
	local frame, stroke, nameLabel, valueLabelRef, inputBoxRef
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
			local toggleBtn, sLabel, iBox, sExp, gExp = buildValueRow(frame, value, placeholder, tw, function(v)
				value = v
				if active then startFn(value) end
			end)
			valueLabelRef = sLabel
			inputBoxRef = iBox
			setExpanded = sExp
			getExpanded = gExp
			local th = false
			toggleBtn.Activated:Connect(function()
				th = true
				setExpanded(not getExpanded())
			end)
			local clickArea = NewInstance("TextButton", frame)
			clickArea.Size = UDim2.new(1, -36, 0, 44)
			clickArea.BackgroundTransparency = 1
			clickArea.Text = ""
			clickArea.ZIndex = 2
			makeDraggable(frame, clickArea)
			clickArea.Activated:Connect(function()
				if th then th = false return end
				active = not active
				local col = active and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(220, 70, 70)
				nameLabel.Text = active and labelOn or labelOff
				TweenService:Create(stroke, tw, {Color = col}):Play()
				TweenService:Create(nameLabel, tw, {TextColor3 = col}):Play()
				if active then startFn(value) else stopFn() end
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
				value = tonumber(spd) or spd
				if valueLabelRef then valueLabelRef.Text = tostring(value) end
				if inputBoxRef then inputBoxRef.Text = tostring(value) end
			end
			active = true
			frame.Visible = true
			stroke.Color = Color3.fromRGB(80, 220, 120)
			nameLabel.Text = labelOn
			nameLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
			startFn(hasValue and value or nil)
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
	local cmdRhText = NewInstance("TextLabel", cmdResizeHandle)
	cmdRhText.Size = UDim2.new(1, 0, 1, 0)
	cmdRhText.BackgroundTransparency = 1
	cmdRhText.Text = "↘"
	cmdRhText.TextColor3 = Color3.fromRGB(150, 150, 150)
	cmdRhText.TextTransparency = 0.15
	cmdRhText.Font = Enum.Font.GothamBold
	cmdRhText.TextSize = 14
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
	cmdListSearch.TextWrapped = false
	cmdListSearch.TextTruncate = Enum.TextTruncate.AtEnd
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
	local cmdThumbStroke = NewInstance("UIStroke", cmdScrollThumb)
	cmdThumbStroke.Color = Color3.fromRGB(255, 255, 255)
	cmdThumbStroke.Thickness = 1
	cmdThumbStroke.Transparency = 0.6

	local function updateCmdScrollThumb()
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

	cmdListScroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateCmdScrollThumb)
	cmdListScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(updateCmdScrollThumb)
	cmdListScroll:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateCmdScrollThumb)
	cmdScrollTrack:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCmdScrollThumb)

	local cmdThumbDrag = false
	local cmdThumbDragInput = nil
	local cmdThumbDragStartY = 0
	local cmdThumbStartOffset = 0
	cmdScrollThumb.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			cmdThumbDrag = true
			cmdThumbDragInput = input
			cmdThumbDragStartY = input.Position.Y
			cmdThumbStartOffset = cmdScrollThumb.Position.Y.Offset
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if cmdThumbDrag and input == cmdThumbDragInput then
			local trackH = cmdScrollTrack.AbsoluteSize.Y
			local thumbH = cmdScrollThumb.AbsoluteSize.Y
			local delta = input.Position.Y - cmdThumbDragStartY
			local newY = math.clamp(cmdThumbStartOffset + delta, 0, math.max(trackH - thumbH, 0))
			local range = trackH - thumbH
			local ratio = range > 0 and (newY / range) or 0

			local canvasH = cmdListScroll.AbsoluteCanvasSize.Y
			local winH = cmdListScroll.AbsoluteWindowSize.Y
			local maxScroll = math.max(canvasH - winH, 0)
			cmdListScroll.CanvasPosition = Vector2.new(0, ratio * maxScroll)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if cmdThumbDrag and input == cmdThumbDragInput then
			cmdThumbDrag = false
			cmdThumbDragInput = nil
		end
	end)

	task.defer(updateCmdScrollThumb)

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
	local rowPad = NewInstance("UIPadding", row)
	rowPad.PaddingLeft = UDim.new(0, 4)
	rowPad.PaddingRight = UDim.new(0, 4)

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
	valLbl.Text = string.format("%.1fx", UI.currentScale)
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

	local pct0 = pctFor(UI.currentScale)
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

	local function openManager(targetSize)
		cfg.guiOpenRef.v = true
		mainFrame.Visible = true
		mainFrame.Size = UDim2.new(0, 0, 0, 0)
		setManagerContentVisible(false)
		local tw = TweenService:Create(mainFrame, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = targetSize or UDim2.new(0, 396, 0, 220)})
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
		bx.TextWrapped = false
		bx.TextTruncate = Enum.TextTruncate.AtEnd
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

do
	local pickerOpen = false

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
		local targetSize = UDim2.new(0, n * 148 + (n - 1) * 14 + 32, 0, 140)
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
	DelayBox.TextWrapped = false
	DelayBox.TextTruncate = Enum.TextTruncate.AtEnd
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
	acLine2.TextTruncate = Enum.TextTruncate.AtEnd
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
	acBox.TextWrapped = false
	acBox.TextTruncate = Enum.TextTruncate.AtEnd
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

	function UI.Autocorrect.show(wrongCmd, suggestion, callback)
		if acOpen then return end
		acOpen = true

		acLine1.Text = 'command "' .. wrongCmd .. '" doesn\'t exist'
		acLine2.Text = 'did you mean "' .. suggestion .. '"?'
		acBox.Text = ""

		overlay.Visible = true
		acFrame.Size = UDim2.new(0, 0, 0, 0)
		TweenService:Create(overlay, TweenInfo.new(0.2), {BackgroundTransparency = 0.6}):Play()
		TweenService:Create(acFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 320, 0, 178)}):Play()

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
