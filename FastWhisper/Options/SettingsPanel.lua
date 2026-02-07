-- FastWhisper - Settings (ESC -> Options -> AddOns)
-- Modern Settings API (Canvas categories). This replaces the legacy OptionFrame.

local CreateFrame = CreateFrame
local UIParent = UIParent
local GameTooltip = GameTooltip
local StaticPopup_Show = StaticPopup_Show

local addon = FastWhisper
local L = addon.L or {}

local function DB()
	return addon and addon.db
end

local function GetOpt(key, fallback)
	local db = DB()
	if not db then return fallback end
	local v = db[key]
	if v == nil then return fallback end
	return v
end

local function SetOpt(key, value)
	local db = DB()
	if not db then return end
	db[key] = value
	if type(addon.BroadcastOptionEvent) == "function" then
		addon:BroadcastOptionEvent(key, value)
	end
end

local function NumBool(v)
	return v and 1 or 0
end

local function BoolNum(v)
	return v == 1
end

local function CreateHeader(parent, text)
	local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	fs:SetText(text)
	fs:SetJustifyH("LEFT")
	return fs
end

local function CreateSubHeader(parent, text)
	local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	fs:SetText(text)
	fs:SetJustifyH("LEFT")
	return fs
end

local function CreateCheck(parent, label, tooltip)
	local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
	cb.Text:SetText(label)
	if tooltip then
		cb.tooltipText = tooltip
		cb:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:ClearLines()
			GameTooltip:AddLine(self.Text:GetText() or "")
			GameTooltip:AddLine(self.tooltipText, 1, 1, 1, true)
			GameTooltip:Show()
		end)
		cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
	end
	return cb
end

local function CreateSlider(parent, label, minVal, maxVal, step)
	local s = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
	s:SetMinMaxValues(minVal, maxVal)
	s:SetValueStep(step or 1)
	s:SetObeyStepOnDrag(true)
	s:SetWidth(260)
	-- OptionsSliderTemplate creates named regions; slider itself may have no name
	if s.Text then s.Text:SetText(label) else _G[(s:GetName() or "") .. "Text"]:SetText(label) end
	if s.Low then s.Low:SetText(tostring(minVal)) else _G[(s:GetName() or "") .. "Low"]:SetText(tostring(minVal)) end
	if s.High then s.High:SetText(tostring(maxVal)) else _G[(s:GetName() or "") .. "High"]:SetText(tostring(maxVal)) end
	-- value label
	local val = s:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	val:SetPoint("TOP", s, "BOTTOM", 0, 0)
	val:SetText("")
	s.valueText = val

	return s
end

local function CreateEditBox(parent, label, width)
	local wrap = CreateFrame("Frame", nil, parent)
	wrap:SetSize(width or 320, 44)

	local fs = wrap:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	fs:SetPoint("TOPLEFT", 0, 0)
	fs:SetText(label)

	local eb = CreateFrame("EditBox", nil, wrap, "InputBoxTemplate")
	eb:SetAutoFocus(false)
	eb:SetSize(width or 320, 26)
	eb:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", -5, -6)
	eb:SetTextInsets(10, 10, 0, 0)

	wrap.label = fs
	wrap.editBox = eb
	return wrap
end

local function CreateButton(parent, text, width)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetText(text)
	b:SetWidth(width or 160)
	b:SetHeight(22)
	return b
end

local function CreateDropdown(parent, label, width)
	local wrap = CreateFrame("Frame", nil, parent)
	wrap:SetSize(width or 220, 46)

	local fs = wrap:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	fs:SetPoint("TOPLEFT", 0, 0)
	fs:SetText(label)

	local dd = CreateFrame("Frame", nil, wrap, "UIDropDownMenuTemplate")
	dd:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", -16, -2)
	UIDropDownMenu_SetWidth(dd, width or 220)

	wrap.label = fs
	wrap.dropdown = dd
	return wrap
