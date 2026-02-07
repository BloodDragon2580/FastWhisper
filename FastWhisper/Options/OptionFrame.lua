local IsShiftKeyDown = IsShiftKeyDown
local tostring = tostring
local tonumber = tonumber
local format = format
local GameTooltip = GameTooltip
local SETTINGS = SETTINGS

local addon = FastWhisper
local L = addon.L

-- DB can be nil early during load; always guard access
local function DB()
    return addon and addon.db
end

BINDING_HEADER_FASTWHISPER_TITLE = "FastWhisper"
BINDING_NAME_FASTWHISPER_TOGGLE = L["toggle frame"]

-- Initialisiere optionFrame vor der Verwendung
local frame = CreateFrame("Frame", "FastWhisperOptionFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(400, 760) -- Vergrößerte Größe des Frames
frame:SetPoint("CENTER")
frame:Hide() -- Initial ausblenden

-- Funktion zum Verschieben des Frames
local function StartMoving(self)
    self:StartMoving()
end

local function StopMovingOrSizing(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint()
    local db = DB()
    if db then db.framePosition = {point, x, y} end
end

frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", StartMoving)
frame:SetScript("OnDragStop", StopMovingOrSizing)

addon.optionFrame = frame

-- Globale Variablen für die Checkboxen und Slider
local notifyButton, receiveOnlyButton, soundButton, realmCheck, foreignCheck, timeCheck, ignoreTagsButton, applyFiltersButton, saveButton
local notifySlider, mainSlider, widthSlider, heightSlider

-- WhisperNotifier (integrated)
local wnEnableButton, wnMuteButton
local wnMsgEditBox
local wnSizeSlider, wnYSlider, wnXSlider, wnVolumeSlider
local wnChannelDropdown

-- Funktion zum Initialisieren der Optionen beim Öffnen des Frames
local function InitializeOptions()
    -- Checkboxen initialisieren
    notifyButton:SetChecked(addon.db.notifyButton)
    receiveOnlyButton:SetChecked(addon.db.receiveOnly)
    soundButton:SetChecked(addon.db.sound)
    realmCheck:SetChecked(addon.db.showRealm)
    foreignCheck:SetChecked(addon.db.foreignOnly)
    timeCheck:SetChecked(addon.db.time)
    ignoreTagsButton:SetChecked(addon.db.ignoreTags)
    applyFiltersButton:SetChecked(addon.db.applyFilters)
    saveButton:SetChecked(addon.db.save)
    
    -- Slider initialisieren
    notifySlider:SetValue(addon.db.buttonScale or 120) -- Fallback auf 120, wenn kein Wert gespeichert ist
    mainSlider:SetValue(addon.db.listScale or 100)
    widthSlider:SetValue(addon.db.listWidth or addon.DB_DEFAULTS.listWidth.default)
    heightSlider:SetValue(addon.db.listHeight or addon.DB_DEFAULTS.listHeight.default)

    -- WhisperNotifier
    if wnEnableButton then wnEnableButton:SetChecked(addon.db.wn_enable) end
    if wnMuteButton then wnMuteButton:SetChecked(addon.db.wn_mute) end
    if wnMsgEditBox then wnMsgEditBox:SetText(addon.db.wn_alertMsg or "") end
    if wnSizeSlider then wnSizeSlider:SetValue(addon.db.wn_fontSize or addon.DB_DEFAULTS.wn_fontSize.default) end
    if wnYSlider then wnYSlider:SetValue(addon.db.wn_posY or addon.DB_DEFAULTS.wn_posY.default) end
    if wnXSlider then wnXSlider:SetValue(addon.db.wn_posX or addon.DB_DEFAULTS.wn_posX.default) end
    if wnVolumeSlider then wnVolumeSlider:SetValue(addon.db.wn_volumePct or addon.DB_DEFAULTS.wn_volumePct.default) end
    if wnChannelDropdown and UIDropDownMenu_SetSelectedValue then
        do
    local db = DB()
    local initial = (db and db.wn_channel) or (addon.DB_DEFAULTS.wn_channel or "Master")
    UIDropDownMenu_SetSelectedValue(wnChannelDropdown, initial)
end
    end
end

-- Funktion zum Öffnen des Frames
function addon.optionFrame:Open()
    InitializeOptions() -- Optionen initialisieren, bevor der Frame angezeigt wird
    self:Show()
end

-- Konfigurationsbutton für das Hauptfenster
local configButton = CreateFrame("Button", addon.frame:GetName().."Config", addon.frame, "UIPanelButtonTemplate")
configButton:SetSize(16, 16)
configButton:SetNormalTexture("Interface\\Icons\\Trade_Engineering")
configButton:SetPoint("TOPLEFT", 10, -10)

configButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(SETTINGS)
    GameTooltip:AddLine(L["settings tooltip 1"], 1, 1, 1, true)
    GameTooltip:AddLine(L["settings tooltip 2"], 1, 1, 1, true)
    GameTooltip:Show()
end)

configButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

configButton:SetScript("OnClick", function(self)
    if IsShiftKeyDown() then
        addon:PopupShowConfirm(L["clear all confirm"], addon.Clear, addon)
    else
        addon.optionFrame:Open()
    end
end)

-- Titel für allgemeine Optionen
local generalGroup = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
generalGroup:SetText(L["general options"])
generalGroup:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -40) -- Titel positioniert

