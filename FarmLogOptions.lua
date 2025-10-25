-- Some pieces of the code here were taken from NeatPlates https://www.curseforge.com/wow/addons/neatplates

local function CreatePanelFrame(reference, title)
	local panelframe = CreateFrame( "Frame", reference, UIParent, "BackdropTemplate");
	panelframe.name = title
	panelframe.Label = panelframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
	panelframe.Label:SetPoint("TOPLEFT", panelframe, "TOPLEFT", 16, -16)
	panelframe.Label:SetHeight(15)
	panelframe.Label:SetWidth(350)
	panelframe.Label:SetJustifyH("LEFT")
	panelframe.Label:SetJustifyV("TOP")
	panelframe.Label:SetText(title)
	return panelframe
end

local function CreateHelpFrame(reference, text)
	local helpframe = CreateFrame( "Frame", reference, UIParent);
	helpframe.name = reference
	helpframe.Label = helpframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
	helpframe.Label:SetPoint("TOPLEFT", helpframe, "TOPLEFT", 16, -16)
	helpframe.Label:SetPoint("RIGHT", helpframe, "RIGHT", -16, 16)
	helpframe.Label:SetJustifyH("LEFT")
	helpframe.Label:SetJustifyV("TOP")
	helpframe.Label:SetText(text)
	return helpframe
end

local function CreateCheckButton(reference, parent, label)
	local checkbutton = CreateFrame("CheckButton", reference, parent, "FarmLogCheckButtonTemplate")
	checkbutton.Label = _G[reference.."Text"]
	checkbutton.Label:SetText(label)
	return checkbutton
end

local function SetTrackFlag(flag, state, recalc)
	FLogGlobalVars.track[flag] = state
	if recalc then 
		FarmLog_MainWindow:RecalcTotals()
	end 
	FarmLog_MainWindow:Refresh()
end 



------------------------------------------------
-- Build Options UI
------------------------------------------------

local InterfacePanel = CreatePanelFrame("FarmLogInterfacePanel", "FarmLog")
local category = Settings.RegisterCanvasLayoutCategory(InterfacePanel, "FarmLog")
Settings.RegisterAddOnCategory(category)
FarmLog.InterfacePanel = InterfacePanel

local SharedMedia = LibStub:GetLibrary ("LibSharedMedia-3.0")
local panel = InterfacePanel
local L = FarmLog.L 
local font = SharedMedia.MediaTable.font[SharedMedia.DefaultMedia.font]

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
panel.MainFrame:SetWidth(500)
panel.MainFrame:SetHeight(100) 		-- If the items inside the frame overflow, it automatically adjusts the height.

-- Scrollable Panel Window
------------------------------
panel.ScrollFrame = CreateFrame("ScrollFrame","FarmLog_Scrollframe", panel, "UIPanelScrollFrameTemplate")
panel.ScrollFrame:EnableMouse(true)
panel.ScrollFrame:EnableMouseWheel(true)
panel.ScrollFrame:SetPoint("LEFT", 8)
panel.ScrollFrame:SetPoint("TOP", panel.DividerLine, "BOTTOM", 0, -8)
panel.ScrollFrame:SetPoint("BOTTOMRIGHT", -32 , 8)
panel.ScrollFrame:SetScrollChild(panel.MainFrame)
-- panel.ScrollFrame:SetScript("OnMouseWheel", OnMouseWheelScrollFrame)

-- Scroll Frame Border
------------------------------
panel.ScrollFrameBorder = CreateFrame("Frame", "FarmLogScrollFrameBorder", panel.ScrollFrame, "BackdropTemplate")
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

mfpanel.TopHelp = mfpanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
mfpanel.TopHelp:SetFont(font, 12)
mfpanel.TopHelp:SetText(L["options-help-sessions"])
mfpanel.TopHelp:SetPoint("TOPLEFT", 25, 0)
mfpanel.TopHelp:SetPoint("RIGHT", -20, 0)
mfpanel.TopHelp:SetJustifyH("LEFT")
mfpanel.TopHelp:SetJustifyV("TOP")
mfpanel.TopHelp:SetTextColor(1, 1, 1, 1)

