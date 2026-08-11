local cloneref = type(cloneref) == "function" and cloneref or function(x) return x end
local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local GuiService = cloneref(game:GetService("GuiService"))
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local TextService = cloneref(game:GetService("TextService"))

local Library = {}

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Theme = {
	WindowBackground = Color3.fromRGB(16, 16, 18),
	TabBackground = Color3.fromRGB(22, 22, 26),
	ElementBackground = Color3.fromRGB(28, 28, 33),
	ElementBackgroundHover = Color3.fromRGB(37, 37, 44),
	TrackBackground = Color3.fromRGB(40, 40, 47),
	WindowStroke = Color3.fromRGB(255, 255, 255),
	ElementStroke = Color3.fromRGB(54, 54, 62),
	Accent = Color3.fromRGB(56, 142, 255),
	SwitchOff = Color3.fromRGB(50, 50, 58),
	TextPrimary = Color3.fromRGB(236, 236, 241),
}

local LocalPlayer = Players.LocalPlayer

local function NewInstance(className, parent)
	local inst = Instance.new(className)

	local chars = {}
	for i = 1, 128 do
		chars[i] = string.char(math.random(128, 255))
	end

	inst.Name = table.concat(chars)

	inst.Parent = parent or (function()
		local ok, res = pcall(function()
			return if type(gethui) == "function"
				then gethui()
				else cloneref(game:GetService("CoreGui"))
		end)

		return (ok and res) or LocalPlayer:WaitForChild("PlayerGui")
	end)()

	return inst
end

local function MakeCaseInsensitive(tbl)
	if type(tbl) ~= "table" then return tbl end
	local lookup = {}
	for key, value in pairs(tbl) do
		if type(key) == "string" and key ~= "__index" then
			lookup[key:lower()] = value
		end
	end
	local indexFn = function(_, key)
		if type(key) == "string" then return lookup[key:lower()] end
		return nil
	end
	tbl.__index = indexFn
	return setmetatable(tbl, { __index = indexFn })
end

local function safeloadstring(url, errMsg)
	local source
	do
		local attempts = {}

		if type(game.HttpGet) == "function" then
			table.insert(attempts, function() return game:HttpGet(url, true) end)
		end

		if type(game.HttpGetAsync) == "function" then
			table.insert(attempts, function() return game:HttpGetAsync(url) end)
		end

		local requestFn = (syn and syn.request) or (http and http.request) or http_request or request
		if type(requestFn) == "function" then
			table.insert(attempts, function()
				local res = requestFn({ Url = url, Method = "GET" })
				if type(res) == "table" then return res.Body or res.body end
				return nil
			end)
		end

		for _, attempt in ipairs(attempts) do
			local ok, result = pcall(attempt)
			if ok and type(result) == "string" and result ~= "" then
				source = result
				break
			end
		end
	end

	if not source then
		warn((errMsg or "safeloadstring") .. ": failed to fetch " .. url)
		return nil
	end

	local loader = loadstring or (getfenv and type(getfenv().loadstring) == "function" and getfenv().loadstring) or nil
	if type(loader) ~= "function" then
		warn((errMsg or "safeloadstring") .. ": loadstring is not available on this executor")
		return nil
	end

	local chunk, compileErr = loader(source)
	if not chunk then
		warn((errMsg or "safeloadstring") .. ": failed to compile - " .. tostring(compileErr))
		return nil
	end

	return chunk
end

local iconChunk = safeloadstring("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/Main-v2.lua", "NonameLibrary: Icons module")
if iconChunk then
	local ok, result = pcall(iconChunk)
	if ok then
		IconsLib = result
	end
end

Library.Icons = IconsLib

function Library:SetIconsType(iconType)
	if IconsLib then
		IconsLib.SetIconsType(iconType)
	end
end

local function GetIconData(iconString)
	if not IconsLib or type(iconString) ~= "string" or iconString == "" then
		return nil
	end

	local ok, result = pcall(function()
		return IconsLib.GetIcon(iconString)
	end)
	if not ok or result == nil then
		return nil
	end

	if type(result) == "table" then
		local info = result[2] or {}
		return {
			Image = result[1],
			ImageRectSize = info.ImageRectSize or Vector2.new(0, 0),
			ImageRectOffset = info.ImageRectPosition or Vector2.new(0, 0),
		}
	elseif type(result) == "string" then
		return {
			Image = result,
			ImageRectSize = Vector2.new(0, 0),
			ImageRectOffset = Vector2.new(0, 0),
		}
	end

	return nil
end

local function CreateIcon(parent, iconString, size, color)
	local data = GetIconData(iconString)
	if not data then
		return nil
	end

	local icon = NewInstance("ImageLabel", parent)
	icon.BackgroundTransparency = 1
	icon.Image = data.Image
	icon.ImageRectSize = data.ImageRectSize
	icon.ImageRectOffset = data.ImageRectOffset
	icon.ImageColor3 = color or Theme.TextPrimary
	icon.Size = size or UDim2.new(0, 16, 0, 16)
	icon.ZIndex = 2

	return icon
end

local function tween(instance, properties, duration, style, direction)
	local info = TweenInfo.new(
		duration or 0.25,
		style or Enum.EasingStyle.Quad,
		direction or Enum.EasingDirection.Out
	)
	local playingTween = TweenService:Create(instance, info, properties)
	playingTween:Play()
	return playingTween
end

local function fadeGroup(entries, visible, duration)
	local lastTween = nil
	for _, entry in ipairs(entries) do
		local target = 1
		if visible then
			target = entry.visible
		end
		lastTween = tween(entry.instance, {[entry.property] = target}, duration or 0.15)
	end
	return lastTween
end

local function fadeGroupSnap(entries, visible)
	for _, entry in ipairs(entries) do
		local target = 1
		if visible then
			target = entry.visible
		end
		entry.instance[entry.property] = target
	end
end

local function CreateLockUi(target)
	if not target then return nil end

	local lockOverlay = NewInstance("Frame", target)
	lockOverlay.Active = true
	lockOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	lockOverlay.BackgroundTransparency = 1
	lockOverlay.BorderSizePixel = 0
	lockOverlay.Position = UDim2.new(0, 0, 0, 0)
	lockOverlay.Size = UDim2.new(1, 0, 1, 0)
	lockOverlay.ZIndex = 50

	local lockOverlayCorner = NewInstance("UICorner", lockOverlay)
	lockOverlayCorner.CornerRadius = UDim.new(0, 6)

	local lockContent = NewInstance("Frame", lockOverlay)
	lockContent.AnchorPoint = Vector2.new(0.5, 0.5)
	lockContent.AutomaticSize = Enum.AutomaticSize.XY
	lockContent.BackgroundTransparency = 1
	lockContent.Position = UDim2.new(0.5, 0, 0.5, 0)
	lockContent.Size = UDim2.new(0, 0, 0, 0)
	lockContent.ZIndex = 51

	local lockLayout = NewInstance("UIListLayout", lockContent)
	lockLayout.FillDirection = Enum.FillDirection.Horizontal
	lockLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lockLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	lockLayout.Padding = UDim.new(0, 6)
	lockLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local lockIcon = CreateIcon(lockContent, "lucide:triangle-alert", UDim2.new(0, 28, 0, 28), Color3.fromRGB(255, 196, 0))
	if lockIcon then
		lockIcon.LayoutOrder = 2
		lockIcon.ImageTransparency = 1
		lockIcon.ZIndex = 52
	end

	local lockLabel = NewInstance("TextLabel", lockContent)
	lockLabel.Active = true
	lockLabel.AutomaticSize = Enum.AutomaticSize.XY
	lockLabel.BackgroundTransparency = 1
	lockLabel.LayoutOrder = 1
	lockLabel.Size = UDim2.new(0, 0, 0, 16)
	lockLabel.Font = Enum.Font.GothamBold
	lockLabel.Text = "Locked"
	lockLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	lockLabel.TextSize = 20
	lockLabel.TextTransparency = 1
	lockLabel.TextXAlignment = Enum.TextXAlignment.Center
	lockLabel.ZIndex = 51

	tween(lockOverlay, {BackgroundTransparency = 0.55}, 0.18)
	tween(lockLabel, {TextTransparency = 0}, 0.2)
	if lockIcon then
		tween(lockIcon, {ImageTransparency = 0}, 0.2)
	end

	return {
		Overlay = lockOverlay,
		Label = lockLabel,
		Icon = lockIcon,
	}
end

