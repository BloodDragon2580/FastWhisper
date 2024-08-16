local IsShiftKeyDown = IsShiftKeyDown
local tostring = tostring
local tonumber = tonumber
local format = format
local GameTooltip = GameTooltip
local SETTINGS = SETTINGS

local addon = FastWhisper
local L = addon.L

BINDING_HEADER_FASTWHISPER_TITLE = "FastWhisper"
BINDING_NAME_FASTWHISPER_TOGGLE = L["toggle frame"]

-- Initialisiere optionFrame vor der Verwendung
local frame = CreateFrame("Frame", "FastWhisperOptionFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(400, 600) -- Vergrößerte Größe des Frames
frame:SetPoint("CENTER")
frame:Hide() -- Initial ausblenden

-- Funktion zum Verschieben des Frames
local function StartMoving(self)
    self:StartMoving()
end

local function StopMovingOrSizing(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint()
    addon.db.framePosition = {point, x, y}
end

frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", StartMoving)
frame:SetScript("OnDragStop", StopMovingOrSizing)

addon.optionFrame = frame

-- Funktion zum Öffnen des Frames
function addon.optionFrame:Open()
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

-- Funktion zum Hinzufügen von Schaltflächen
local function AddButton(group, text, key)
    local button = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    button.text:SetText(text)
    button:SetPoint("TOPLEFT", group, "BOTTOMLEFT", 0, -25) -- Abstand zwischen Buttons angepasst
    button:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        addon.db[key] = checked
        addon:BroadcastOptionEvent(key, checked)
        if key == "sound" and checked then
            addon:PlaySound()
        end
    end)
    return button
end

local notifyButton = AddButton(generalGroup, L["show notify button"], "notifyButton")
local receiveOnlyButton = AddButton(notifyButton, L["receive only"], "receiveOnly")
local soundButton = AddButton(receiveOnlyButton, L["sound notify"], "sound")

local realmCheck = AddButton(soundButton, L["show realms"], "showRealm")

local foreignCheck = AddButton(realmCheck, L["foreign realms"], "foreignOnly")
local timeCheck = AddButton(foreignCheck, L["timestamp"], "time")
local ignoreTagsButton = AddButton(timeCheck, L["ignore tag messages"], "ignoreTags")
local applyFiltersButton = AddButton(ignoreTagsButton, L["apply third-party filters"], "applyFilters")
local saveButton = AddButton(applyFiltersButton, L["save messages"], "save")

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
frameLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -280) -- Titelpositionierung angepasst

local notifySlider = CreateSlider(L["button scale"], "buttonScale", "%d%%")
local mainSlider = CreateSlider(L["list scale"], "listScale", "%d%%")
local widthSlider = CreateSlider(L["list width"], "listWidth")
local heightSlider = CreateSlider(L["list height"], "listHeight")

-- Schieberegler Positionen
notifySlider:SetPoint("TOPLEFT", frameLabel, "BOTTOMLEFT", 0, -20)
mainSlider:SetPoint("TOPLEFT", notifySlider, "BOTTOMLEFT", 0, -40)
widthSlider:SetPoint("TOPLEFT", mainSlider, "BOTTOMLEFT", 0, -40)
heightSlider:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT", 0, -40)

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
