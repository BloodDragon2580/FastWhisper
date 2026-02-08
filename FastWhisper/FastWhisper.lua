local pairs = pairs
local ipairs = ipairs
local strfind = strfind
local type = type
local tinsert = tinsert
local strsub = strsub
local date = date
local tonumber = tonumber
local select = select
local PlaySoundFile = PlaySoundFile
local wipe = wipe
local tremove = tremove
local SendWho = SendWho
local min = min
local max = max
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local BNGetNumFriends = BNGetNumFriends
local BNGetFriendInfo = C_BattleNet.GetFriendAccountInfo
local BNGetFriendInfoByID = C_BattleNet.GetAccountInfoByID
local GMChatFrame_IsGM = GMChatFrame_IsGM
-- TWW 11.2.7+: Chat filter API moved/changed; keep backward compatibility
local ChatFrame_GetMessageEventFilters =
	(ChatFrameUtil and ChatFrameUtil.GetMessageEventFilters) or ChatFrame_GetMessageEventFilters
local ChatFrame_SendTell = ChatFrame_SendTell
local ChatFrame_SendBNetTell = ChatFrame_SendBNetTell
local InviteUnit = InviteUnit
local FriendsFrame_ShowDropdown = FriendsFrame_ShowDropdown
local FriendsFrame_ShowBNDropdown = FriendsFrame_ShowBNDropdown
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local UNKNOWN = UNKNOWN

local addon = LibAddonManager:CreateAddon(...)
local L = addon.L

addon:RegisterDB("FastWhisperDB")
addon:RegisterSlashCmd("fastwhisper", "fw")

addon.ICON_FILE = "Interface\\Icons\\INV_Letter_05"
addon.SOUND_FILE = "Interface\\AddOns\\FastWhisper\\Sounds\\Notify.ogg"
addon.BACKGROUND = "Interface\\DialogFrame\\UI-DialogBox-Background"
addon.BORDER = "Interface\\Tooltips\\UI-Tooltip-Border"

addon.MAX_MESSAGES = 500

function addon:EncodeMessage(text, inform)
	local timeStamp = strsub(date(), 10, 17)
	return (inform and "1" or "0")..timeStamp..(text or ""), timeStamp
end

function addon:DecodeMessage(line)
	if type(line) ~= "string" then
		return
	end

	local inform
	if strsub(line, 1, 1) == "1" then
		inform = 1
	end

	local timeStamp = strsub(line, 2, 9)
	local text = strsub(line, 10)
	return text, inform, timeStamp
end

function addon:ParseNameRealm(text)
	if type(text) == "string" then
		local _, _, name, realm = strfind(text, "(.+)%-(.+)")
		return name or text, realm
	end
end

function addon:GetDisplayName(text, forceRealm)
	if self:IsBattleTag(text) then
		local id, name = self:GetBNInfoFromTag(text)
		return name or UNKNOWN
	end

	if forceRealm then
		return text
	end

	local name, realm = self:ParseNameRealm(text)
	if self.db.showRealm then
		if foreignOnly and realm == self.realm then
			return name
		else
			return text
		end
	else
		return name
	end
end

function addon:GetBNInfoFromTag(tag)
	if type(tag) ~= "string" then
		return
	end

	local count = BNGetNumFriends()
	local i
	for i = 1, count do
		BNetAccountInfo = BNGetFriendInfo(i)
		local id, name, battleTag, online = BNetAccountInfo.bnetAccountID, BNetAccountInfo.accountName, BNetAccountInfo.battleTag, BNetAccountInfo.isOnline
		if battleTag == tag then
			return id, name, online
		end
	end
end

function addon:IsBattleTag(name)
	if type(name) == "string" then
		local _, _, prefix, surfix = strfind(name, "(.+)#(%d+)$")
		return prefix, surfix
	end
end

function addon:GetNewMessage()
	local i
	for i = 1, #self.db.history do
		local data = self.db.history[i]
		if data.new then
			return addon:GetDisplayName(data.name), data.class, addon:DecodeMessage(data.messages[1])
		end
	end
end

function addon:GetNewNames()
	local newNames = {}
	local i
	for i = 1, #self.db.history do
		local data = self.db.history[i]
		if data.new then
			tinsert(newNames, addon:GetDisplayName(data.name))
		end
	end
	return newNames
end