local function AddButton(group, text, key)
    local button = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    
    -- Manually create a FontString for the button's label
    local label = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetText(text)
    label:SetPoint("LEFT", button, "RIGHT", 5, 0) -- Position the label to the right of the checkbox
    button.label = label

    button:SetPoint("TOPLEFT", group, "BOTTOMLEFT", 0, -5) -- Adjust vertical spacing between buttons
    button:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        addon.db[key] = checked
        addon:BroadcastOptionEvent(key, checked)
        if key == "sound" and checked then
            addon:PlaySound()
        end
    end)

    -- Assign the button to the appropriate global variable
    if key == "notifyButton" then
        notifyButton = button
    elseif key == "receiveOnly" then
        receiveOnlyButton = button
    elseif key == "sound" then
        soundButton = button
    elseif key == "showRealm" then
        realmCheck = button
    elseif key == "foreignOnly" then
        foreignCheck = button
    elseif key == "time" then
        timeCheck = button
    elseif key == "ignoreTags" then
        ignoreTagsButton = button
    elseif key == "applyFilters" then
        applyFiltersButton = button
    elseif key == "save" then
        saveButton = button
    end

    return button
end

-- Checkboxen hinzufügen
notifyButton = AddButton(generalGroup, L["show notify button"], "notifyButton")
receiveOnlyButton = AddButton(notifyButton, L["receive only"], "receiveOnly")
soundButton = AddButton(receiveOnlyButton, L["sound notify"], "sound")

realmCheck = AddButton(soundButton, L["show realms"], "showRealm")

foreignCheck = AddButton(realmCheck, L["foreign realms"], "foreignOnly")
timeCheck = AddButton(foreignCheck, L["timestamp"], "time")
ignoreTagsButton = AddButton(timeCheck, L["ignore tag messages"], "ignoreTags")
applyFiltersButton = AddButton(ignoreTagsButton, L["apply third-party filters"], "applyFilters")
saveButton = AddButton(applyFiltersButton, L["save messages"], "save")

addon:RegisterOptionCallback("showRealm", function(value)
    if value then
        foreignCheck:Enable()
    else
        foreignCheck:Disable()
    end
end)

-- Funktionen für Slider
local function Slider_OnSliderInit(self)
    return addon.db[self.key]
end

local function Slider_OnSliderChanged(self, value)
    addon.db[self.key] = value
    addon:BroadcastOptionEvent(self.key, value)
end

local function CreateSlider(text, key, fmt)
    local config = addon.DB_DEFAULTS[key]
    local slider = CreateFrame("Slider", nil, frame, "OptionsSliderTemplate")
    slider:SetMinMaxValues(config.min, config.max)
    slider:SetValueStep(config.step)
    slider.text = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    slider.text:SetText(text)
    slider.text:SetPoint("BOTTOM", slider, "TOP", 0, 0)
    slider:SetSize(320, 20) -- Größe des Sliders
    slider:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -220) -- Positionierung der Slider
    slider.key = key
    slider.OnSliderInit = Slider_OnSliderInit
    slider.OnValueChanged = Slider_OnSliderChanged

    return slider
end

-- Titel für Frame-Einstellungen
local frameLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
frameLabel:SetText(L["frame settings"])
frameLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -420) -- Titelpositionierung angepasst

notifySlider = CreateSlider(L["button scale"], "buttonScale", "%d%%")
mainSlider = CreateSlider(L["list scale"], "listScale", "%d%%")
widthSlider = CreateSlider(L["list width"], "listWidth")
heightSlider = CreateSlider(L["list height"], "listHeight")