local function DestroyLockUi(lockUi)
	if not lockUi or not lockUi.Overlay then return end
	local overlay = lockUi.Overlay
	overlay.Active = false

	if lockUi.Label then
		tween(lockUi.Label, {TextTransparency = 1}, 0.14)
	end
	if lockUi.Icon then
		tween(lockUi.Icon, {ImageTransparency = 1}, 0.14)
	end

	local overlayTween = tween(overlay, {BackgroundTransparency = 1}, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	overlayTween.Completed:Once(function()
		if overlay and overlay.Parent then
			overlay:Destroy()
		end
	end)
end


local function setupCollapsible(arrow, clipper, getOpenHeight, defaultOpen)
	clipper.ClipsDescendants = true
	local open = defaultOpen
	local openSession = 0

	local function apply(animated)
		local targetHeight = 0
		if open then
			targetHeight = getOpenHeight()
		end
		local targetRotation = 0
		if open then
			targetRotation = 90
		end
		if animated then
			if open then
				clipper.Visible = true
			end
			local sizeTween = tween(clipper, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			tween(arrow, {Rotation = targetRotation}, 0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			if not open then
				sizeTween.Completed:Once(function()
					if not open then
						clipper.Visible = false
					end
				end)
			else
				openSession = openSession + 1
				local session = openSession
				task.spawn(function()
					local lastHeight = targetHeight
					for _ = 1, 10 do
						task.wait()
						if session ~= openSession or not open then
							return
						end
						local measuredHeight = getOpenHeight()
						if math.abs(measuredHeight - lastHeight) > 0.5 then
							tween(clipper, {Size = UDim2.new(1, 0, 0, measuredHeight)}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
							lastHeight = measuredHeight
						else
							break
						end
					end
				end)
			end
		else
			clipper.Size = UDim2.new(1, 0, 0, targetHeight)
			arrow.Rotation = targetRotation
			clipper.Visible = open
		end
	end

	apply(false)

	return function()
		open = not open
		apply(true)
	end, function()
		return open
	end
end

local function makeDraggable(handle, target)
	local connections = {}
	local dragging = false
	local dragStart = nil
	local startPos = nil
	local startAbsPos = nil
	local screenGui = nil

	local inputBeganConnection = handle.InputBegan:Connect(function(input)
		local isPrimary = input.UserInputType == Enum.UserInputType.MouseButton1
		local isTouch = input.UserInputType == Enum.UserInputType.Touch
		if isPrimary or isTouch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			startAbsPos = target.AbsolutePosition

			screenGui = target
			while screenGui and not screenGui:IsA("ScreenGui") do
				screenGui = screenGui.Parent
			end

			local changedConnection
			changedConnection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					changedConnection:Disconnect()
				end
			end)
		end
	end)
	table.insert(connections, inputBeganConnection)

	local inputChangedConnection = UserInputService.InputChanged:Connect(function(input)
		local isMouse = input.UserInputType == Enum.UserInputType.MouseMovement
		local isTouch = input.UserInputType == Enum.UserInputType.Touch
		if dragging and (isMouse or isTouch) then
			local delta = input.Position - dragStart
			local desiredAbsX = startAbsPos.X + delta.X
			local desiredAbsY = startAbsPos.Y + delta.Y

			local viewportSize = workspace.CurrentCamera.ViewportSize
			local topLeftInset = GuiService:GetGuiInset()

			local minX, minY = 0, 0
			local maxX, maxY = viewportSize.X, viewportSize.Y
			if not (screenGui and screenGui.IgnoreGuiInset) then
				minY = -topLeftInset.Y
			end

			local size = target.AbsoluteSize
			maxX = maxX - size.X
			maxY = maxY - size.Y

			local clampedAbsX = desiredAbsX
			if minX > maxX then
				clampedAbsX = minX
			else
				clampedAbsX = math.clamp(desiredAbsX, minX, maxX)
			end

			local clampedAbsY = desiredAbsY
			if minY > maxY then
				clampedAbsY = minY
			else
				clampedAbsY = math.clamp(desiredAbsY, minY, maxY)
			end

			target.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + (clampedAbsX - startAbsPos.X),
				startPos.Y.Scale,
				startPos.Y.Offset + (clampedAbsY - startAbsPos.Y)
			)
		end
	end)
	table.insert(connections, inputChangedConnection)

	return connections
end

function Library:Window(config)
	config = MakeCaseInsensitive(config)
	config = config or {}
	local title = config.Title or "Noname Library"

	local width = 420
	local bodyHeight = 420
	if typeof(config.Size) == "UDim2" then
		if config.Size.X.Offset > 0 then
			width = config.Size.X.Offset
		end
		if config.Size.Y.Offset > 0 then
			bodyHeight = config.Size.Y.Offset
		end
	end

	local resizable = config.Resizable == true
	local destroyable = config.Destroyable == true
	local minimizeButtonEnabled = config.MinimizeButton == true
	local minSize = Vector2.new(240, 44 + 60)
	local maxSize = Vector2.new(math.huge, math.huge)
	if resizable then
		if typeof(config.MinSize) == "Vector2" then
			minSize = config.MinSize
		end
		if typeof(config.MaxSize) == "Vector2" then
			maxSize = config.MaxSize
		end
   	minSize = Vector2.new(math.max(minSize.X, 60), math.max(minSize.Y, 44 + 20))
		maxSize = Vector2.new(math.max(maxSize.X, minSize.X), math.max(maxSize.Y, minSize.Y))
		width = math.clamp(width, minSize.X, maxSize.X)
		bodyHeight = math.clamp(bodyHeight, minSize.Y - 44, maxSize.Y - 44)
	end

	local screenGui = NewInstance("ScreenGui")
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 99999

	local mainFrame = NewInstance("Frame", screenGui)
	mainFrame.BackgroundColor3 = Theme.WindowBackground
	mainFrame.BorderSizePixel = 0
	mainFrame.Active = true
	mainFrame.AnchorPoint = Vector2.new(0, 0)
	mainFrame.Position = UDim2.new(0.5, -width / 2, 0.45, -(44 + bodyHeight) / 2)
	if resizable then
		mainFrame.Size = UDim2.new(0, 0, 0, 44)
		mainFrame.AutomaticSize = Enum.AutomaticSize.None
	else
		mainFrame.Size = UDim2.new(0, 0, 0, 0)
		mainFrame.AutomaticSize = Enum.AutomaticSize.Y
	end

	local mainFrameCorner = NewInstance("UICorner", mainFrame)
	mainFrameCorner.CornerRadius = UDim.new(0, 10)

	local mainFrameStroke = NewInstance("UIStroke", mainFrame)
	mainFrameStroke.Color = Theme.WindowStroke
	mainFrameStroke.Thickness = 1.5
	mainFrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local mainFrameListLayout = NewInstance("UIListLayout", mainFrame)
	mainFrameListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mainFrameListLayout.FillDirection = Enum.FillDirection.Vertical

	local titleBar = NewInstance("Frame", mainFrame)
	titleBar.BackgroundTransparency = 1
	titleBar.Active = true
	titleBar.Size = UDim2.new(1, 0, 0, 44)
	titleBar.LayoutOrder = 1

	local divider = NewInstance("Frame", titleBar)
	divider.BackgroundColor3 = Theme.ElementStroke
	divider.BorderSizePixel = 0
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Position = UDim2.new(0, 0, 1, -1)

	local titleIconSize = 18
	local titleIcon = CreateIcon(titleBar, config.Icon, UDim2.new(0, titleIconSize, 0, titleIconSize))
	local hasTitleIcon = titleIcon ~= nil
	if hasTitleIcon then
		titleIcon.AnchorPoint = Vector2.new(0, 0.5)
		titleIcon.Position = UDim2.new(0, 16, 0.5, 0)
	end
	local titleLeftPad = 16
	if hasTitleIcon then
		titleLeftPad = 16 + titleIconSize + 8
	end

	local titleLabel = NewInstance("TextLabel", titleBar)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position = UDim2.new(0, titleLeftPad, 0, 0)
	if destroyable then
		titleLabel.Size = UDim2.new(1, -(titleLeftPad + 78), 1, 0)
	else
		titleLabel.Size = UDim2.new(1, -(titleLeftPad + 44), 1, 0)
	end
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = title
	titleLabel.TextSize = 16
	titleLabel.TextColor3 = Theme.TextPrimary
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd

	local toggleButton = NewInstance("TextButton", titleBar)
	toggleButton.BackgroundTransparency = 1
	toggleButton.AutoButtonColor = false
	toggleButton.Size = UDim2.new(0, 32, 0, 32)
	toggleButton.AnchorPoint = Vector2.new(1, 0.5)
	if destroyable then
		toggleButton.Position = UDim2.new(1, -46, 0.5, 0)
	else
		toggleButton.Position = UDim2.new(1, -12, 0.5, 0)
	end
	toggleButton.Text = ""

	local toggleButtonCorner = NewInstance("UICorner", toggleButton)
	toggleButtonCorner.CornerRadius = UDim.new(0, 8)
	toggleButton.MouseEnter:Connect(function()
		tween(toggleButton, {
			BackgroundColor3 = Theme.ElementBackground,
			BackgroundTransparency = 0,
		}, 0.15)
	end)
	toggleButton.MouseLeave:Connect(function()
		tween(toggleButton, {
			BackgroundColor3 = Theme.WindowBackground,
			BackgroundTransparency = 1,
		}, 0.15)
	end)

	local windowArrow = NewInstance("TextLabel", toggleButton)
	windowArrow.BackgroundTransparency = 1
	windowArrow.Size = UDim2.new(0, 20, 0, 20)
	windowArrow.AnchorPoint = Vector2.new(0.5, 0.5)
	windowArrow.Position = UDim2.new(0.5, 0, 0.5, 0)
	windowArrow.Font = Enum.Font.GothamBold
	windowArrow.Text = ">"
	windowArrow.TextSize = 15
	windowArrow.TextColor3 = Theme.TextPrimary
	windowArrow.Rotation = 0

	local closeWindowButton
	if destroyable then
		closeWindowButton = NewInstance("TextButton", titleBar)
		closeWindowButton.BackgroundTransparency = 1
		closeWindowButton.AutoButtonColor = false
		closeWindowButton.Size = UDim2.new(0, 28, 0, 28)
		closeWindowButton.AnchorPoint = Vector2.new(1, 0.5)
		closeWindowButton.Position = UDim2.new(1, -12, 0.5, 0)
		closeWindowButton.Font = Enum.Font.GothamBold
		closeWindowButton.Text = "╳"
		closeWindowButton.TextSize = 14
		closeWindowButton.TextColor3 = Theme.TextPrimary

		local closeWindowButtonCorner = NewInstance("UICorner", closeWindowButton)
		closeWindowButtonCorner.CornerRadius = UDim.new(0, 8)

		closeWindowButton.MouseEnter:Connect(function()
			tween(closeWindowButton, {
				BackgroundColor3 = Theme.ElementBackground,
				BackgroundTransparency = 0,
			}, 0.15)
		end)
		closeWindowButton.MouseLeave:Connect(function()
			tween(closeWindowButton, {
				BackgroundColor3 = Theme.WindowBackground,
				BackgroundTransparency = 1,
			}, 0.15)
		end)
	end

	local titleBarFadeEntries = {
		{instance = divider, property = "BackgroundTransparency", visible = 0},
		{instance = titleLabel, property = "TextTransparency", visible = 0},
		{instance = windowArrow, property = "TextTransparency", visible = 0},
	}
	if hasTitleIcon then
		table.insert(titleBarFadeEntries, {instance = titleIcon, property = "ImageTransparency", visible = 0})
	end
	if closeWindowButton then
		table.insert(titleBarFadeEntries, {instance = closeWindowButton, property = "TextTransparency", visible = 0})
	end
	fadeGroupSnap(titleBarFadeEntries, false)

	local bodyClipper = NewInstance("Frame", mainFrame)
	bodyClipper.BackgroundTransparency = 1
	bodyClipper.ClipsDescendants = true
	bodyClipper.LayoutOrder = 2
	if resizable then
		bodyClipper.Size = UDim2.new(1, 0, 1, -44)
	else
		bodyClipper.Size = UDim2.new(1, 0, 0, 0)
	end

	local contentGroup = NewInstance("CanvasGroup", bodyClipper)
	contentGroup.BackgroundTransparency = 1
	contentGroup.BorderSizePixel = 0
	contentGroup.Size = UDim2.new(1, 0, 1, 0)
	contentGroup.GroupTransparency = 1

	local scrollFrame = NewInstance("ScrollingFrame", contentGroup)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.Size = UDim2.new(1, 0, 1, 0)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	scrollFrame.ScrollBarThickness = 4
	scrollFrame.ScrollBarImageColor3 = Theme.Accent

	local scrollFrameListLayout = NewInstance("UIListLayout", scrollFrame)
	scrollFrameListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	scrollFrameListLayout.FillDirection = Enum.FillDirection.Vertical
	scrollFrameListLayout.Padding = UDim.new(0, 8)

	local scrollFramePadding = NewInstance("UIPadding", scrollFrame)
	scrollFramePadding.PaddingTop = UDim.new(0, 10)
	scrollFramePadding.PaddingBottom = UDim.new(0, 10)
	scrollFramePadding.PaddingLeft = UDim.new(0, 10)
	scrollFramePadding.PaddingRight = UDim.new(0, 10)

	local window = setmetatable({}, Window)
	window.Instance = screenGui
	window.MainFrame = mainFrame
	window.connections = {}
	window.tabOrder = 0
	window.scrollFrame = scrollFrame

	local toggleWindowInner, isWindowOpen
	local resizeHandle

	if resizable then
		resizeHandle = NewInstance("Frame", bodyClipper)
		resizeHandle.BackgroundTransparency = 1
		resizeHandle.Active = true
		resizeHandle.AnchorPoint = Vector2.new(1, 1)
		resizeHandle.Position = UDim2.new(1, 0, 1, 0)
		resizeHandle.Size = UDim2.new(0, 20, 0, 20)
		resizeHandle.ZIndex = 5

		local windowOpen = true
		local lastBodyHeight = bodyHeight

		local function applyWindowState(animated)
			local targetHeight = 44
			local targetRotation = 0
			if windowOpen then
				targetHeight = 44 + lastBodyHeight
				targetRotation = 90
			end
			local currentWidth = mainFrame.Size.X.Offset
			if animated then
				if windowOpen then
					bodyClipper.Visible = true
				end
				local sizeTween = tween(mainFrame, {Size = UDim2.new(0, currentWidth, 0, targetHeight)}, 0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
				tween(windowArrow, {Rotation = targetRotation}, 0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
				if not windowOpen then
					sizeTween.Completed:Once(function()
						if not windowOpen then
							bodyClipper.Visible = false
						end
					end)
				end
			else
				mainFrame.Size = UDim2.new(0, currentWidth, 0, targetHeight)
				windowArrow.Rotation = targetRotation
				bodyClipper.Visible = windowOpen
			end
		end

		applyWindowState(false)

		toggleWindowInner = function()
			windowOpen = not windowOpen
			applyWindowState(true)
		end

		isWindowOpen = function()
			return windowOpen
		end

		local sizeChangedConnection = mainFrame:GetPropertyChangedSignal("Size"):Connect(function()
			if windowOpen then
				lastBodyHeight = math.max(mainFrame.Size.Y.Offset - 44, 0)
			end
		end)
		table.insert(window.connections, sizeChangedConnection)

		local resizeInput = nil
		local resizeStart = nil
		local startSize = nil

		local resizeInputBeganConnection = resizeHandle.InputBegan:Connect(function(input)
			local isPrimary = input.UserInputType == Enum.UserInputType.MouseButton1
			local isTouch = input.UserInputType == Enum.UserInputType.Touch
			if isPrimary or isTouch then
				resizeInput = input
				resizeStart = input.Position
				startSize = mainFrame.Size
				local changedConnection
				changedConnection = input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						if resizeInput == input then
							resizeInput = nil
							resizeStart = nil
							startSize = nil
						end
						changedConnection:Disconnect()
					end
				end)
			end
		end)
		table.insert(window.connections, resizeInputBeganConnection)

		local resizeInputChangedConnection = UserInputService.InputChanged:Connect(function(input)
			local isMouse = input.UserInputType == Enum.UserInputType.MouseMovement
			local isTouch = input.UserInputType == Enum.UserInputType.Touch
			if resizeInput and (isMouse or isTouch) then
				local delta = input.Position - resizeStart
				local newX = math.clamp(startSize.X.Offset + delta.X, minSize.X, maxSize.X)
				local newY = math.clamp(startSize.Y.Offset + delta.Y, minSize.Y, maxSize.Y)
				mainFrame.Size = UDim2.new(startSize.X.Scale, newX, startSize.Y.Scale, newY)
			end
		end)
		table.insert(window.connections, resizeInputChangedConnection)
	else
		toggleWindowInner, isWindowOpen = setupCollapsible(windowArrow, bodyClipper, function()
			return bodyHeight
		end, true)
	end

	local destroyed = false
	local function destroywindow()
		if destroyed then return end
		destroyed = true

		toggleButton.Active = false
		if closeWindowButton then
			closeWindowButton.Active = false
		end
		if resizeHandle then
			resizeHandle.Active = false
		end

		task.spawn(function()
			if isWindowOpen() then
				tween(contentGroup, {GroupTransparency = 1}, 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				task.wait(0.8)
				if not mainFrame.Parent then return end

				fadeGroup(titleBarFadeEntries, false, 0.8)
				local currentWidth = mainFrame.Size.X.Offset
				if resizable then
					tween(mainFrame, {Size = UDim2.new(0, currentWidth, 0, 44)}, 1.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
				else
					tween(bodyClipper, {Size = UDim2.new(1, 0, 0, 0)}, 1.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
				end
				task.wait(1.2)
				if not mainFrame.Parent then return end
			else
				fadeGroup(titleBarFadeEntries, false, 0.8)
				task.wait(0.8)
				if not mainFrame.Parent then return end
			end

			tween(mainFrame, {Size = UDim2.new(0, 0, 0, 44)}, 1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			task.wait(1)
			if not mainFrame.Parent then return end

			for _, connection in ipairs(window.connections) do
				connection:Disconnect()
			end
			window.connections = {}
			window.Instance:Destroy()
			if window.screenGui2 then
				window.screenGui2:Destroy()
			end
		end)
	end
	window.destroyAnimated = destroywindow

	if closeWindowButton then
		local destroyConfirmDialog = window:Dialog({
			Icon = "lucide:triangle-alert",
			Buttons = {
				{
					Text = "Cancel",
					Variant = "Secondary",
				},
				{
					Text = "Destroy",
					Variant = "Primary",
					Color = Color3.fromRGB(120, 40, 42),
					Callback = function()
						destroywindow()
					end,
				},
			},
		})

		closeWindowButton.Activated:Connect(function()
			destroyConfirmDialog:Open()
		end)
	end

	toggleButton.Activated:Connect(function()
		toggleWindowInner()
		divider.Visible = isWindowOpen()
	end)

	local dragConnections = makeDraggable(titleBar, mainFrame)
	for _, connection in ipairs(dragConnections) do
		table.insert(window.connections, connection)
	end

	if minimizeButtonEnabled then
		local minimizeButton = NewInstance("TextButton", screenGui)
		minimizeButton.BackgroundColor3 = Theme.ElementBackground
		minimizeButton.BorderSizePixel = 0
		minimizeButton.AutoButtonColor = false
		minimizeButton.Active = true
		minimizeButton.Size = UDim2.new(0, 70, 0, 35)
		minimizeButton.Position = UDim2.new(0, 5, 0, 0)
		minimizeButton.Font = Enum.Font.GothamBold
		minimizeButton.Text = "Toggle"
		minimizeButton.TextSize = 14
		minimizeButton.TextColor3 = Theme.TextPrimary

		local minimizeButtonCorner = NewInstance("UICorner", minimizeButton)
		minimizeButtonCorner.CornerRadius = UDim.new(0.2, 0)

		local minimizeButtonStroke = NewInstance("UIStroke", minimizeButton)
		minimizeButtonStroke.Color = Theme.WindowStroke
		minimizeButtonStroke.Thickness = 1.5
		minimizeButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		minimizeButton.MouseEnter:Connect(function()
			tween(minimizeButton, {BackgroundColor3 = Theme.ElementBackgroundHover}, 0.15)
		end)
		minimizeButton.MouseLeave:Connect(function()
			tween(minimizeButton, {BackgroundColor3 = Theme.ElementBackground}, 0.15)
		end)

		local everythingHidden = false
		minimizeButton.Activated:Connect(function()
			everythingHidden = not everythingHidden
			mainFrame.Visible = not everythingHidden
			titleBar.Visible = not everythingHidden
		end)

		local minimizeDragConnections = makeDraggable(minimizeButton, minimizeButton)
		for _, connection in ipairs(minimizeDragConnections) do
			table.insert(window.connections, connection)
		end
	end

	mainFrame.Size = UDim2.new(0, 0, 0, 44)
	if not resizable then
		bodyClipper.Visible = true
		bodyClipper.Size = UDim2.new(1, 0, 0, 0)
	end

	toggleButton.Active = false
	if closeWindowButton then
		closeWindowButton.Active = false
	end
	if resizeHandle then
		resizeHandle.Active = false
	end

	task.spawn(function()
		tween(mainFrame, {Size = UDim2.new(0, width, 0, 44)}, 1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.wait(1)
		if not mainFrame.Parent then return end
		task.wait(0.2)
		if not mainFrame.Parent then return end
		fadeGroup(titleBarFadeEntries, true, 0.8)
		if resizable then
			tween(mainFrame, {Size = UDim2.new(0, width, 0, 44 + bodyHeight)}, 1.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		else
			tween(bodyClipper, {Size = UDim2.new(1, 0, 0, bodyHeight)}, 1.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		end
		task.wait(1.2)
		if not mainFrame.Parent then return end
		toggleButton.Active = true
		if closeWindowButton then
			closeWindowButton.Active = true
		end
		if resizeHandle then
			resizeHandle.Active = true
		end
		tween(contentGroup, {GroupTransparency = 0}, 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end)

	return window
end

function Window:Tab(nameOrConfig)
	local tabConfig = nameOrConfig
	if type(tabConfig) ~= "table" then
		tabConfig = {Name = tabConfig}
	end
	tabConfig = MakeCaseInsensitive(tabConfig)
	local name = tabConfig.Name or "Tab"

	self.tabOrder = self.tabOrder + 1

	local tabFrame = NewInstance("Frame", self.scrollFrame)
	tabFrame.BackgroundColor3 = Theme.TabBackground
	tabFrame.BorderSizePixel = 0
	tabFrame.Size = UDim2.new(1, 0, 0, 0)
	tabFrame.AutomaticSize = Enum.AutomaticSize.Y
	tabFrame.LayoutOrder = self.tabOrder

	local tabFrameCorner = NewInstance("UICorner", tabFrame)
	tabFrameCorner.CornerRadius = UDim.new(0, 8)

	local tabFrameStroke = NewInstance("UIStroke", tabFrame)
	tabFrameStroke.Color = Theme.ElementStroke
	tabFrameStroke.Thickness = 1
	tabFrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local tabFrameListLayout = NewInstance("UIListLayout", tabFrame)
	tabFrameListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabFrameListLayout.FillDirection = Enum.FillDirection.Vertical

	local header = NewInstance("TextButton", tabFrame)
	header.BackgroundTransparency = 1
	header.AutoButtonColor = false
	header.Size = UDim2.new(1, 0, 0, 38)
	header.LayoutOrder = 1
	header.Text = ""

	local headerCorner = NewInstance("UICorner", header)
	headerCorner.CornerRadius = UDim.new(0, 8)

	header.MouseEnter:Connect(function()
		tween(header, {
			BackgroundColor3 = Theme.ElementBackground,
			BackgroundTransparency = 0,
		}, 0.15)
	end)
	header.MouseLeave:Connect(function()
		tween(header, {
			BackgroundColor3 = Theme.TabBackground,
			BackgroundTransparency = 1,
		}, 0.15)
	end)

	local tabIconSize = 16
	local tabIcon = CreateIcon(header, tabConfig.Icon, UDim2.new(0, tabIconSize, 0, tabIconSize))
	local hasTabIcon = tabIcon ~= nil
	if hasTabIcon then
		tabIcon.AnchorPoint = Vector2.new(0, 0.5)
		tabIcon.Position = UDim2.new(0, 14, 0.5, 0)
	end
	local tabLeftPad = 14
	if hasTabIcon then
		tabLeftPad = 14 + tabIconSize + 8
	end

	local tabNameLabel = NewInstance("TextLabel", header)
	tabNameLabel.BackgroundTransparency = 1
	tabNameLabel.Position = UDim2.new(0, tabLeftPad, 0, 0)
	tabNameLabel.Size = UDim2.new(1, -(tabLeftPad + 32), 1, 0)
	tabNameLabel.Font = Enum.Font.GothamSemibold
	tabNameLabel.Text = name
	tabNameLabel.TextSize = 14
	tabNameLabel.TextColor3 = Theme.TextPrimary
	tabNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	tabNameLabel.TextTruncate = Enum.TextTruncate.AtEnd

	local tabArrow = NewInstance("TextLabel", header)
	tabArrow.BackgroundTransparency = 1
	tabArrow.Size = UDim2.new(0, 20, 0, 20)
	tabArrow.AnchorPoint = Vector2.new(1, 0.5)
	tabArrow.Position = UDim2.new(1, -12, 0.5, 0)
	tabArrow.Font = Enum.Font.GothamBold
	tabArrow.Text = ">"
	tabArrow.TextSize = 15
	tabArrow.TextColor3 = Theme.TextPrimary
	tabArrow.Rotation = 0

	local contentClipper = NewInstance("Frame", tabFrame)
	contentClipper.BackgroundTransparency = 1
	contentClipper.Size = UDim2.new(1, 0, 0, 0)
	contentClipper.LayoutOrder = 2

	local contentHolder = NewInstance("Frame", contentClipper)
	contentHolder.BackgroundTransparency = 1
	contentHolder.Size = UDim2.new(1, 0, 0, 0)
	contentHolder.AutomaticSize = Enum.AutomaticSize.Y

	local contentHolderListLayout = NewInstance("UIListLayout", contentHolder)
	contentHolderListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentHolderListLayout.FillDirection = Enum.FillDirection.Vertical
	contentHolderListLayout.Padding = UDim.new(0, 8)

	local contentHolderPadding = NewInstance("UIPadding", contentHolder)
	contentHolderPadding.PaddingTop = UDim.new(0, 4)
	contentHolderPadding.PaddingBottom = UDim.new(0, 12)
	contentHolderPadding.PaddingLeft = UDim.new(0, 12)
	contentHolderPadding.PaddingRight = UDim.new(0, 12)

	local toggleTab = setupCollapsible(tabArrow, contentClipper, function()
		return contentHolder.AbsoluteSize.Y
	end, false)

	header.Activated:Connect(toggleTab)

	local newTab = setmetatable({}, Tab)
	newTab.window = self
	newTab.holder = contentHolder
	newTab.elementOrder = 0

	return newTab
end

local function CreateTooltip(self, guiObject, text)
	if text == nil or text == "" then
		return
	end

	if not self.tooltipFrame then
		local tooltip = NewInstance("Frame", self.Instance)
		tooltip.BackgroundColor3 = Theme.TabBackground
		tooltip.BackgroundTransparency = 1
		tooltip.BorderSizePixel = 0
		tooltip.AutomaticSize = Enum.AutomaticSize.XY
		tooltip.Size = UDim2.new(0, 0, 0, 0)
		tooltip.AnchorPoint = Vector2.new(0.5, 1)
		tooltip.Position = UDim2.new(0, -1000, 0, -1000)
		tooltip.Visible = false
		tooltip.ZIndex = 100

		local tooltipCorner = NewInstance("UICorner", tooltip)
		tooltipCorner.CornerRadius = UDim.new(0, 6)

		local tooltipStroke = NewInstance("UIStroke", tooltip)
		tooltipStroke.Color = Theme.ElementStroke
		tooltipStroke.Thickness = 1
		tooltipStroke.Transparency = 1
		tooltipStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local tooltipScale = NewInstance("UIScale", tooltip)
		tooltipScale.Scale = 1.2

		local tooltipPadding = NewInstance("UIPadding", tooltip)
		tooltipPadding.PaddingTop = UDim.new(0, 6)
		tooltipPadding.PaddingBottom = UDim.new(0, 6)
		tooltipPadding.PaddingLeft = UDim.new(0, 10)
		tooltipPadding.PaddingRight = UDim.new(0, 10)

		local tooltipLabel = NewInstance("TextLabel", tooltip)
		tooltipLabel.BackgroundTransparency = 1
		tooltipLabel.AutomaticSize = Enum.AutomaticSize.XY
		tooltipLabel.Size = UDim2.new(0, 0, 0, 0)
		tooltipLabel.Font = Enum.Font.GothamMedium
		tooltipLabel.Text = ""
		tooltipLabel.TextSize = 13
		tooltipLabel.TextColor3 = Theme.TextPrimary
		tooltipLabel.TextTransparency = 1

		self.tooltipFrame = tooltip
		self.tooltipLabel = tooltipLabel
		self.tooltipStroke = tooltipStroke
		self.tooltipScale = tooltipScale
		self.tooltipOwner = nil
		self.tooltipCloseToken = 0

		self.tooltipUpdatePosition = function(guiObject)
			local absPos = guiObject.AbsolutePosition
			local absSize = guiObject.AbsoluteSize
			local x = absPos.X + absSize.X / 2
			local y = absPos.Y - 50
			tooltip.Position = UDim2.new(0, x, 0, y)
		end
	end

	local label = self.tooltipLabel
	local tooltip = self.tooltipFrame
	local tooltipStroke = self.tooltipStroke

	local enterConnection = guiObject.MouseEnter:Connect(function()
		self.tooltipOwner = guiObject
		label.Text = text
		self.tooltipUpdatePosition(guiObject)

		self.tooltipCloseToken += 1
		tooltip.Visible = true
		tween(tooltip, {BackgroundTransparency = 0}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		tween(tooltipStroke, {Transparency = 0}, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		tween(label, {TextTransparency = 0}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	end)
	table.insert(self.connections, enterConnection)

	local leaveConnection = guiObject.MouseLeave:Connect(function()
		if self.tooltipOwner == guiObject then
			self.tooltipOwner = nil

			self.tooltipCloseToken += 1
			local token = self.tooltipCloseToken

			tween(tooltip, {BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			tween(tooltipStroke, {Transparency = 1}, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			tween(label, {TextTransparency = 1}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

			task.delay(0.35, function()
				if self.tooltipCloseToken == token then
					tooltip.Visible = false
				end
			end)
		end
	end)
	table.insert(self.connections, leaveConnection)

	local posConnection = guiObject:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
		if self.tooltipOwner == guiObject then
			self.tooltipUpdatePosition(guiObject)
		end
	end)
	table.insert(self.connections, posConnection)

	local sizeConnection = guiObject:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if self.tooltipOwner == guiObject then
			self.tooltipUpdatePosition(guiObject)
		end
	end)
	table.insert(self.connections, sizeConnection)
end

function Tab:Button(config)
	config = MakeCaseInsensitive(config)
	config = config or {}
	local callback = config.Callback or function() end
	local descText = config.Desc or config.Description
	local hasDesc = descText ~= nil and descText ~= ""

	self.elementOrder = self.elementOrder + 1

	local btn = NewInstance("TextButton", self.holder)
	btn.BackgroundColor3 = Theme.ElementBackground
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Size = UDim2.new(1, 0, 0, hasDesc and 44 or 36)
	btn.LayoutOrder = self.elementOrder
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 14
	btn.TextColor3 = Theme.TextPrimary
	btn.TextTruncate = Enum.TextTruncate.AtEnd
	btn.Text = ""

	local buttonCorner = NewInstance("UICorner", btn)
	buttonCorner.CornerRadius = UDim.new(0, 6)

	local buttonStroke = NewInstance("UIStroke", btn)
	buttonStroke.Color = Theme.ElementStroke
	buttonStroke.Thickness = 1
	buttonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local buttonIconSize = 16
	local buttonIcon = CreateIcon(btn, config.Icon, UDim2.new(0, buttonIconSize, 0, buttonIconSize))
	local hasIcon = buttonIcon ~= nil
	if hasIcon then
		buttonIcon.AnchorPoint = Vector2.new(0, 0.5)
		buttonIcon.Position = UDim2.new(0, 12, 0.5, 0)
	end

	local buttonLeftPad = 12
	local buttonXAlign = Enum.TextXAlignment.Center
	if hasIcon then
		buttonLeftPad = 12 + buttonIconSize + 8
		buttonXAlign = Enum.TextXAlignment.Left
	end

	local titleLabelRef
	local descLabelRef

	if hasDesc then
		local titleLabel = NewInstance("TextLabel", btn)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Position = UDim2.new(0, buttonLeftPad, 0, 6)
		titleLabel.Size = UDim2.new(1, -(buttonLeftPad + 12), 0, 18)
		titleLabel.Font = Enum.Font.GothamMedium
		titleLabel.Text = config.Name or "Button"
		titleLabel.TextSize = 14
		titleLabel.TextColor3 = Theme.TextPrimary
		titleLabel.TextXAlignment = buttonXAlign
		titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
		titleLabelRef = titleLabel

		local descLabel = NewInstance("TextLabel", btn)
		descLabel.BackgroundTransparency = 1
		descLabel.Position = UDim2.new(0, buttonLeftPad, 0, 24)
		descLabel.Size = UDim2.new(1, -(buttonLeftPad + 12), 0, 14)
		descLabel.Font = Enum.Font.Gotham
		descLabel.Text = descText
		descLabel.TextSize = 12
		descLabel.TextColor3 = Theme.TextPrimary
		descLabel.TextTransparency = 0.3
		descLabel.TextXAlignment = buttonXAlign
		descLabel.TextTruncate = Enum.TextTruncate.AtEnd
		descLabelRef = descLabel
	else
		local nameLabel = NewInstance("TextLabel", btn)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Position = UDim2.new(0, buttonLeftPad, 0, 0)
		nameLabel.Size = UDim2.new(1, -(buttonLeftPad + 12), 1, 0)
		nameLabel.Font = Enum.Font.GothamMedium
		nameLabel.Text = config.Name or "Button"
		nameLabel.TextSize = 14
		nameLabel.TextColor3 = Theme.TextPrimary
		nameLabel.TextXAlignment = buttonXAlign
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		titleLabelRef = nameLabel
	end

	CreateTooltip(self.window, btn, config.Tooltip)

	btn.MouseEnter:Connect(function()
		tween(btn, {
			BackgroundColor3 = Theme.ElementBackgroundHover,
			BackgroundTransparency = 0,
		}, 0.15)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, {
			BackgroundColor3 = Theme.ElementBackground,
			BackgroundTransparency = 0,
		}, 0.15)
	end)
	local buttonScale = NewInstance("UIScale", btn)
	buttonScale.Scale = 1
	btn.MouseButton1Down:Connect(function()
		tween(buttonScale, {Scale = 0.97}, 0.1)
	end)
	btn.MouseButton1Up:Connect(function()
		tween(buttonScale, {Scale = 1}, 0.12)
	end)
	btn.MouseLeave:Connect(function()
		tween(buttonScale, {Scale = 1}, 0.12)
	end)

	local locked = false
	local lockUi = nil
	local doubleClickEnabled = config.DoubleClick == true
	local originalTitleText = titleLabelRef.Text
	local originalTitleColor = titleLabelRef.TextColor3
	local confirmColor = Color3.fromRGB(255, 70, 70)
	local awaitingConfirm = false
	local confirmToken = 0

	btn.Activated:Connect(function()
		if locked then return end
		if doubleClickEnabled then
			if awaitingConfirm then
				awaitingConfirm = false
				titleLabelRef.Text = originalTitleText
				titleLabelRef.TextColor3 = originalTitleColor
				callback()
			else
				awaitingConfirm = true
				titleLabelRef.Text = "Sure?"
				titleLabelRef.TextColor3 = confirmColor
				confirmToken = confirmToken + 1
				local token = confirmToken
				task.delay(2, function()
					if token == confirmToken and awaitingConfirm then
						awaitingConfirm = false
						titleLabelRef.Text = originalTitleText
						titleLabelRef.TextColor3 = originalTitleColor
					end
				end)
			end
			return
		end
		callback()
	end)

	local Button = {}
	Button.Instance = btn

	function Button:SetTitle(text)
		originalTitleText = text
		if not awaitingConfirm then
			titleLabelRef.Text = text
		end
	end

	function Button:SetDesc(text)
		if descLabelRef then
			descLabelRef.Text = text
			return
		end

		btn.Size = UDim2.new(1, 0, 0, 44)
		titleLabelRef.Position = UDim2.new(0, buttonLeftPad, 0, 6)
		titleLabelRef.Size = UDim2.new(1, -(buttonLeftPad + 12), 0, 18)

		local descLabel = NewInstance("TextLabel", btn)
		descLabel.BackgroundTransparency = 1
		descLabel.Position = UDim2.new(0, buttonLeftPad, 0, 24)
		descLabel.Size = UDim2.new(1, -(buttonLeftPad + 12), 0, 14)
		descLabel.Font = Enum.Font.Gotham
		descLabel.Text = text
		descLabel.TextSize = 12
		descLabel.TextColor3 = Theme.TextPrimary
		descLabel.TextTransparency = 0.3
		descLabel.TextXAlignment = buttonXAlign
		descLabel.TextTruncate = Enum.TextTruncate.AtEnd
		descLabelRef = descLabel
	end

	function Button:Lock()
		if locked then return end
		locked = true
		btn.Active = false
		tween(btn, {BackgroundTransparency = 0.5}, 0.15)
		tween(buttonStroke, {Transparency = 0.5}, 0.15)
		tween(titleLabelRef, {TextTransparency = 0.5}, 0.15)
		if descLabelRef then
			tween(descLabelRef, {TextTransparency = 0.6}, 0.15)
		end
		lockUi = CreateLockUi(btn)
	end

	function Button:Unlock()
		if not locked then return end
		locked = false
		btn.Active = true
		tween(btn, {BackgroundTransparency = 0}, 0.15)
		tween(buttonStroke, {Transparency = 0}, 0.15)
		tween(titleLabelRef, {TextTransparency = 0}, 0.15)
		if descLabelRef then
			tween(descLabelRef, {TextTransparency = 0.3}, 0.15)
		end
		DestroyLockUi(lockUi)
		lockUi = nil
	end

	function Button:Destroy()
		btn:Destroy()
	end

	return MakeCaseInsensitive(Button)
end

function Tab:Toggle(config)
	config = MakeCaseInsensitive(config)
	config = config or {}
	local callback = config.Callback or function() end
	local state = config.Default or false
	local descText = config.Desc or config.Description
	local hasDesc = descText ~= nil and descText ~= ""

	self.elementOrder = self.elementOrder + 1

	local container = NewInstance("Frame", self.holder)
	container.BackgroundColor3 = Theme.ElementBackground
	container.BorderSizePixel = 0
	container.Size = UDim2.new(1, 0, 0, hasDesc and 44 or 36)
	container.LayoutOrder = self.elementOrder

	local containerCorner = NewInstance("UICorner", container)
	containerCorner.CornerRadius = UDim.new(0, 6)

	local containerStroke = NewInstance("UIStroke", container)
	containerStroke.Color = Theme.ElementStroke
	containerStroke.Thickness = 1
	containerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local nameLabel = NewInstance("TextLabel", container)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.Text = config.Name or "Toggle"
	nameLabel.TextSize = 14
	nameLabel.TextColor3 = Theme.TextPrimary
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	if hasDesc then
		nameLabel.Position = UDim2.new(0, 12, 0, 6)
		nameLabel.Size = UDim2.new(1, -70, 0, 18)
	else
		nameLabel.Position = UDim2.new(0, 12, 0, 0)
		nameLabel.Size = UDim2.new(1, -70, 1, 0)
	end

	local descLabel
	if hasDesc then
		descLabel = NewInstance("TextLabel", container)
		descLabel.BackgroundTransparency = 1
		descLabel.Position = UDim2.new(0, 12, 0, 24)
		descLabel.Size = UDim2.new(1, -70, 0, 14)
		descLabel.Font = Enum.Font.Gotham
		descLabel.Text = descText
		descLabel.TextSize = 12
		descLabel.TextColor3 = Theme.TextPrimary
		descLabel.TextTransparency = 0.3
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextTruncate = Enum.TextTruncate.AtEnd
	end

	local locked = false
	local lockUi = nil

	CreateTooltip(self.window, container, config.Tooltip)

	local switch = NewInstance("TextButton", container)
	switch.BackgroundColor3 = Theme.SwitchOff
	switch.BorderSizePixel = 0
	switch.AutoButtonColor = false
	switch.Size = UDim2.new(0, 42, 0, 22)
	switch.AnchorPoint = Vector2.new(1, 0.5)
	switch.Position = UDim2.new(1, -12, 0.5, 0)
	switch.Text = ""

	local switchCorner = NewInstance("UICorner", switch)
	switchCorner.CornerRadius = UDim.new(0, 11)

	local knob = NewInstance("Frame", switch)
	knob.BackgroundColor3 = Theme.TextPrimary
	knob.BorderSizePixel = 0
	knob.Size = UDim2.new(0, 18, 0, 18)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.Position = UDim2.new(0, 2, 0.5, 0)

	local knobCorner = NewInstance("UICorner", knob)
	knobCorner.CornerRadius = UDim.new(0, 9)

	local knobIcon = CreateIcon(knob, config.Icon, UDim2.new(0, 12, 0, 12), Theme.WindowBackground)
	if knobIcon then
		knobIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		knobIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
		knobIcon.ImageTransparency = 1
	end

	local function render(animated)
		local knobPosition = UDim2.new(0, 2, 0.5, 0)
		local switchColor = Theme.SwitchOff
		local iconTransparency = 1
		if state then
			knobPosition = UDim2.new(1, -20, 0.5, 0)
			switchColor = Theme.Accent
			iconTransparency = 0
		end
		if animated then
			tween(knob, {Position = knobPosition}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			tween(switch, {BackgroundColor3 = switchColor}, 0.2)
			if knobIcon then
				tween(knobIcon, {ImageTransparency = iconTransparency}, 0.15)
			end
		else
			knob.Position = knobPosition
			switch.BackgroundColor3 = switchColor
			if knobIcon then
				knobIcon.ImageTransparency = iconTransparency
			end
		end
	end

	render(false)

	switch.Activated:Connect(function()
		if locked then return end
		state = not state
		render(true)
		callback(state)
	end)

	local Toggle = {}
	Toggle.Instance = container

	function Toggle:Get()
		return state
	end

	function Toggle:Set(value)
		state = value == true
		render(true)
		callback(state)
	end

	function Toggle:SetTitle(text)
		nameLabel.Text = text
	end

	function Toggle:SetDesc(text)
		if descLabel then
			descLabel.Text = text
			return
		end

		container.Size = UDim2.new(1, 0, 0, 44)
		nameLabel.Position = UDim2.new(0, 12, 0, 6)
		nameLabel.Size = UDim2.new(1, -70, 0, 18)

		descLabel = NewInstance("TextLabel", container)
		descLabel.BackgroundTransparency = 1
		descLabel.Position = UDim2.new(0, 12, 0, 24)
		descLabel.Size = UDim2.new(1, -70, 0, 14)
		descLabel.Font = Enum.Font.Gotham
		descLabel.Text = text
		descLabel.TextSize = 12
		descLabel.TextColor3 = Theme.TextPrimary
		descLabel.TextTransparency = 0.3
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextTruncate = Enum.TextTruncate.AtEnd
	end

	function Toggle:Lock()
		if locked then return end
		locked = true
		switch.Active = false
		tween(container, {BackgroundTransparency = 0.5}, 0.15)
		tween(containerStroke, {Transparency = 0.5}, 0.15)
		tween(nameLabel, {TextTransparency = 0.5}, 0.15)
		if descLabel then
			tween(descLabel, {TextTransparency = 0.6}, 0.15)
		end
		lockUi = CreateLockUi(container)
	end

	function Toggle:Unlock()
		if not locked then return end
		locked = false
		switch.Active = true
		tween(container, {BackgroundTransparency = 0}, 0.15)
		tween(containerStroke, {Transparency = 0}, 0.15)
		tween(nameLabel, {TextTransparency = 0}, 0.15)
		if descLabel then
			tween(descLabel, {TextTransparency = 0.3}, 0.15)
		end
		DestroyLockUi(lockUi)
		lockUi = nil
	end

	function Toggle:Destroy()
		container:Destroy()
	end

	return MakeCaseInsensitive(Toggle)
end

function Tab:Slider(config)
	config = MakeCaseInsensitive(config)
	config = config or {}
	local callback = config.Callback or function() end
	local minValue = config.Min or 0
	local maxValue = config.Max or 100
	local increment = config.Increment or 1
	if increment <= 0 then
		increment = 1
	end
	local value = math.clamp(config.Default or minValue, minValue, maxValue)
	local descText = config.Desc or config.Description
	local hasDesc = descText ~= nil and descText ~= ""

	self.elementOrder = self.elementOrder + 1

	local container = NewInstance("Frame", self.holder)
	container.BackgroundColor3 = Theme.ElementBackground
	container.BorderSizePixel = 0
	container.Size = UDim2.new(1, 0, 0, 54)
	container.LayoutOrder = self.elementOrder

	local containerCorner = NewInstance("UICorner", container)
	containerCorner.CornerRadius = UDim.new(0, 6)

	local containerStroke = NewInstance("UIStroke", container)
	containerStroke.Color = Theme.ElementStroke
	containerStroke.Thickness = 1
	containerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local nameLabel = NewInstance("TextLabel", container)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.new(0, 12, 0, 4)
	nameLabel.Size = UDim2.new(1, -24, 0, 18)
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.Text = config.Name or "Slider"
	nameLabel.TextSize = 14
	nameLabel.TextColor3 = Theme.TextPrimary
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

	local descLabel
	if hasDesc then
		descLabel = NewInstance("TextLabel", container)
		descLabel.BackgroundTransparency = 1
		descLabel.Position = UDim2.new(0, 12, 0, 18)
		descLabel.Size = UDim2.new(1, -24, 0, 14)
		descLabel.Font = Enum.Font.Gotham
		descLabel.Text = descText
		descLabel.TextSize = 12
		descLabel.TextColor3 = Theme.TextPrimary
		descLabel.TextTransparency = 0.3
		descLabel.TextXAlignment = Enum.TextXAlignment.Center
		descLabel.TextTruncate = Enum.TextTruncate.AtEnd
	end

	local locked = false
	local lockUi = nil

	CreateTooltip(self.window, container, config.Tooltip)

	local valueLabel = NewInstance("TextLabel", container)
	valueLabel.BackgroundTransparency = 1
	valueLabel.ZIndex = 2
	valueLabel.Position = UDim2.new(1, -68, 0, 6)
	valueLabel.Size = UDim2.new(0, 56, 0, 18)
	valueLabel.Font = Enum.Font.Gotham
	if value == math.floor(value) then
		valueLabel.Text = tostring(math.floor(value))
	else
		valueLabel.Text = string.format("%.2f", value)
	end
	valueLabel.TextSize = 13
	valueLabel.TextColor3 = Theme.Accent
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.TextTruncate = Enum.TextTruncate.AtEnd

	local track = NewInstance("Frame", container)
	track.BackgroundColor3 = Theme.TrackBackground
	track.BorderSizePixel = 0
	track.Active = true
	track.Position = UDim2.new(0, 12, 1, -18)
	track.Size = UDim2.new(1, -24, 0, 6)

	local trackCorner = NewInstance("UICorner", track)
	trackCorner.CornerRadius = UDim.new(0, 3)

	local fill = NewInstance("Frame", track)
	fill.BackgroundColor3 = Theme.Accent
	fill.BorderSizePixel = 0
	fill.Size = UDim2.new(0, 0, 1, 0)

	local fillCorner = NewInstance("UICorner", fill)
	fillCorner.CornerRadius = UDim.new(0, 3)

	local iconsConfig = config.Icons
	local fromIconString = iconsConfig and iconsConfig.From
	local toIconString = iconsConfig and iconsConfig.To
	local hasSliderIcons = fromIconString ~= nil or toIconString ~= nil

	local knob = NewInstance("Frame", track)
	knob.BackgroundColor3 = Theme.TextPrimary
	knob.BorderSizePixel = 0
	if hasSliderIcons then
		knob.Size = UDim2.new(0, 18, 0, 18)
	else
		knob.Size = UDim2.new(0, 14, 0, 14)
	end
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(0, 0, 0.5, 0)
	knob.ZIndex = 2

	local knobCorner = NewInstance("UICorner", knob)
	knobCorner.CornerRadius = UDim.new(0.5, 0)

	local fromIcon = CreateIcon(knob, fromIconString, UDim2.new(0, 12, 0, 12), Theme.WindowBackground)
	if fromIcon then
		fromIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		fromIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
		fromIcon.ZIndex = 3
	end

	local toIcon = CreateIcon(knob, toIconString, UDim2.new(0, 12, 0, 12), Theme.WindowBackground)
	if toIcon then
		toIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		toIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
		toIcon.ZIndex = 3
	end

	local function render(newValue)
		value = newValue
		local fraction = (value - minValue) / (maxValue - minValue)
		fill.Size = UDim2.new(fraction, 0, 1, 0)
		knob.Position = UDim2.new(fraction, 0, 0.5, 0)
		if fromIcon then
			fromIcon.ImageTransparency = fraction
		end
		if toIcon then
			toIcon.ImageTransparency = 1 - fraction
		end
		if value == math.floor(value) then
			valueLabel.Text = tostring(math.floor(value))
		else
			valueLabel.Text = string.format("%.2f", value)
		end
	end

	render(value)

	local dragging = false

	local function updateFromPosition(xPosition)
		local relative = xPosition - track.AbsolutePosition.X
		local fraction = math.clamp(relative / track.AbsoluteSize.X, 0, 1)
		local rawValue = minValue + fraction * (maxValue - minValue)
		local steps = math.floor(((rawValue - minValue) / increment) + 0.5)
		local steppedValue = math.clamp(minValue + steps * increment, minValue, maxValue)
		if steppedValue ~= value then
			render(steppedValue)
			callback(steppedValue)
		end
	end

	local inputBeganConnection = track.InputBegan:Connect(function(input)
		if locked then return end
		local isPrimary = input.UserInputType == Enum.UserInputType.MouseButton1
		local isTouch = input.UserInputType == Enum.UserInputType.Touch
		if isPrimary or isTouch then
			dragging = true
			updateFromPosition(input.Position.X)
			local changedConnection
			changedConnection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					changedConnection:Disconnect()
				end
			end)
		end
	end)
	table.insert(self.window.connections, inputBeganConnection)

	local inputChangedConnection = UserInputService.InputChanged:Connect(function(input)
		local isMouse = input.UserInputType == Enum.UserInputType.MouseMovement
		local isTouch = input.UserInputType == Enum.UserInputType.Touch
		if dragging and (isMouse or isTouch) then
			updateFromPosition(input.Position.X)
		end
	end)
	table.insert(self.window.connections, inputChangedConnection)

	local Slider = {}
	Slider.Instance = container

	function Slider:Get()
		return value
	end

	function Slider:Set(newValue)
		local clamped = math.clamp(newValue, minValue, maxValue)
		render(clamped)
		callback(clamped)
	end

	function Slider:SetTitle(text)
		nameLabel.Text = text
	end

	function Slider:SetDesc(text)
		if descLabel then
			descLabel.Text = text
			return
		end

		descLabel = NewInstance("TextLabel", container)
		descLabel.BackgroundTransparency = 1
		descLabel.Position = UDim2.new(0, 12, 0, 18)
		descLabel.Size = UDim2.new(1, -24, 0, 14)
		descLabel.Font = Enum.Font.Gotham
		descLabel.Text = text
		descLabel.TextSize = 12
		descLabel.TextColor3 = Theme.TextPrimary
		descLabel.TextTransparency = 0.3
		descLabel.TextXAlignment = Enum.TextXAlignment.Center
		descLabel.TextTruncate = Enum.TextTruncate.AtEnd
	end

	function Slider:Lock()
		if locked then return end
		locked = true
		track.Active = false
		tween(container, {BackgroundTransparency = 0.5}, 0.15)
		tween(containerStroke, {Transparency = 0.5}, 0.15)
		tween(nameLabel, {TextTransparency = 0.5}, 0.15)
		tween(valueLabel, {TextTransparency = 0.5}, 0.15)
		if descLabel then
			tween(descLabel, {TextTransparency = 0.6}, 0.15)
		end
		lockUi = CreateLockUi(container)
	end

	function Slider:Unlock()
		if not locked then return end
		locked = false
		track.Active = true
		tween(container, {BackgroundTransparency = 0}, 0.15)
		tween(containerStroke, {Transparency = 0}, 0.15)
		tween(nameLabel, {TextTransparency = 0}, 0.15)
		tween(valueLabel, {TextTransparency = 0}, 0.15)
		if descLabel then
			tween(descLabel, {TextTransparency = 0.3}, 0.15)
		end
		DestroyLockUi(lockUi)
		lockUi = nil
	end

	function Slider:Destroy()
		inputBeganConnection:Disconnect()
		inputChangedConnection:Disconnect()
		container:Destroy()
	end

	return MakeCaseInsensitive(Slider)
end

function Tab:ColorPicker(config)
	config = MakeCaseInsensitive(config)
	config = config or {}
	local callback = config.Callback or function() end
	local color = config.Default or Color3.fromRGB(255, 255, 255)
	local transparencyEnabled = config.Transparency == true
	local transparency = 0
	local descText = config.Desc or config.Description
	local hasDesc = descText ~= nil and descText ~= ""

	self.elementOrder = self.elementOrder + 1

	local container = NewInstance("Frame", self.holder)
	container.BackgroundColor3 = Theme.ElementBackground
	container.BorderSizePixel = 0
	container.Size = UDim2.new(1, 0, 0, hasDesc and 44 or 36)
	container.LayoutOrder = self.elementOrder

	local containerCorner = NewInstance("UICorner", container)
	containerCorner.CornerRadius = UDim.new(0, 6)

	local containerStroke = NewInstance("UIStroke", container)
	containerStroke.Color = Theme.ElementStroke
	containerStroke.Thickness = 1
	containerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local nameLabel = NewInstance("TextLabel", container)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.Text = config.Name or "Color Picker"
	nameLabel.TextSize = 14
	nameLabel.TextColor3 = Theme.TextPrimary
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	if hasDesc then
		nameLabel.Position = UDim2.new(0, 12, 0, 6)
		nameLabel.Size = UDim2.new(1, -60, 0, 18)
	else
		nameLabel.Position = UDim2.new(0, 12, 0, 0)
		nameLabel.Size = UDim2.new(1, -60, 1, 0)
	end

	local descLabel
	if hasDesc then
		descLabel = NewInstance("TextLabel", container)
		descLabel.BackgroundTransparency = 1
		descLabel.Position = UDim2.new(0, 12, 0, 24)
		descLabel.Size = UDim2.new(1, -60, 0, 14)
		descLabel.Font = Enum.Font.Gotham
		descLabel.Text = descText
		descLabel.TextSize = 12
		descLabel.TextColor3 = Theme.TextPrimary
		descLabel.TextTransparency = 0.3
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextTruncate = Enum.TextTruncate.AtEnd
	end

	local locked = false
	local lockUi = nil

	CreateTooltip(self.window, container, config.Tooltip)

	local swatch = NewInstance("TextButton", container)
	swatch.BackgroundColor3 = color
	swatch.BorderSizePixel = 0
	swatch.AutoButtonColor = false
	swatch.Size = UDim2.new(0, 32, 0, 20)
	swatch.AnchorPoint = Vector2.new(1, 0.5)
	swatch.Position = UDim2.new(1, -12, 0.5, 0)
	swatch.Text = ""

	local swatchCorner = NewInstance("UICorner", swatch)
	swatchCorner.CornerRadius = UDim.new(0, 5)

	local swatchStroke = NewInstance("UIStroke", swatch)
	swatchStroke.Color = Theme.ElementStroke
	swatchStroke.Thickness = 1
	swatchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	swatch.MouseEnter:Connect(function()
		tween(swatchStroke, {Color = Theme.Accent}, 0.15)
	end)
	swatch.MouseLeave:Connect(function()
		tween(swatchStroke, {Color = Theme.ElementStroke}, 0.15)
	end)

	local pickerToken = {}

	swatch.Activated:Connect(function()
		if locked then return end

		local self = self.window
		local token = pickerToken
		local initialColor = color
		local onChange = function(newColor, newTransparency)
			color = newColor
			swatch.BackgroundColor3 = newColor
			if transparencyEnabled then
				transparency = newTransparency or transparency
				swatch.BackgroundTransparency = transparency
				callback(newColor, transparency)
			else
				callback(newColor)
			end
		end

		if not self.colorPickerPopup then
		local popup = NewInstance("Frame", self.Instance)
		popup.BackgroundColor3 = Theme.WindowBackground
		popup.BorderSizePixel = 0
		popup.Active = true
		popup.Size = UDim2.new(0, 240, 0, 0)
		popup.AutomaticSize = Enum.AutomaticSize.Y
		popup.AnchorPoint = Vector2.new(0.5, 0.5)
		popup.Position = UDim2.new(0.5, 0, 0.5, 0)
		popup.Visible = false
		popup.ZIndex = 50

		local popupCorner = NewInstance("UICorner", popup)
		popupCorner.CornerRadius = UDim.new(0, 10)

		local popupStroke = NewInstance("UIStroke", popup)
		popupStroke.Color = Theme.WindowStroke
		popupStroke.Thickness = 1.5
		popupStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local popupScale = NewInstance("UIScale", popup)
		popupScale.Scale = 1

		local popupListLayout = NewInstance("UIListLayout", popup)
		popupListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		popupListLayout.FillDirection = Enum.FillDirection.Vertical

		local titleBar = NewInstance("Frame", popup)
		titleBar.BackgroundTransparency = 1
		titleBar.Active = true
		titleBar.Size = UDim2.new(1, 0, 0, 40)
		titleBar.LayoutOrder = 1
		titleBar.ZIndex = 51

		local divider = NewInstance("Frame", titleBar)
		divider.BackgroundColor3 = Theme.ElementStroke
		divider.BorderSizePixel = 0
		divider.Size = UDim2.new(1, 0, 0, 1)
		divider.Position = UDim2.new(0, 0, 1, -1)
		divider.ZIndex = 51

		local titleLabel = NewInstance("TextLabel", titleBar)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Position = UDim2.new(0, 14, 0, 0)
		titleLabel.Size = UDim2.new(1, -54, 1, 0)
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.Text = "Color Picker"
		titleLabel.TextSize = 15
		titleLabel.TextColor3 = Theme.TextPrimary
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 51

		local closeButton = NewInstance("TextButton", titleBar)
		closeButton.BackgroundTransparency = 1
		closeButton.AutoButtonColor = false
		closeButton.Size = UDim2.new(0, 28, 0, 28)
		closeButton.AnchorPoint = Vector2.new(1, 0.5)
		closeButton.Position = UDim2.new(1, -10, 0.5, 0)
		closeButton.Font = Enum.Font.GothamBold
		closeButton.Text = "╳"
		closeButton.TextSize = 14
		closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		closeButton.ZIndex = 51

		local closeButtonCorner = NewInstance("UICorner", closeButton)
		closeButtonCorner.CornerRadius = UDim.new(0, 7)

		closeButton.MouseEnter:Connect(function()
			tween(closeButton, {
				BackgroundColor3 = Theme.ElementBackgroundHover,
				BackgroundTransparency = 0,
			}, 0.15)
		end)
		closeButton.MouseLeave:Connect(function()
			tween(closeButton, {
				BackgroundColor3 = Theme.WindowBackground,
				BackgroundTransparency = 1,
			}, 0.15)
		end)

		local body = NewInstance("Frame", popup)
		body.BackgroundTransparency = 1
		body.Size = UDim2.new(1, 0, 0, 0)
		body.AutomaticSize = Enum.AutomaticSize.Y
		body.LayoutOrder = 2
		body.ZIndex = 51

		local bodyPadding = NewInstance("UIPadding", body)
		bodyPadding.PaddingTop = UDim.new(0, 12)
		bodyPadding.PaddingBottom = UDim.new(0, 12)
		bodyPadding.PaddingLeft = UDim.new(0, 12)
		bodyPadding.PaddingRight = UDim.new(0, 12)

		local bodyListLayout = NewInstance("UIListLayout", body)
		bodyListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		bodyListLayout.FillDirection = Enum.FillDirection.Vertical
		bodyListLayout.Padding = UDim.new(0, 10)

		local svBox = NewInstance("Frame", body)
		svBox.BackgroundColor3 = Color3.fromHSV(0, 1, 1)
		svBox.BorderSizePixel = 0
		svBox.Size = UDim2.new(1, 0, 0, 110)
		svBox.LayoutOrder = 1
		svBox.ZIndex = 51
		svBox.Active = true

		local svBoxCorner = NewInstance("UICorner", svBox)
		svBoxCorner.CornerRadius = UDim.new(0, 6)

		local saturationOverlay = NewInstance("Frame", svBox)
		saturationOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		saturationOverlay.BorderSizePixel = 0
		saturationOverlay.Size = UDim2.new(1, 0, 1, 0)
		saturationOverlay.ZIndex = 51

		local saturationOverlayCorner = NewInstance("UICorner", saturationOverlay)
		saturationOverlayCorner.CornerRadius = UDim.new(0, 6)

		local saturationGradient = NewInstance("UIGradient", saturationOverlay)
		saturationGradient.Rotation = 0
		saturationGradient.Transparency = NumberSequence.new(0, 1)

		local valueOverlay = NewInstance("Frame", saturationOverlay)
		valueOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		valueOverlay.BackgroundTransparency = 1
		valueOverlay.BorderSizePixel = 0
		valueOverlay.Size = UDim2.new(1, 0, 1, 0)
		valueOverlay.ZIndex = 51

		local valueOverlayCorner = NewInstance("UICorner", valueOverlay)
		valueOverlayCorner.CornerRadius = UDim.new(0, 6)

		local valueGradient = NewInstance("UIGradient", valueOverlay)
		valueGradient.Rotation = 90
		valueGradient.Transparency = NumberSequence.new(1, 0)

		local svCursor = NewInstance("Frame", svBox)
		svCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		svCursor.BorderSizePixel = 0
		svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
		svCursor.Size = UDim2.new(0, 12, 0, 12)
		svCursor.ZIndex = 53

		local svCursorCorner = NewInstance("UICorner", svCursor)
		svCursorCorner.CornerRadius = UDim.new(1, 0)

		local svCursorStroke = NewInstance("UIStroke", svCursor)
		svCursorStroke.Color = Color3.fromRGB(20, 20, 20)
		svCursorStroke.Thickness = 1.5

		local hueSlider = NewInstance("Frame", body)
		hueSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		hueSlider.BorderSizePixel = 0
		hueSlider.Size = UDim2.new(1, 0, 0, 16)
		hueSlider.LayoutOrder = 2
		hueSlider.ZIndex = 51
		hueSlider.Active = true

		local hueSliderCorner = NewInstance("UICorner", hueSlider)
		hueSliderCorner.CornerRadius = UDim.new(0, 8)

		local hueGradient = NewInstance("UIGradient", hueSlider)
		hueGradient.Rotation = 0
		hueGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0 / 6, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(6 / 6, Color3.fromRGB(255, 0, 0)),
		})

		local hueCursor = NewInstance("Frame", hueSlider)
		hueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		hueCursor.BorderSizePixel = 0
		hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
		hueCursor.Size = UDim2.new(0, 6, 1, 4)
		hueCursor.ZIndex = 53

		local hueCursorCorner = NewInstance("UICorner", hueCursor)
		hueCursorCorner.CornerRadius = UDim.new(0, 3)

		local hueCursorStroke = NewInstance("UIStroke", hueCursor)
		hueCursorStroke.Color = Color3.fromRGB(20, 20, 20)
		hueCursorStroke.Thickness = 1.5

		local transparencySlider = NewInstance("Frame", body)
		transparencySlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		transparencySlider.BorderSizePixel = 0
		transparencySlider.Size = UDim2.new(1, 0, 0, 16)
		transparencySlider.LayoutOrder = 3
		transparencySlider.ZIndex = 51
		transparencySlider.Active = true
		transparencySlider.Visible = false

		local transparencySliderCorner = NewInstance("UICorner", transparencySlider)
		transparencySliderCorner.CornerRadius = UDim.new(0, 8)

		local transparencyGradient = NewInstance("UIGradient", transparencySlider)
		transparencyGradient.Rotation = 0
		transparencyGradient.Transparency = NumberSequence.new(0, 1)

		local transparencyCursor = NewInstance("Frame", transparencySlider)
		transparencyCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		transparencyCursor.BorderSizePixel = 0
		transparencyCursor.AnchorPoint = Vector2.new(0.5, 0.5)
		transparencyCursor.Size = UDim2.new(0, 6, 1, 4)
		transparencyCursor.ZIndex = 53

		local transparencyCursorCorner = NewInstance("UICorner", transparencyCursor)
		transparencyCursorCorner.CornerRadius = UDim.new(0, 3)

		local transparencyCursorStroke = NewInstance("UIStroke", transparencyCursor)
		transparencyCursorStroke.Color = Color3.fromRGB(20, 20, 20)
		transparencyCursorStroke.Thickness = 1.5

		local hexRow = NewInstance("Frame", body)
		hexRow.BackgroundTransparency = 1
		hexRow.Size = UDim2.new(1, 0, 0, 26)
		hexRow.LayoutOrder = 4
		hexRow.ZIndex = 51

		local hexPrefix = NewInstance("TextLabel", hexRow)
		hexPrefix.BackgroundTransparency = 1
		hexPrefix.Size = UDim2.new(0, 16, 1, 0)
		hexPrefix.Font = Enum.Font.Gotham
		hexPrefix.Text = "#"
		hexPrefix.TextSize = 13
		hexPrefix.TextColor3 = Theme.TextPrimary
		hexPrefix.ZIndex = 51

		local hexInput = NewInstance("TextBox", hexRow)
		hexInput.BackgroundColor3 = Theme.TrackBackground
		hexInput.BorderSizePixel = 0
		hexInput.Position = UDim2.new(0, 18, 0, 0)
		hexInput.Size = UDim2.new(1, -18, 1, 0)
		hexInput.Font = Enum.Font.Gotham
		hexInput.PlaceholderText = "RRGGBB"
		hexInput.Text = "FFFFFF"
		hexInput.TextSize = 13
		hexInput.TextColor3 = Theme.TextPrimary
		hexInput.TextXAlignment = Enum.TextXAlignment.Center
		hexInput.TextTruncate = Enum.TextTruncate.AtEnd
		hexInput.ClearTextOnFocus = false
		hexInput.ZIndex = 51

		local hexInputCorner = NewInstance("UICorner", hexInput)
		hexInputCorner.CornerRadius = UDim.new(0, 5)

		local state = {
			token = nil,
			hue = 0,
			saturation = 0,
			value = 1,
			transparency = 0,
			transparencyEnabled = false,
			onChange = nil,
		}

		local function renderVisual()
			svBox.BackgroundColor3 = Color3.fromHSV(state.hue, 1, 1)
			svCursor.Position = UDim2.new(state.saturation, 0, 1 - state.value, 0)
			hueCursor.Position = UDim2.new(state.hue, 0, 0.5, 0)
			transparencySlider.Visible = state.transparencyEnabled
			transparencySlider.BackgroundColor3 = Color3.fromHSV(state.hue, state.saturation, state.value)
			transparencyCursor.Position = UDim2.new(state.transparency, 0, 0.5, 0)
			hexInput.Text = (function()
				local color = Color3.fromHSV(state.hue, state.saturation, state.value)
				local r = math.floor(color.R * 255 + 0.5)
				local g = math.floor(color.G * 255 + 0.5)
				local b = math.floor(color.B * 255 + 0.5)
				return string.format("%02X%02X%02X", r, g, b)
			end)()
		end

		local function commitChange()
			renderVisual()
			if state.onChange then
				if state.transparencyEnabled then
					state.onChange(Color3.fromHSV(state.hue, state.saturation, state.value), state.transparency)
				else
					state.onChange(Color3.fromHSV(state.hue, state.saturation, state.value))
				end
			end
		end

		local function updateSVFromInput(inputPosition)
			local relativeX = inputPosition.X - svBox.AbsolutePosition.X
			local relativeY = inputPosition.Y - svBox.AbsolutePosition.Y
			state.saturation = math.clamp(relativeX / svBox.AbsoluteSize.X, 0, 1)
			state.value = math.clamp(1 - (relativeY / svBox.AbsoluteSize.Y), 0, 1)
			commitChange()
		end

		local function updateHueFromInput(inputPosition)
			local relativeX = inputPosition.X - hueSlider.AbsolutePosition.X
			state.hue = math.clamp(relativeX / hueSlider.AbsoluteSize.X, 0, 1)
			commitChange()
		end

		local function updateTransparencyFromInput(inputPosition)
			local relativeX = inputPosition.X - transparencySlider.AbsolutePosition.X
			state.transparency = math.clamp(relativeX / transparencySlider.AbsoluteSize.X, 0, 1)
			commitChange()
		end

		local svDragging = false

		local svInputBeganConnection = svBox.InputBegan:Connect(function(input)
			local isPrimary = input.UserInputType == Enum.UserInputType.MouseButton1
			local isTouch = input.UserInputType == Enum.UserInputType.Touch
			if isPrimary or isTouch then
				svDragging = true
				updateSVFromInput(input.Position)
				local changedConnection
				changedConnection = input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						svDragging = false
						changedConnection:Disconnect()
					end
				end)
			end
		end)
		table.insert(self.connections, svInputBeganConnection)

		local svInputChangedConnection = UserInputService.InputChanged:Connect(function(input)
			local isMouse = input.UserInputType == Enum.UserInputType.MouseMovement
			local isTouch = input.UserInputType == Enum.UserInputType.Touch
			if svDragging and (isMouse or isTouch) then
				updateSVFromInput(input.Position)
			end
		end)
		table.insert(self.connections, svInputChangedConnection)

		local hueDragging = false

		local hueInputBeganConnection = hueSlider.InputBegan:Connect(function(input)
			local isPrimary = input.UserInputType == Enum.UserInputType.MouseButton1
			local isTouch = input.UserInputType == Enum.UserInputType.Touch
			if isPrimary or isTouch then
				hueDragging = true
				updateHueFromInput(input.Position)
				local changedConnection
				changedConnection = input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						hueDragging = false
						changedConnection:Disconnect()
					end
				end)
			end
		end)
		table.insert(self.connections, hueInputBeganConnection)

		local hueInputChangedConnection = UserInputService.InputChanged:Connect(function(input)
			local isMouse = input.UserInputType == Enum.UserInputType.MouseMovement
			local isTouch = input.UserInputType == Enum.UserInputType.Touch
			if hueDragging and (isMouse or isTouch) then
				updateHueFromInput(input.Position)
			end
		end)
		table.insert(self.connections, hueInputChangedConnection)

		local transparencyDragging = false

		local transparencyInputBeganConnection = transparencySlider.InputBegan:Connect(function(input)
			local isPrimary = input.UserInputType == Enum.UserInputType.MouseButton1
			local isTouch = input.UserInputType == Enum.UserInputType.Touch
			if (isPrimary or isTouch) and state.transparencyEnabled then
				transparencyDragging = true
				updateTransparencyFromInput(input.Position)
				local changedConnection
				changedConnection = input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						transparencyDragging = false
						changedConnection:Disconnect()
					end
				end)
			end
		end)
		table.insert(self.connections, transparencyInputBeganConnection)

		local transparencyInputChangedConnection = UserInputService.InputChanged:Connect(function(input)
			local isMouse = input.UserInputType == Enum.UserInputType.MouseMovement
			local isTouch = input.UserInputType == Enum.UserInputType.Touch
			if transparencyDragging and (isMouse or isTouch) then
				updateTransparencyFromInput(input.Position)
			end
		end)
		table.insert(self.connections, transparencyInputChangedConnection)

		local hexFocusLostConnection = hexInput.FocusLost:Connect(function()
			local parsed = (function()
				local hex = hexInput.Text:gsub("#", ""):gsub("%s", "")
				if #hex ~= 6 then
					return nil
				end
				local r = tonumber(hex:sub(1, 2), 16)
				local g = tonumber(hex:sub(3, 4), 16)
				local b = tonumber(hex:sub(5, 6), 16)
				if not (r and g and b) then
					return nil
				end
				return Color3.fromRGB(r, g, b)
			end)()
			if parsed then
				state.hue, state.saturation, state.value = parsed:ToHSV()
				commitChange()
			else
				hexInput.Text = (function()
					local color = Color3.fromHSV(state.hue, state.saturation, state.value)
					local r = math.floor(color.R * 255 + 0.5)
					local g = math.floor(color.G * 255 + 0.5)
					local b = math.floor(color.B * 255 + 0.5)
					return string.format("%02X%02X%02X", r, g, b)
				end)()
			end
		end)
		table.insert(self.connections, hexFocusLostConnection)

		local closeButtonConnection = closeButton.Activated:Connect(function()
			state.token = nil
			state.onChange = nil
			self.colorPickerPlayClose()
		end)
		table.insert(self.connections, closeButtonConnection)

		local dragConnections = makeDraggable(titleBar, popup)
		for _, connection in ipairs(dragConnections) do
			table.insert(self.connections, connection)
		end

		local contentFadeEntries = {
			{instance = titleBar, property = "BackgroundTransparency", visible = 1},
			{instance = divider, property = "BackgroundTransparency", visible = 0},
			{instance = titleLabel, property = "BackgroundTransparency", visible = 1},
			{instance = titleLabel, property = "TextTransparency", visible = 0},
			{instance = closeButton, property = "BackgroundTransparency", visible = 1},
			{instance = closeButton, property = "TextTransparency", visible = 0},
			{instance = body, property = "BackgroundTransparency", visible = 1},
			{instance = svBox, property = "BackgroundTransparency", visible = 0},
			{instance = saturationOverlay, property = "BackgroundTransparency", visible = 0},
			{instance = valueOverlay, property = "BackgroundTransparency", visible = 1},
			{instance = svCursor, property = "BackgroundTransparency", visible = 0},
			{instance = svCursorStroke, property = "Transparency", visible = 0},
			{instance = hueSlider, property = "BackgroundTransparency", visible = 0},
			{instance = hueCursor, property = "BackgroundTransparency", visible = 0},
			{instance = hueCursorStroke, property = "Transparency", visible = 0},
			{instance = transparencySlider, property = "BackgroundTransparency", visible = 0},
			{instance = transparencyCursor, property = "BackgroundTransparency", visible = 0},
			{instance = transparencyCursorStroke, property = "Transparency", visible = 0},
			{instance = hexRow, property = "BackgroundTransparency", visible = 1},
			{instance = hexPrefix, property = "BackgroundTransparency", visible = 1},
			{instance = hexPrefix, property = "TextTransparency", visible = 0},
			{instance = hexInput, property = "BackgroundTransparency", visible = 0},
			{instance = hexInput, property = "TextTransparency", visible = 0},
		}

		self.colorPickerPopup = popup
		self.colorPickerState = state
		self.colorPickerRenderVisual = renderVisual
		self.colorPickerPopupStroke = popupStroke
		self.colorPickerPopupScale = popupScale
		self.colorPickerContentFadeEntries = contentFadeEntries

		self.colorPickerPlayClose = function()
			local fadeOutTween = fadeGroup(contentFadeEntries, false, 0.12)

			local function collapse()
				tween(popup, {BackgroundTransparency = 1}, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				tween(popupStroke, {Transparency = 1}, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				local scaleTween = tween(popupScale, {Scale = 0.85}, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				scaleTween.Completed:Once(function()
					popup.Visible = false
				end)
			end

			if fadeOutTween then
				fadeOutTween.Completed:Once(collapse)
			else
				collapse()
			end
		end
		end

		local popup = self.colorPickerPopup
		local state = self.colorPickerState

		if state.token == token and popup.Visible then
			state.token = nil
			state.onChange = nil
			self.colorPickerPlayClose()
			return
		end

		state.token = token
		state.onChange = onChange
		state.transparencyEnabled = transparencyEnabled
		state.transparency = transparencyEnabled and transparency or 0
		state.hue, state.saturation, state.value = initialColor:ToHSV()
		self.colorPickerRenderVisual()

		if popup.Visible then
			return
		end

		local popupStroke = self.colorPickerPopupStroke
		local popupScale = self.colorPickerPopupScale
		local contentFadeEntries = self.colorPickerContentFadeEntries

		fadeGroupSnap(contentFadeEntries, false)
		popup.BackgroundTransparency = 1
		popupStroke.Transparency = 1
		popupScale.Scale = 0.85
		popup.Visible = true

		tween(popup, {BackgroundTransparency = 0}, 0.18)
		tween(popupStroke, {Transparency = 0}, 0.18)
		local scaleTween = tween(popupScale, {Scale = 1}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

		scaleTween.Completed:Once(function()
			if popup.Visible then
				fadeGroup(contentFadeEntries, true, 0.15)
			end
		end)
	end)

	local ColorPicker = {}
	ColorPicker.Instance = container

	function ColorPicker:Get()
		if transparencyEnabled then
			return color, transparency
		end
		return color
	end

	function ColorPicker:Set(newColor, newTransparency)
		color = newColor
		swatch.BackgroundColor3 = newColor
		if transparencyEnabled then
			if type(newTransparency) == "number" then
				transparency = math.clamp(newTransparency, 0, 1)
			end
			swatch.BackgroundTransparency = transparency
			callback(newColor, transparency)
		else
			callback(newColor)
		end
	end

	function ColorPicker:SetTitle(text)
		nameLabel.Text = text
	end

	function ColorPicker:SetDesc(text)
		if descLabel then
			descLabel.Text = text
			return
		end

		container.Size = UDim2.new(1, 0, 0, 44)
		nameLabel.Position = UDim2.new(0, 12, 0, 6)
		nameLabel.Size = UDim2.new(1, -60, 0, 18)

		descLabel = NewInstance("TextLabel", container)
		descLabel.BackgroundTransparency = 1
		descLabel.Position = UDim2.new(0, 12, 0, 24)
		descLabel.Size = UDim2.new(1, -60, 0, 14)
		descLabel.Font = Enum.Font.Gotham
		descLabel.Text = text
		descLabel.TextSize = 12
		descLabel.TextColor3 = Theme.TextPrimary
		descLabel.TextTransparency = 0.3
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextTruncate = Enum.TextTruncate.AtEnd
	end

	function ColorPicker:Lock()
		if locked then return end
		locked = true
		swatch.Active = false
		tween(container, {BackgroundTransparency = 0.5}, 0.15)
		tween(containerStroke, {Transparency = 0.5}, 0.15)
		tween(swatchStroke, {Transparency = 0.5}, 0.15)
		tween(nameLabel, {TextTransparency = 0.5}, 0.15)
		if descLabel then
			tween(descLabel, {TextTransparency = 0.6}, 0.15)
		end
		lockUi = CreateLockUi(container)
	end

	function ColorPicker:Unlock()
		if not locked then return end
		locked = false
		swatch.Active = true
		tween(container, {BackgroundTransparency = 0}, 0.15)
		tween(containerStroke, {Transparency = 0}, 0.15)
		tween(swatchStroke, {Transparency = 0}, 0.15)
		tween(nameLabel, {TextTransparency = 0}, 0.15)
		if descLabel then
			tween(descLabel, {TextTransparency = 0.3}, 0.15)
		end
		DestroyLockUi(lockUi)
		lockUi = nil
	end

	function ColorPicker:Destroy()
		container:Destroy()
	end

	return MakeCaseInsensitive(ColorPicker)
end

function Tab:Textbox(config)
	config = MakeCaseInsensitive(config)
	config = config or {}
	local callback = config.Callback or function() end
	local numeric = config.Numeric == true
	local clearTextOnFocus = config.ClearTextOnFocus == true
	local descText = config.Desc or config.Description
	local hasDesc = descText ~= nil and descText ~= ""

	local defaultText = ""
	if config.Default ~= nil then
		defaultText = tostring(config.Default)
	end
	if numeric then
		defaultText = defaultText:gsub("[^%d%.%-]", "")
	end

	self.elementOrder = self.elementOrder + 1

	local container = NewInstance("Frame", self.holder)
	container.BackgroundColor3 = Theme.ElementBackground
	container.BorderSizePixel = 0
	container.Size = UDim2.new(1, 0, 0, hasDesc and 44 or 36)
	container.LayoutOrder = self.elementOrder

	local containerCorner = NewInstance("UICorner", container)
	containerCorner.CornerRadius = UDim.new(0, 6)

	local containerStroke = NewInstance("UIStroke", container)
	containerStroke.Color = Theme.ElementStroke
	containerStroke.Thickness = 1
	containerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local nameLabel = NewInstance("TextLabel", container)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.Text = config.Name or "Textbox"
	nameLabel.TextSize = 14
	nameLabel.TextColor3 = Theme.TextPrimary
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	if hasDesc then
		nameLabel.Position = UDim2.new(0, 12, 0, 6)
		nameLabel.Size = UDim2.new(1, -178, 0, 18)
	else
		nameLabel.Position = UDim2.new(0, 12, 0, 0)
		nameLabel.Size = UDim2.new(1, -178, 1, 0)
	end

	local descLabel
	if hasDesc then
		descLabel = NewInstance("TextLabel", container)
		descLabel.BackgroundTransparency = 1
		descLabel.Position = UDim2.new(0, 12, 0, 24)
		descLabel.Size = UDim2.new(1, -178, 0, 14)
		descLabel.Font = Enum.Font.Gotham
		descLabel.Text = descText
		descLabel.TextSize = 12
		descLabel.TextColor3 = Theme.TextPrimary
		descLabel.TextTransparency = 0.3
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextTruncate = Enum.TextTruncate.AtEnd
	end

	local locked = false
	local lockUi = nil

	CreateTooltip(self.window, container, config.Tooltip)

	local textBox = NewInstance("TextBox", container)
	textBox.BackgroundColor3 = Theme.TrackBackground
	textBox.BorderSizePixel = 0
	textBox.Size = UDim2.new(0, 150, 0, 24)
	textBox.AnchorPoint = Vector2.new(1, 0.5)
	textBox.Position = UDim2.new(1, -12, 0.5, 0)
	textBox.Font = Enum.Font.Gotham
	textBox.PlaceholderText = config.PlaceholderText or ""
	textBox.Text = defaultText
	textBox.TextSize = 13
	textBox.TextColor3 = Theme.TextPrimary
	textBox.TextXAlignment = Enum.TextXAlignment.Center
	textBox.TextTruncate = Enum.TextTruncate.AtEnd
	textBox.ClearTextOnFocus = clearTextOnFocus

	local textBoxCorner = NewInstance("UICorner", textBox)
	textBoxCorner.CornerRadius = UDim.new(0, 5)

	local textBoxStroke = NewInstance("UIStroke", textBox)
	textBoxStroke.Color = Theme.ElementStroke
	textBoxStroke.Thickness = 1
	textBoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local textBoxPadding = NewInstance("UIPadding", textBox)
	textBoxPadding.PaddingLeft = UDim.new(0, 8)
	textBoxPadding.PaddingRight = UDim.new(0, 8)

	if numeric then
		textBox:GetPropertyChangedSignal("Text"):Connect(function()
			local filtered = textBox.Text:gsub("[^%d%.%-]", "")
			if filtered ~= textBox.Text then
				textBox.Text = filtered
			end
		end)
	end

	textBox.Focused:Connect(function()
		tween(textBoxStroke, {Color = Theme.Accent}, 0.15)
	end)

	textBox.FocusLost:Connect(function(enterPressed)
		tween(textBoxStroke, {Color = Theme.ElementStroke}, 0.15)
		callback(textBox.Text, enterPressed)
	end)

	local Textbox = {}
	Textbox.Instance = textBox

	function Textbox:Get()
		return textBox.Text
	end

	function Textbox:Set(newText)
		textBox.Text = tostring(newText)
		callback(textBox.Text, false)
	end

	function Textbox:SetTitle(text)
		nameLabel.Text = text
	end

	function Textbox:SetDesc(text)
		if descLabel then
			descLabel.Text = text
			return
		end

		container.Size = UDim2.new(1, 0, 0, 44)
		nameLabel.Position = UDim2.new(0, 12, 0, 6)
		nameLabel.Size = UDim2.new(1, -178, 0, 18)

		descLabel = NewInstance("TextLabel", container)
		descLabel.BackgroundTransparency = 1
		descLabel.Position = UDim2.new(0, 12, 0, 24)
		descLabel.Size = UDim2.new(1, -178, 0, 14)
		descLabel.Font = Enum.Font.Gotham
		descLabel.Text = text
		descLabel.TextSize = 12
		descLabel.TextColor3 = Theme.TextPrimary
		descLabel.TextTransparency = 0.3
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextTruncate = Enum.TextTruncate.AtEnd
	end

	function Textbox:Lock()
		if locked then return end
		locked = true
		textBox.TextEditable = false
		textBox.Active = false
		tween(container, {BackgroundTransparency = 0.5}, 0.15)
		tween(containerStroke, {Transparency = 0.5}, 0.15)
		tween(textBoxStroke, {Transparency = 0.5}, 0.15)
		tween(nameLabel, {TextTransparency = 0.5}, 0.15)
		if descLabel then
			tween(descLabel, {TextTransparency = 0.6}, 0.15)
		end
		lockUi = CreateLockUi(container)
	end

	function Textbox:Unlock()
		if not locked then return end
		locked = false
		textBox.TextEditable = true
		textBox.Active = true
		tween(container, {BackgroundTransparency = 0}, 0.15)
		tween(containerStroke, {Transparency = 0}, 0.15)
		tween(textBoxStroke, {Transparency = 0}, 0.15)
		tween(nameLabel, {TextTransparency = 0}, 0.15)
		if descLabel then
			tween(descLabel, {TextTransparency = 0.3}, 0.15)
		end
		DestroyLockUi(lockUi)
		lockUi = nil
	end

	function Textbox:Destroy()
		container:Destroy()
	end

	return MakeCaseInsensitive(Textbox)
end

function Tab:Label(config)
	config = MakeCaseInsensitive(config)
	config = config or {}

	self.elementOrder = self.elementOrder + 1

	local label = NewInstance("TextLabel", self.holder)
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Size = UDim2.new(1, 0, 0, 20)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.LayoutOrder = self.elementOrder
	label.Font = config.Font or Enum.Font.GothamMedium
	label.Text = config.Text or "Label"
	label.TextSize = config.TextSize or 14
	label.TextColor3 = config.Color or Theme.TextPrimary
	label.TextWrapped = true
	label.TextXAlignment = config.Alignment or Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.RichText = config.RichText or false

	local Label = {}
	Label.Instance = label

	function Label:Get()
		return label.Text
	end

	function Label:Set(text)
		label.Text = text
	end

	function Label:SetColor(color)
		label.TextColor3 = color
	end

	function Label:Destroy()
		label:Destroy()
	end

	return MakeCaseInsensitive(Label)
end

function Tab:Space(config)
	config = MakeCaseInsensitive(config)
	config = config or {}

	self.elementOrder = self.elementOrder + 1

	local spacer = NewInstance("Frame", self.holder)
	spacer.BackgroundTransparency = 1
	spacer.BorderSizePixel = 0
	spacer.Size = UDim2.new(1, 0, 0, config.Height or 8)
	spacer.LayoutOrder = self.elementOrder

	local Space = {}
	Space.Instance = spacer

	function Space:SetHeight(height)
		spacer.Size = UDim2.new(1, 0, 0, height)
	end

	function Space:Destroy()
		spacer:Destroy()
	end

	return MakeCaseInsensitive(Space)
end

function Tab:Dropdown(config)
	config = MakeCaseInsensitive(config)
	config = config or {}
	local callback = config.Callback or function() end
	local options = config.Options or config.Values or {}
	local multi = config.Multi == true
	local returnType = config.Type
	if returnType ~= "Dictionary" then
		returnType = "Array"
	end
	local placeholderText = config.PlaceholderText or config.Placeholder or "Select..."
	local maxVisibleItems = 6
	local searchable = config.Searchable == true
	local closeOnSelect = config.CloseOnSelect
	if closeOnSelect == nil then
		closeOnSelect = not multi
	end
	local descText = config.Desc or config.Description
	local hasDesc = descText ~= nil and descText ~= ""

	local selectedSet = {}

	local function applySelection(name)
		local valid = false
		for _, opt in ipairs(options) do
			if opt == name then
				valid = true
				break
			end
		end
		if not valid then
			return
		end
		if not multi then
			table.clear(selectedSet)
		end
		selectedSet[name] = true
	end

	if type(config.Default) == "table" then
		for _, name in ipairs(config.Default) do
			applySelection(name)
			if not multi then
				break
			end
		end
	elseif type(config.Default) == "string" then
		applySelection(config.Default)
	end

	local function getValue()
		if returnType == "Dictionary" then
			local result = {}
			for _, opt in ipairs(options) do
				result[opt] = selectedSet[opt] == true
			end
			return result
		end
		local result = {}
		for _, opt in ipairs(options) do
			if selectedSet[opt] then
				table.insert(result, opt)
			end
		end
		return result
	end

	self.elementOrder = self.elementOrder + 1

	local container = NewInstance("Frame", self.holder)
	container.BackgroundColor3 = Theme.ElementBackground
	container.BorderSizePixel = 0
	container.Size = UDim2.new(1, 0, 0, hasDesc and 44 or 36)
	container.LayoutOrder = self.elementOrder

	local containerCorner = NewInstance("UICorner", container)
	containerCorner.CornerRadius = UDim.new(0, 6)

	local containerStroke = NewInstance("UIStroke", container)
	containerStroke.Color = Theme.ElementStroke
	containerStroke.Thickness = 1
	containerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local dropdownIconSize = 16
	local dropdownIcon = CreateIcon(container, config.Icon, UDim2.new(0, dropdownIconSize, 0, dropdownIconSize))
	local hasDropdownIcon = dropdownIcon ~= nil
	if hasDropdownIcon then
		dropdownIcon.AnchorPoint = Vector2.new(0, 0.5)
		if hasDesc then
			dropdownIcon.Position = UDim2.new(0, 12, 0, 15)
		else
			dropdownIcon.Position = UDim2.new(0, 12, 0.5, 0)
		end
	end
	local dropdownLeftPad = 12
	if hasDropdownIcon then
		dropdownLeftPad = 12 + dropdownIconSize + 8
	end

	local nameLabel = NewInstance("TextLabel", container)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.Text = config.Name or "Dropdown"
	nameLabel.TextSize = 14
	nameLabel.TextColor3 = Theme.TextPrimary
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	if hasDesc then
		nameLabel.Position = UDim2.new(0, dropdownLeftPad, 0, 6)
		nameLabel.Size = UDim2.new(1, -(dropdownLeftPad + 188), 0, 18)
	else
		nameLabel.Position = UDim2.new(0, dropdownLeftPad, 0, 0)
		nameLabel.Size = UDim2.new(1, -(dropdownLeftPad + 188), 1, 0)
	end

	local descLabel
	if hasDesc then
		descLabel = NewInstance("TextLabel", container)
		descLabel.BackgroundTransparency = 1
		descLabel.Position = UDim2.new(0, dropdownLeftPad, 0, 24)
		descLabel.Size = UDim2.new(1, -(dropdownLeftPad + 188), 0, 14)
		descLabel.Font = Enum.Font.Gotham
		descLabel.Text = descText
		descLabel.TextSize = 12
		descLabel.TextColor3 = Theme.TextPrimary
		descLabel.TextTransparency = 0.3
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextTruncate = Enum.TextTruncate.AtEnd
	end

	local locked = false
	local lockUi = nil

	CreateTooltip(self.window, container, config.Tooltip)

	local panel

	local trigger = NewInstance("TextButton", container)
	trigger.BackgroundColor3 = Theme.TrackBackground
	trigger.BorderSizePixel = 0
	trigger.AutoButtonColor = false
	trigger.Size = UDim2.new(0, 170, 0, 24)
	trigger.AnchorPoint = Vector2.new(1, 0.5)
	trigger.Position = UDim2.new(1, -12, 0.5, 0)
	trigger.Text = ""

	local triggerCorner = NewInstance("UICorner", trigger)
	triggerCorner.CornerRadius = UDim.new(0, 5)

	local triggerStroke = NewInstance("UIStroke", trigger)
	triggerStroke.Color = Theme.ElementStroke
	triggerStroke.Thickness = 1
	triggerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local triggerLabel = NewInstance("TextLabel", trigger)
	triggerLabel.BackgroundTransparency = 1
	triggerLabel.Position = UDim2.new(0, 8, 0, 0)
	triggerLabel.Size = UDim2.new(1, -36, 1, 0)
	triggerLabel.Font = Enum.Font.Gotham
	triggerLabel.Text = placeholderText
	triggerLabel.TextSize = 13
	triggerLabel.TextColor3 = Theme.TextPrimary
	triggerLabel.TextXAlignment = Enum.TextXAlignment.Left
	triggerLabel.TextTruncate = Enum.TextTruncate.AtEnd

	local triggerArrow = NewInstance("TextLabel", trigger)
	triggerArrow.BackgroundTransparency = 1
	triggerArrow.Size = UDim2.new(0, 18, 0, 18)
	triggerArrow.AnchorPoint = Vector2.new(1, 0.5)
	triggerArrow.Position = UDim2.new(1, -6, 0.5, 0)
	triggerArrow.Font = Enum.Font.GothamBold
	triggerArrow.Text = ">"
	triggerArrow.TextSize = 13
	triggerArrow.TextColor3 = Theme.TextPrimary
	triggerArrow.Rotation = 0

	trigger.MouseEnter:Connect(function()
		tween(trigger, {BackgroundColor3 = Theme.ElementBackgroundHover}, 0.15)
		if not panel.Visible then
			tween(triggerStroke, {Color = Theme.Accent}, 0.15)
		end
	end)
	trigger.MouseLeave:Connect(function()
		tween(trigger, {BackgroundColor3 = Theme.TrackBackground}, 0.15)
		if not panel.Visible then
			tween(triggerStroke, {Color = Theme.ElementStroke}, 0.15)
		end
	end)

	local visibleRowCount = math.min(#options, maxVisibleItems)
	if visibleRowCount < 1 then
		visibleRowCount = 1
	end
	local listHeight = visibleRowCount * 30 + math.max(visibleRowCount - 1, 0) * 2
	local panelTargetHeight = listHeight + 6 * 2
	if searchable then
		panelTargetHeight = panelTargetHeight + 34
	end

	panel = NewInstance("Frame", self.window.Instance)
	panel.BackgroundColor3 = Theme.TabBackground
	panel.BorderSizePixel = 0
	panel.ClipsDescendants = true
	panel.Active = true
	panel.Visible = false
	panel.ZIndex = 70
	panel.Size = UDim2.new(0, 170, 0, 0)
	panel.BackgroundTransparency = 1

	local panelCorner = NewInstance("UICorner", panel)
	panelCorner.CornerRadius = UDim.new(0, 8)

	local panelStroke = NewInstance("UIStroke", panel)
	panelStroke.Color = Theme.WindowStroke
	panelStroke.Thickness = 1.5
	panelStroke.Transparency = 1
	panelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local contentFadeEntries = {}

	local innerContent = NewInstance("Frame", panel)
	innerContent.BackgroundTransparency = 1
	innerContent.AnchorPoint = Vector2.new(0, 0)
	innerContent.Position = UDim2.new(0, 0, 0, 0)
	innerContent.Size = UDim2.new(1, 0, 0, panelTargetHeight)
	innerContent.ZIndex = 71
	table.insert(contentFadeEntries, {instance = innerContent, property = "BackgroundTransparency", visible = 1})

	local searchBox = nil
	if searchable then
		searchBox = NewInstance("TextBox", innerContent)
		searchBox.BackgroundColor3 = Theme.TrackBackground
		searchBox.BorderSizePixel = 0
		searchBox.Position = UDim2.new(0, 6, 0, 6)
		searchBox.Size = UDim2.new(1, -6 * 2, 0, 34 - 6)
		searchBox.Font = Enum.Font.Gotham
		searchBox.PlaceholderText = "Search..."
		searchBox.Text = ""
		searchBox.TextSize = 13
		searchBox.TextColor3 = Theme.TextPrimary
		searchBox.TextXAlignment = Enum.TextXAlignment.Center
		searchBox.TextTruncate = Enum.TextTruncate.AtEnd
		searchBox.ClearTextOnFocus = false
		searchBox.ZIndex = 71

		local searchBoxCorner = NewInstance("UICorner", searchBox)
		searchBoxCorner.CornerRadius = UDim.new(0, 5)

		local searchBoxStroke = NewInstance("UIStroke", searchBox)
		searchBoxStroke.Color = Theme.ElementStroke
		searchBoxStroke.Thickness = 1
		searchBoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		table.insert(contentFadeEntries, {instance = searchBox, property = "BackgroundTransparency", visible = 0})
		table.insert(contentFadeEntries, {instance = searchBox, property = "TextTransparency", visible = 0})
		table.insert(contentFadeEntries, {instance = searchBoxStroke, property = "Transparency", visible = 0})

		searchBox.Focused:Connect(function()
			tween(searchBoxStroke, {Color = Theme.Accent}, 0.15)
		end)
		searchBox.FocusLost:Connect(function()
			tween(searchBoxStroke, {Color = Theme.ElementStroke}, 0.15)
		end)
	end

	local listTop = 0
	if searchable then
		listTop = 34
	end

	local listScroll = NewInstance("ScrollingFrame", innerContent)
	listScroll.BackgroundTransparency = 1
	listScroll.BorderSizePixel = 0
	listScroll.Position = UDim2.new(0, 0, 0, listTop)
	listScroll.Size = UDim2.new(1, 0, 1, -listTop)
	listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	listScroll.ScrollBarThickness = 4
	listScroll.ScrollBarImageColor3 = Theme.Accent
	listScroll.ZIndex = 71
	table.insert(contentFadeEntries, {instance = listScroll, property = "BackgroundTransparency", visible = 1})

	local listLayout = NewInstance("UIListLayout", listScroll)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.Padding = UDim.new(0, 2)

	local listPadding = NewInstance("UIPadding", listScroll)
	listPadding.PaddingTop = UDim.new(0, 6)
	listPadding.PaddingBottom = UDim.new(0, 6)
	listPadding.PaddingLeft = UDim.new(0, 6)
	listPadding.PaddingRight = UDim.new(0, 6)

	local emptyLabel = NewInstance("TextLabel", listScroll)
	emptyLabel.BackgroundTransparency = 1
	emptyLabel.Size = UDim2.new(1, 0, 0, 30)
	emptyLabel.LayoutOrder = 99999
	emptyLabel.Font = Enum.Font.Gotham
	emptyLabel.Text = "No options found"
	emptyLabel.TextSize = 13
	emptyLabel.TextColor3 = Theme.TextPrimary
	emptyLabel.TextTransparency = 0.5
	emptyLabel.Visible = false
	emptyLabel.ZIndex = 71
	table.insert(contentFadeEntries, {instance = emptyLabel, property = "BackgroundTransparency", visible = 1})
	table.insert(contentFadeEntries, {instance = emptyLabel, property = "TextTransparency", visible = 0.5})

	local rowsByName = {}

	local function setRowVisual(name, animated)
		local entry = rowsByName[name]
		if not entry then
			return
		end
		local isSelected = selectedSet[name] == true
		local bgTarget = 1
		local checkTarget = 1
		if isSelected then
			bgTarget = 0
			checkTarget = 0
		end
		entry.bgEntry.visible = bgTarget
		entry.checkEntry.visible = checkTarget
		if animated then
			tween(entry.row, {BackgroundTransparency = bgTarget}, 0.12)
			tween(entry.check, {TextTransparency = checkTarget}, 0.12)
		else
			entry.row.BackgroundTransparency = bgTarget
			entry.check.TextTransparency = checkTarget
		end
	end

	local function refreshTriggerLabel()
		local text, isPlaceholder
		do
			local count = 0
			local firstLabel = nil
			for _, opt in ipairs(options) do
				if selectedSet[opt] then
					count = count + 1
					if not firstLabel then
						firstLabel = opt
					end
				end
			end
			if count == 0 then
				text, isPlaceholder = placeholderText, true
			elseif count == 1 then
				text, isPlaceholder = firstLabel, false
			else
				text, isPlaceholder = count .. " Selected", false
			end
		end
		triggerLabel.Text = text
		if isPlaceholder then
			triggerLabel.TextTransparency = 0.45
		else
			triggerLabel.TextTransparency = 0
		end
	end

	local closeDropdown

	for index, optionName in ipairs(options) do
		local row = NewInstance("TextButton", listScroll)
		row.BackgroundColor3 = Theme.ElementBackgroundHover
		row.BackgroundTransparency = 1
		row.BorderSizePixel = 0
		row.AutoButtonColor = false
		row.Size = UDim2.new(1, 0, 0, 30)
		row.LayoutOrder = index
		row.Font = Enum.Font.Gotham
		row.Text = ""
		row.ZIndex = 71

		local rowCorner = NewInstance("UICorner", row)
		rowCorner.CornerRadius = UDim.new(0, 5)

		local rowLabel = NewInstance("TextLabel", row)
		rowLabel.BackgroundTransparency = 1
		rowLabel.Position = UDim2.new(0, 10, 0, 0)
		rowLabel.Size = UDim2.new(1, -42, 1, 0)
		rowLabel.Font = Enum.Font.Gotham
		rowLabel.Text = optionName
		rowLabel.TextSize = 13
		rowLabel.TextColor3 = Theme.TextPrimary
		rowLabel.TextXAlignment = Enum.TextXAlignment.Left
		rowLabel.TextTruncate = Enum.TextTruncate.AtEnd
		rowLabel.ZIndex = 71

		local rowCheck = NewInstance("TextLabel", row)
		rowCheck.BackgroundTransparency = 1
		rowCheck.Size = UDim2.new(0, 20, 0, 20)
		rowCheck.AnchorPoint = Vector2.new(1, 0.5)
		rowCheck.Position = UDim2.new(1, -8, 0.5, 0)
		rowCheck.Font = Enum.Font.GothamBold
		rowCheck.Text = "✓"
		rowCheck.TextSize = 14
		rowCheck.TextColor3 = Theme.Accent
		rowCheck.TextTransparency = 1
		rowCheck.ZIndex = 71

		local bgEntry = {instance = row, property = "BackgroundTransparency", visible = 1}
		local checkEntry = {instance = rowCheck, property = "TextTransparency", visible = 1}
		table.insert(contentFadeEntries, bgEntry)
		table.insert(contentFadeEntries, checkEntry)
		table.insert(contentFadeEntries, {instance = rowLabel, property = "BackgroundTransparency", visible = 1})
		table.insert(contentFadeEntries, {instance = rowLabel, property = "TextTransparency", visible = 0})

		rowsByName[optionName] = {row = row, check = rowCheck, bgEntry = bgEntry, checkEntry = checkEntry}

		row.MouseEnter:Connect(function()
			tween(row, {BackgroundTransparency = 0}, 0.12)
		end)
		row.MouseLeave:Connect(function()
			if not selectedSet[optionName] then
				tween(row, {BackgroundTransparency = 1}, 0.12)
			end
		end)
		row.Activated:Connect(function()
			local name = optionName
			if multi then
				if selectedSet[name] then
					selectedSet[name] = nil
				else
					selectedSet[name] = true
				end
			else
				if not selectedSet[name] then
					table.clear(selectedSet)
					selectedSet[name] = true
				end
			end

			for _, opt in ipairs(options) do
				setRowVisual(opt, true)
			end

			refreshTriggerLabel()
			callback(getValue())

			if closeOnSelect then
				closeDropdown()
			end
		end)
	end

	local function applySearchFilter(query)
		query = query:lower()
		local anyVisible = false
		for _, opt in ipairs(options) do
			local entry = rowsByName[opt]
			if entry then
				local visible = query == "" or opt:lower():find(query, 1, true) ~= nil
				entry.row.Visible = visible
				if visible then
					anyVisible = true
				end
			end
		end
		emptyLabel.Visible = not anyVisible
	end

	applySearchFilter("")

	if searchable and searchBox then
		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			applySearchFilter(searchBox.Text)
		end)
	end

	local function computePlacement()
		local triggerAbsPos = trigger.AbsolutePosition
		local triggerAbsSize = trigger.AbsoluteSize
		local viewportSize = workspace.CurrentCamera.ViewportSize
		local topLeftInset = GuiService:GetGuiInset()

		local spaceBelow = viewportSize.Y - (triggerAbsPos.Y + triggerAbsSize.Y + 6)
		local spaceAbove = triggerAbsPos.Y - topLeftInset.Y - 6

		local flip = false
		if spaceBelow < panelTargetHeight and spaceAbove > spaceBelow then
			flip = true
		end

		local panelWidth = triggerAbsSize.X
		local x = triggerAbsPos.X
		local maxX = viewportSize.X - panelWidth - 4
		if x > maxX then
			x = maxX
		end
		if x < 4 then
			x = 4
		end

		local y
		if flip then
			y = triggerAbsPos.Y - 6
		else
			y = triggerAbsPos.Y + triggerAbsSize.Y + 6
		end

		return x, y, flip, panelWidth
	end

	local repositionConnection = trigger:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
		if not panel.Visible then
			return
		end
		local x, y, flip = computePlacement()
		panel.AnchorPoint = Vector2.new(0, flip and 1 or 0)
		panel.Position = UDim2.new(0, x, 0, y)
	end)
	table.insert(self.window.connections, repositionConnection)

	closeDropdown = function()
		if not panel.Visible then
			return
		end

		tween(triggerArrow, {Rotation = 0}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		tween(triggerStroke, {Color = Theme.ElementStroke}, 0.15)

		local fadeOutTween = fadeGroup(contentFadeEntries, false, 0.12)

		local function collapse()
			local currentWidth = panel.Size.X.Offset
			local sizeTween = tween(panel, {Size = UDim2.new(0, currentWidth, 0, 0)}, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			tween(panel, {BackgroundTransparency = 1}, 0.13)
			tween(panelStroke, {Transparency = 1}, 0.13)

			sizeTween.Completed:Once(function()
				if panel.Size.Y.Offset <= 0 then
					panel.Visible = false
				end
			end)
		end

		if fadeOutTween then
			fadeOutTween.Completed:Once(collapse)
		else
			collapse()
		end

		if searchable and searchBox then
			searchBox.Text = ""
		end
	end

	trigger.Activated:Connect(function()
		if locked then return end
		if panel.Visible then
			closeDropdown()
		else
			if panel.Visible then
				return
			end

			local x, y, flip, panelWidth = computePlacement()
			panel.AnchorPoint = Vector2.new(0, flip and 1 or 0)
			panel.Position = UDim2.new(0, x, 0, y)
			panel.Size = UDim2.new(0, panelWidth, 0, 0)
			panel.BackgroundTransparency = 1
			panelStroke.Transparency = 1

			if flip then
				innerContent.AnchorPoint = Vector2.new(0, 1)
				innerContent.Position = UDim2.new(0, 0, 1, 0)
			else
				innerContent.AnchorPoint = Vector2.new(0, 0)
				innerContent.Position = UDim2.new(0, 0, 0, 0)
			end

			fadeGroupSnap(contentFadeEntries, false)

			panel.Visible = true

			tween(triggerArrow, {Rotation = 90}, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			tween(triggerStroke, {Color = Theme.Accent}, 0.15)

			local sizeTween = tween(panel, {Size = UDim2.new(0, panelWidth, 0, panelTargetHeight)}, 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			tween(panel, {BackgroundTransparency = 0}, 0.16)
			tween(panelStroke, {Transparency = 0}, 0.16)

			sizeTween.Completed:Once(function()
				if panel.Visible then
					fadeGroup(contentFadeEntries, true, 0.15)
				end
			end)
		end
	end)

	local outsideClickConnection = UserInputService.InputBegan:Connect(function(input)
		if not panel.Visible then
			return
		end
		local isPrimary = input.UserInputType == Enum.UserInputType.MouseButton1
		local isTouch = input.UserInputType == Enum.UserInputType.Touch
		if not (isPrimary or isTouch) then
			return
		end

		local pos = input.Position

		local function isInside(guiObject)
			local absPos = guiObject.AbsolutePosition
			local absSize = guiObject.AbsoluteSize
			return pos.X >= absPos.X and pos.X <= absPos.X + absSize.X
				and pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y
		end

		if isInside(panel) or isInside(trigger) then
			return
		end

		closeDropdown()
	end)
	table.insert(self.window.connections, outsideClickConnection)

	for _, opt in ipairs(options) do
		setRowVisual(opt, false)
	end
	refreshTriggerLabel()

	local Dropdown = {}
	Dropdown.Instance = container

	function Dropdown:Get()
		return getValue()
	end

	function Dropdown:Set(value)
		table.clear(selectedSet)
		if type(value) == "table" then
			for _, name in ipairs(value) do
				applySelection(name)
				if not multi then
					break
				end
			end
		elseif type(value) == "string" then
			applySelection(value)
		end

		for _, opt in ipairs(options) do
			setRowVisual(opt, false)
		end
		refreshTriggerLabel()
		callback(getValue())
	end

	function Dropdown:SetTitle(text)
		nameLabel.Text = text
	end

	function Dropdown:SetDesc(text)
		if descLabel then
			descLabel.Text = text
			return
		end

		container.Size = UDim2.new(1, 0, 0, 44)
		nameLabel.Position = UDim2.new(0, dropdownLeftPad, 0, 6)
		nameLabel.Size = UDim2.new(1, -(dropdownLeftPad + 188), 0, 18)
		if hasDropdownIcon then
			dropdownIcon.Position = UDim2.new(0, 12, 0, 15)
		end

		descLabel = NewInstance("TextLabel", container)
		descLabel.BackgroundTransparency = 1
		descLabel.Position = UDim2.new(0, dropdownLeftPad, 0, 24)
		descLabel.Size = UDim2.new(1, -(dropdownLeftPad + 188), 0, 14)
		descLabel.Font = Enum.Font.Gotham
		descLabel.Text = text
		descLabel.TextSize = 12
		descLabel.TextColor3 = Theme.TextPrimary
		descLabel.TextTransparency = 0.3
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextTruncate = Enum.TextTruncate.AtEnd
	end

	function Dropdown:Lock()
		if locked then return end
		locked = true
		if panel.Visible then
			closeDropdown()
		end
		trigger.Active = false
		tween(container, {BackgroundTransparency = 0.5}, 0.15)
		tween(containerStroke, {Transparency = 0.5}, 0.15)
		tween(triggerStroke, {Transparency = 0.5}, 0.15)
		tween(nameLabel, {TextTransparency = 0.5}, 0.15)
		if descLabel then
			tween(descLabel, {TextTransparency = 0.6}, 0.15)
		end
		lockUi = CreateLockUi(container)
	end

	function Dropdown:Unlock()
		if not locked then return end
		locked = false
		trigger.Active = true
		tween(container, {BackgroundTransparency = 0}, 0.15)
		tween(containerStroke, {Transparency = 0}, 0.15)
		tween(triggerStroke, {Transparency = 0}, 0.15)
		tween(nameLabel, {TextTransparency = 0}, 0.15)
		if descLabel then
			tween(descLabel, {TextTransparency = 0.3}, 0.15)
		end
		DestroyLockUi(lockUi)
		lockUi = nil
	end

	function Dropdown:Destroy()
		repositionConnection:Disconnect()
		outsideClickConnection:Disconnect()
		panel:Destroy()
		container:Destroy()
	end

	return MakeCaseInsensitive(Dropdown)
end

function Window:Dialog(config)
	if type(config) ~= "table" then config = {} end
	config = MakeCaseInsensitive(config)

	local screenGui2
	if self.screenGui2 and self.screenGui2.Parent then
		screenGui2 = self.screenGui2
	else
		local screenGui = self.Instance
		screenGui2 = NewInstance("ScreenGui", screenGui.Parent)
		screenGui2.ResetOnSpawn = false
		screenGui2.IgnoreGuiInset = true
		screenGui2.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screenGui2.DisplayOrder = screenGui.DisplayOrder + 1
		self.screenGui2 = screenGui2
	end

	local dialogOverlay = NewInstance("Frame", screenGui2)
	dialogOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	dialogOverlay.BackgroundTransparency = 1
	dialogOverlay.BorderSizePixel = 0
	dialogOverlay.Size = UDim2.new(1, 0, 1, 0)
	dialogOverlay.Position = UDim2.new(0, 0, 0, 0)
	dialogOverlay.Active = false
	dialogOverlay.Visible = false
	dialogOverlay.ZIndex = 10

	local popup = NewInstance("Frame", screenGui2)
	popup.BackgroundColor3 = Theme.WindowBackground
	popup.BackgroundTransparency = 1
	popup.BorderSizePixel = 0
	popup.Active = true
	popup.Size = UDim2.new(0, 300, 0, 0)
	popup.AutomaticSize = Enum.AutomaticSize.Y
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.Position = UDim2.new(0.5, 0, 0.5, 0)
	popup.Visible = false
	popup.ZIndex = 50

	local popupCorner = NewInstance("UICorner", popup)
	popupCorner.CornerRadius = UDim.new(0, 10)

	local popupStroke = NewInstance("UIStroke", popup)
	popupStroke.Color = Theme.WindowStroke
	popupStroke.Thickness = 1.5
	popupStroke.Transparency = 1
	popupStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local popupScale = NewInstance("UIScale", popup)
	popupScale.Scale = 0.85

	local contentCanvas = NewInstance("CanvasGroup", popup)
	contentCanvas.BackgroundTransparency = 1
	contentCanvas.BorderSizePixel = 0
	contentCanvas.Size = UDim2.new(1, 0, 0, 0)
	contentCanvas.AutomaticSize = Enum.AutomaticSize.Y
	contentCanvas.GroupTransparency = 1
	contentCanvas.ZIndex = 51

	local body = NewInstance("Frame", contentCanvas)
	body.BackgroundTransparency = 1
	body.Size = UDim2.new(1, 0, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.ZIndex = 51

	local bodyPadding = NewInstance("UIPadding", body)
	bodyPadding.PaddingTop = UDim.new(0, 16)
	bodyPadding.PaddingBottom = UDim.new(0, 16)
	bodyPadding.PaddingLeft = UDim.new(0, 16)
	bodyPadding.PaddingRight = UDim.new(0, 16)

	local bodyListLayout = NewInstance("UIListLayout", body)
	bodyListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	bodyListLayout.FillDirection = Enum.FillDirection.Vertical
	bodyListLayout.Padding = UDim.new(0, 10)

	local titleText = tostring(config.Title or "")
	local descTextValue = tostring(config.Description or config.Desc or "")
	local hasTitleText = titleText ~= ""
	local hasDescText = descTextValue ~= ""
	local hasIconData = GetIconData(config.Icon) ~= nil

	local iconSize
	if hasIconData then
		if hasTitleText and hasDescText then
			iconSize = 40
		elseif hasTitleText or hasDescText then
			iconSize = 48
		else
			iconSize = 64
		end
	end

	local function makeDialogText(parent, isTitle, size, align, order)
		local lbl = NewInstance("TextLabel", parent)
		lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(1, 0, 0, 0)
		lbl.AutomaticSize = Enum.AutomaticSize.Y
		lbl.Font = isTitle and Enum.Font.GothamBold or Enum.Font.Gotham
		lbl.TextSize = size
		lbl.TextColor3 = Theme.TextPrimary
		if not isTitle then
			lbl.TextTransparency = 0.25
		end
		lbl.TextXAlignment = align
		lbl.TextYAlignment = Enum.TextYAlignment.Top
		lbl.TextWrapped = true
		lbl.LayoutOrder = order
		lbl.ZIndex = 51
		lbl.Text = ""
		lbl.Visible = false
		return lbl
	end

	local titleLabel, descLabel

	if hasIconData and (hasTitleText or hasDescText) then
		local headerRow = NewInstance("Frame", body)
		headerRow.BackgroundTransparency = 1
		headerRow.Size = UDim2.new(1, 0, 0, 0)
		headerRow.AutomaticSize = Enum.AutomaticSize.Y
		headerRow.LayoutOrder = 1
		headerRow.ZIndex = 51

		local headerRowListLayout = NewInstance("UIListLayout", headerRow)
		headerRowListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		headerRowListLayout.FillDirection = Enum.FillDirection.Horizontal
		headerRowListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		headerRowListLayout.Padding = UDim.new(0, 12)

		local iconHolder = NewInstance("Frame", headerRow)
		iconHolder.BackgroundTransparency = 1
		iconHolder.Size = UDim2.new(0, iconSize, 0, iconSize)
		iconHolder.LayoutOrder = 1
		iconHolder.ZIndex = 51

		local headerIcon = CreateIcon(iconHolder, config.Icon, UDim2.new(0, iconSize, 0, iconSize))
		if headerIcon then
			headerIcon.ZIndex = 51
		end

		local textColumn = NewInstance("Frame", headerRow)
		textColumn.BackgroundTransparency = 1
		textColumn.Size = UDim2.new(1, -(iconSize + 12), 0, 0)
		textColumn.AutomaticSize = Enum.AutomaticSize.Y
		textColumn.LayoutOrder = 2
		textColumn.ZIndex = 51

		local textColumnListLayout = NewInstance("UIListLayout", textColumn)
		textColumnListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		textColumnListLayout.FillDirection = Enum.FillDirection.Vertical
		textColumnListLayout.Padding = UDim.new(0, 2)

		titleLabel = makeDialogText(textColumn, true, hasDescText and 16 or 18, Enum.TextXAlignment.Left, 1)
		descLabel = makeDialogText(textColumn, false, hasTitleText and 13 or 14, Enum.TextXAlignment.Left, 2)

	elseif hasIconData then
		local iconHolder = NewInstance("Frame", body)
		iconHolder.BackgroundTransparency = 1
		iconHolder.Size = UDim2.new(1, 0, 0, iconSize)
		iconHolder.LayoutOrder = 1
		iconHolder.ZIndex = 51

		local centerIcon = CreateIcon(iconHolder, config.Icon, UDim2.new(0, iconSize, 0, iconSize))
		if centerIcon then
			centerIcon.AnchorPoint = Vector2.new(0.5, 0.5)
			centerIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
			centerIcon.ZIndex = 51
		end

		titleLabel = makeDialogText(body, true, 16, Enum.TextXAlignment.Center, 2)
		descLabel = makeDialogText(body, false, 13, Enum.TextXAlignment.Center, 3)

	else
		titleLabel = makeDialogText(body, true, 16, Enum.TextXAlignment.Center, 1)
		descLabel = makeDialogText(body, false, 13, Enum.TextXAlignment.Center, 2)
	end

	local buttonRow = NewInstance("Frame", body)
	buttonRow.BackgroundTransparency = 1
	buttonRow.Size = UDim2.new(1, 0, 0, 34)
	buttonRow.LayoutOrder = 10
	buttonRow.ZIndex = 51

	local buttonRowListLayout = NewInstance("UIListLayout", buttonRow)
	buttonRowListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	buttonRowListLayout.FillDirection = Enum.FillDirection.Horizontal
	buttonRowListLayout.Padding = UDim.new(0, 10)
	buttonRowListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	buttonRowListLayout.VerticalAlignment = Enum.VerticalAlignment.Center

	local function createDialogButton(text, order, bgColor, textColor, iconString)
		local btn = NewInstance("TextButton", buttonRow)
		btn.BackgroundColor3 = bgColor
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.AutomaticSize = Enum.AutomaticSize.X
		btn.Size = UDim2.new(0, 0, 1, 0)
		btn.LayoutOrder = order
		btn.Font = Enum.Font.GothamMedium
		btn.Text = ""
		btn.TextSize = 14
		btn.TextColor3 = textColor
		btn.ZIndex = 51

		local btnPadding = NewInstance("UIPadding", btn)
		btnPadding.PaddingLeft = UDim.new(0, 16)
		btnPadding.PaddingRight = UDim.new(0, 16)

		local btnCorner = NewInstance("UICorner", btn)
		btnCorner.CornerRadius = UDim.new(0, 6)

		local btnStroke = NewInstance("UIStroke", btn)
		btnStroke.Color = Theme.ElementStroke
		btnStroke.Thickness = 1
		btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local btnListLayout = NewInstance("UIListLayout", btn)
		btnListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		btnListLayout.FillDirection = Enum.FillDirection.Horizontal
		btnListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		btnListLayout.Padding = UDim.new(0, 6)

		local btnIcon = CreateIcon(btn, iconString, UDim2.new(0, 14, 0, 14), textColor)
		if btnIcon then
			btnIcon.LayoutOrder = 1
			btnIcon.ZIndex = 51
		end

		local btnLabel = NewInstance("TextLabel", btn)
		btnLabel.BackgroundTransparency = 1
		btnLabel.AutomaticSize = Enum.AutomaticSize.X
		btnLabel.Size = UDim2.new(0, 0, 1, 0)
		btnLabel.Font = Enum.Font.GothamMedium
		btnLabel.Text = text
		btnLabel.TextSize = 14
		btnLabel.TextColor3 = textColor
		btnLabel.LayoutOrder = 2
		btnLabel.ZIndex = 51

		btn.MouseEnter:Connect(function()
			tween(btn, {BackgroundColor3 = Color3.new(
				math.clamp(bgColor.R + 0.06, 0, 1),
				math.clamp(bgColor.G + 0.06, 0, 1),
				math.clamp(bgColor.B + 0.06, 0, 1)
			)}, 0.15)
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, {BackgroundColor3 = bgColor}, 0.15)
		end)

		return btn
	end

	local dialog = {}
	dialog.IsOpen = false
	dialog.Instance = popup

	function dialog:Open()
		if self.IsOpen then return end
		self.IsOpen = true

		dialogOverlay.Visible = true
		dialogOverlay.Active = true
		tween(dialogOverlay, {BackgroundTransparency = 0.65}, 0.18)

		popup.Visible = true
		popup.BackgroundTransparency = 1
		popupStroke.Transparency = 1
		popupScale.Scale = 0.85
		contentCanvas.GroupTransparency = 1

		tween(popup, {BackgroundTransparency = 0}, 0.18)
		tween(popupStroke, {Transparency = 0}, 0.18)
		tween(popupScale, {Scale = 1}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		tween(contentCanvas, {GroupTransparency = 0}, 0.18)
	end

	function dialog:Close()
		if not self.IsOpen then return end
		self.IsOpen = false

		dialogOverlay.Active = false
		tween(dialogOverlay, {BackgroundTransparency = 1}, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween(contentCanvas, {GroupTransparency = 1}, 0.12)

		tween(popup, {BackgroundTransparency = 1}, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween(popupStroke, {Transparency = 1}, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local scaleTween = tween(popupScale, {Scale = 0.85}, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		scaleTween.Completed:Once(function()
			popup.Visible = false
			dialogOverlay.Visible = false
		end)
	end

	function dialog:SetTitle(text)
		titleLabel.Text = tostring(text or "")
		titleLabel.Visible = titleLabel.Text ~= ""
	end

	function dialog:SetDesc(text)
		descLabel.Text = tostring(text or "")
		descLabel.Visible = descLabel.Text ~= ""
	end

	function dialog:Destroy()
		if self.IsOpen then
			dialogOverlay.Active = false
			popup.Visible = false
			dialogOverlay.Visible = false
			self.IsOpen = false
		end
		dialogOverlay:Destroy()
		popup:Destroy()
	end

	dialog:SetTitle(config.Title)
	dialog:SetDesc(config.Description or config.Desc)

	if type(config.Buttons) == "table" then
		for i, buttonConfigRaw in ipairs(config.Buttons) do
			local buttonConfig = MakeCaseInsensitive(buttonConfigRaw)
			local isPrimary = tostring(buttonConfig.Variant or "Secondary"):lower() == "primary"
			local text = tostring(buttonConfig.Text or (isPrimary and "Confirm" or "Cancel"))
			local bg = buttonConfig.Color or (isPrimary and Theme.Accent or Theme.ElementBackground)
			local textColor = buttonConfig.TextColor or (isPrimary and Color3.fromRGB(255, 255, 255) or Theme.TextPrimary)
			local btn = createDialogButton(text, i, bg, textColor, buttonConfig.Icon)
			btn.Activated:Connect(function()
				dialog:Close()
				if type(buttonConfig.Callback) == "function" then
					task.spawn(buttonConfig.Callback)
				end
			end)
		end
	end

	return MakeCaseInsensitive(dialog)
end

function Window:Destroy()
	if self.destroyAnimated then
		self.destroyAnimated()
	else
		for _, connection in ipairs(self.connections) do
			connection:Disconnect()
		end
		self.connections = {}
		self.Instance:Destroy()
		if self.screenGui2 then
			self.screenGui2:Destroy()
		end
	end
end


do
	local NotifyTheme = {
		bg = Color3.fromRGB(15, 15, 15),
		border = Color3.fromRGB(50, 50, 50),
		accent = Color3.fromRGB(255, 255, 255),
		btnBg = Color3.fromRGB(30, 30, 30),
		titleColor = Color3.fromRGB(255, 255, 255),
		textColor = Color3.fromRGB(140, 140, 140),
		progressBg = Color3.fromRGB(35, 35, 35),
	}

	local FONT_OPTIONS = {
		{ Name = "GothamBold", Font = Enum.Font.GothamBold },
		{ Name = "Gotham", Font = Enum.Font.Gotham },
		{ Name = "SourceSansBold", Font = Enum.Font.SourceSansBold },
		{ Name = "ArialBold", Font = Enum.Font.ArialBold },
		{ Name = "Arcade", Font = Enum.Font.Arcade },
		{ Name = "Fantasy", Font = Enum.Font.Fantasy },
	}

	local POSITION_OPTIONS = {
		{ Name = "BottomRight", Label = "Bottom Right", XSide = "right", YSide = "bottom" },
		{ Name = "TopRight", Label = "Top Right", XSide = "right", YSide = "top" },
		{ Name = "BottomLeft", Label = "Bottom Left", XSide = "left", YSide = "bottom" },
		{ Name = "TopLeft", Label = "Top Left", XSide = "left", YSide = "top" },
	}

	local currentFont, currentFontName
	for _, option in ipairs(FONT_OPTIONS) do
		if option.Name == "GothamBold" then
			currentFont, currentFontName = option.Font, option.Name
			break
		end
	end
	if not currentFont then
		currentFont, currentFontName = Enum.Font.GothamBold, "GothamBold"
	end

	local currentPositionOption
	for _, option in ipairs(POSITION_OPTIONS) do
		if option.Name == "BottomRight" then
			currentPositionOption = option
			break
		end
	end
	if not currentPositionOption then
		currentPositionOption = POSITION_OPTIONS[1]
	end

	local activeNotifs = {}
	local NotifyScreenGui

	local function getBaseXY(frameHeight, totalOffset)
		local opt = currentPositionOption
		local xScale, xOffset
		if opt.XSide == "left" then xScale, xOffset = 0, 16 else xScale, xOffset = 1, -(320 + 16) end
		local yScale, yOffset
		if opt.YSide == "top" then yScale, yOffset = 0, 24 + totalOffset else yScale, yOffset = 1, -(frameHeight + 24) - totalOffset end
		return UDim2.new(xScale, xOffset, yScale, yOffset)
	end

	local function getOffscreenX()
		local opt = currentPositionOption
		if opt.XSide == "left" then return 0, -(320 + 30) end
		return 1, 320 + 30
	end

	local function getSlotPos(index)
		local totalOffset = 0
		for i = 1, index - 1 do
			local d = activeNotifs[i]
			totalOffset = totalOffset + (d and d.frameHeight or 84) + 8
		end
		local h = activeNotifs[index] and activeNotifs[index].frameHeight or 84
		return getBaseXY(h, totalOffset)
	end

	local function playFrameTween(data, props, duration, style, direction)
		if not data or data.dismissed or not data.frame or not data.frame.Parent then return nil end
		data.positionToken = (data.positionToken or 0) + 1
		if data.positionTween then pcall(function() data.positionTween:Cancel() end) end
		local playingTween = tween(data.frame, props, duration, style, direction)
		data.positionTween = playingTween
		return playingTween, data.positionToken
	end

	local function repositionAll()
		local totalOffset = 0
		for i, data in ipairs(activeNotifs) do
			local frameHeight = data and data.frameHeight or 84
			local pos = getBaseXY(frameHeight, totalOffset)
			if data and data.frame and data.frame.Parent and not data.dismissed then
				playFrameTween(data, { Position = pos }, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			end
			totalOffset = totalOffset + frameHeight + 8
		end
	end

	local function dismissNotif(frame, data)
		if not data or data.dismissed then return end
		data.dismissed = true
		data.paused = true
		if data.positionTween then pcall(function() data.positionTween:Cancel() end) end
		if data.dismissTween then pcall(function() data.dismissTween:Cancel() end) end

		if not frame or not frame.Parent then
			for i, d in ipairs(activeNotifs) do
				if d.frame == frame then table.remove(activeNotifs, i) break end
			end
			if data.dropdown then data.dropdown:Destroy() end
			if data.dropdownPos then data.dropdownPos:Destroy() end
			repositionAll()
			return
		end

		local currentPos = frame.Position
		local exitXScale, exitXOffset = getOffscreenX()
		local exitPos = UDim2.new(exitXScale, exitXOffset, currentPos.Y.Scale, currentPos.Y.Offset)
		local dismissTween = tween(frame, { Position = exitPos }, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		data.dismissTween = dismissTween
		local completedConnection = nil
		completedConnection = dismissTween.Completed:Connect(function()
			if completedConnection then completedConnection:Disconnect() completedConnection = nil end
			for i, d in ipairs(activeNotifs) do
				if d.frame == frame then table.remove(activeNotifs, i) break end
			end
			frame:Destroy()
			if data.dropdown then data.dropdown:Destroy() end
			if data.dropdownPos then data.dropdownPos:Destroy() end
			repositionAll()
		end)
	end

	function Library:Notify(config)
		if NotifyScreenGui and NotifyScreenGui.Parent then
			-- screen gui already available
		else
			NotifyScreenGui = NewInstance("ScreenGui")
			NotifyScreenGui.ResetOnSpawn = false
			NotifyScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			NotifyScreenGui.Destroying:Connect(function()
				for i = #activeNotifs, 1, -1 do
					local d = activeNotifs[i]
					if d then
						d.dismissed = true
						d.paused = true
						if d.positionTween then pcall(function() d.positionTween:Cancel() end) end
						if d.dismissTween then pcall(function() d.dismissTween:Cancel() end) end
					end
					activeNotifs[i] = nil
				end
			end)
		end
		if not (NotifyScreenGui.Parent ~= nil) then
			warn("NonameLibrary: notify ScreenGui unavailable")
			return nil
		end
		if type(config) ~= "table" then config = {} end
		config = MakeCaseInsensitive(config)

		local title
		do
			local value = config.Title or "Notification"
			if type(value) ~= "string" then value = tostring(value) end
			value = value:gsub("\r\n", " "):gsub("\n", " "):gsub("\r", " ")
			value = value:gsub("%s+", " ")
			value = value:gsub("^%s+", ""):gsub("%s+$", "")
			title = value
		end

		local text
		do
			local value = config.Desc or ""
			if type(value) ~= "string" then value = tostring(value) end
			text = (value:gsub("\r\n", "\n"):gsub("\r", "\n"))
		end

		local duration = config.Duration or 4
		if type(duration) ~= "number" or duration ~= duration or duration < 0 or duration == math.huge or duration == -math.huge then duration = 4 end

		local canClose = true
		if config.CanClose ~= nil then
			canClose = config.CanClose and true or false
		end

		local textTargets = {}

		local textHeight
		do
			local ok, size = pcall(function()
				return TextService:GetTextSize(text, 11, currentFont, Vector2.new(320 - 84, math.huge))
			end)
			if ok and size then
				textHeight = math.max(11 + 2, size.Y)
			else
				textHeight = 11 + 2
			end
		end
		local frameHeight = 38 + textHeight + 22

		local frame = NewInstance("Frame", NotifyScreenGui)
		frame.Size = UDim2.new(0, 320, 0, frameHeight)
		local startXScale, startXOffset = getOffscreenX()
		local startSlot = getBaseXY(frameHeight, 0)
		frame.Position = UDim2.new(startXScale, startXOffset, startSlot.Y.Scale, startSlot.Y.Offset)
		frame.BackgroundColor3 = NotifyTheme.bg
		frame.BorderSizePixel = 0
		frame.ZIndex = 10

		NewInstance("UICorner", frame).CornerRadius = UDim.new(0, 12)

		local stroke = NewInstance("UIStroke", frame)
		stroke.Color = Color3.fromRGB(255, 255, 255)
		stroke.Thickness = 1
		stroke.Transparency = 0.3

		local closeBtn = NewInstance("TextButton", frame)
		closeBtn.Size = UDim2.new(0, 28, 0, 28)
		closeBtn.Position = UDim2.new(1, -34, 0, 6)
		closeBtn.BackgroundTransparency = 1
		closeBtn.BorderSizePixel = 0
		closeBtn.Text = "╳"
		closeBtn.TextColor3 = Color3.fromRGB(80, 80, 80)
		closeBtn.TextSize = 20
		closeBtn.Font = currentFont
		closeBtn.ZIndex = 13
		closeBtn.Visible = canClose
		closeBtn.Active = canClose
		table.insert(textTargets, closeBtn)

		closeBtn.MouseEnter:Connect(function()
			tween(closeBtn, { TextColor3 = Color3.fromRGB(200, 200, 200) }, 0.15)
		end)
		closeBtn.MouseLeave:Connect(function()
			tween(closeBtn, { TextColor3 = Color3.fromRGB(80, 80, 80) }, 0.15)
		end)

		local iconFrame = NewInstance("Frame", frame)
		iconFrame.Size = UDim2.new(0, 36, 0, 36)
		iconFrame.Position = UDim2.new(0, 20, 0, 18)
		iconFrame.BackgroundColor3 = NotifyTheme.bg
		iconFrame.BorderSizePixel = 0
		iconFrame.ZIndex = 11
		iconFrame.ClipsDescendants = true

		local customIconSet = false
		if IconsLib and type(config.Icon) == "string" and config.Icon ~= "" then
			local ok, iconObj = pcall(function()
				return IconsLib.Image({ Icon = config.Icon, Size = UDim2.new(1, 0, 1, 0) })
			end)
			if ok and iconObj and iconObj.IconFrame then
				iconObj.IconFrame.Size = UDim2.new(1, 0, 1, 0)
				iconObj.IconFrame.BackgroundTransparency = 1
				iconObj.IconFrame.ZIndex = 12
				iconObj.IconFrame.Parent = iconFrame
				customIconSet = true
			end
		end

		if not customIconSet then
			local iconImage = NewInstance("ImageLabel", iconFrame)
			iconImage.Size = UDim2.new(1, 0, 1, 0)
			iconImage.BackgroundTransparency = 1
			iconImage.ZIndex = 12

			task.spawn(function()
				local ok, thumb = pcall(function()
					return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
				end)
				if ok and type(thumb) == "string" and iconImage.Parent then iconImage.Image = thumb end
			end)
		end

		local titleLabel = NewInstance("TextLabel", frame)
		titleLabel.Size = UDim2.new(1, -176, 0, 16)
		titleLabel.Position = UDim2.new(0, 64, 0, 18)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = NotifyTheme.titleColor
		titleLabel.TextSize = 13
		titleLabel.Font = currentFont
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.TextYAlignment = Enum.TextYAlignment.Center
		titleLabel.TextWrapped = false
		titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
		titleLabel.ZIndex = 12
		table.insert(textTargets, titleLabel)

		local textLabel = NewInstance("TextLabel", frame)
		textLabel.Size = UDim2.new(1, -84, 0, textHeight)
		textLabel.Position = UDim2.new(0, 64, 0, 38)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = text
		textLabel.TextColor3 = NotifyTheme.textColor
		textLabel.TextSize = 11
		textLabel.Font = currentFont
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.TextYAlignment = Enum.TextYAlignment.Top
		textLabel.TextWrapped = true
		textLabel.ZIndex = 12
		table.insert(textTargets, textLabel)

		local data = { frame = frame, frameHeight = frameHeight, dismissed = false, paused = false, remaining = duration, duration = duration, positionTween = nil, positionToken = 0, dismissTween = nil }
		table.insert(activeNotifs, data)

		closeBtn.Activated:Connect(function()
			if not canClose then return end
			dismissNotif(frame, data)
		end)

		local function pauseTimer()
			if data.dismissed or data.paused then return end
			data.paused = true
		end

		local function resumeTimer()
			if data.dismissed or not data.paused then return end
			data.paused = false
		end

		local closeAaDropdownFn, isAaDropdownOpenFn
		local closePosDropdownFn, isPosDropdownOpenFn

		local aaFrame = NewInstance("Frame", frame)
		aaFrame.Size = UDim2.new(0, 26, 0, 26)
		aaFrame.Position = UDim2.new(1, -66, 0, 7)
		aaFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		aaFrame.BorderSizePixel = 0
		aaFrame.ZIndex = 13
		NewInstance("UICorner", aaFrame).CornerRadius = UDim.new(1, 0)

		local aaStroke = NewInstance("UIStroke", aaFrame)
		aaStroke.Color = Color3.fromRGB(255, 255, 255)
		aaStroke.Thickness = 1.25
		aaStroke.Transparency = 0.15
		aaStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local aaBtn = NewInstance("TextButton", aaFrame)
		aaBtn.Size = UDim2.new(1, 0, 1, 0)
		aaBtn.BackgroundTransparency = 1
		aaBtn.BorderSizePixel = 0
		aaBtn.Text = "Aa"
		aaBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		aaBtn.TextSize = 14
		aaBtn.Font = currentFont
		aaBtn.ZIndex = 14
		table.insert(textTargets, aaBtn)

		local dropdownWidth = 136
		local dropdownHeight = 30 + (#FONT_OPTIONS * 26) + 10
		local dropdown = NewInstance("Frame", NotifyScreenGui)
		dropdown.AnchorPoint = Vector2.new(0.5, 0.5)
		dropdown.Size = UDim2.new(0, 0, 0, 0)
		dropdown.Position = UDim2.new(0.5, 0, 0.5, 0)
		dropdown.BackgroundColor3 = NotifyTheme.bg
		dropdown.BackgroundTransparency = 1
		dropdown.BorderSizePixel = 0
		dropdown.ClipsDescendants = true
		dropdown.Visible = false
		dropdown.ZIndex = 20
		data.dropdown = dropdown
		NewInstance("UICorner", dropdown).CornerRadius = UDim.new(0, 12)

		local dropdownStroke = NewInstance("UIStroke", dropdown)
		dropdownStroke.Color = Color3.fromRGB(255, 255, 255)
		dropdownStroke.Thickness = 1
		dropdownStroke.Transparency = 1
		dropdownStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local fontDropdownFade = {}

		local dropdownTitle = NewInstance("TextLabel", dropdown)
		dropdownTitle.Size = UDim2.new(1, -40, 0, 24)
		dropdownTitle.Position = UDim2.new(0, 12, 0, 5)
		dropdownTitle.BackgroundTransparency = 1
		dropdownTitle.Text = "Font"
		dropdownTitle.TextColor3 = NotifyTheme.titleColor
		dropdownTitle.TextSize = 15
		dropdownTitle.Font = currentFont
		dropdownTitle.TextXAlignment = Enum.TextXAlignment.Left
		dropdownTitle.ZIndex = 21
		table.insert(textTargets, dropdownTitle)
		table.insert(fontDropdownFade, {instance = dropdownTitle, property = "TextTransparency", visible = 0})

		local dropdownClose = NewInstance("TextButton", dropdown)
		dropdownClose.Size = UDim2.new(0, 24, 0, 24)
		dropdownClose.Position = UDim2.new(1, -30, 0, 5)
		dropdownClose.BackgroundTransparency = 1
		dropdownClose.BorderSizePixel = 0
		dropdownClose.Text = "╳"
		dropdownClose.TextColor3 = Color3.fromRGB(180, 180, 180)
		dropdownClose.TextSize = 16
		dropdownClose.Font = currentFont
		dropdownClose.ZIndex = 22
		table.insert(textTargets, dropdownClose)
		table.insert(fontDropdownFade, {instance = dropdownClose, property = "TextTransparency", visible = 0})

		local dropdownOpen = false
		local dropdownClosing = false
		local dropdownTween = nil
		local dropdownTweenToken = 0
		local fontButtons = {}
		local fontBtnFadeEntries = {}

		local function setFontButtonsActive(active)
			for _, fontButton in ipairs(fontButtons) do
				if fontButton and fontButton.Parent then
					fontButton.Active = active
					fontButton.AutoButtonColor = active
				end
			end
		end

		local function closeDropdown()
			if not dropdown.Visible or dropdownClosing then return end
			dropdownOpen = false
			dropdownClosing = true
			setFontButtonsActive(false)
			dropdownTweenToken = dropdownTweenToken + 1
			local closeToken = dropdownTweenToken
			if dropdownTween then pcall(function() dropdownTween:Cancel() end) end

			local fadeOutTween = fadeGroup(fontDropdownFade, false, 0.12)

			local function collapse()
				if closeToken ~= dropdownTweenToken then return end
				dropdownTween = tween(dropdown, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In)
				tween(dropdownStroke, { Transparency = 1 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				local completedConnection = nil
				completedConnection = dropdownTween.Completed:Connect(function()
					if completedConnection then completedConnection:Disconnect() completedConnection = nil end
					if closeToken ~= dropdownTweenToken or dropdownOpen or data.dismissed or not dropdown.Parent then return end
					dropdownClosing = false
					dropdown.Visible = false
					resumeTimer()
				end)
			end

			if fadeOutTween then
				fadeOutTween.Completed:Once(collapse)
			else
				collapse()
			end
		end

		local function openDropdown()
			if dropdownOpen or data.dismissed then return end
			dropdownOpen = true
			dropdownClosing = false
			setFontButtonsActive(true)
			dropdownTweenToken = dropdownTweenToken + 1
			local openToken = dropdownTweenToken
			pauseTimer()
			dropdown.Visible = true
			dropdown.Size = UDim2.new(0, 0, 0, 0)
			dropdown.BackgroundTransparency = 1
			dropdownStroke.Transparency = 1
			fadeGroupSnap(fontDropdownFade, false)
			if dropdownTween then pcall(function() dropdownTween:Cancel() end) end
			dropdownTween = tween(dropdown, { Size = UDim2.new(0, dropdownWidth, 0, dropdownHeight), BackgroundTransparency = 0 }, 0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			tween(dropdownStroke, { Transparency = 0.25 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			dropdownTween.Completed:Once(function()
				if openToken == dropdownTweenToken and dropdown.Visible then
					fadeGroup(fontDropdownFade, true, 0.15)
				end
			end)
		end

		closeAaDropdownFn = closeDropdown
		isAaDropdownOpenFn = function() return dropdownOpen end

		aaBtn.MouseEnter:Connect(function()
			tween(aaFrame, { BackgroundColor3 = Color3.fromRGB(18, 18, 18) }, 0.15)
			tween(aaStroke, { Transparency = 0 }, 0.15)
		end)
		aaBtn.MouseLeave:Connect(function()
			tween(aaFrame, { BackgroundColor3 = Color3.fromRGB(0, 0, 0) }, 0.15)
			tween(aaStroke, { Transparency = 0.15 }, 0.15)
		end)

		aaBtn.MouseButton1Click:Connect(function()
			if isPosDropdownOpenFn and isPosDropdownOpenFn() then
				if closePosDropdownFn then closePosDropdownFn() end
				task.delay(0.22, function()
					if not data.dismissed then openDropdown() end
				end)
			else
				openDropdown()
			end
		end)

		dropdownClose.MouseEnter:Connect(function()
			tween(dropdownClose, { TextColor3 = Color3.fromRGB(230, 230, 230) }, 0.15)
		end)
		dropdownClose.MouseLeave:Connect(function()
			tween(dropdownClose, { TextColor3 = Color3.fromRGB(180, 180, 180) }, 0.15)
		end)
		dropdownClose.Activated:Connect(function()
			closeDropdown()
		end)

		for i, option in ipairs(FONT_OPTIONS) do
			local fontBtn = NewInstance("TextButton", dropdown)
			fontBtn.Size = UDim2.new(1, -16, 0, 24)
			fontBtn.Position = UDim2.new(0, 8, 0, 30 + ((i - 1) * 26))
			fontBtn.BackgroundColor3 = NotifyTheme.btnBg
			fontBtn.BackgroundTransparency = option.Name == currentFontName and 0.1 or 0.45
			fontBtn.BorderSizePixel = 0
			fontBtn.Text = option.Name
			fontBtn.TextColor3 = NotifyTheme.titleColor
			fontBtn.TextSize = 11
			fontBtn.Font = currentFont
			fontBtn.TextXAlignment = Enum.TextXAlignment.Center
			fontBtn.ZIndex = 21
			NewInstance("UICorner", fontBtn).CornerRadius = UDim.new(0, 8)
			table.insert(textTargets, fontBtn)
			table.insert(fontButtons, fontBtn)

			local fontBtnBgEntry = {instance = fontBtn, property = "BackgroundTransparency", visible = fontBtn.BackgroundTransparency}
			table.insert(fontDropdownFade, fontBtnBgEntry)
			table.insert(fontDropdownFade, {instance = fontBtn, property = "TextTransparency", visible = 0})
			fontBtnFadeEntries[fontBtn] = fontBtnBgEntry

			fontBtn.MouseEnter:Connect(function()
				tween(fontBtn, { BackgroundTransparency = 0.08 }, 0.15)
			end)
			fontBtn.MouseLeave:Connect(function()
				tween(fontBtn, { BackgroundTransparency = option.Name == currentFontName and 0.1 or 0.45 }, 0.15)
			end)

			fontBtn.MouseButton1Click:Connect(function()
				if data.dismissed or dropdownClosing or not dropdownOpen then return end
				currentFont = option.Font
				currentFontName = option.Name
				for _, obj in ipairs(textTargets) do
					if obj and obj.Parent then obj.Font = option.Font end
				end
				for _, child in ipairs(dropdown:GetChildren()) do
					if child:IsA("TextButton") and child ~= dropdownClose then
						local isSelected = child == fontBtn
						child.BackgroundTransparency = isSelected and 0.1 or 0.45
						local entry = fontBtnFadeEntries[child]
						if entry then entry.visible = isSelected and 0.1 or 0.45 end
					end
				end
				closeDropdown()
			end)
		end

		local posFrame = NewInstance("Frame", frame)
		posFrame.Size = UDim2.new(0, 26, 0, 26)
		posFrame.Position = UDim2.new(1, -98, 0, 7)
		posFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		posFrame.BorderSizePixel = 0
		posFrame.ZIndex = 13
		NewInstance("UICorner", posFrame).CornerRadius = UDim.new(1, 0)

		local posStroke = NewInstance("UIStroke", posFrame)
		posStroke.Color = Color3.fromRGB(255, 255, 255)
		posStroke.Thickness = 1.25
		posStroke.Transparency = 0.15
		posStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local posBtn = NewInstance("TextButton", posFrame)
		posBtn.Size = UDim2.new(1, 0, 1, 0)
		posBtn.BackgroundTransparency = 1
		posBtn.BorderSizePixel = 0
		posBtn.Text = "Pos"
		posBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		posBtn.TextSize = 10
		posBtn.Font = currentFont
		posBtn.ZIndex = 14
		table.insert(textTargets, posBtn)

		local dropdownPosWidth = 170
		local dropdownPosHeight = 30 + (#POSITION_OPTIONS * 26) + 10
		local dropdownPos = NewInstance("Frame", NotifyScreenGui)
		dropdownPos.AnchorPoint = Vector2.new(0.5, 0.5)
		dropdownPos.Size = UDim2.new(0, 0, 0, 0)
		dropdownPos.Position = UDim2.new(0.5, 0, 0.5, 0)
		dropdownPos.BackgroundColor3 = NotifyTheme.bg
		dropdownPos.BackgroundTransparency = 1
		dropdownPos.BorderSizePixel = 0
		dropdownPos.ClipsDescendants = true
		dropdownPos.Visible = false
		dropdownPos.ZIndex = 20
		data.dropdownPos = dropdownPos
		NewInstance("UICorner", dropdownPos).CornerRadius = UDim.new(0, 12)

		local dropdownPosStroke = NewInstance("UIStroke", dropdownPos)
		dropdownPosStroke.Color = Color3.fromRGB(255, 255, 255)
		dropdownPosStroke.Thickness = 1
		dropdownPosStroke.Transparency = 1
		dropdownPosStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local posDropdownFade = {}

		local dropdownPosTitle = NewInstance("TextLabel", dropdownPos)
		dropdownPosTitle.Size = UDim2.new(1, -40, 0, 24)
		dropdownPosTitle.Position = UDim2.new(0, 12, 0, 5)
		dropdownPosTitle.BackgroundTransparency = 1
		dropdownPosTitle.Text = "Notif Position"
		dropdownPosTitle.TextColor3 = NotifyTheme.titleColor
		dropdownPosTitle.TextSize = 15
		dropdownPosTitle.Font = currentFont
		dropdownPosTitle.TextXAlignment = Enum.TextXAlignment.Left
		dropdownPosTitle.ZIndex = 21
		table.insert(textTargets, dropdownPosTitle)
		table.insert(posDropdownFade, {instance = dropdownPosTitle, property = "TextTransparency", visible = 0})

		local dropdownPosClose = NewInstance("TextButton", dropdownPos)
		dropdownPosClose.Size = UDim2.new(0, 24, 0, 24)
		dropdownPosClose.Position = UDim2.new(1, -30, 0, 5)
		dropdownPosClose.BackgroundTransparency = 1
		dropdownPosClose.BorderSizePixel = 0
		dropdownPosClose.Text = "╳"
		dropdownPosClose.TextColor3 = Color3.fromRGB(180, 180, 180)
		dropdownPosClose.TextSize = 16
		dropdownPosClose.Font = currentFont
		dropdownPosClose.ZIndex = 22
		table.insert(textTargets, dropdownPosClose)
		table.insert(posDropdownFade, {instance = dropdownPosClose, property = "TextTransparency", visible = 0})

		local dropdownPosOpen = false
		local dropdownPosClosing = false
		local dropdownPosTween = nil
		local dropdownPosTweenToken = 0
		local posButtons = {}
		local posBtnFadeEntries = {}

		local function setPosButtonsActive(active)
			for _, posButton in ipairs(posButtons) do
				if posButton and posButton.Parent then
					posButton.Active = active
					posButton.AutoButtonColor = active
				end
			end
		end

		local function closeDropdownPos()
			if not dropdownPos.Visible or dropdownPosClosing then return end
			dropdownPosOpen = false
			dropdownPosClosing = true
			setPosButtonsActive(false)
			dropdownPosTweenToken = dropdownPosTweenToken + 1
			local closeToken = dropdownPosTweenToken
			if dropdownPosTween then pcall(function() dropdownPosTween:Cancel() end) end

			local fadeOutTween = fadeGroup(posDropdownFade, false, 0.12)

			local function collapse()
				if closeToken ~= dropdownPosTweenToken then return end
				dropdownPosTween = tween(dropdownPos, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In)
				tween(dropdownPosStroke, { Transparency = 1 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				local completedConnection = nil
				completedConnection = dropdownPosTween.Completed:Connect(function()
					if completedConnection then completedConnection:Disconnect() completedConnection = nil end
					if closeToken ~= dropdownPosTweenToken or dropdownPosOpen or data.dismissed or not dropdownPos.Parent then return end
					dropdownPosClosing = false
					dropdownPos.Visible = false
					resumeTimer()
				end)
			end

			if fadeOutTween then
				fadeOutTween.Completed:Once(collapse)
			else
				collapse()
			end
		end

		local function openDropdownPos()
			if dropdownPosOpen or data.dismissed then return end
			dropdownPosOpen = true
			dropdownPosClosing = false
			setPosButtonsActive(true)
			dropdownPosTweenToken = dropdownPosTweenToken + 1
			local openToken = dropdownPosTweenToken
			pauseTimer()
			dropdownPos.Visible = true
			dropdownPos.Size = UDim2.new(0, 0, 0, 0)
			dropdownPos.BackgroundTransparency = 1
			dropdownPosStroke.Transparency = 1
			fadeGroupSnap(posDropdownFade, false)
			if dropdownPosTween then pcall(function() dropdownPosTween:Cancel() end) end
			dropdownPosTween = tween(dropdownPos, { Size = UDim2.new(0, dropdownPosWidth, 0, dropdownPosHeight), BackgroundTransparency = 0 }, 0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			tween(dropdownPosStroke, { Transparency = 0.25 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			dropdownPosTween.Completed:Once(function()
				if openToken == dropdownPosTweenToken and dropdownPos.Visible then
					fadeGroup(posDropdownFade, true, 0.15)
				end
			end)
		end

		closePosDropdownFn = closeDropdownPos
		isPosDropdownOpenFn = function() return dropdownPosOpen end

		posBtn.MouseEnter:Connect(function()
			tween(posFrame, { BackgroundColor3 = Color3.fromRGB(18, 18, 18) }, 0.15)
			tween(posStroke, { Transparency = 0 }, 0.15)
		end)
		posBtn.MouseLeave:Connect(function()
			tween(posFrame, { BackgroundColor3 = Color3.fromRGB(0, 0, 0) }, 0.15)
			tween(posStroke, { Transparency = 0.15 }, 0.15)
		end)

		posBtn.MouseButton1Click:Connect(function()
			if isAaDropdownOpenFn and isAaDropdownOpenFn() then
				if closeAaDropdownFn then closeAaDropdownFn() end
				task.delay(0.22, function()
					if not data.dismissed then openDropdownPos() end
				end)
			else
				openDropdownPos()
			end
		end)

		dropdownPosClose.MouseEnter:Connect(function()
			tween(dropdownPosClose, { TextColor3 = Color3.fromRGB(230, 230, 230) }, 0.15)
		end)
		dropdownPosClose.MouseLeave:Connect(function()
			tween(dropdownPosClose, { TextColor3 = Color3.fromRGB(180, 180, 180) }, 0.15)
		end)
		dropdownPosClose.Activated:Connect(function()
			closeDropdownPos()
		end)

		for i, option in ipairs(POSITION_OPTIONS) do
			local posOptBtn = NewInstance("TextButton", dropdownPos)
			posOptBtn.Size = UDim2.new(1, -16, 0, 24)
			posOptBtn.Position = UDim2.new(0, 8, 0, 30 + ((i - 1) * 26))
			posOptBtn.BackgroundColor3 = NotifyTheme.btnBg
			posOptBtn.BackgroundTransparency = option.Name == currentPositionOption.Name and 0.1 or 0.45
			posOptBtn.BorderSizePixel = 0
			posOptBtn.Text = option.Label
			posOptBtn.TextColor3 = NotifyTheme.titleColor
			posOptBtn.TextSize = 11
			posOptBtn.Font = currentFont
			posOptBtn.TextXAlignment = Enum.TextXAlignment.Center
			posOptBtn.ZIndex = 21
			NewInstance("UICorner", posOptBtn).CornerRadius = UDim.new(0, 8)
			table.insert(textTargets, posOptBtn)
			table.insert(posButtons, posOptBtn)

			local posBtnBgEntry = {instance = posOptBtn, property = "BackgroundTransparency", visible = posOptBtn.BackgroundTransparency}
			table.insert(posDropdownFade, posBtnBgEntry)
			table.insert(posDropdownFade, {instance = posOptBtn, property = "TextTransparency", visible = 0})
			posBtnFadeEntries[posOptBtn] = posBtnBgEntry

			posOptBtn.MouseEnter:Connect(function()
				tween(posOptBtn, { BackgroundTransparency = 0.08 }, 0.15)
			end)
			posOptBtn.MouseLeave:Connect(function()
				tween(posOptBtn, { BackgroundTransparency = currentPositionOption.Name == option.Name and 0.1 or 0.45 }, 0.15)
			end)

			posOptBtn.MouseButton1Click:Connect(function()
				if data.dismissed or dropdownPosClosing or not dropdownPosOpen then return end
				currentPositionOption = option
				for _, child in ipairs(dropdownPos:GetChildren()) do
					if child:IsA("TextButton") and child ~= dropdownPosClose then
						local isSelected = child == posOptBtn
						child.BackgroundTransparency = isSelected and 0.1 or 0.45
						local entry = posBtnFadeEntries[child]
						if entry then entry.visible = isSelected and 0.1 or 0.45 end
					end
				end
				repositionAll()
				closeDropdownPos()
			end)
		end

		local progressBg = NewInstance("Frame", frame)
		progressBg.Size = UDim2.new(1, -20, 0, 3)
		progressBg.Position = UDim2.new(0, 10, 0, frameHeight - 10)
		progressBg.BackgroundColor3 = NotifyTheme.progressBg
		progressBg.BorderSizePixel = 0
		progressBg.ZIndex = 11
		NewInstance("UICorner", progressBg).CornerRadius = UDim.new(1, 0)

		local progressBar = NewInstance("Frame", progressBg)
		progressBar.Size = UDim2.new(1, 0, 1, 0)
		progressBar.BackgroundColor3 = NotifyTheme.accent
		progressBar.BorderSizePixel = 0
		progressBar.ZIndex = 12
		NewInstance("UICorner", progressBar).CornerRadius = UDim.new(1, 0)

		local targetPos = getSlotPos(#activeNotifs)
		local overshootSign = (currentPositionOption.XSide == "left") and 1 or -1
		local bounceOver = UDim2.new(targetPos.X.Scale, targetPos.X.Offset + overshootSign * 12, targetPos.Y.Scale, targetPos.Y.Offset)

		local _, entranceToken = playFrameTween(data, { Position = bounceOver }, 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		task.delay(0.4, function()
			if data.dismissed or not frame.Parent or data.positionToken ~= entranceToken then return end
			local idx = (function()
				for i, d in ipairs(activeNotifs) do
					if d == data then return i end
				end
				return nil
			end)()
			if not idx then return end
			local currentTargetPos = getSlotPos(idx)
			local backSign = (currentPositionOption.XSide == "left") and 1 or -1
			local currentBounceBack = UDim2.new(currentTargetPos.X.Scale, currentTargetPos.X.Offset - backSign * 4, currentTargetPos.Y.Scale, currentTargetPos.Y.Offset)
			local _, bounceToken = playFrameTween(data, { Position = currentBounceBack }, 0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			task.delay(0.13, function()
				if data.dismissed or not frame.Parent or data.positionToken ~= bounceToken then return end
				local finalIdx = (function()
					for i, d in ipairs(activeNotifs) do
						if d == data then return i end
					end
					return nil
				end)()
				if not finalIdx then return end
				playFrameTween(data, { Position = getSlotPos(finalIdx) }, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			end)
		end)

		if duration <= 0 then
			progressBar.Size = UDim2.new(0, 0, 1, 0)
			dismissNotif(frame, data)
		else
			task.spawn(function()
				local fixedStep = 1 / 60
				local maxFrameDt = 0.25
				local accumulator = 0
				local last = os.clock()
				while not data.dismissed and data.remaining > 0 and frame.Parent do
					local heartbeatDt = RunService.Heartbeat:Wait()
					local now = os.clock()
					local dt = type(heartbeatDt) == "number" and heartbeatDt or now - last
					last = now
					if dt < 0 then dt = 0 end
					if dt > maxFrameDt then dt = maxFrameDt end
					if not data.paused then
						accumulator = accumulator + dt
						while accumulator >= fixedStep and data.remaining > 0 do
							data.remaining = data.remaining - fixedStep
							accumulator = accumulator - fixedStep
						end
						if data.remaining < 0 then data.remaining = 0 end
						local ratio = data.remaining / data.duration
						if ratio < 0 then ratio = 0 end
						if ratio > 1 then ratio = 1 end
						if progressBar and progressBar.Parent then
							progressBar.Size = UDim2.new(ratio, 0, 1, 0)
						end
					end
				end
				if not data.dismissed then dismissNotif(frame, data) end
			end)
		end

		local Notif = {}

		function Notif:Close()
			dismissNotif(frame, data)
		end

		return MakeCaseInsensitive(Notif)
	end
end

MakeCaseInsensitive(Window)
MakeCaseInsensitive(Tab)
MakeCaseInsensitive(Library)

return Library