function addon:AddTooltipText(tooltip)
	local newNames = self:GetNewNames()
	if newNames[1] then
		tooltip:AddLine(L["new messages from"], 1, 1, 1, true)
		local i
		for i = 1, #newNames do
			tooltip:AddLine(newNames[i], 0, 1, 0, true)
		end
	else
		tooltip:AddLine(L["no new messages"], 1, 1, 1, true)
	end
end

function addon:HandleAction(name, action)
	if type(name) ~= "string" then
		return
	end

	local bnId, bnName, bnOnline
	if addon:IsBattleTag(name) then
		bnId, bnName, bnOnline = self:GetBNInfoFromTag(name)
		if not bnId then
			return
		end
	end

	if action == "MENU" then
		if bnId then
			FriendsFrame_ShowBNDropdown(bnName, bnOnline, nil, nil, nil, 1, bnId)
		else
			FriendsFrame_ShowDropdown(name, 1)
		end

	elseif action == "WHO" then
		SendWho("n-"..(bnName or name))

	elseif action == "INVITE" then
		if bnId then
			FriendsFrame_BattlenetInvite(nil, bnId)
		else
			InviteUnit(name)
		end

	elseif action == "WHISPER" then
		if bnName then
			ChatFrame_SendBNetTell(bnName)
		else
			ChatFrame_SendTell(name)
		end
	end
end

function addon:PlaySound()
	PlaySoundFile(self.SOUND_FILE, "Master")
end

addon.DB_DEFAULTS = {
	time = 1,
	sound = 1,
	save = 1,
	notifyButton = 1,
	ignoreTags = 1,
	applyFilters = 1,
	receiveOnly = 0,
	showRealm = 0,
	foreignOnly = 1,
	buttonScale = { min = 50, max = 200, step = 5, default = 120 },
	listScale = { min = 50, max = 200, step = 5, default = 100 },
	listWidth = { min = 100, max = 400, step = 5, default = 200 },
	listHeight = { min = 100, max = 640, step = 20, default = 320 },

	-- WhisperNotifier (integrated)
	wn_enable = 1,
	wn_mute = 0,
	wn_alertMsg = "__DEFAULT__",
	wn_font = "Friz",
	wn_colorR = 1,
	wn_colorG = 1,
	wn_colorB = 0,
	wn_colorA = 1,
	wn_fontSize = { min = 20, max = 80, step = 1, default = 42 },
	wn_posY = { min = 0, max = 1200, step = 5, default = 880 },
	wn_posX = { min = -800, max = 800, step = 5, default = 0 },
	wn_volumePct = { min = 0, max = 100, step = 1, default = 100 },
	wn_channel = "Master",
	wn_bgAlert = 0
}

function addon:OnInitialize(db, firstTime)
	if firstTime or not addon:VerifyDBVersion(4.12, db) then
		db.version = 4.12
		local k, v
		for k, v in pairs(self.DB_DEFAULTS) do
			-- Preserve existing user settings whenever possible.
			-- Only apply defaults when the key is missing or invalid.
			if v == 1 then
				if db[k] == nil then
					db[k] = 1
				end
			elseif type(v) == "table" then
				-- Numeric sliders: validate range.
				if type(db[k]) ~= "number"  or db[k] < v.min or db[k] > v.max then
					db[k] = v.default
				end
			end
		end
	end

	-- Defaults for non-numeric / non-boolean settings (WhisperNotifier integration)
	if db.wn_enable == nil then db.wn_enable = 1 end
	if db.wn_mute == nil then db.wn_mute = 0 end
	if db.wn_bgAlert == nil then db.wn_bgAlert = 0 end
	if type(db.wn_font) ~= "string" or db.wn_font == "" then db.wn_font = "Friz" end
	if type(db.wn_colorR) ~= "number" then db.wn_colorR = 1 end
	if type(db.wn_colorG) ~= "number" then db.wn_colorG = 1 end
	if type(db.wn_colorB) ~= "number" then db.wn_colorB = 0 end
	if type(db.wn_colorA) ~= "number" then db.wn_colorA = 1 end
	if type(db.wn_channel) ~= "string" or db.wn_channel == "" then db.wn_channel = "Master" end
	if type(db.wn_alertMsg) ~= "string" or db.wn_alertMsg == "" or db.wn_alertMsg == "__DEFAULT__" then
		db.wn_alertMsg = (L and L["wn default text"]) or "!!! Whisper message !!!"
	end

	-- Midnight/Settings migration: enforce "standard" defaults once (without touching other user settings).
	-- This turns the on-screen whisper alert on by default and ensures a localized default text.
	if db._wnDefaultsMigrated == nil then
		db.wn_enable = 1
		if type(db.wn_alertMsg) ~= "string" or db.wn_alertMsg == "" or db.wn_alertMsg == "__DEFAULT__" then
			db.wn_alertMsg = (L and L["wn default text"]) or "!!! Whisper message !!!"
		end
		db._wnDefaultsMigrated = 1
	end

	if type(db.history) ~= "table" then
		db.history = {}
	end

	self:BroadcastEvent("OnInitialize", db)

	local k
	for k in pairs(self.DB_DEFAULTS) do
		self:BroadcastOptionEvent(k, db[k])
	end

	self:RegisterEvent("PLAYER_LOGOUT")
	self:RegisterEvent("CHAT_MSG_WHISPER")
	self:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
	self:RegisterEvent("CHAT_MSG_BN_WHISPER")
	self:RegisterEvent("CHAT_MSG_BN_WHISPER_INFORM")

	self:InitWhisperNotifier()

	self:BroadcastEvent("OnListUpdate")
