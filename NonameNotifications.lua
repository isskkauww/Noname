local NNNotify = nil

local function _nnInit()
	local function _nnRef(svc)
		local s = game:GetService(svc)
		if cloneref and type(cloneref) == "function" then
			local ok, r = pcall(cloneref, s)
			if ok and r then return r end
		end
		return s
	end

	local Players = _nnRef("Players")
	local TweenService = _nnRef("TweenService")
	local RunService = _nnRef("RunService")
	local HttpService = _nnRef("HttpService")

	local IconModule
	task.spawn(function()
		local ok, result = pcall(function()
			return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/Main-v2.lua"))()
		end)
		if ok and type(result) == "table" then
			IconModule = result
		end
	end)

	local LocalPlayer = Players.LocalPlayer
	local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)

	local function _nnPickParent()
		if gethui and type(gethui) == "function" then
			local ok, h = pcall(gethui)
			if ok and type(typeof) == "function" and typeof(h) == "Instance" then return h end
		end
		local cg = _nnRef("CoreGui")
		if cg then
			local rg = cg:FindFirstChild("RobloxGui")
			if rg then return rg end
			return cg
		end
		return PlayerGui
	end

	local function _nnProtect(gui)
		if type(syn) == "table" and type(syn.protect_gui) == "function" then
			pcall(syn.protect_gui, gui)
		elseif protect_gui and type(protect_gui) == "function" then
			pcall(protect_gui, gui)
		end
		return gui
	end

	local guiParent = _nnPickParent()
	if not guiParent then error("NNNotify: Gui parent unavailable", 2) end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "NNNotifGui"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	_nnProtect(ScreenGui)
	ScreenGui.Parent = guiParent

	local activeNotifs = {}
	local DEFAULT_FONT = Enum.Font.GothamBold
	local FONT_OPTIONS = {
		{ Name = "GothamBold", Font = Enum.Font.GothamBold },
		{ Name = "Gotham", Font = Enum.Font.Gotham },
		{ Name = "SourceSansBold", Font = Enum.Font.SourceSansBold },
		{ Name = "ArialBold", Font = Enum.Font.ArialBold },
		{ Name = "Arcade", Font = Enum.Font.Arcade },
		{ Name = "Fantasy", Font = Enum.Font.Fantasy },
	}
	local SETTINGS_FOLDER = "Noname"
	local SETTINGS_FILE = SETTINGS_FOLDER .. "/NonameNotif_Settings.json"

	local function getFontByName(name)
		if type(name) ~= "string" then return DEFAULT_FONT, "GothamBold" end
		for _, option in ipairs(FONT_OPTIONS) do
			if option.Name == name then
				return option.Font, option.Name
			end
		end
		return DEFAULT_FONT, "GothamBold"
	end

	local POSITION_OPTIONS = {
		{ Name = "BottomRight", Label = "Bottom Right", XSide = "right", YSide = "bottom" },
		{ Name = "TopRight", Label = "Top Right", XSide = "right", YSide = "top" },
		{ Name = "BottomLeft", Label = "Bottom Left", XSide = "left", YSide = "bottom" },
		{ Name = "TopLeft", Label = "Top Left", XSide = "left", YSide = "top" },
	}
	local DEFAULT_POSITION_NAME = "BottomRight"

	local function getPositionByName(name)
		if type(name) ~= "string" then return POSITION_OPTIONS[1] end
		for _, option in ipairs(POSITION_OPTIONS) do
			if option.Name == name then
				return option
			end
		end
		return POSITION_OPTIONS[1]
	end

	local function canUseSettingsFile()
		return type(isfile) == "function" and type(readfile) == "function" and type(writefile) == "function"
			and type(isfolder) == "function" and type(makefolder) == "function"
	end

	local function ensureSettingsFolder()
		if isfolder(SETTINGS_FOLDER) then return true end
		local ok = pcall(makefolder, SETTINGS_FOLDER)
		return ok
	end

	local function loadSettings()
		if not canUseSettingsFile() or not HttpService then return {} end
		if not isfile(SETTINGS_FILE) then return {} end
		local okRead, content = pcall(readfile, SETTINGS_FILE)
		if not okRead or type(content) ~= "string" or content == "" then return {} end
		local okDecode, decoded = pcall(function()
			return HttpService:JSONDecode(content)
		end)
		if okDecode and type(decoded) == "table" then return decoded end
		return {}
	end

	local function saveSettings(settings)
		if not canUseSettingsFile() or not ensureSettingsFolder() then return end
		local payload = '{"Font":"' .. tostring(settings.Font) .. '","Position":"' .. tostring(settings.Position) .. '"}'
		if HttpService then
			local okEncode, encoded = pcall(function()
				return HttpService:JSONEncode(settings)
			end)
			if okEncode and type(encoded) == "string" then payload = encoded end
		end
		pcall(writefile, SETTINGS_FILE, payload)
	end

	local savedSettings = loadSettings()
	local currentFont, currentFontName = getFontByName(savedSettings.Font or savedSettings.font)
	local currentPositionOption = getPositionByName(savedSettings.Position or savedSettings.position or DEFAULT_POSITION_NAME)
	saveSettings({ Font = currentFontName, Position = currentPositionOption.Name })

	local function applyFont(font, targets)
		if type(typeof) ~= "function" or typeof(font) ~= "EnumItem" then font = DEFAULT_FONT end
		for _, obj in ipairs(targets) do
			if obj and obj.Parent then
				obj.Font = font
			end
		end
	end

	local function getFrameHeight(btnCount, textLines)
		local textHeight = math.max(24, (tonumber(textLines) or 1) * 14)
		if btnCount > 0 then
			return 38 + textHeight + 4 + 1 + 34 + 15
		end
		return 38 + textHeight + 22
	end

	local function cleanSingleLineText(value)
		if type(value) ~= "string" then value = tostring(value) end
		value = value:gsub("\r\n", " "):gsub("\n", " "):gsub("\r", " ")
		value = value:gsub("%s+", " ")
		value = value:gsub("^%s+", ""):gsub("%s+$", "")
		return value
	end

	local function cleanNotifText(value)
		if type(value) ~= "string" then value = tostring(value) end
		value = value:gsub("\r\n", " "):gsub("\n", " "):gsub("\r", " ")
		local newlineCount = 0
		local parts = {}
		local cursor = 1
		while true do
			local startPos, endPos = string.find(value, "/n", cursor, true)
			if not startPos then
				table.insert(parts, string.sub(value, cursor))
				break
			end
			table.insert(parts, string.sub(value, cursor, startPos - 1))
			if newlineCount < 3 then
				table.insert(parts, "\n")
				newlineCount = newlineCount + 1
			else
				table.insert(parts, " ")
			end
			cursor = endPos + 1
		end
		return table.concat(parts), newlineCount + 1, newlineCount
	end

	local THEME = {
		bg = Color3.fromRGB(15, 15, 15),
		border = Color3.fromRGB(50, 50, 50),
		accent = Color3.fromRGB(255, 255, 255),
		btnBg = Color3.fromRGB(30, 30, 30),
		btnHover = Color3.fromRGB(255, 255, 255),
		btnText = Color3.fromRGB(160, 160, 160),
		btnTextHover = Color3.fromRGB(0, 0, 0),
		titleColor = Color3.fromRGB(255, 255, 255),
		textColor = Color3.fromRGB(140, 140, 140),
		iconBg = Color3.fromRGB(25, 25, 25),
		progressBg = Color3.fromRGB(35, 35, 35),
	}

	local function getBaseXY(frameHeight, totalOffset)
		local opt = currentPositionOption or POSITION_OPTIONS[1]
		local xScale, xOffset
		if opt.XSide == "left" then
			xScale, xOffset = 0, 16
		else
			xScale, xOffset = 1, -(320 + 16)
		end
		local yScale, yOffset
		if opt.YSide == "top" then
			yScale, yOffset = 0, 24 + totalOffset
		else
			yScale, yOffset = 1, -(frameHeight + 24) - totalOffset
		end
		return UDim2.new(xScale, xOffset, yScale, yOffset)
	end

	local function getOffscreenX()
		local opt = currentPositionOption or POSITION_OPTIONS[1]
		if opt.XSide == "left" then
			return 0, -(320 + 30)
		end
		return 1, 320 + 30
	end

	local function getOvershootSign()
		local opt = currentPositionOption or POSITION_OPTIONS[1]
		if opt.XSide == "left" then return 1 end
		return -1
	end

	local function getSlotPos(index)
		local totalOffset = 0
		for i = 1, index - 1 do
			local d = activeNotifs[i]
			local dh = d and d.frameHeight or 84
			totalOffset = totalOffset + dh + 8
		end
		local h = activeNotifs[index] and activeNotifs[index].frameHeight or 84
		return getBaseXY(h, totalOffset)
	end

	local function getNotifIndex(data)
		for i, d in ipairs(activeNotifs) do
			if d == data then return i end
		end
		return nil
	end

	local function ensureScreenGui()
		if ScreenGui and ScreenGui.Parent then return true end
		local parent = _nnPickParent()
		if not parent then return false end
		local ok = pcall(function()
			ScreenGui.Parent = parent
		end)
		return ok and ScreenGui.Parent ~= nil
	end

	local function stopTween(tween)
		if tween then
			pcall(function()
				tween:Cancel()
			end)
		end
	end

	local function playFrameTween(data, tweenInfo, props)
		if not data or data.dismissed or not data.frame or not data.frame.Parent then return nil end
		data.positionToken = (data.positionToken or 0) + 1
		stopTween(data.positionTween)
		local tween = TweenService:Create(data.frame, tweenInfo, props)
		data.positionTween = tween
		tween:Play()
		return tween, data.positionToken
	end

	local function repositionAll()
		local totalOffset = 0
		for i, data in ipairs(activeNotifs) do
			local frameHeight = data and data.frameHeight or 84
			local pos = getBaseXY(frameHeight, totalOffset)
			if data and data.frame and data.frame.Parent and not data.dismissed then
				playFrameTween(data, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Position = pos
				})
			end
			totalOffset = totalOffset + frameHeight + 8
		end
	end

	local function dismissNotif(frame, data)
		if not data or data.dismissed then return end
		data.dismissed = true
		data.paused = true
		stopTween(data.positionTween)
		stopTween(data.dismissTween)

		if not frame or not frame.Parent then
			for i, d in ipairs(activeNotifs) do
				if d.frame == frame then
					table.remove(activeNotifs, i)
					break
				end
			end
			if data.dropdown then data.dropdown:Destroy() end
			if data.dropdownPos then data.dropdownPos:Destroy() end
			repositionAll()
			return
		end

		local currentPos = frame.Position
		local exitXScale, exitXOffset = getOffscreenX()
		local exitPos = UDim2.new(exitXScale, exitXOffset, currentPos.Y.Scale, currentPos.Y.Offset)
		local tween = TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
			Position = exitPos
		})
		data.dismissTween = tween
		local completedConnection = nil
		completedConnection = tween.Completed:Connect(function()
			if completedConnection then
				completedConnection:Disconnect()
				completedConnection = nil
			end
			for i, d in ipairs(activeNotifs) do
				if d.frame == frame then
					table.remove(activeNotifs, i)
					break
				end
			end
			frame:Destroy()
			if data.dropdown then data.dropdown:Destroy() end
			if data.dropdownPos then data.dropdownPos:Destroy() end
			repositionAll()
		end)
		tween:Play()
	end

	local function createNotif(config)
		if not ensureScreenGui() then
			warn("NNNotify: ScreenGui unavailable")
			return nil
		end
		if type(config) ~= "table" then config = {} end
		local title = cleanSingleLineText(config.Title or "Notification")
		local text, textLines = cleanNotifText(config.Text or "")
		local duration = config.Duration or 4
		local buttons = config.Buttons or {}
		if type(duration) ~= "number" or duration ~= duration or duration < 0 or duration == math.huge or duration == -math.huge then duration = 4 end
		if type(buttons) ~= "table" then buttons = {} end
		if #buttons > 2 then buttons = { buttons[1], buttons[2] } end
		local btnCount = #buttons
		local textTargets = {}

		local textHeight = math.max(24, textLines * 14)
		local dividerY = 38 + textHeight + 4
		local buttonY = dividerY + 1
		local frameHeight = getFrameHeight(btnCount, textLines)

		local frame = Instance.new("Frame")
		frame.Name = "NNNotif"
		frame.Size = UDim2.new(0, 320, 0, frameHeight)
		local startXScale, startXOffset = getOffscreenX()
		local startSlot = getBaseXY(frameHeight, 0)
		frame.Position = UDim2.new(startXScale, startXOffset, startSlot.Y.Scale, startSlot.Y.Offset)
		frame.BackgroundColor3 = THEME.bg
		frame.BorderSizePixel = 0
		frame.ZIndex = 10
		frame.Parent = ScreenGui

		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

		local stroke = Instance.new("UIStroke")
		stroke.Color = THEME.border
		stroke.Thickness = 1
		stroke.Transparency = 0.3
		stroke.Parent = frame

		local closeBtn = Instance.new("TextButton")
		closeBtn.Size = UDim2.new(0, 28, 0, 28)
		closeBtn.Position = UDim2.new(1, -34, 0, 6)
		closeBtn.BackgroundTransparency = 1
		closeBtn.BorderSizePixel = 0
		closeBtn.Text = ""
		closeBtn.ZIndex = 13
		closeBtn.Parent = frame

		local closeIcon = Instance.new("TextLabel")
		closeIcon.Size = UDim2.new(0, 42, 0, 42)
		closeIcon.Position = UDim2.new(0.5, -21, 0.5, -22)
		closeIcon.BackgroundTransparency = 1
		closeIcon.BorderSizePixel = 0
		closeIcon.Text = "×"
		closeIcon.TextColor3 = Color3.fromRGB(80, 80, 80)
		closeIcon.TextSize = 36
		closeIcon.Font = currentFont
		closeIcon.ZIndex = 14
		closeIcon.Parent = closeBtn
		table.insert(textTargets, closeIcon)

		closeBtn.MouseEnter:Connect(function()
			TweenService:Create(closeIcon, TweenInfo.new(0.15), {
				TextColor3 = Color3.fromRGB(200, 200, 200)
			}):Play()
		end)

		closeBtn.MouseLeave:Connect(function()
			TweenService:Create(closeIcon, TweenInfo.new(0.15), {
				TextColor3 = Color3.fromRGB(80, 80, 80)
			}):Play()
		end)

		local iconFrame = Instance.new("Frame")
		iconFrame.Size = UDim2.new(0, 36, 0, 36)
		iconFrame.Position = UDim2.new(0, 20, 0, 18)
		iconFrame.BackgroundColor3 = THEME.bg
		iconFrame.BorderSizePixel = 0
		iconFrame.ZIndex = 11
		iconFrame.ClipsDescendants = true
		iconFrame.Parent = frame

		local customIconSet = false
		if IconModule and type(config.Icon) == "string" and config.Icon ~= "" then
			local ok, iconObj = pcall(function()
				return IconModule.Image({
					Icon = config.Icon,
					Size = UDim2.new(1, 0, 1, 0),
				})
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
			local iconImage = Instance.new("ImageLabel")
			iconImage.Size = UDim2.new(1, 0, 1, 0)
			iconImage.BackgroundTransparency = 1
			iconImage.ZIndex = 12
			iconImage.Parent = iconFrame

			task.spawn(function()
				local ok, thumb = pcall(function()
					return Players:GetUserThumbnailAsync(
						LocalPlayer.UserId,
						Enum.ThumbnailType.HeadShot,
						Enum.ThumbnailSize.Size48x48
					)
				end)
				if ok and type(thumb) == "string" and iconImage.Parent then iconImage.Image = thumb end
			end)
		end

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, -176, 0, 16)
		titleLabel.Position = UDim2.new(0, 64, 0, 18)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = THEME.titleColor
		titleLabel.TextSize = 13
		titleLabel.Font = currentFont
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.TextYAlignment = Enum.TextYAlignment.Center
		titleLabel.TextWrapped = false
		titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
		titleLabel.ZIndex = 12
		titleLabel.Parent = frame
		table.insert(textTargets, titleLabel)

		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(1, -84, 0, textHeight)
		textLabel.Position = UDim2.new(0, 64, 0, 38)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = text
		textLabel.TextColor3 = THEME.textColor
		textLabel.TextSize = 11
		textLabel.Font = currentFont
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.TextYAlignment = Enum.TextYAlignment.Top
		textLabel.TextWrapped = true
		textLabel.ZIndex = 12
		textLabel.Parent = frame
		table.insert(textTargets, textLabel)

		local data = { frame = frame, frameHeight = frameHeight, dismissed = false, paused = false, remaining = duration, duration = duration, buttonClicked = false, positionTween = nil, positionToken = 0, dismissTween = nil }
		table.insert(activeNotifs, data)

		closeBtn.MouseButton1Click:Connect(function()
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

		local aaFrame = Instance.new("Frame")
		aaFrame.Size = UDim2.new(0, 26, 0, 26)
		aaFrame.Position = UDim2.new(1, -66, 0, 7)
		aaFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		aaFrame.BorderSizePixel = 0
		aaFrame.ZIndex = 13
		aaFrame.Parent = frame
		Instance.new("UICorner", aaFrame).CornerRadius = UDim.new(1, 0)

		local aaStroke = Instance.new("UIStroke")
		aaStroke.Color = Color3.fromRGB(255, 255, 255)
		aaStroke.Thickness = 1.25
		aaStroke.Transparency = 0.15
		aaStroke.Parent = aaFrame
		aaStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local aaBtn = Instance.new("TextButton")
		aaBtn.Size = UDim2.new(1, 0, 1, 0)
		aaBtn.BackgroundTransparency = 1
		aaBtn.BorderSizePixel = 0
		aaBtn.Text = "Aa"
		aaBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		aaBtn.TextSize = 14
		aaBtn.Font = currentFont
		aaBtn.ZIndex = 14
		aaBtn.Parent = aaFrame
		table.insert(textTargets, aaBtn)

		local dropdownWidth = 136
		local dropdownHeight = 30 + (#FONT_OPTIONS * 26) + 10
		local dropdown = Instance.new("Frame")
		dropdown.AnchorPoint = Vector2.new(0.5, 0.5)
		dropdown.Size = UDim2.new(0, 0, 0, 0)
		dropdown.Position = UDim2.new(0.5, 0, 0.5, 0)
		dropdown.BackgroundColor3 = THEME.bg
		dropdown.BackgroundTransparency = 1
		dropdown.BorderSizePixel = 0
		dropdown.ClipsDescendants = true
		dropdown.Visible = false
		dropdown.ZIndex = 20
		dropdown.Parent = ScreenGui
		data.dropdown = dropdown
		Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0, 12)

		local dropdownStroke = Instance.new("UIStroke")
		dropdownStroke.Color = Color3.fromRGB(255, 255, 255)
		dropdownStroke.Thickness = 1
		dropdownStroke.Transparency = 1
		dropdownStroke.Parent = dropdown
		dropdownStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local dropdownTitle = Instance.new("TextLabel")
		dropdownTitle.Size = UDim2.new(1, -40, 0, 24)
		dropdownTitle.Position = UDim2.new(0, 12, 0, 5)
		dropdownTitle.BackgroundTransparency = 1
		dropdownTitle.Text = "Font"
		dropdownTitle.TextColor3 = THEME.titleColor
		dropdownTitle.TextSize = 15
		dropdownTitle.Font = currentFont
		dropdownTitle.TextXAlignment = Enum.TextXAlignment.Left
		dropdownTitle.ZIndex = 21
		dropdownTitle.Parent = dropdown
		table.insert(textTargets, dropdownTitle)

		local dropdownClose = Instance.new("TextButton")
		dropdownClose.Size = UDim2.new(0, 24, 0, 24)
		dropdownClose.Position = UDim2.new(1, -30, 0, 5)
		dropdownClose.BackgroundTransparency = 1
		dropdownClose.BorderSizePixel = 0
		dropdownClose.Text = ""
		dropdownClose.ZIndex = 22
		dropdownClose.Parent = dropdown

		local dropdownCloseIcon = Instance.new("TextLabel")
		dropdownCloseIcon.Size = UDim2.new(0, 34, 0, 34)
		dropdownCloseIcon.Position = UDim2.new(0.5, -17, 0.5, -18)
		dropdownCloseIcon.BackgroundTransparency = 1
		dropdownCloseIcon.BorderSizePixel = 0
		dropdownCloseIcon.Text = "×"
		dropdownCloseIcon.TextColor3 = Color3.fromRGB(180, 180, 180)
		dropdownCloseIcon.TextSize = 30
		dropdownCloseIcon.Font = currentFont
		dropdownCloseIcon.ZIndex = 23
		dropdownCloseIcon.Parent = dropdownClose
		table.insert(textTargets, dropdownCloseIcon)

		local selectedFont = currentFont
		local selectedFontName = currentFontName
		local dropdownOpen = false
		local dropdownClosing = false
		local dropdownTween = nil
		local dropdownTweenToken = 0
		local fontButtons = {}

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
			stopTween(dropdownTween)
			dropdownTween = TweenService:Create(dropdown, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Size = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1
			})
			dropdownTween:Play()
			TweenService:Create(dropdownStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Transparency = 1
			}):Play()
			local completedConnection = nil
			completedConnection = dropdownTween.Completed:Connect(function()
				if completedConnection then
					completedConnection:Disconnect()
					completedConnection = nil
				end
				if closeToken ~= dropdownTweenToken or dropdownOpen or data.dismissed or not dropdown.Parent then return end
				dropdownClosing = false
				dropdown.Visible = false
				resumeTimer()
			end)
		end

		local function openDropdown()
			if dropdownOpen or data.dismissed then return end
			dropdownOpen = true
			dropdownClosing = false
			setFontButtonsActive(true)
			dropdownTweenToken = dropdownTweenToken + 1
			pauseTimer()
			dropdown.Visible = true
			dropdown.Size = UDim2.new(0, 0, 0, 0)
			dropdown.BackgroundTransparency = 1
			dropdownStroke.Transparency = 1
			stopTween(dropdownTween)
			dropdownTween = TweenService:Create(dropdown, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, dropdownWidth, 0, dropdownHeight),
				BackgroundTransparency = 0
			})
			dropdownTween:Play()
			TweenService:Create(dropdownStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = 0.25
			}):Play()
		end

		closeAaDropdownFn = closeDropdown
		isAaDropdownOpenFn = function() return dropdownOpen end

		aaBtn.MouseEnter:Connect(function()
			TweenService:Create(aaFrame, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(18, 18, 18)
			}):Play()
			TweenService:Create(aaStroke, TweenInfo.new(0.15), {
				Transparency = 0
			}):Play()
		end)

		aaBtn.MouseLeave:Connect(function()
			TweenService:Create(aaFrame, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			}):Play()
			TweenService:Create(aaStroke, TweenInfo.new(0.15), {
				Transparency = 0.15
			}):Play()
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
			TweenService:Create(dropdownCloseIcon, TweenInfo.new(0.15), {
				TextColor3 = Color3.fromRGB(230, 230, 230)
			}):Play()
		end)

		dropdownClose.MouseLeave:Connect(function()
			TweenService:Create(dropdownCloseIcon, TweenInfo.new(0.15), {
				TextColor3 = Color3.fromRGB(180, 180, 180)
			}):Play()
		end)

		dropdownClose.MouseButton1Click:Connect(function()
			closeDropdown()
		end)

		for i, option in ipairs(FONT_OPTIONS) do
			local fontBtn = Instance.new("TextButton")
			fontBtn.Size = UDim2.new(1, -16, 0, 24)
			fontBtn.Position = UDim2.new(0, 8, 0, 30 + ((i - 1) * 26))
			fontBtn.BackgroundColor3 = THEME.btnBg
			fontBtn.BackgroundTransparency = option.Name == currentFontName and 0.1 or 0.45
			fontBtn.BorderSizePixel = 0
			fontBtn.Text = option.Name
			fontBtn.TextColor3 = THEME.titleColor
			fontBtn.TextSize = 11
			fontBtn.Font = currentFont
			fontBtn.TextXAlignment = Enum.TextXAlignment.Center
			fontBtn.ZIndex = 21
			fontBtn.Parent = dropdown
			Instance.new("UICorner", fontBtn).CornerRadius = UDim.new(0, 8)
			table.insert(textTargets, fontBtn)
			table.insert(fontButtons, fontBtn)

			fontBtn.MouseEnter:Connect(function()
				TweenService:Create(fontBtn, TweenInfo.new(0.15), {
					BackgroundTransparency = 0.08
				}):Play()
			end)

			fontBtn.MouseLeave:Connect(function()
				TweenService:Create(fontBtn, TweenInfo.new(0.15), {
					BackgroundTransparency = option.Font == selectedFont and 0.1 or 0.45
				}):Play()
			end)

			fontBtn.MouseButton1Click:Connect(function()
				if data.dismissed or dropdownClosing or not dropdownOpen then return end
				selectedFont = option.Font
				selectedFontName = option.Name
				currentFont = option.Font
				currentFontName = option.Name
				saveSettings({ Font = option.Name, Position = currentPositionOption.Name })
				applyFont(option.Font, textTargets)
				for _, child in ipairs(dropdown:GetChildren()) do
					if child:IsA("TextButton") and child ~= dropdownClose then
						child.BackgroundTransparency = child == fontBtn and 0.1 or 0.45
					end
				end
				closeDropdown()
			end)
		end

		local posFrame = Instance.new("Frame")
		posFrame.Size = UDim2.new(0, 26, 0, 26)
		posFrame.Position = UDim2.new(1, -98, 0, 7)
		posFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		posFrame.BorderSizePixel = 0
		posFrame.ZIndex = 13
		posFrame.Parent = frame
		Instance.new("UICorner", posFrame).CornerRadius = UDim.new(1, 0)

		local posStroke = Instance.new("UIStroke")
		posStroke.Color = Color3.fromRGB(255, 255, 255)
		posStroke.Thickness = 1.25
		posStroke.Transparency = 0.15
		posStroke.Parent = posFrame
		posStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local posBtn = Instance.new("TextButton")
		posBtn.Size = UDim2.new(1, 0, 1, 0)
		posBtn.BackgroundTransparency = 1
		posBtn.BorderSizePixel = 0
		posBtn.Text = "Pos"
		posBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		posBtn.TextSize = 10
		posBtn.Font = currentFont
		posBtn.ZIndex = 14
		posBtn.Parent = posFrame
		table.insert(textTargets, posBtn)

		local dropdownPosWidth = 170
		local dropdownPosHeight = 30 + (#POSITION_OPTIONS * 26) + 10
		local dropdownPos = Instance.new("Frame")
		dropdownPos.AnchorPoint = Vector2.new(0.5, 0.5)
		dropdownPos.Size = UDim2.new(0, 0, 0, 0)
		dropdownPos.Position = UDim2.new(0.5, 0, 0.5, 0)
		dropdownPos.BackgroundColor3 = THEME.bg
		dropdownPos.BackgroundTransparency = 1
		dropdownPos.BorderSizePixel = 0
		dropdownPos.ClipsDescendants = true
		dropdownPos.Visible = false
		dropdownPos.ZIndex = 20
		dropdownPos.Parent = ScreenGui
		data.dropdownPos = dropdownPos
		Instance.new("UICorner", dropdownPos).CornerRadius = UDim.new(0, 12)

		local dropdownPosStroke = Instance.new("UIStroke")
		dropdownPosStroke.Color = Color3.fromRGB(255, 255, 255)
		dropdownPosStroke.Thickness = 1
		dropdownPosStroke.Transparency = 1
		dropdownPosStroke.Parent = dropdownPos
		dropdownPosStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local dropdownPosTitle = Instance.new("TextLabel")
		dropdownPosTitle.Size = UDim2.new(1, -40, 0, 24)
		dropdownPosTitle.Position = UDim2.new(0, 12, 0, 5)
		dropdownPosTitle.BackgroundTransparency = 1
		dropdownPosTitle.Text = "Notif Position"
		dropdownPosTitle.TextColor3 = THEME.titleColor
		dropdownPosTitle.TextSize = 15
		dropdownPosTitle.Font = currentFont
		dropdownPosTitle.TextXAlignment = Enum.TextXAlignment.Left
		dropdownPosTitle.ZIndex = 21
		dropdownPosTitle.Parent = dropdownPos
		table.insert(textTargets, dropdownPosTitle)

		local dropdownPosClose = Instance.new("TextButton")
		dropdownPosClose.Size = UDim2.new(0, 24, 0, 24)
		dropdownPosClose.Position = UDim2.new(1, -30, 0, 5)
		dropdownPosClose.BackgroundTransparency = 1
		dropdownPosClose.BorderSizePixel = 0
		dropdownPosClose.Text = ""
		dropdownPosClose.ZIndex = 22
		dropdownPosClose.Parent = dropdownPos

		local dropdownPosCloseIcon = Instance.new("TextLabel")
		dropdownPosCloseIcon.Size = UDim2.new(0, 34, 0, 34)
		dropdownPosCloseIcon.Position = UDim2.new(0.5, -17, 0.5, -18)
		dropdownPosCloseIcon.BackgroundTransparency = 1
		dropdownPosCloseIcon.BorderSizePixel = 0
		dropdownPosCloseIcon.Text = "×"
		dropdownPosCloseIcon.TextColor3 = Color3.fromRGB(180, 180, 180)
		dropdownPosCloseIcon.TextSize = 30
		dropdownPosCloseIcon.Font = currentFont
		dropdownPosCloseIcon.ZIndex = 23
		dropdownPosCloseIcon.Parent = dropdownPosClose
		table.insert(textTargets, dropdownPosCloseIcon)

		local dropdownPosOpen = false
		local dropdownPosClosing = false
		local dropdownPosTween = nil
		local dropdownPosTweenToken = 0
		local posButtons = {}

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
			stopTween(dropdownPosTween)
			dropdownPosTween = TweenService:Create(dropdownPos, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Size = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1
			})
			dropdownPosTween:Play()
			TweenService:Create(dropdownPosStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Transparency = 1
			}):Play()
			local completedConnection = nil
			completedConnection = dropdownPosTween.Completed:Connect(function()
				if completedConnection then
					completedConnection:Disconnect()
					completedConnection = nil
				end
				if closeToken ~= dropdownPosTweenToken or dropdownPosOpen or data.dismissed or not dropdownPos.Parent then return end
				dropdownPosClosing = false
				dropdownPos.Visible = false
				resumeTimer()
			end)
		end

		local function openDropdownPos()
			if dropdownPosOpen or data.dismissed then return end
			dropdownPosOpen = true
			dropdownPosClosing = false
			setPosButtonsActive(true)
			dropdownPosTweenToken = dropdownPosTweenToken + 1
			pauseTimer()
			dropdownPos.Visible = true
			dropdownPos.Size = UDim2.new(0, 0, 0, 0)
			dropdownPos.BackgroundTransparency = 1
			dropdownPosStroke.Transparency = 1
			stopTween(dropdownPosTween)
			dropdownPosTween = TweenService:Create(dropdownPos, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, dropdownPosWidth, 0, dropdownPosHeight),
				BackgroundTransparency = 0
			})
			dropdownPosTween:Play()
			TweenService:Create(dropdownPosStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = 0.25
			}):Play()
		end

		closePosDropdownFn = closeDropdownPos
		isPosDropdownOpenFn = function() return dropdownPosOpen end

		posBtn.MouseEnter:Connect(function()
			TweenService:Create(posFrame, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(18, 18, 18)
			}):Play()
			TweenService:Create(posStroke, TweenInfo.new(0.15), {
				Transparency = 0
			}):Play()
		end)

		posBtn.MouseLeave:Connect(function()
			TweenService:Create(posFrame, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			}):Play()
			TweenService:Create(posStroke, TweenInfo.new(0.15), {
				Transparency = 0.15
			}):Play()
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
			TweenService:Create(dropdownPosCloseIcon, TweenInfo.new(0.15), {
				TextColor3 = Color3.fromRGB(230, 230, 230)
			}):Play()
		end)

		dropdownPosClose.MouseLeave:Connect(function()
			TweenService:Create(dropdownPosCloseIcon, TweenInfo.new(0.15), {
				TextColor3 = Color3.fromRGB(180, 180, 180)
			}):Play()
		end)

		dropdownPosClose.MouseButton1Click:Connect(function()
			closeDropdownPos()
		end)

		for i, option in ipairs(POSITION_OPTIONS) do
			local posOptBtn = Instance.new("TextButton")
			posOptBtn.Size = UDim2.new(1, -16, 0, 24)
			posOptBtn.Position = UDim2.new(0, 8, 0, 30 + ((i - 1) * 26))
			posOptBtn.BackgroundColor3 = THEME.btnBg
			posOptBtn.BackgroundTransparency = option.Name == currentPositionOption.Name and 0.1 or 0.45
			posOptBtn.BorderSizePixel = 0
			posOptBtn.Text = option.Label
			posOptBtn.TextColor3 = THEME.titleColor
			posOptBtn.TextSize = 11
			posOptBtn.Font = currentFont
			posOptBtn.TextXAlignment = Enum.TextXAlignment.Center
			posOptBtn.ZIndex = 21
			posOptBtn.Parent = dropdownPos
			Instance.new("UICorner", posOptBtn).CornerRadius = UDim.new(0, 8)
			table.insert(textTargets, posOptBtn)
			table.insert(posButtons, posOptBtn)

			posOptBtn.MouseEnter:Connect(function()
				TweenService:Create(posOptBtn, TweenInfo.new(0.15), {
					BackgroundTransparency = 0.08
				}):Play()
			end)

			posOptBtn.MouseLeave:Connect(function()
				TweenService:Create(posOptBtn, TweenInfo.new(0.15), {
					BackgroundTransparency = currentPositionOption.Name == option.Name and 0.1 or 0.45
				}):Play()
			end)

			posOptBtn.MouseButton1Click:Connect(function()
				if data.dismissed or dropdownPosClosing or not dropdownPosOpen then return end
				currentPositionOption = option
				saveSettings({ Font = currentFontName, Position = option.Name })
				for _, child in ipairs(dropdownPos:GetChildren()) do
					if child:IsA("TextButton") and child ~= dropdownPosClose then
						child.BackgroundTransparency = child == posOptBtn and 0.1 or 0.45
					end
				end
				repositionAll()
				closeDropdownPos()
			end)
		end

		if btnCount > 0 then
			local divider = Instance.new("Frame")
			divider.Size = UDim2.new(1, 0, 0, 1)
			divider.Position = UDim2.new(0, 0, 0, dividerY)
			divider.BackgroundColor3 = THEME.border
			divider.BorderSizePixel = 0
			divider.ZIndex = 11
			divider.Parent = frame

			for i, btnConfig in ipairs(buttons) do
				if type(btnConfig) ~= "table" then btnConfig = {} end
				local btnText = btnConfig.Text or "Button"
				btnText = cleanSingleLineText(btnText)
				local btnW = btnCount == 2 and 0.5 or 1
				local btnX = btnCount == 2 and (i - 1) * 0.5 or 0

				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(btnW, 0, 0, 34)
				btn.Position = UDim2.new(btnX, 0, 0, buttonY)
				btn.BackgroundTransparency = 1
				btn.BorderSizePixel = 0
				btn.Text = btnText
				btn.TextColor3 = THEME.btnText
				btn.TextSize = 15
				btn.Font = currentFont
				btn.ZIndex = 13
				btn.Parent = frame
				table.insert(textTargets, btn)
				Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)

				btn.MouseEnter:Connect(function()
					TweenService:Create(btn, TweenInfo.new(0.15), {
						BackgroundTransparency = 0.85,
						TextColor3 = THEME.titleColor
					}):Play()
				end)

				btn.MouseLeave:Connect(function()
					TweenService:Create(btn, TweenInfo.new(0.15), {
						BackgroundTransparency = 1,
						TextColor3 = THEME.btnText
					}):Play()
				end)

				btn.MouseButton1Click:Connect(function()
					if data.dismissed or data.buttonClicked then return end
					data.buttonClicked = true
					data.paused = true
					dismissNotif(frame, data)
					if type(btnConfig.Callback) == "function" then
						task.spawn(function()
							local ok, err = pcall(btnConfig.Callback)
							if not ok then warn("NNNotify callback error: " .. tostring(err)) end
						end)
					end
				end)
			end

			if btnCount == 2 then
				local vDivider = Instance.new("Frame")
				vDivider.Size = UDim2.new(0, 1, 0, 34)
				vDivider.Position = UDim2.new(0.5, 0, 0, buttonY)
				vDivider.BackgroundColor3 = THEME.border
				vDivider.BorderSizePixel = 0
				vDivider.ZIndex = 12
				vDivider.Parent = frame
			end
		end

		local progressBg = Instance.new("Frame")
		progressBg.Size = UDim2.new(1, -20, 0, 3)
		progressBg.Position = UDim2.new(0, 10, 0, frameHeight - 10)
		progressBg.BackgroundColor3 = THEME.progressBg
		progressBg.BorderSizePixel = 0
		progressBg.ZIndex = 11
		progressBg.Parent = frame
		Instance.new("UICorner", progressBg).CornerRadius = UDim.new(1, 0)

		local progressBar = Instance.new("Frame")
		progressBar.Size = UDim2.new(1, 0, 1, 0)
		progressBar.BackgroundColor3 = THEME.accent
		progressBar.BorderSizePixel = 0
		progressBar.ZIndex = 12
		progressBar.Parent = progressBg
		Instance.new("UICorner", progressBar).CornerRadius = UDim.new(1, 0)

		local targetPos = getSlotPos(#activeNotifs)
		local overshootSign = getOvershootSign()
		local bounceOver = UDim2.new(targetPos.X.Scale, targetPos.X.Offset + overshootSign * 12, targetPos.Y.Scale, targetPos.Y.Offset)

		local _, entranceToken = playFrameTween(data, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = bounceOver
		})
		task.delay(0.4, function()
			if data.dismissed or not frame.Parent or data.positionToken ~= entranceToken then return end
			local idx = getNotifIndex(data)
			if not idx then return end
			local currentTargetPos = getSlotPos(idx)
			local backSign = getOvershootSign()
			local currentBounceBack = UDim2.new(currentTargetPos.X.Scale, currentTargetPos.X.Offset - backSign * 4, currentTargetPos.Y.Scale, currentTargetPos.Y.Offset)
			local _, bounceToken = playFrameTween(data, TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = currentBounceBack
			})
			task.delay(0.13, function()
				if data.dismissed or not frame.Parent or data.positionToken ~= bounceToken then return end
				local finalIdx = getNotifIndex(data)
				if not finalIdx then return end
				playFrameTween(data, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = getSlotPos(finalIdx)
				})
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
				if not data.dismissed then
					dismissNotif(frame, data)
				end
			end)
		end
	end

	ScreenGui.Destroying:Connect(function()
		for i = #activeNotifs, 1, -1 do
			local data = activeNotifs[i]
			if data then
				data.dismissed = true
				data.paused = true
				stopTween(data.positionTween)
				stopTween(data.dismissTween)
			end
			activeNotifs[i] = nil
		end
	end)

	NNNotify = createNotif

end

local _nnTraceback = debug and type(debug.traceback) == "function" and debug.traceback or function(err)
	return tostring(err)
end

local _nnOk, _nnErr = xpcall(_nnInit, _nnTraceback)
if not _nnOk then
	warn("NNNotify init failed: " .. tostring(_nnErr))
	error(_nnErr, 0)
end

return NNNotify