end

local function CreateColorSwatch(parent, label)
	local wrap = CreateFrame("Frame", nil, parent)
	wrap:SetSize(260, 26)

	local fs = wrap:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	fs:SetPoint("LEFT", 0, 0)
	fs:SetText(label)

	local b = CreateFrame("Button", nil, wrap)
	b:SetSize(22, 22)
	b:SetPoint("LEFT", fs, "RIGHT", 10, 0)

	local border = b:CreateTexture(nil, "BORDER")
	border:SetAllPoints(true)
	border:SetColorTexture(0, 0, 0, 1)

	local swatch = b:CreateTexture(nil, "ARTWORK")
	swatch:SetPoint("TOPLEFT", 1, -1)
	swatch:SetPoint("BOTTOMRIGHT", -1, 1)
	swatch:SetColorTexture(1, 1, 0, 1)

	wrap.label = fs
	wrap.button = b
	wrap.swatch = swatch
	return wrap
end

-- Simple confirm popups (re-using the messages already localized in L)
local function EnsurePopups()
	if StaticPopupDialogs and not StaticPopupDialogs.FASTWHISPER_RESET_FRAMES then
		StaticPopupDialogs.FASTWHISPER_RESET_FRAMES = {
			text = L["reset frames confirm"] or "Reset frames?",
			button1 = YES,
			button2 = NO,
			OnAccept = function()
				if type(addon.BroadcastEvent) == "function" then
					addon:BroadcastEvent("OnResetFrames")
				end
			end,
			timeout = 0,
			whileDead = 1,
			hideOnEscape = 1,
			preferredIndex = 3,
		}
	end

	if StaticPopupDialogs and not StaticPopupDialogs.FASTWHISPER_CLEAR_MESSAGES then
		StaticPopupDialogs.FASTWHISPER_CLEAR_MESSAGES = {
			text = L["clear all confirm"] or "Clear messages?",
			button1 = YES,
			button2 = NO,
			OnAccept = function()
				if type(addon.Clear) == "function" then
					addon:Clear()
				end
			end,
			timeout = 0,
			whileDead = 1,
			hideOnEscape = 1,
			preferredIndex = 3,
		}
	end
end