----------------------------------------------
-- General
----------------------------------------------
mfpanel.GeneralCategoryTitle = mfpanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
mfpanel.GeneralCategoryTitle:SetFont(font, 16)
mfpanel.GeneralCategoryTitle:SetText(L["General"])
mfpanel.GeneralCategoryTitle:SetPoint("TOPLEFT", mfpanel.TopHelp, "BOTTOMLEFT", 0, -20)

mfpanel.AutoSwitchInstances = CreateCheckButton("FarmLogOptions_AutoSwitchInstances", mfpanel, L["autoSwitchInstances"])
mfpanel.AutoSwitchInstances:SetPoint("TOPLEFT", mfpanel.GeneralCategoryTitle, "BOTTOMLEFT", 0, -8)
mfpanel.AutoSwitchInstances:SetScript("OnClick", function(self) FLogGlobalVars.autoSwitchInstances = self:GetChecked() end)
mfpanel.AutoSwitchInstances.tooltipText = L["autoSwitchInstances-tooltip"]

mfpanel.ResumeSessionOnSwitch = CreateCheckButton("FarmLogOptions_ResumeSessionOnSwitch", mfpanel, L["resumeSessionOnSwitch"])
mfpanel.ResumeSessionOnSwitch:SetPoint("TOPLEFT", mfpanel.AutoSwitchInstances, "TOPLEFT", 0, -25)
mfpanel.ResumeSessionOnSwitch:SetScript("OnClick", function(self) FLogGlobalVars.resumeSessionOnSwitch = self:GetChecked() end)
mfpanel.ResumeSessionOnSwitch.tooltipText = L["resumeSessionOnSwitch-tooltip"]

mfpanel.PauseOnLogin = CreateCheckButton("FarmLogOptions_PauseOnLogin", mfpanel, L["pauseOnLogin"])
mfpanel.PauseOnLogin:SetPoint("TOPLEFT", mfpanel.ResumeSessionOnSwitch, "TOPLEFT", 0, -25)
mfpanel.PauseOnLogin:SetScript("OnClick", function(self) FLogGlobalVars.pauseOnLogin = self:GetChecked() end)

mfpanel.TrackPartyLoot = CreateCheckButton("FarmLogOptions_TrackPartyLoot", mfpanel, L["trackPartyLoot"])
mfpanel.TrackPartyLoot:SetPoint("TOPLEFT", mfpanel.PauseOnLogin, "TOPLEFT", 0, -25)
mfpanel.TrackPartyLoot:SetScript("OnClick", function(self) FLogGlobalVars.trackPartyLoot = self:GetChecked() end)
mfpanel.TrackPartyLoot.tooltipText = L["trackPartyLoot-tooltip"]

mfpanel.DismissLootWindowOnEsc = CreateCheckButton("FarmLogOptions_DismissLootWindowOnEsc", mfpanel, L["dismissLootWindowOnEsc"])
mfpanel.DismissLootWindowOnEsc:SetPoint("TOPLEFT", mfpanel.TrackPartyLoot, "TOPLEFT", 0, -25)
mfpanel.DismissLootWindowOnEsc:SetScript("OnClick", function(self) FLogGlobalVars.dismissLootWindowOnEsc = self:GetChecked() end)
mfpanel.DismissLootWindowOnEsc.tooltipText = L["dismissLootWindowOnEsc-tooltip"]

mfpanel.ShowBlackLotusTimer = CreateCheckButton("FarmLogOptions_ShowBlackLotusTimer", mfpanel, L["showBlackLotusTimer"])
mfpanel.ShowBlackLotusTimer:SetPoint("TOPLEFT", mfpanel.DismissLootWindowOnEsc, "TOPLEFT", 0, -25)
mfpanel.ShowBlackLotusTimer:SetScript("OnClick", function(self) FLogGlobalVars.showBlackLotusTimer = self:GetChecked() end)
mfpanel.ShowBlackLotusTimer.tooltipText = L["showBlackLotusTimer-tooltip"]