-- Schieberegler Positionen
notifySlider:SetPoint("TOPLEFT", frameLabel, "BOTTOMLEFT", 0, -20)
mainSlider:SetPoint("TOPLEFT", notifySlider, "BOTTOMLEFT", 0, -40)
widthSlider:SetPoint("TOPLEFT", mainSlider, "BOTTOMLEFT", 0, -40)
heightSlider:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT", 0, -40)

-- ---------------------------------------------------------------------------
-- WhisperNotifier (integrated)

local function CreateWNEditBox(parent, width)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(width, 20)
    box:SetAutoFocus(false)
    return box
end

local wnLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
wnLabel:SetText(L["wn options"])
wnLabel:SetPoint("TOPLEFT", heightSlider, "BOTTOMLEFT", -10, -30)

wnEnableButton = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
wnEnableButton:SetPoint("TOPLEFT", wnLabel, "BOTTOMLEFT", 0, -8)
wnEnableButton.Text:SetText(L["wn enable"])
wnEnableButton:SetScript("OnClick", function(self)
    local checked = self:GetChecked() and 1 or 0
    addon.db.wn_enable = checked
end)

wnMuteButton = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
wnMuteButton:SetPoint("LEFT", wnEnableButton.Text, "RIGHT", 20, 0)
wnMuteButton.Text:SetText(L["wn mute"])
wnMuteButton:SetScript("OnClick", function(self)
    local checked = self:GetChecked() and 1 or 0
    addon.db.wn_mute = checked
end)

local wnMsgLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
wnMsgLabel:SetPoint("TOPLEFT", wnEnableButton, "BOTTOMLEFT", 0, -16)
wnMsgLabel:SetText(L["wn message"])

wnMsgEditBox = CreateWNEditBox(frame, 220)
wnMsgEditBox:SetPoint("LEFT", wnMsgLabel, "RIGHT", 10, 0)
wnMsgEditBox:SetScript("OnEnterPressed", function(self)
    local v = self:GetText()
    if v and v ~= "" then
        addon.db.wn_alertMsg = v
        addon:BroadcastOptionEvent("wn_alertMsg", v)
    end
    self:ClearFocus()
end)

wnSizeSlider = CreateFrame("Slider", "FastWhisperWNFontSize", frame, "OptionsSliderTemplate")
wnSizeSlider:SetMinMaxValues(addon.DB_DEFAULTS.wn_fontSize.min, addon.DB_DEFAULTS.wn_fontSize.max)
wnSizeSlider:SetValueStep(addon.DB_DEFAULTS.wn_fontSize.step)
wnSizeSlider:SetWidth(240)
wnSizeSlider:SetPoint("TOPLEFT", wnMsgLabel, "BOTTOMLEFT", 0, -28)
_G[wnSizeSlider:GetName().."Low"]:SetText(tostring(addon.DB_DEFAULTS.wn_fontSize.min))
_G[wnSizeSlider:GetName().."High"]:SetText(tostring(addon.DB_DEFAULTS.wn_fontSize.max))
_G[wnSizeSlider:GetName().."Text"]:SetText(L["wn font size"])
wnSizeSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value)
    local db = DB()
    if db then db.wn_fontSize = value end
    addon:BroadcastOptionEvent("wn_fontSize", value)
end)

wnYSlider = CreateFrame("Slider", "FastWhisperWNPosY", frame, "OptionsSliderTemplate")
wnYSlider:SetMinMaxValues(addon.DB_DEFAULTS.wn_posY.min, addon.DB_DEFAULTS.wn_posY.max)
wnYSlider:SetValueStep(addon.DB_DEFAULTS.wn_posY.step)
wnYSlider:SetWidth(240)
wnYSlider:SetPoint("TOPLEFT", wnSizeSlider, "BOTTOMLEFT", 0, -38)
_G[wnYSlider:GetName().."Low"]:SetText(tostring(addon.DB_DEFAULTS.wn_posY.min))
_G[wnYSlider:GetName().."High"]:SetText(tostring(addon.DB_DEFAULTS.wn_posY.max))
_G[wnYSlider:GetName().."Text"]:SetText(L["wn pos y"])
wnYSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value)
    local db = DB()
    if db then db.wn_posY = value end
    addon:BroadcastOptionEvent("wn_posY", value)
end)

