
local function CreatePanelFrame(reference, name, title)
	local panelframe = CreateFrame( "Frame", reference, UIParent);
	panelframe.name = name
	panelframe.Label = panelframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
	panelframe.Label:SetPoint("TOPLEFT", panelframe, "TOPLEFT", 16, -16)
	panelframe.Label:SetHeight(15)
	panelframe.Label:SetWidth(350)
	panelframe.Label:SetJustifyH("LEFT")
	panelframe.Label:SetJustifyV("TOP")
	panelframe.Label:SetText(title or name)
	return panelframe
end

local function CreateCheckButton(reference, parent, label)
	local checkbutton = CreateFrame("CheckButton", reference, parent, "FarmLogCheckButtonTemplate")
	checkbutton.Label = _G[reference.."Text"]
	checkbutton.Label:SetText(label)
	return checkbutton
end

local InterfacePanel = CreatePanelFrame("FarmLogInterfacePanel", "FarmLog", nil)
InterfaceOptions_AddCategory(InterfacePanel);
FarmLog.InterfacePanel = InterfacePanel

local panel = InterfacePanel
local L = FarmLog.L 
local font = "Fonts\\FRIZQT__.TTF"

panel:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", insets = { left = 2, right = 2, top = 2, bottom = 2 },})
panel:SetBackdropColor(0.06, 0.06, 0.06, .7)

panel.Label:SetFont(font, 20)
panel.Label:SetPoint("TOPLEFT", panel, "TOPLEFT", 16+6, -16-4)

panel.Version = panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
panel.Version:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -20, -26)
panel.Version:SetHeight(15)
panel.Version:SetWidth(350)
panel.Version:SetJustifyH("RIGHT")
panel.Version:SetJustifyV("TOP")
panel.Version:SetText(FarmLog.Version)
panel.Version:SetFont(font, 12)

panel.DividerLine = panel:CreateTexture(nil, 'ARTWORK')
panel.DividerLine:SetTexture("Interface\\Addons\\FarmLog\\assets\\ThinBlackLine")
panel.DividerLine:SetSize(500, 12)
panel.DividerLine:SetPoint("TOPLEFT", panel.Label, "BOTTOMLEFT", -6, -8)

-- Main Scrolled Frame
------------------------------
panel.MainFrame = CreateFrame("Frame")
panel.MainFrame:SetWidth(412)
panel.MainFrame:SetHeight(100) 		-- If the items inside the frame overflow, it automatically adjusts the height.

-- Scrollable Panel Window
------------------------------
panel.ScrollFrame = CreateFrame("ScrollFrame","FarmLog_Scrollframe", panel, "UIPanelScrollFrameTemplate")
panel.ScrollFrame:SetPoint("LEFT", 16)
panel.ScrollFrame:SetPoint("TOP", panel.DividerLine, "BOTTOM", 0, -8)
panel.ScrollFrame:SetPoint("BOTTOMRIGHT", -32 , 16)
panel.ScrollFrame:SetScrollChild(panel.MainFrame)
panel.ScrollFrame:SetScript("OnMouseWheel", OnMouseWheelScrollFrame)

-- Scroll Frame Border
------------------------------
panel.ScrollFrameBorder = CreateFrame("Frame", "FarmLogScrollFrameBorder", panel.ScrollFrame)
panel.ScrollFrameBorder:SetPoint("TOPLEFT", -4, 5)
panel.ScrollFrameBorder:SetPoint("BOTTOMRIGHT", 3, -5)
panel.ScrollFrameBorder:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                                            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                                            --tile = true, tileSize = 16,
                                            edgeSize = 16,
                                            insets = { left = 4, right = 4, top = 4, bottom = 4 }
                                            });
panel.ScrollFrameBorder:SetBackdropColor(0.05, 0.05, 0.05, 0)
panel.ScrollFrameBorder:SetBackdropBorderColor(0.2, 0.2, 0.2, 0)

local mfpanel = panel.MainFrame

----------------------------------------------
-- General
----------------------------------------------
mfpanel.GeneralCategoryTitle = mfpanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
mfpanel.GeneralCategoryTitle:SetFont(font, 16)
mfpanel.GeneralCategoryTitle:SetText(L["General"])
mfpanel.GeneralCategoryTitle:SetPoint("TOPLEFT", 20, -10)