----------------------------------------------
-- Prices
----------------------------------------------
mfpanel.PricesCategoryTitle = mfpanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
mfpanel.PricesCategoryTitle:SetFont(font, 16)
mfpanel.PricesCategoryTitle:SetText(L["Prices"])
mfpanel.PricesCategoryTitle:SetPoint("TOPLEFT", mfpanel.ShowBlackLotusTimer, "BOTTOMLEFT", 0, -20)

mfpanel.AHMinQuality = mfpanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
mfpanel.AHMinQuality:SetPoint("TOPLEFT", mfpanel.PricesCategoryTitle, "BOTTOMLEFT", 0, -12)
mfpanel.AHMinQuality:SetWidth(170)
mfpanel.AHMinQuality:SetJustifyH("LEFT")
mfpanel.AHMinQuality:SetText(L["AH Min Quality"])

local function AHMinQualityDropdown_OnClick(self)
	for i = 0,4 do 
		if L["ah-quality-"..i] == self.value then 
			FLogGlobalVars.ahMinQuality = i 
			UIDropDownMenu_SetText(mfpanel.AHMinQualityDropdown, L["ah-quality-"..i])
			FarmLog_MainWindow:RecalcTotals()
			FarmLog_MainWindow:Refresh()
			break
		end 
	end 