end

function addon:PLAYER_LOGOUT()
	if not self.db.save then
		wipe(self.db.history)
	end
end

function addon:Clear()
	local history = self.db.history
	local i
	for i = #history, 1, -1 do
		if not history[i].protected then
			tremove(history, i)
		end
	end

	self:BroadcastEvent("OnListUpdate")
	self:BroadcastEvent("OnClearMessages")
end

function addon:FindPlayerData(name)
	local index, data
	for index, data in ipairs(self.db.history) do
		if data.name == name then
			return index, data
		end
	end
end

function addon:Delete(name)
	local index, data = self:FindPlayerData(name)
	if index and not data.protected then
		tremove(self.db.history, index)
		self:BroadcastEvent("OnListUpdate")
	end
end

function addon:ProcessChatMsg(name, class, text, inform, bnid)
	if type(text) ~= "string" or type(name) ~= "string" then
		return
	end

	if self.db.ignoreTags then
		local tag = strsub(text, 1, 1)
		if tag == "<" or tag == "[" then
			return
		end
	end

	if self:IsIgnoredMessage(arg1) then
		return
	end

	if class == "BN" then
		-- Battle.net whispers: try to resolve a BattleTag; fall back to the provided name.
		local bt
		local ok, a,b,c,d,e,f,g,h = pcall(BNGetFriendInfoByID, bnid or 0)
		if ok then
			-- Modern API may return a table; older API returns multiple values.
			if type(a) == "table" then
				bt = a.battleTag or (a.accountInfo and a.accountInfo.battleTag)
			elseif type(b) == "string" and b:find("#") then
				bt = b
			elseif type(c) == "string" and c:find("#") then
				bt = c
			end
		end
		name = bt or name
		if not name or name == "" then
			return
		end
	elseif class ~= "GM" then
		local _, realm = self:ParseNameRealm(name)
		if not realm then
			name = name.."-"..self.realm
		end
	end
	local index, data = self:FindPlayerData(name)
	if index then
		if index > 1 then
			tremove(self.db.history, index)
			tinsert(self.db.history, 1, data)
		end
	else
		data = { name = name, class = class }
		tinsert(self.db.history, 1, data)
	end

	if type(data.messages) ~= "table" then
		data.messages = {}
	end

	if inform then
		data.new = nil
	else
		data.new = 1
		data.received = 1
	end

	local msg, timeStamp = self:EncodeMessage(text, inform)
	tinsert(data.messages, msg)

	while #data.messages > self.MAX_MESSAGES do
		tremove(data.messages, 1)
	end

	self:BroadcastEvent("OnListUpdate")

	if not inform and self.db.sound then
		self:PlaySound()
	end

	self:BroadcastEvent("OnNewMessage", name, class, text, inform, timeStamp)
end

function addon:CHAT_MSG_WHISPER(...)
	local text, name, _, _, _, flag, _, _, _, _, _, guid, _, _, _, hide = ...
	if hide then
		return
	end

	if flag == "GM" or flag == "DEV" then
		flag = "GM"
	else
		if self.db.applyFilters then
			local filtersList = ChatFrame_GetMessageEventFilters and ChatFrame_GetMessageEventFilters("CHAT_MSG_WHISPER") or nil
			if filtersList then
				local _, func
				for _, func in ipairs(filtersList) do
					if type(func) == "function" and func(DEFAULT_CHAT_FRAME, "CHAT_MSG_WHISPER", ...) then
						return
					end
				end
			end
		end

		flag = select(2, GetPlayerInfoByGUID(guid or ""))
	end

	self:ProcessChatMsg(name, flag, text)