wnXSlider = CreateFrame("Slider", "FastWhisperWNPosX", frame, "OptionsSliderTemplate")
wnXSlider:SetMinMaxValues(addon.DB_DEFAULTS.wn_posX.min, addon.DB_DEFAULTS.wn_posX.max)
wnXSlider:SetValueStep(addon.DB_DEFAULTS.wn_posX.step)
wnXSlider:SetWidth(240)
wnXSlider:SetPoint("TOPLEFT", wnYSlider, "BOTTOMLEFT", 0, -38)
_G[wnXSlider:GetName().."Low"]:SetText(tostring(addon.DB_DEFAULTS.wn_posX.min))
_G[wnXSlider:GetName().."High"]:SetText(tostring(addon.DB_DEFAULTS.wn_posX.max))
_G[wnXSlider:GetName().."Text"]:SetText(L["wn pos x"])
wnXSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value)
    local db = DB()
    if db then db.wn_posX = value end
    addon:BroadcastOptionEvent("wn_posX", value)
end)

wnVolumeSlider = CreateFrame("Slider", "FastWhisperWNVolume", frame, "OptionsSliderTemplate")
wnVolumeSlider:SetMinMaxValues(addon.DB_DEFAULTS.wn_volumePct.min, addon.DB_DEFAULTS.wn_volumePct.max)
wnVolumeSlider:SetValueStep(addon.DB_DEFAULTS.wn_volumePct.step)
wnVolumeSlider:SetWidth(240)
wnVolumeSlider:SetPoint("TOPLEFT", wnXSlider, "BOTTOMLEFT", 0, -38)
_G[wnVolumeSlider:GetName().."Low"]:SetText("0%")
_G[wnVolumeSlider:GetName().."High"]:SetText("100%")
_G[wnVolumeSlider:GetName().."Text"]:SetText(L["wn volume"])
wnVolumeSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value)
    local db = DB()
    if db then db.wn_volumePct = value end
end)

wnChannelDropdown = CreateFrame("Frame", "FastWhisperNotifierChannelDropdown", frame, "UIDropDownMenuTemplate")
wnChannelDropdown:SetPoint("LEFT", wnVolumeSlider, "RIGHT", -10, -2)
local channels = {
    {text=L["wn channel master"], value="Master"},
    {text=L["wn channel sfx"], value="SFX"},
    {text=L["wn channel music"], value="Music"},
    {text=L["wn channel ambience"], value="Ambience"},
}
local function ChannelDropdown_OnClick(self)
    local db = DB()
    if db then db.wn_channel = self.value end
    UIDropDownMenu_SetSelectedValue(wnChannelDropdown, self.value)
end
UIDropDownMenu_Initialize(wnChannelDropdown, function(self, level)
    for _, ch in ipairs(channels) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = ch.text
        info.value = ch.value
        info.func = ChannelDropdown_OnClick
        UIDropDownMenu_AddButton(info)
    end
end)
UIDropDownMenu_SetWidth(wnChannelDropdown, 90)
do
    local db = DB()
    local initial = (db and db.wn_channel) or (addon.DB_DEFAULTS.wn_channel or "Master")
    UIDropDownMenu_SetSelectedValue(wnChannelDropdown, initial)
end

local wnTestBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
wnTestBtn:SetSize(120, 22)
wnTestBtn:SetPoint("TOPLEFT", wnVolumeSlider, "BOTTOMLEFT", 0, -10)
wnTestBtn:SetText(L["wn test"])
wnTestBtn:SetScript("OnClick", function()
    if addon.WN_ShowAlert then
        addon:WN_ShowAlert()
    end
end)

-- Funktion für Rücksetz-Schaltfläche
local function OnResetFrames()
    notifySlider:SetValue(120)
    mainSlider:SetValue(100)
    widthSlider:SetValue(addon.DB_DEFAULTS.listWidth.default)
    heightSlider:SetValue(addon.DB_DEFAULTS.listHeight.default)
    addon:BroadcastEvent("OnResetFrames")
end

local resetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
resetButton:SetSize(150, 22)
resetButton:SetText(L["reset frames"])
resetButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10) -- Position am unteren Rand

resetButton:SetScript("OnClick", function()
    addon:PopupShowConfirm(L["reset frames confirm"], OnResetFrames)
end)

local clearButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
clearButton:SetSize(150, 22)
clearButton:SetText(L["clear all"])
clearButton:SetPoint("LEFT", resetButton, "RIGHT", 10, 0) -- Position neben der Reset-Schaltfläche

clearButton:SetScript("OnClick", function()
    addon:PopupShowConfirm(L["clear all confirm"], addon.Clear, addon)
end)