mfpanel.AutoSwitchInstances = CreateCheckButton("FarmLogOptions_AutoSwitchInstances", mfpanel, L["autoSwitchInstances"])
mfpanel.AutoSwitchInstances:SetPoint("TOPLEFT", mfpanel.GeneralCategoryTitle, "BOTTOMLEFT", 0, -8)
mfpanel.AutoSwitchInstances:SetScript("OnClick", function(self) FLogGlobalVars.autoSwitchInstances = self:GetChecked() end)
mfpanel.AutoSwitchInstances.tooltipText = L["autoSwitchInstances-tooltip"]

mfpanel.ResumeSessionOnSwitch = CreateCheckButton("FarmLogOptions_ResumeSessionOnSwitch", mfpanel, L["resumeSessionOnSwitch"])
mfpanel.ResumeSessionOnSwitch:SetPoint("TOPLEFT", mfpanel.AutoSwitchInstances, "TOPLEFT", 0, -25)
mfpanel.ResumeSessionOnSwitch:SetScript("OnClick", function(self) FLogGlobalVars.resumeSessionOnSwitch = self:GetChecked() end)
mfpanel.ResumeSessionOnSwitch.tooltipText = L["resumeSessionOnSwitch-tooltip"]

mfpanel.DismissLootWindowOnEsc = CreateCheckButton("FarmLogOptions_DismissLootWindowOnEsc", mfpanel, L["dismissLootWindowOnEsc"])
mfpanel.DismissLootWindowOnEsc:SetPoint("TOPLEFT", mfpanel.ResumeSessionOnSwitch, "TOPLEFT", 0, -25)
mfpanel.DismissLootWindowOnEsc:SetScript("OnClick", function(self) FLogGlobalVars.dismissLootWindowOnEsc = self:GetChecked() end)
mfpanel.DismissLootWindowOnEsc.tooltipText = L["dismissLootWindowOnEsc-tooltip"]

----------------------------------------------
-- Appearance
----------------------------------------------
mfpanel.AppearanceCategoryTitle = mfpanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
mfpanel.AppearanceCategoryTitle:SetFont(font, 16)
mfpanel.AppearanceCategoryTitle:SetText(L["Appearance"])
mfpanel.AppearanceCategoryTitle:SetPoint("TOPLEFT", mfpanel.DismissLootWindowOnEsc, "BOTTOMLEFT", 0, -20)

mfpanel.ResetMinimapPositionButton = CreateFrame("Button", "FarmLogOptions_ResetMinimapPositionButton", panel, "FarmLogPanelButtonTemplate")
mfpanel.ResetMinimapPositionButton:SetPoint("TOPLEFT", mfpanel.AppearanceCategoryTitle, "BOTTOMLEFT", -0, -10)
mfpanel.ResetMinimapPositionButton:SetWidth(200)
mfpanel.ResetMinimapPositionButton:SetText(L["Reset Minimap Icon Position"])
mfpanel.ResetMinimapPositionButton:SetScript("OnClick", function(self) FarmLog_MinimapButton:ResetPosition() end)

mfpanel.ResetLootWindowPositionButton = CreateFrame("Button", "FarmLogOptions_ResetButton", panel, "FarmLogPanelButtonTemplate")
mfpanel.ResetLootWindowPositionButton:SetPoint("TOPLEFT", mfpanel.ResetMinimapPositionButton, "TOPRIGHT", 10, 0)
mfpanel.ResetLootWindowPositionButton:SetWidth(200)
mfpanel.ResetLootWindowPositionButton:SetText(L["Reset Loot Window Position"])
mfpanel.ResetLootWindowPositionButton:SetScript("OnClick", function(self) FarmLog_MainWindow:ResetPosition() end)


----------------------------------------------
-- Init
----------------------------------------------

function InterfacePanel:AddonLoaded() 
	InterfacePanel.MainFrame.AutoSwitchInstances:SetChecked(FLogGlobalVars.autoSwitchInstances)
	InterfacePanel.MainFrame.ResumeSessionOnSwitch:SetChecked(FLogGlobalVars.resumeSessionOnSwitch)
	InterfacePanel.MainFrame.DismissLootWindowOnEsc:SetChecked(FLogGlobalVars.dismissLootWindowOnEsc)
end 