local function CreatePanel()
	local panel = CreateFrame("Frame", "FastWhisperSettingsPanel", UIParent)
	panel.name = "FastWhisper"

	-- Scrollable content (Canvas category doesn't automatically scroll)
	local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 0, -8)
	scroll:SetPoint("BOTTOMRIGHT", -30, 8)

	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(1, 1)
	scroll:SetScrollChild(content)
	panel.content = content

	local y = -12
	local function Place(obj, x)
		x = x or 16
		obj:ClearAllPoints()
		obj:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
		y = y - (obj:GetHeight() + 10)
	end

	-- Title / description
	local title = CreateHeader(content, L["title"] or "FastWhisper")
	title:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -12)
	local desc = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	desc:SetWidth(520)
	desc:SetJustifyH("LEFT")
	desc:SetText(L["desc"] or "")

	y = -70

	-- General options
	local h1 = CreateSubHeader(content, L["general options"] or "General")
	Place(h1)

	local cb_notifyButton = CreateCheck(content, L["show notify button"] or "Show notify button")
	cb_notifyButton:SetScript("OnClick", function(self) SetOpt("notifyButton", NumBool(self:GetChecked())) end)
	Place(cb_notifyButton)

	local cb_receiveOnly = CreateCheck(content, L["receive only"] or "Show received only")
	cb_receiveOnly:SetScript("OnClick", function(self) SetOpt("receiveOnly", NumBool(self:GetChecked())) end)
	Place(cb_receiveOnly)

	local cb_sound = CreateCheck(content, L["sound notify"] or "Sound")
	cb_sound:SetScript("OnClick", function(self) SetOpt("sound", NumBool(self:GetChecked())) end)
	Place(cb_sound)

	local cb_showRealm = CreateCheck(content, L["show realms"] or "Show realms")
	cb_showRealm:SetScript("OnClick", function(self) SetOpt("showRealm", NumBool(self:GetChecked())) end)
	Place(cb_showRealm)

	local cb_foreignOnly = CreateCheck(content, L["foreign realms"] or "Foreign only")
	cb_foreignOnly:SetScript("OnClick", function(self) SetOpt("foreignOnly", NumBool(self:GetChecked())) end)
	Place(cb_foreignOnly)

	local cb_time = CreateCheck(content, L["timestamp"] or "Timestamp")
	cb_time:SetScript("OnClick", function(self) SetOpt("time", NumBool(self:GetChecked())) end)
	Place(cb_time)

	local cb_filters = CreateCheck(content, L["apply third-party filters"] or "Apply third-party filters")
	cb_filters:SetScript("OnClick", function(self) SetOpt("applyFilters", NumBool(self:GetChecked())) end)
	Place(cb_filters)

	local cb_ignoreTags = CreateCheck(content, L["ignore tag messages"] or "Ignore tagged messages")
	cb_ignoreTags:SetScript("OnClick", function(self) SetOpt("ignoreTags", NumBool(self:GetChecked())) end)
	Place(cb_ignoreTags)

	local cb_save = CreateCheck(content, L["save messages"] or "Save messages")
	cb_save:SetScript("OnClick", function(self) SetOpt("save", NumBool(self:GetChecked())) end)
	Place(cb_save)

	-- Frame settings
	local h2 = CreateSubHeader(content, L["frame settings"] or "Frame")
	Place(h2)

	local s_buttonScale = CreateSlider(content, L["button scale"] or "Button scale", 50, 200, 5)
	s_buttonScale:SetScript("OnValueChanged", function(self, v)
		if self._fw_refreshing then
			v = floor(v + 0.5)
			self.valueText:SetText(tostring(v))
			return
		end
		v = floor(v + 0.5)
		self.valueText:SetText(v)
		SetOpt("buttonScale", v)
	end)
	Place(s_buttonScale)

	local s_listScale = CreateSlider(content, L["list scale"] or "List scale", 50, 200, 5)
	s_listScale:SetScript("OnValueChanged", function(self, v)
		if self._fw_refreshing then
			v = floor(v + 0.5)
			self.valueText:SetText(tostring(v))
			return
		end
		v = floor(v + 0.5)
		self.valueText:SetText(v)
		SetOpt("listScale", v)
	end)
	Place(s_listScale)

	local s_listWidth = CreateSlider(content, L["list width"] or "List width", 100, 400, 5)
	s_listWidth:SetScript("OnValueChanged", function(self, v)
		if self._fw_refreshing then
			v = floor(v + 0.5)
			self.valueText:SetText(tostring(v))
			return
		end
		v = floor(v + 0.5)
		self.valueText:SetText(v)
		SetOpt("listWidth", v)
	end)
	Place(s_listWidth)

	local s_listHeight = CreateSlider(content, L["list height"] or "List height", 100, 640, 20)
	s_listHeight:SetScript("OnValueChanged", function(self, v)
		if self._fw_refreshing then
			v = floor(v + 0.5)
			self.valueText:SetText(tostring(v))
			return
		end
		v = floor(v + 0.5)
		self.valueText:SetText(v)
		SetOpt("listHeight", v)
	end)
	Place(s_listHeight)

	-- Action buttons
	local row = CreateFrame("Frame", nil, content)
	row:SetSize(520, 26)
	local b_reset = CreateButton(row, L["reset frames"] or "Reset frames", 170)
	b_reset:SetPoint("LEFT", row, "LEFT", 0, 0)
	local b_clear = CreateButton(row, L["clear all"] or "Clear messages", 170)
	b_clear:SetPoint("LEFT", b_reset, "RIGHT", 10, 0)
	EnsurePopups()
	b_reset:SetScript("OnClick", function() StaticPopup_Show("FASTWHISPER_RESET_FRAMES") end)
	b_clear:SetScript("OnClick", function() StaticPopup_Show("FASTWHISPER_CLEAR_MESSAGES") end)
	Place(row)

	-- Whisper notifier
	local h3 = CreateSubHeader(content, L["wn options"] or "Whisper alert")
	Place(h3)

	local cb_wn_enable = CreateCheck(content, L["wn enable"] or "Enable whisper alert")
	cb_wn_enable:SetScript("OnClick", function(self) SetOpt("wn_enable", NumBool(self:GetChecked())) end)
	Place(cb_wn_enable)

	local cb_wn_mute = CreateCheck(content, L["wn mute"] or "Mute alert sound")
	cb_wn_mute:SetScript("OnClick", function(self) SetOpt("wn_mute", NumBool(self:GetChecked())) end)
	Place(cb_wn_mute)

	local eb_msg = CreateEditBox(content, L["wn message"] or "Alert text", 360)
	eb_msg:SetHeight(48)
	eb_msg.editBox:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		SetOpt("wn_alertMsg", self:GetText() or "")
	end)
	eb_msg.editBox:SetScript("OnEditFocusLost", function(self)
		SetOpt("wn_alertMsg", self:GetText() or "")
	end)
	Place(eb_msg)

	local dd_font = CreateDropdown(content, L["wn font"] or "Font", 220)
	Place(dd_font)

	local cs_color = CreateColorSwatch(content, L["wn color"] or "Text color")
	Place(cs_color)

	local s_font = CreateSlider(content, L["wn font size"] or "Font size", 20, 80, 1)
	s_font:SetScript("OnValueChanged", function(self, v)
		if self._fw_refreshing then
			v = floor(v + 0.5)
			self.valueText:SetText(tostring(v))
			return
		end
		v = floor(v + 0.5)
		self.valueText:SetText(v)
		SetOpt("wn_fontSize", v)
	end)
	Place(s_font)

	local s_posY = CreateSlider(content, L["wn pos y"] or "Position Y", 0, 1200, 5)
	s_posY:SetScript("OnValueChanged", function(self, v)
		if self._fw_refreshing then
			v = floor(v + 0.5)
			self.valueText:SetText(tostring(v))
			return
		end
		v = floor(v + 0.5)
		self.valueText:SetText(v)
		SetOpt("wn_posY", v)
	end)
	Place(s_posY)

	local s_posX = CreateSlider(content, L["wn pos x"] or "Position X", -800, 800, 5)
	s_posX:SetScript("OnValueChanged", function(self, v)
		if self._fw_refreshing then
			v = floor(v + 0.5)
			self.valueText:SetText(tostring(v))
			return
		end
		v = floor(v + 0.5)
		self.valueText:SetText(v)
		SetOpt("wn_posX", v)
	end)
	Place(s_posX)

	local s_vol = CreateSlider(content, L["wn volume"] or "Volume", 0, 100, 1)
	s_vol:SetScript("OnValueChanged", function(self, v)
		if self._fw_refreshing then
			v = floor(v + 0.5)
			self.valueText:SetText(v .. "%")
			return
		end
		v = floor(v + 0.5)
		self.valueText:SetText(v .. "%")
		SetOpt("wn_volumePct", v)
	end)
	Place(s_vol)

	local dd_channel = CreateDropdown(content, "Channel", 220)
	Place(dd_channel)

	local b_test = CreateButton(content, L["wn test"] or "Test", 170)
	b_test:SetScript("OnClick", function()
		if type(addon.TestWhisperNotifier) == "function" then
			addon:TestWhisperNotifier()
		end
	end)
	Place(b_test)

	-- Color picker
	cs_color.button:SetScript("OnClick", function()
		if not ColorPickerFrame then return end
		local r = tonumber(GetOpt("wn_colorR", 1)) or 1
		local g = tonumber(GetOpt("wn_colorG", 1)) or 1
		local b = tonumber(GetOpt("wn_colorB", 0)) or 0
		local a = tonumber(GetOpt("wn_colorA", 1)) or 1

		local function apply(newR, newG, newB, newA)
			newR = tonumber(newR)
			newG = tonumber(newG)
			newB = tonumber(newB)
			newA = tonumber(newA)
			if newR == nil or newG == nil or newB == nil or newA == nil then
				return
			end
			SetOpt("wn_colorR", newR)
			SetOpt("wn_colorG", newG)
			SetOpt("wn_colorB", newB)
			SetOpt("wn_colorA", newA)
			cs_color.swatch:SetColorTexture(newR, newG, newB, newA)
		end

		ColorPickerFrame.previousValues = { r, g, b, a }
		local function pickerChanged()
			local cr, cg, cb
			if ColorPickerFrame.GetColorRGB then
				cr, cg, cb = ColorPickerFrame:GetColorRGB()
			elseif ColorPickerFrame.Color and ColorPickerFrame.Color.GetRGB then
				cr, cg, cb = ColorPickerFrame.Color:GetRGB()
			end
			local ca = 1 - (ColorPickerFrame.opacity or 0)
			apply(cr, cg, cb, ca)
		end

		local info = {
			r = r, g = g, b = b,
			opacity = 1 - a,
			hasOpacity = true,
			swatchFunc = pickerChanged,
			opacityFunc = pickerChanged,
			cancelFunc = function(previous)
				local pr, pg, pb, pa
				if type(previous) == "table" then
					pr, pg, pb, pa = unpack(previous)
				elseif previous and type(previous.GetRGBA) == "function" then
					pr, pg, pb, pa = previous:GetRGBA()
				elseif ColorPickerFrame.previousValues then
					pr, pg, pb, pa = unpack(ColorPickerFrame.previousValues)
				else
					pr, pg, pb, pa = r, g, b, a
				end
				apply(pr, pg, pb, pa)
			end,
		}

		if ColorPickerFrame.SetupColorPickerAndShow then
			ColorPickerFrame:SetupColorPickerAndShow(info)
		else
			ColorPickerFrame.hasOpacity = true
			ColorPickerFrame.opacity = info.opacity
			if ColorPickerFrame.SetColorRGB then
				ColorPickerFrame:SetColorRGB(r, g, b)
			end
			ColorPickerFrame.func = pickerChanged
			ColorPickerFrame.opacityFunc = pickerChanged
			ColorPickerFrame.cancelFunc = info.cancelFunc
			ColorPickerFrame:Hide()
			ColorPickerFrame:Show()
		end
	end)

	-- Refresh from DB when shown
	function panel:RefreshFromDB()
		cb_notifyButton:SetChecked(BoolNum(GetOpt("notifyButton", 1)))
		cb_receiveOnly:SetChecked(BoolNum(GetOpt("receiveOnly", 0)))
		cb_sound:SetChecked(BoolNum(GetOpt("sound", 1)))
		cb_showRealm:SetChecked(BoolNum(GetOpt("showRealm", 0)))
		cb_foreignOnly:SetChecked(BoolNum(GetOpt("foreignOnly", 1)))
		cb_time:SetChecked(BoolNum(GetOpt("time", 1)))
		cb_filters:SetChecked(BoolNum(GetOpt("applyFilters", 1)))
		cb_ignoreTags:SetChecked(BoolNum(GetOpt("ignoreTags", 1)))
		cb_save:SetChecked(BoolNum(GetOpt("save", 1)))

		local function setSlider(sl, key, fallback)
			local v = tonumber(GetOpt(key, fallback)) or fallback
			sl._fw_refreshing = true
			sl:SetValue(v)
			sl._fw_refreshing = false
			sl.valueText:SetText(key == "wn_volumePct" and (v .. "%") or tostring(v))
		end

		setSlider(s_buttonScale, "buttonScale", 120)
		setSlider(s_listScale, "listScale", 100)
		setSlider(s_listWidth, "listWidth", 200)
		setSlider(s_listHeight, "listHeight", 320)

		cb_wn_enable:SetChecked(BoolNum(GetOpt("wn_enable", 1)))
		cb_wn_mute:SetChecked(BoolNum(GetOpt("wn_mute", 0)))
		eb_msg.editBox:SetText(GetOpt("wn_alertMsg", L["wn default text"] or "Check Whispers!") or "")
		setSlider(s_font, "wn_fontSize", 42)
		setSlider(s_posY, "wn_posY", 880)
		setSlider(s_posX, "wn_posX", 0)
		setSlider(s_vol, "wn_volumePct", 100)

		-- dropdown
		local channel = GetOpt("wn_channel", "Master")
		UIDropDownMenu_SetText(dd_channel.dropdown, channel)

		local fontKey = GetOpt("wn_font", "Friz")
		UIDropDownMenu_SetText(dd_font.dropdown, fontKey)

		local r = tonumber(GetOpt("wn_colorR", 1)) or 1
		local g = tonumber(GetOpt("wn_colorG", 1)) or 1
		local b = tonumber(GetOpt("wn_colorB", 0)) or 0
		local a = tonumber(GetOpt("wn_colorA", 1)) or 1
		cs_color.swatch:SetColorTexture(r, g, b, a)
	end

	panel:SetScript("OnShow", function(self)
		if DB() then
			self:RefreshFromDB()
		end
	end)

	-- dropdown init after panel exists
	UIDropDownMenu_Initialize(dd_channel.dropdown, function(self, level)
		local function add(text, value)
			local info = UIDropDownMenu_CreateInfo()
			info.text = text
			info.value = value
			info.func = function(btn)
				UIDropDownMenu_SetSelectedValue(dd_channel.dropdown, btn.value)
				UIDropDownMenu_SetText(dd_channel.dropdown, btn.value)
				SetOpt("wn_channel", btn.value)
			end
			UIDropDownMenu_AddButton(info)
		end
		add(L["wn channel master"] or "Master", "Master")
		add(L["wn channel sfx"] or "SFX", "SFX")
		add(L["wn channel music"] or "Music", "Music")
		add(L["wn channel ambience"] or "Ambience", "Ambience")
	end)

	UIDropDownMenu_Initialize(dd_font.dropdown, function(self, level)
		local function add(text, value)
			local info = UIDropDownMenu_CreateInfo()
			info.text = text
			info.value = value
			info.func = function(btn)
				UIDropDownMenu_SetSelectedValue(dd_font.dropdown, btn.value)
				UIDropDownMenu_SetText(dd_font.dropdown, btn.value)
				SetOpt("wn_font", btn.value)
			end
			UIDropDownMenu_AddButton(info)
		end
		add(L["wn font friz"] or "Friz", "Friz")
		add(L["wn font arial"] or "Arial", "Arial")
		add(L["wn font morpheus"] or "Morpheus", "Morpheus")
		add(L["wn font skurri"] or "Skurri", "Skurri")
	end)

	-- Make sure the scroll child has a sensible height
	content:SetHeight(-y + 60)

	return panel
end

local function RegisterSettings(panel)
	if not Settings or not Settings.RegisterCanvasLayoutCategory then
		-- Fallback: do nothing (older clients)
		return
	end

	local category = Settings.RegisterCanvasLayoutCategory(panel, "FastWhisper")
	category.ID = "FastWhisper"
	Settings.RegisterAddOnCategory(category)

	addon.settingsCategoryID = category.ID
end

-- Create/register after DB is initialized
addon:RegisterEventCallback("OnInitialize", function()
	local panel = CreatePanel()
	RegisterSettings(panel)
end)