end

function addon:CHAT_MSG_WHISPER_INFORM(...)
	local text, name, _, _, _, flag, _, _, _, _, _, guid = ...
	if flag == "GM" or flag == "DEV" or (GMChatFrame_IsGM and GMChatFrame_IsGM(name)) then
		flag = "GM"
	else
		flag = select(2, GetPlayerInfoByGUID(guid or ""))
	end

	self:ProcessChatMsg(name, flag, text, 1)
end

function addon:CHAT_MSG_BN_WHISPER(...)
	local text, name, _, _, _, _, _, _, _, _, _, _, bnid = ...
	self:ProcessChatMsg(name, "BN", text, nil, bnid)
end

function addon:CHAT_MSG_BN_WHISPER_INFORM(...)
	local text, name, _, _, _, _, _, _, _, _, _, _, bnid = ...
	self:ProcessChatMsg(name, "BN", text, 1, bnid)
end

addon.IGNORED_MESSAGES = {}

function addon:AddIgnore(pattern)
	if type(pattern) ~= "string" then
		return
	end

	local index, str
	for index, str in ipairs(self.IGNORED_MESSAGES) do
		if str == pattern then
			return
		end
	end

	tinsert(self.IGNORED_MESSAGES, pattern)
end

function addon:IsIgnoredMessage(text)
	if type(text) ~= "string" then
		return
	end

	local pattern
	for _, pattern in ipairs(self.IGNORED_MESSAGES) do
		if strfind(text, pattern) then
			return pattern
		end
	end
end

-- ---------------------------------------------------------------------------
-- WhisperNotifier integration (on-screen alert + optional sound)
-- ---------------------------------------------------------------------------

local function FW_WN_GetForeground()
	if IsGameWindowActive then
		local ok, active = pcall(IsGameWindowActive)
		if ok then return active end
	end
	return true
end