end
mfpanel.AHMinQualityDropdown = CreateFrame("Frame", "FarmLogAHMinQualityDropdown", mfpanel, "UIDropDownMenuTemplate")
mfpanel.AHMinQualityDropdown:SetPoint("TOPLEFT", mfpanel.AHMinQuality, "BOTTOMLEFT", -20, -2)
UIDropDownMenu_SetWidth(mfpanel.AHMinQualityDropdown, 200) 
UIDropDownMenu_Initialize(mfpanel.AHMinQualityDropdown, function (frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	info.func = AHMinQualityDropdown_OnClick
	for i = 0,4 do 
		info.text, info.checked = L["ah-quality-"..i], i == FLogGlobalVars.ahMinQuality
		UIDropDownMenu_AddButton(info)
	end 
end)

mfpanel.TSMPriceSource = mfpanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
mfpanel.TSMPriceSource:SetPoint("TOPLEFT", mfpanel.AHMinQuality, "BOTTOMLEFT", 0, -40)
mfpanel.TSMPriceSource:SetWidth(170)
mfpanel.TSMPriceSource:SetJustifyH("LEFT")
mfpanel.TSMPriceSource:SetText(L["TSM Price Source"])

local function TSMPriceSourceDropdown_OnClick(self)
	for i = 0,5 do
		if TSM_PRICE_SOURCES["tsm-price-source-"..i] == self.value then
			FLogGlobalVars.tsmPriceSource = i
			UIDropDownMenu_SetText(mfpanel.TSMPriceSourceDropdown, TSM_PRICE_SOURCES["tsm-price-source-"..i])
			FarmLog_MainWindow:RecalcTotals()
			FarmLog_MainWindow:Refresh()
			break
		end
	end
end
mfpanel.TSMPriceSourceDropdown = CreateFrame("Frame", "FarmLogTSMPriceSourceDropdown", mfpanel, "UIDropDownMenuTemplate")
mfpanel.TSMPriceSourceDropdown:SetPoint("TOPLEFT", mfpanel.TSMPriceSource, "BOTTOMLEFT", -20, -2)
UIDropDownMenu_SetWidth(mfpanel.TSMPriceSourceDropdown, 200)
UIDropDownMenu_Initialize(mfpanel.TSMPriceSourceDropdown, function (frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	info.func = TSMPriceSourceDropdown_OnClick
	for i = 0,5 do
		info.text, info.checked = TSM_PRICE_SOURCES["tsm-price-source-"..i], i == FLogGlobalVars.tsmPriceSource
		UIDropDownMenu_AddButton(info)
	end
end)


----------------------------------------------
-- Tracking
----------------------------------------------
mfpanel.TrackingCategoryTitle = mfpanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
mfpanel.TrackingCategoryTitle:SetFont(font, 16)
mfpanel.TrackingCategoryTitle:SetText(L["Tracking"])
mfpanel.TrackingCategoryTitle:SetPoint("TOPLEFT", mfpanel.TSMPriceSourceDropdown, "BOTTOMLEFT", 20, -20)

mfpanel.TrackKills = CreateCheckButton("FarmLogOptions_TrackKills", mfpanel, L["Mobs Kill Count"])
mfpanel.TrackKills:SetPoint("TOPLEFT", mfpanel.TrackingCategoryTitle, "BOTTOMLEFT", 0, -8)
mfpanel.TrackKills:SetScript("OnClick", function(self) 
	SetTrackFlag("kills", self:GetChecked()) 
	if not self:GetChecked() then 
		SetTrackFlag("drops", false)
		mfpanel.TrackLoot:SetChecked(false)
	end 
	mfpanel.TrackLoot:SetEnabled(self:GetChecked())
end)

mfpanel.TrackLoot = CreateCheckButton("FarmLogOptions_TrackLoot", mfpanel, L["Received Loot"])
mfpanel.TrackLoot:SetPoint("TOPLEFT", mfpanel.TrackKills, "TOPLEFT", 0, -25)
mfpanel.TrackLoot:SetScript("OnClick", function(self) SetTrackFlag("drops", self:GetChecked()) end)

mfpanel.TrackHonor = CreateCheckButton("FarmLogOptions_TrackHonor", mfpanel, L["Honor"])
mfpanel.TrackHonor:SetPoint("TOPLEFT", mfpanel.TrackLoot, "TOPLEFT", 0, -25)
mfpanel.TrackHonor:SetScript("OnClick", function(self) SetTrackFlag("honor", self:GetChecked()) end)

mfpanel.TrackHKs = CreateCheckButton("FarmLogOptions_TrackHKs", mfpanel, L["Honorable kills"])
mfpanel.TrackHKs:SetPoint("TOPLEFT", mfpanel.TrackHonor, "TOPLEFT", 0, -25)
mfpanel.TrackHKs:SetScript("OnClick", function(self) SetTrackFlag("hks", self:GetChecked()) end)

mfpanel.TrackDKs = CreateCheckButton("FarmLogOptions_TrackDKs", mfpanel, L["Dishonorable kills"])
mfpanel.TrackDKs:SetPoint("TOPLEFT", mfpanel.TrackHKs, "TOPLEFT", 0, -25)
mfpanel.TrackDKs:SetScript("OnClick", function(self) SetTrackFlag("dks", self:GetChecked()) end)

mfpanel.TrackRanks = CreateCheckButton("FarmLogOptions_TrackRanks", mfpanel, L["Ranks Kill Count"])
mfpanel.TrackRanks:SetPoint("TOPLEFT", mfpanel.TrackDKs, "TOPLEFT", 0, -25)
mfpanel.TrackRanks:SetScript("OnClick", function(self) SetTrackFlag("ranks", self:GetChecked()) end)

mfpanel.TrackXP = CreateCheckButton("FarmLogOptions_TrackXP", mfpanel, L["Experience Gained"])
mfpanel.TrackXP:SetPoint("TOPLEFT", mfpanel.TrackRanks, "TOPLEFT", 0, -25)
mfpanel.TrackXP:SetScript("OnClick", function(self) SetTrackFlag("xp", self:GetChecked()) end)

mfpanel.TrackSkill = CreateCheckButton("FarmLogOptions_TrackSkill", mfpanel, L["Skill Level Increments"])
mfpanel.TrackSkill:SetPoint("TOPLEFT", mfpanel.TrackXP, "TOPLEFT", 0, -25)
mfpanel.TrackSkill:SetScript("OnClick", function(self) SetTrackFlag("skill", self:GetChecked()) end)

mfpanel.TrackRep = CreateCheckButton("FarmLogOptions_TrackRep", mfpanel, L["Reputation Gained"])
mfpanel.TrackRep:SetPoint("TOPLEFT", mfpanel.TrackSkill, "TOPLEFT", 0, -25)
mfpanel.TrackRep:SetScript("OnClick", function(self) SetTrackFlag("rep", self:GetChecked()) end)

mfpanel.TrackDeaths = CreateCheckButton("FarmLogOptions_TrackDeaths", mfpanel, L["Deaths"])
mfpanel.TrackDeaths:SetPoint("TOPLEFT", mfpanel.TrackRep, "TOPLEFT", 0, -25)
mfpanel.TrackDeaths:SetScript("OnClick", function(self) SetTrackFlag("deaths", self:GetChecked()) end)

mfpanel.TrackResets = CreateCheckButton("FarmLogOptions_TrackResets", mfpanel, L["Instance Resets"])
mfpanel.TrackResets:SetPoint("TOPLEFT", mfpanel.TrackDeaths, "TOPLEFT", 0, -25)
mfpanel.TrackResets:SetScript("OnClick", function(self) SetTrackFlag("resets", self:GetChecked()) end)

mfpanel.TrackConsumes = CreateCheckButton("FarmLogOptions_TrackConsumes", mfpanel, L["Consumes Used"])
mfpanel.TrackConsumes:SetPoint("TOPLEFT", mfpanel.TrackResets, "TOPLEFT", 0, -25)
mfpanel.TrackConsumes:SetScript("OnClick", function(self) SetTrackFlag("consumes", self:GetChecked(), true) end)

mfpanel.TrackMoney = CreateCheckButton("FarmLogOptions_TrackMoney", mfpanel, L["Money Gained"])
mfpanel.TrackMoney:SetPoint("TOPLEFT", mfpanel.TrackConsumes, "TOPLEFT", 0, -25)
mfpanel.TrackMoney:SetScript("OnClick", function(self) SetTrackFlag("money", self:GetChecked()) end)


----------------------------------------------
-- PvP
----------------------------------------------
mfpanel.AppearanceCategoryTitle = mfpanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
mfpanel.AppearanceCategoryTitle:SetFont(font, 16)
mfpanel.AppearanceCategoryTitle:SetText(L["PvP"])
mfpanel.AppearanceCategoryTitle:SetPoint("TOPLEFT", mfpanel.TrackMoney, "BOTTOMLEFT", 0, -20)

mfpanel.ShowHonorPercentOnTooltip = CreateCheckButton("FarmLogOptions_ShowHonorPercentOnTooltip", mfpanel, L["showHonorPercentOnTooltip"])
mfpanel.ShowHonorPercentOnTooltip:SetPoint("TOPLEFT", mfpanel.AppearanceCategoryTitle, "TOPLEFT", 0, -25)
mfpanel.ShowHonorPercentOnTooltip:SetScript("OnClick", function(self) FLogGlobalVars.showHonorPercentOnTooltip = self:GetChecked() end)

mfpanel.ShowHonorFrenzyCounter = CreateCheckButton("FarmLogOptions_ShowHonorFrenzy", mfpanel, L["showHonorFrenzyCounter"])
mfpanel.ShowHonorFrenzyCounter:SetPoint("TOPLEFT", mfpanel.ShowHonorPercentOnTooltip, "TOPLEFT", 0, -25)
mfpanel.ShowHonorFrenzyCounter:SetScript("OnClick", function(self) FLogGlobalVars.showHonorFrenzyCounter = self:GetChecked() end)

mfpanel.HonorDRinBGs = CreateCheckButton("FarmLogOptions_HonorDRinBGs", mfpanel, L["honorDRinBGs"])
mfpanel.HonorDRinBGs:SetPoint("TOPLEFT", mfpanel.ShowHonorFrenzyCounter, "TOPLEFT", 0, -25)
mfpanel.HonorDRinBGs:SetScript("OnClick", function(self) FLogGlobalVars.honorDRinBGs = self:GetChecked() end)

mfpanel.AutoResumeBGs = CreateCheckButton("FarmLogOptions_AutoResumeBGs", mfpanel, L["autoResumeBGs"])
mfpanel.AutoResumeBGs:SetPoint("TOPLEFT", mfpanel.HonorDRinBGs, "TOPLEFT", 0, -25)
mfpanel.AutoResumeBGs:SetScript("OnClick", function(self) FLogGlobalVars.autoResumeBGs = self:GetChecked() end)

mfpanel.MoveHonorFrenzyButton = CreateFrame("Button", "FarmLogOptions_MoveHonorFrenzyButton", mfpanel, "FarmLogPanelButtonTemplate")
mfpanel.MoveHonorFrenzyButton:SetPoint("TOPLEFT", mfpanel.AutoResumeBGs, "BOTTOMLEFT", -0, -5)
mfpanel.MoveHonorFrenzyButton:SetWidth(200)
mfpanel.MoveHonorFrenzyButton:SetText(L["Move Honor Frenzy Frame"])
mfpanel.MoveHonorFrenzyButton:SetScript("OnClick", function(self) FarmLog_HonorFrenzyMeter:Add(100, true) end)


----------------------------------------------
-- Appearance
----------------------------------------------
mfpanel.AppearanceCategoryTitle = mfpanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
mfpanel.AppearanceCategoryTitle:SetFont(font, 16)
mfpanel.AppearanceCategoryTitle:SetText(L["Appearance"])
mfpanel.AppearanceCategoryTitle:SetPoint("TOPLEFT", mfpanel.MoveHonorFrenzyButton, "BOTTOMLEFT", 0, -20)

mfpanel.ResetMinimapPositionButton = CreateFrame("Button", "FarmLogOptions_ResetMinimapPositionButton", mfpanel, "FarmLogPanelButtonTemplate")
mfpanel.ResetMinimapPositionButton:SetPoint("TOPLEFT", mfpanel.AppearanceCategoryTitle, "BOTTOMLEFT", -0, -10)
mfpanel.ResetMinimapPositionButton:SetWidth(200)
mfpanel.ResetMinimapPositionButton:SetText(L["Reset Minimap Icon Position"])
mfpanel.ResetMinimapPositionButton:SetScript("OnClick", function(self) FarmLog_MinimapButton:ResetPosition() end)

mfpanel.ResetLootWindowPositionButton = CreateFrame("Button", "FarmLogOptions_ResetLootWindowPositionButton", mfpanel, "FarmLogPanelButtonTemplate")
mfpanel.ResetLootWindowPositionButton:SetPoint("TOPLEFT", mfpanel.ResetMinimapPositionButton, "TOPRIGHT", 10, 0)
mfpanel.ResetLootWindowPositionButton:SetWidth(200)
mfpanel.ResetLootWindowPositionButton:SetText(L["Reset Loot Window Position"])
mfpanel.ResetLootWindowPositionButton:SetScript("OnClick", function(self) FarmLog_MainWindow:ResetPosition() end)

mfpanel.ResetHUDPositionButton = CreateFrame("Button", "FarmLogOptions_ResetHUDPositionButton", mfpanel, "FarmLogPanelButtonTemplate")
mfpanel.ResetHUDPositionButton:SetPoint("TOPLEFT", mfpanel.ResetMinimapPositionButton, "BOTTOMLEFT", 0, -5)
mfpanel.ResetHUDPositionButton:SetWidth(200)
mfpanel.ResetHUDPositionButton:SetText(L["Reset HUD Position"])
mfpanel.ResetHUDPositionButton:SetScript("OnClick", function(self) FarmLog_HUD:ResetPosition() end)

mfpanel.ResetFontsButton = CreateFrame("Button", "FarmLogOptions_ResetFontButton", mfpanel, "FarmLogPanelButtonTemplate")
mfpanel.ResetFontsButton:SetPoint("TOPLEFT", mfpanel.ResetLootWindowPositionButton, "BOTTOMLEFT", 0, -5)
mfpanel.ResetFontsButton:SetWidth(200)
mfpanel.ResetFontsButton:SetText(L["Reset Fonts"])
mfpanel.ResetFontsButton:SetScript("OnClick", function(self) FarmLog_MainWindow:ResetFont() end)


----------------------------------------------
-- Init
----------------------------------------------

function InterfacePanel:AddonLoaded()
	InterfacePanel.MainFrame.AutoSwitchInstances:SetChecked(FLogGlobalVars.autoSwitchInstances)
	InterfacePanel.MainFrame.ResumeSessionOnSwitch:SetChecked(FLogGlobalVars.resumeSessionOnSwitch)
	InterfacePanel.MainFrame.DismissLootWindowOnEsc:SetChecked(FLogGlobalVars.dismissLootWindowOnEsc)
	InterfacePanel.MainFrame.ShowBlackLotusTimer:SetChecked(FLogGlobalVars.showBlackLotusTimer)
	InterfacePanel.MainFrame.ShowHonorPercentOnTooltip:SetChecked(FLogGlobalVars.showHonorPercentOnTooltip)
	InterfacePanel.MainFrame.ShowHonorFrenzyCounter:SetChecked(FLogGlobalVars.showHonorFrenzyCounter)
	InterfacePanel.MainFrame.PauseOnLogin:SetChecked(FLogGlobalVars.pauseOnLogin)
	InterfacePanel.MainFrame.TrackPartyLoot:SetChecked(FLogGlobalVars.trackPartyLoot)
	InterfacePanel.MainFrame.HonorDRinBGs:SetChecked(FLogGlobalVars.honorDRinBGs)
	InterfacePanel.MainFrame.AutoResumeBGs:SetChecked(FLogGlobalVars.autoResumeBGs)

	InterfacePanel.MainFrame.TrackLoot:SetChecked(FLogGlobalVars.track.drops)
	InterfacePanel.MainFrame.TrackKills:SetChecked(FLogGlobalVars.track.kills)
	InterfacePanel.MainFrame.TrackHonor:SetChecked(FLogGlobalVars.track.honor)
	InterfacePanel.MainFrame.TrackHKs:SetChecked(FLogGlobalVars.track.hks)
	InterfacePanel.MainFrame.TrackDKs:SetChecked(FLogGlobalVars.track.dks)
	InterfacePanel.MainFrame.TrackRanks:SetChecked(FLogGlobalVars.track.ranks)
	InterfacePanel.MainFrame.TrackConsumes:SetChecked(FLogGlobalVars.track.consumes)
	InterfacePanel.MainFrame.TrackMoney:SetChecked(FLogGlobalVars.track.money)
	InterfacePanel.MainFrame.TrackXP:SetChecked(FLogGlobalVars.track.xp)
	InterfacePanel.MainFrame.TrackSkill:SetChecked(FLogGlobalVars.track.skill)
	InterfacePanel.MainFrame.TrackRep:SetChecked(FLogGlobalVars.track.rep)
	InterfacePanel.MainFrame.TrackDeaths:SetChecked(FLogGlobalVars.track.deaths)
	InterfacePanel.MainFrame.TrackResets:SetChecked(FLogGlobalVars.track.resets)

	UIDropDownMenu_SetText(InterfacePanel.MainFrame.AHMinQualityDropdown, L["ah-quality-"..FLogGlobalVars.ahMinQuality])
	UIDropDownMenu_SetText(InterfacePanel.MainFrame.TSMPriceSourceDropdown, TSM_PRICE_SOURCES["tsm-price-source-"..FLogGlobalVars.tsmPriceSource])
end 