local function FW_WN_GetFontPath(key)
	if key == "Arial" then
		return "Fonts\\ARIALN.TTF"
	elseif key == "Morpheus" then
		return "Fonts\\MORPHEUS.TTF"
	elseif key == "Skurri" then
		return "Fonts\\SKURRI.TTF"
	end
	-- Default: Friz Quadrata
	return (STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF")
end

function addon:WN_PlaySound()
	if self.db.wn_mute then
		return
	end

	local channel = self.db.wn_channel or "Master"
	local cvarName = "Sound_MasterVolume"
	if channel == "SFX" then cvarName = "Sound_SFXVolume"
	elseif channel == "Music" then cvarName = "Sound_MusicVolume"
	elseif channel == "Ambience" then cvarName = "Sound_AmbienceVolume" end

	local prevVolume = tonumber(GetCVar and GetCVar(cvarName) or 1) or 1
	local addonVolume = tonumber(self.db.wn_volumePct or 100) / 100
	local tempVolume = prevVolume * addonVolume

	if SetCVar and GetCVar then
		SetCVar(cvarName, tempVolume)
	end
	PlaySound(15273, channel)
	if SetCVar and GetCVar then
		C_Timer.After(0.5, function()
			SetCVar(cvarName, prevVolume)
		end)
	end
end

function addon:WN_ShowAlert()
	local frame = self.wnFrame
	if not frame then
		return
	end

	if frame.hideTimer then
		frame.hideTimer:Cancel()
		frame.hideTimer = nil
	end

	frame.text:SetText(self.db.wn_alertMsg or ((L and L["wn default text"]) or "Check Whispers!"))
	frame:Show()
	if not frame.anim:IsPlaying() then
		frame.anim:Play()
	end

	local isForeground = FW_WN_GetForeground()
	if isForeground or self.db.wn_bgAlert then
		self:WN_PlaySound()
	end

	frame.hideTimer = C_Timer.NewTimer(3, function()
		frame.anim:Stop()
		frame.text:SetAlpha(1)
		frame:Hide()
	end)
end

function addon:InitWhisperNotifier()
	if self.wnFrame then
		return
	end

	local frame = CreateFrame("Frame", "FastWhisperNotifierFrame", UIParent)
	frame:SetSize(400, 80)
	frame:Hide()
	frame.bg = frame:CreateTexture(nil, "BACKGROUND")
	frame.bg:SetAllPoints(true)
	frame.bg:SetColorTexture(0, 0, 0, 0)

	frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
	frame.text:SetPoint("CENTER")
	frame.text:SetText(self.db.wn_alertMsg or ((L and L["wn default text"]) or "Check Whispers!"))
	frame.text:SetTextColor(self.db.wn_colorR or 1, self.db.wn_colorG or 1, self.db.wn_colorB or 0, self.db.wn_colorA or 1)
	local fontPath = FW_WN_GetFontPath(self.db.wn_font or "Friz")
	frame.text:SetFont(fontPath, self.db.wn_fontSize or (self.DB_DEFAULTS.wn_fontSize and self.DB_DEFAULTS.wn_fontSize.default) or 42, "OUTLINE")

	frame:ClearAllPoints()
	frame:SetPoint("CENTER", UIParent, "BOTTOM", self.db.wn_posX or 0, self.db.wn_posY or 880)

	frame.anim = frame.text:CreateAnimationGroup()
	local fadeOut = frame.anim:CreateAnimation("Alpha")
	fadeOut:SetFromAlpha(1)
	fadeOut:SetToAlpha(0.2)
	fadeOut:SetDuration(0.4)
	fadeOut:SetOrder(1)

	local fadeIn = frame.anim:CreateAnimation("Alpha")
	fadeIn:SetFromAlpha(0.2)
	fadeIn:SetToAlpha(1)
	fadeIn:SetDuration(0.4)
	fadeIn:SetOrder(2)
	frame.anim:SetLooping("REPEAT")

	self.wnFrame = frame

	-- Keep frame updated when options change
	self:RegisterOptionCallback("wn_fontSize", function(value)
		if self.wnFrame and self.wnFrame.text then
			local fp = FW_WN_GetFontPath(self.db.wn_font or "Friz")
			self.wnFrame.text:SetFont(fp, value, "OUTLINE")
		end
	end)
	self:RegisterOptionCallback("wn_font", function(value)
		if self.wnFrame and self.wnFrame.text then
			local fp = FW_WN_GetFontPath(value or "Friz")
			local size = tonumber(self.db.wn_fontSize) or 42
			self.wnFrame.text:SetFont(fp, size, "OUTLINE")
		end
	end)
	local function applyColor()
		if self.wnFrame and self.wnFrame.text then
			self.wnFrame.text:SetTextColor(self.db.wn_colorR or 1, self.db.wn_colorG or 1, self.db.wn_colorB or 0, self.db.wn_colorA or 1)
		end
	end
	self:RegisterOptionCallback("wn_colorR", function() applyColor() end)
	self:RegisterOptionCallback("wn_colorG", function() applyColor() end)
	self:RegisterOptionCallback("wn_colorB", function() applyColor() end)
	self:RegisterOptionCallback("wn_colorA", function() applyColor() end)
	self:RegisterOptionCallback("wn_posX", function(value)
		if self.wnFrame then
			self.wnFrame:ClearAllPoints()
			self.wnFrame:SetPoint("CENTER", UIParent, "BOTTOM", value, self.db.wn_posY or 880)
		end
	end)
	self:RegisterOptionCallback("wn_posY", function(value)
		if self.wnFrame then
			self.wnFrame:ClearAllPoints()
			self.wnFrame:SetPoint("CENTER", UIParent, "BOTTOM", self.db.wn_posX or 0, value)
		end
	end)
	self:RegisterOptionCallback("wn_alertMsg", function(value)
		if self.wnFrame and self.wnFrame.text then
			self.wnFrame.text:SetText(value)
		end
	end)

	-- Trigger alerts on received whispers
	self:RegisterEventCallback("OnNewMessage", function(_, _, _, _, inform)
		-- inform == nil/false => received whisper
		if inform then
			return
		end
		if not self.db.wn_enable then
			return
		end
		self:WN_ShowAlert()
	end)
end

-- Manual test trigger (used by the Settings panel)
function addon:TestWhisperNotifier()
	-- Ensure frame exists even if the user toggled settings before the frame was created.
	if not self.wnFrame then
		self:InitWhisperNotifier()
	end
	if not self.wnFrame then
		return
	end

	-- Temporarily show the alert regardless of "receive" vs "inform".
	local wasEnabled = self.db.wn_enable
	self.db.wn_enable = 1
	self:WN_ShowAlert()
	self.db.wn_enable = wasEnabled
end
