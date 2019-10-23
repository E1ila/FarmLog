local VERSION = "1.8.3"
local VERSION_INT = 1.0803
local APPNAME = "FarmLog"
local CREDITS = "by |cff40C7EBKof|r @ |cffff2222Shazzrah|r"

FarmLog_ScrollRows = {}

FLogGlobalVars = {
	["debug"] = false,
	["ahPrice"] = {},
	["ignoredItems"] = {},
	["autoSwitchInstances"] = true,
	["reportTo"] = {},
	["ver"] = VERSION,
}

FLogVars = {
	["enabled"] = false,
	["sessions"] = {},
	["currentSession"] = "default",
	["inInstance"] = false,
	["lockFrames"] = false,
	["lockMinimapButton"] = false,
	["frameRect"] = {
		["width"] = 250,
		["height"] = 200,
		["point"] = "CENTER",
		["x"] = 0,
		["y"] = 0,
	},
	["minimapButtonPosition"] = {
		["point"] = "TOPRIGHT",
		["x"] = -165,
		["y"] = -127,
	},
	["enableMinimapButton"] = true, 
	["itemTooltip"] = true,
	["ver"] = VERSION,
}

local editName = "";
local editItem = "";
local editIdx = -1;
local L = FarmLog_BuildLocalization()

local showingMinimapTip = false
local visibleRows = 0
local sessionListMode = false
local gphNeedsUpdate = false 
local sessionStartTime = nil 
local lastMobLoot = {}
local lastUnknownLoot = {}
local lastUnknownLootTime = 0
local skillName = nil 
local skillNameTime = nil 
local lastUpdate = 0
local lastGphUpdate = 0
local goldPerHour = 0

local UNKNOWN_MOBNAME = L["Unknown"]
local DROP_META_INDEX_COUNT =  1
local LOOT_AUTOFIX_TIMEOUT_SEC = 1

local TEXT_COLOR = {
	["xp"] = "6a78f9",
	["skill"] = "4e62f8",
	["rep"] = "7d87f9",
	["mob"] = "ff000b",
	["money"] = "fffb49",
	["honor"] = "e1c73b",
	["gathering"] = "4cb4ff",
	["unknown"] = "eeeeee",
}

TEXT_COLOR[L["Skinning"]] = TEXT_COLOR["gathering"]
TEXT_COLOR[L["Herbalism"]] = TEXT_COLOR["gathering"]
TEXT_COLOR[L["Mining"]] = TEXT_COLOR["gathering"]
TEXT_COLOR[UNKNOWN_MOBNAME] = TEXT_COLOR["unknown"]

local TITLE_COLOR = "|cff4CB4ff"
local SPELL_HERBING = 2366
local SPELL_MINING = 2575
local SPELL_FISHING = 7620
local SPELL_SKINNING = {
	["10768"] = 1,
	["8617"] = 1,
	["8618"] = 1,
	["8613"] = 1,
}
local SKILL_LOOTWINDOW_OPEN_TIMEOUT = 8 -- trade skill takes 5 sec to cast, after 8 discard it

local function out(text)
	print(" |cffff8800<|cffffbb00FarmLog|cffff8800>|r "..text)
end 

local function debug(text)
	if FLogGlobalVars.debug then 
		out(text)
	end 
end 

local function tobool(arg1)
	return arg1 == 1 or arg1 == true
end

local function secondsToClock(seconds)
	local seconds = tonumber(seconds)

	if not seconds or  seconds <= 0 then
		return "00:00:00";
	else
		hours = string.format("%02.f", math.floor(seconds/3600));
		mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
		secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
		return hours..":"..mins..":"..secs
	end
end

local function GetShortCoinTextureString(money)
	if not money or tostring(money) == "nan" or tostring(money) == "inf" or money == 0 then return "--" end 
	-- out("money = "..tostring(money))
	if money > 100000 then 
		money = math.floor(money / 10000) * 10000
	elseif money > 10000 then 
		money = math.floor(money / 100) * 100
	end 
	return GetCoinTextureString(money, 12)
end 

local function SortByStringKey(db)
	local database = {};
	for name, _ in pairs(db) do	
		local i = 1
		local n = #database + 1;
		while i <= n do			
			if i == n then
				tinsert(database, name);
			elseif name <= database[i] then
				tinsert(database, i, name);					
				i = n;			
			end
			i = i + 1;
		end
	end
	return database;
end

local function SortByLinkKey(db)
	local database = {};
	for itemLink, _ in pairs(db) do	
		local name1, _, _, _, _, _, _, _, _, _, _ = GetItemInfo(itemLink);
		if name1 then
			local i = 1
			local n = #database + 1;
			while i <= n do			
				if i == n then
					tinsert(database, itemLink);
				else
					local name2, _, _, _, _, _, _, _, _, _, _ = GetItemInfo(database[i]);					
					if name2 then
						if name1 <= name2 then
							tinsert(database, i, itemLink);					
							i = n;
						end
					end
				end
				i = i + 1;
			end
		end
	end
	return database;
end

local function normalizeLink(link)
	-- remove player level from item link
	local p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17 = _G.string.split(":", link)
	return p1..":"..p2..":"..p3..":"..p4..":"..p5..":"..p6..":"..p7..":"..p8..":"..p9..":".."_"..":"..p11..":"..p12..":"..p13..":"..p14..":"..p15..":"..p16..":"..p17
end 

-- Data migration ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local function migrateItemLinkTable(t) 
	local fixed = {}
	for itemLink, value in pairs(t) do
		fixed[normalizeLink(itemLink)] = value
	end 
	return fixed
end 

function FarmLog:Migrate() 
	-- migration
	if FLogSVTotalSeconds and FLogSVTotalSeconds > 0 then 
		-- migrate 1 session into multi session DB
		FLogVars.sessions[FLogVars.currentSession] = {
			["drops"] = FLogSVDrops,
			["kills"] = FLogSVKills,
			["skill"] = FLogSVSkill,
			["rep"] = FLogSVRep,
			["gold"] = FLogSVGold,
			["vendor"] = FLogSVVendor,
			["ah"] = FLogSVAH,
			["xp"] = FLogSVXP,
			["honor"] = FLogSVHonor,
			["seconds"] = FLogSVTotalSeconds,
		}
		FLogSVTotalSeconds = nil 
		out("Migrated previous session into session 'default'.")
	elseif not FLogVars.sessions[FLogVars.currentSession] then 
		self:ResetSessionVars()
	end 

	if FLogSVAHValue then 
		FLogGlobalVars.autoSwitchInstances = FLogSVAutoSwitchOnInstances
		FLogGlobalVars.debug = FLogSVDebugMode
		FLogGlobalVars.ahPrice = FLogSVAHValue
		FLogGlobalVars.reportTo = FLogSVOptionReportTo
		FLogSVAHValue = nil 
		out("Migrated old global vars into new database format.")
	end 

	if FLogSVSessions then 
		FLogVars.sessions = FLogSVSessions
		FLogVars.enabled = FLogSVEnabled
		FLogVars.currentSession = FLogSVCurrentSession
		FLogVars.instanceName = FLogSVLastInstance
		FLogVars.inInstance = FLogSVInInstance

		FLogVars.lockFrames = FLogSVLockFrames
		FLogVars.lockMinimapButton = FLogSVLockMinimapButton
		FLogVars.frameRect = FLogSVFrame
		FLogVars.minimapButtonPosition = FLogSVMinimapButtonPosition
		FLogVars.enableMinimapButton = FLogSVEnableMinimapButton
		FLogVars.itemTooltip = FLogSVTooltip
		FLogSVSessions = nil 
		out("Migrated old character vars into new database format.")
	end 

	if FLogVars["minimapButtonPosision"] then 
		FLogVars.minimapButtonPosition = FLogVars["minimapButtonPosision"]
		FLogVars["minimapButtonPosision"] = nil 
	end 

	if FLogGlobalVars.itemQuality then FLogGlobalVars.itemQuality = nil end 
	if not FLogGlobalVars.ignoredItems then FLogGlobalVars.ignoredItems = {} end 

	if FLogGlobalVars.version then 
		out("Fixing AH prices and ignored items database links")
		FLogGlobalVars.ahPrice = migrateItemLinkTable(FLogGlobalVars.ahPrice)
		FLogGlobalVars.ignoredItems = migrateItemLinkTable(FLogGlobalVars.ignoredItems)
		FLogGlobalVars.version = nil 
	end 

	if FLogVars.version then 
		out("Migrating drops database structure and links")
		for sessionName, session in pairs(FLogVars.sessions) do 
			for mobName, items in pairs(session.drops) do 
				local fixedItems = {}
				for itemLink, meta in pairs(items) do 
					local fixedLink = normalizeLink(itemLink)
					if fixedItems[fixedLink] then 
						fixedItems[fixedLink] = fixedItems[fixedLink][DROP_META_INDEX_COUNT] + meta[1][DROP_META_INDEX_COUNT]
					else 
						fixedItems[fixedLink] = {meta[1][DROP_META_INDEX_COUNT]}
					end 
				end 
				session.drops[mobName] = fixedItems
			end 
		end 
		FLogVars.version = nil 
	end 

	FLogVars.ver = VERSION_INT
	FLogGlobalVars.ver = VERSION_INT
end 

-- Session management ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local function GetSessionVar(varName, sessionName)
	return (FLogVars.sessions[sessionName or FLogVars.currentSession] or {})[varName]
end 

local function SetSessionVar(varName, value)
	FLogVars.sessions[FLogVars.currentSession][varName] = value 
end 

local function IncreaseSessionVar(varName, incValue)
	debug("|cff999999IncreaseSessionVar|r currentSession |cffff9900"..FLogVars.currentSession.."|r, varName |cffff9900"..varName.."|r, incValue |cffff9900"..tostring(incValue))
	FLogVars.sessions[FLogVars.currentSession][varName] = ((FLogVars.sessions[FLogVars.currentSession] or {})[varName] or 0) + incValue 
end 

local function IncreaseSessionDictVar(varName, entry, incValue)
	FLogVars.sessions[FLogVars.currentSession][varName][entry] = ((FLogVars.sessions[FLogVars.currentSession] or {})[varName][entry] or 0) + incValue 
end 

function FarmLog:GetCurrentSessionTime()
	local now = time()
	return GetSessionVar("seconds") + now - (sessionStartTime or now)
end 

function FarmLog:GetSessionWindowTitle()
	local text = FLogVars.currentSession or ""
	local time = self:GetCurrentSessionTime() or 0
	if time > 0 then 
		text = text .. "  --  " .. secondsToClock(time) 
	end 
	-- if goldPerHour and goldPerHour > 0 and tostring(goldPerHour) ~= "nan" tostring(goldPerHour) ~= "inf" then 
	-- 	text = text .. " / " .. GetShortCoinTextureString(goldPerHour) .. " g/h"
	-- end 
	return text
end 

function FarmLog:UpdateMainWindowTitle()
	if sessionListMode then 
		FarmLog_MainWindow_Title_Text:SetTextColor(0.3, 0.7, 1, 1)
		FarmLog_MainWindow_Title_Text:SetText(L["All Sessions"])
	else 
		if FLogVars.enabled then 
			FarmLog_MainWindow_Title_Text:SetTextColor(0, 1, 0, 1.0);
		else 
			FarmLog_MainWindow_Title_Text:SetTextColor(1, 1, 0, 1.0);
			FarmLog_MainWindow_Title_Text:SetText(self:GetSessionWindowTitle())
		end 
	end 
end 

function FarmLog:ResumeSession() 
	sessionStartTime = time()

	FLogVars.enabled = true  
	FarmLog_MinimapButtonIcon:SetTexture("Interface\\AddOns\\FarmLog\\FarmLogIconON");
	self:UpdateMainWindowTitle()
end 

function FarmLog:PauseSession(temporary)
	if sessionStartTime then 
		local delta = time() - sessionStartTime
		IncreaseSessionVar("seconds", delta)
		sessionStartTime = nil
	end 

	if not temporary then 
		FLogVars.enabled = false 
		FarmLog_MinimapButtonIcon:SetTexture("Interface\\AddOns\\FarmLog\\FarmLogIconOFF");
		self:UpdateMainWindowTitle()
	end 
end 

function FarmLog:ResetSessionVars()
	FLogVars.sessions[FLogVars.currentSession] = {
		["drops"] = {},
		["kills"] = {},
		["skill"] = {},
		["rep"] = {},
		["gold"] = 0,
		["vendor"] = 0,
		["ah"] = 0,
		["xp"] = 0,
		["honor"] = 0,
		["seconds"] = 0,
	}
end 

function FarmLog:StartSession(sessionName, dontPause, dontResume) 
	if FLogVars.enabled then 
		gphNeedsUpdate = true 
		if not dontPause then 
			self:PauseSession(true) 
		end 
	end 

	sessionListMode = false 
	FLogVars.currentSession = sessionName
	if not FLogVars.sessions[FLogVars.currentSession] then 
		self:ResetSessionVars()
	end 
	if not dontResume then 
		self:ResumeSession()
	else 
		self:UpdateMainWindowTitle() -- done by resume, update text color
	end 
	self:RefreshMainWindow()
end 

function FarmLog:DeleteSession(name) 
	FLogVars.sessions[name] = nil 
	if FLogVars.currentSession == name then 
		self:StartSession("default", true, true)
		sessionListMode = true 
		self:RefreshMainWindow()
	end 
	if FLogVars.currentSession == name and name == "default" then 
		out("Reset the |cff99ff00"..name.."|r session")
	else 
		out("Deleted session |cff99ff00"..name)
	end 
end 

function FarmLog:ResetSession()
	self:PauseSession(true)
	self:ResetSessionVars()
	if FLogVars.enabled then 
		self:ResumeSession()
	end 
	out("Reset session |cff99ff00"..FLogVars.currentSession)
	gphNeedsUpdate = true 
	self:RefreshMainWindow()
end

function FarmLog:InitSession()
	if FLogVars.enabled then 
		self:ResumeSession()
	else 
		self:PauseSession()
	end 
	gphNeedsUpdate = true
	self:RefreshMainWindow()
end 

function FarmLog:ToggleLogging() 
	if FLogVars.enabled then 
		self:PauseSession()
		out("Farm session |cff99ff00"..FLogVars.currentSession.."|r paused|r")
	else 
		self:StartSession(FLogVars.currentSession or "default")
		if GetSessionVar("seconds") == 0 then 
			out("Farm session |cff99ff00"..FLogVars.currentSession.."|r started")
		else 
			out("Farm session |cff99ff00"..FLogVars.currentSession.."|r resumed")
		end 	
	end 
end 


-- Main Window UI ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function FarmLog:ToggleWindow()
	if IsShiftKeyDown() then 
		FarmLog_MainWindow:ResetPosition()
		FarmLog_MainWindow:Show()
	else 
		if FarmLog_MainWindow:IsShown() then
			FarmLog_MainWindow:Hide()
		else
			FarmLog_MainWindow:LoadPosition()
			FarmLog_MainWindow:Show()
		end
	end 
end

function FarmLog:PlaceLinkInChatEditBox(itemLink)
	-- Copy itemLink into ChatFrame
	local chatFrame = SELECTED_DOCK_FRAME
	local editbox = chatFrame.editBox
	if editbox then
		if editbox:HasFocus() then
			editbox:SetText(editbox:GetText()..itemLink);
		else
			editbox:SetFocus(true);
			editbox:SetText(itemLink);
		end
	end
end

function FarmLog:GetOnLogItemClick(itemLink) 
	return function(self, button)
		if IsShiftKeyDown() then
			FarmLog:PlaceLinkInChatEditBox(itemLink) -- paste in chat box
		elseif IsControlKeyDown() then
			DressUpItemLink(itemLink) -- preview
		end
	end 
end

function FarmLog:GetOnLogSessionItemClick(sessionName) 
	return function(self, button)
		if button == "RightButton" then 
			FarmLog_QuestionDialog_Yes:SetScript("OnClick", function() 
				FarmLog:DeleteSession(sessionName)
				FarmLog:RefreshMainWindow()
				FarmLog_QuestionDialog:Hide()
			end)
			FarmLog_QuestionDialog_Title_Text:SetText(L["deletesession-title"])
			FarmLog_QuestionDialog_Question:SetText(L["deletesession-question"])
			FarmLog_QuestionDialog:Show()
		else 
			if IsAltKeyDown() then
				-- edit?
			else 
				sessionListMode = false 
				out("Farm session |cff99ff00"..sessionName.."|r resumed")
				FarmLog:StartSession(sessionName, false, true)
			end
		end 
	end 
end

local function CreateRow_Text(existingRow, text)
	local row = existingRow or {};
	local previousType = row.type
	row.type = "text"

	if not row.root then 
		row.root = CreateFrame("FRAME", nil, FarmLog_MainWindow_Scroll_Content);		
		row.root:SetWidth(FarmLog_MainWindow_Scroll_Content:GetWidth() - 20);
		row.root:SetHeight(15);
		if #FarmLog_ScrollRows == 0 then 
			row.root:SetPoint("TOPLEFT", FarmLog_MainWindow_Scroll_Content, "TOPLEFT");
		else 
			row.root:SetPoint("TOPLEFT", FarmLog_ScrollRows[#FarmLog_ScrollRows].root, "BOTTOMLEFT");
		end 
	end 
	row.root:SetScript("OnEnter", nil);
	row.root:SetScript("OnLeave", nil);
	row.root:SetScript("OnMouseUp", nil);	
	row.root:Show();
	
	if not row.label then 
		row.label = row.root:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
		row.label:SetTextColor(0.8, 0.8, 0.8, 1)
		row.label:SetPoint("LEFT")
		row.label:SetFont("Fonts\\FRIZQT__.TTF", 12)
	end 
	row.label:SetText(text);
	row.label:Show()

	if not existingRow then 
		tinsert(FarmLog_ScrollRows, row);
	end 
	return row
end

local function AddItem_Text(text, quantity, color) 
	visibleRows = visibleRows + 1
	text = "|cff"..(color or "dddddd")..text.."|r"
	if quantity and quantity > 1 then 
		text = text.." x"..tostring(quantity)
	end 
	return CreateRow_Text(FarmLog_ScrollRows[visibleRows], text)
end 

local function HideRowsBeyond(j)
	local n = #FarmLog_ScrollRows;
	if j <= n then 
		for i = j, n do
			FarmLog_ScrollRows[i].root:Hide()
		end
	end 
end

local function SetItemTooltip(row, itemLink, text)
	row.root:SetScript("OnEnter", function(self)
		self:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background"});
		self:SetBackdropColor(0.8,0.8,0.8,0.6);
		if FLogVars.itemTooltip then
			GameTooltip:SetOwner(self, "ANCHOR_LEFT");
			if itemLink then 
				GameTooltip:SetHyperlink(itemLink);
			elseif text then 
				GameTooltip:SetText(text);
			end 					
			GameTooltip:Show();
		end
	end);
	row.root:SetScript("OnLeave", function(self)
		if FLogVars.itemTooltip then
			GameTooltip_Hide();
		end
		self:SetBackdrop(nil);
	end);		
end 

local function SetItemActions(row, callback) 
	row.root:SetScript("OnMouseUp", function(self, ...)
		self:SetBackdrop(nil);
		callback(self, ...)
	end);
end 

function FarmLog:AddSessionYieldItems() 
	if goldPerHour and goldPerHour > 0 and tostring(goldPerHour) ~= "nan" and tostring(goldPerHour) ~= "inf" then AddItem_Text(L["Gold / Hour"] .. " " .. GetShortCoinTextureString(goldPerHour)) end 
	if GetSessionVar("ah") > 0 then AddItem_Text(L["Auction House"].." "..GetShortCoinTextureString(GetSessionVar("ah")), nil, TEXT_COLOR["money"]) end 
	if GetSessionVar("gold") > 0 then AddItem_Text(L["Money"].." "..GetShortCoinTextureString(GetSessionVar("gold")), nil, TEXT_COLOR["money"]) end 
	if GetSessionVar("vendor") > 0 then AddItem_Text(L["Vendor"].." "..GetShortCoinTextureString(GetSessionVar("vendor")), nil, TEXT_COLOR["money"]) end 
	if GetSessionVar("xp") > 0 then AddItem_Text(L["XP"].." "..GetSessionVar("xp"), nil, TEXT_COLOR["xp"]) end 
	for faction, rep in pairs(GetSessionVar("rep")) do AddItem_Text(rep.." "..faction.." "..L["reputation"], nil, TEXT_COLOR["rep"]) end 
	for skillName, levels in pairs(GetSessionVar("skill")) do AddItem_Text("+"..levels.." "..skillName, nil, TEXT_COLOR["skill"]) end 

	local sessionKills = GetSessionVar("kills")
	local sortedNames = SortByStringKey(sessionKills);
	-- add missing mobNames like Herbalism / Mining / Fishing
	local sessionDrops = GetSessionVar("drops")
	for name, _ in pairs(sessionDrops) do 
		if not sessionKills[name] then 
			tinsert(sortedNames, 1, name)
		end 
	end 
	for _, mobName in ipairs(sortedNames) do	
		local sortedItemLinks = SortByLinkKey(sessionDrops[mobName] or {});	
		local section = mobName 
		AddItem_Text(section, sessionKills[mobName], TEXT_COLOR["mob"])
		for _, itemLink in ipairs(sortedItemLinks) do			
			if not FLogGlobalVars.ignoredItems[itemLink] then 
				local count = sessionDrops[mobName][itemLink][DROP_META_INDEX_COUNT];
				local itemText = "    "..itemLink
				local row = AddItem_Text(itemText, count)
				SetItemTooltip(row, itemLink)
				SetItemActions(row, self:GetOnLogItemClick(itemLink))
				row.root:Show();
			end 
		end		
	end
end 

function FarmLog:AddSessionListItems() 
	for name, session in pairs(FLogVars.sessions) do 
		local gph = (GetSessionVar("ah", name) + GetSessionVar("vendor", name) + GetSessionVar("gold", name)) / (GetSessionVar("seconds", name) / 3600)
		local text = name
		if gph and gph > 0 and tostring(gph) ~= "nan" then 
			text = text .. " " .. GetShortCoinTextureString(gph) .. " " .. L["G/H"]
		end 
		local row = AddItem_Text(text)
		SetItemTooltip(row)
		SetItemActions(row, self:GetOnLogSessionItemClick(name))
	end 
end 

function FarmLog:RefreshMainWindow()
	visibleRows = 0

	if sessionListMode then 
		self:AddSessionListItems()
		FarmLog_MainWindow_ResetButton:Disable()
	else 
		self:AddSessionYieldItems()
		if #FarmLog_ScrollRows > 0 then
			FarmLog_MainWindow_ResetButton:Enable()
		else
			FarmLog_MainWindow_ResetButton:Disable()
		end	
	end 
	HideRowsBeyond(visibleRows + 1);	
	FarmLog_MainWindow_SessionsButton:Enable()
end

function FarmLog:RecalcTotals()
	local sessionVendor = 0
	local sessionAH = 0
	local sessionDrops = GetSessionVar("drops")
	for mobName, drops in pairs(sessionDrops) do	
		for itemLink, meta in pairs(drops) do 
			if not FLogGlobalVars.ignoredItems[itemLink] then 
				local _, _, _, _, _, _, _, _, _, _, vendorPrice = GetItemInfo(itemLink);
				local value = FLogGlobalVars.ahPrice[itemLink]
				if value and value > 0 then 
					sessionAH = sessionAH + value * meta[DROP_META_INDEX_COUNT]
				else
					sessionVendor = sessionVendor + (vendorPrice or 0) * meta[DROP_META_INDEX_COUNT]
				end 
			end 
		end 
	end 
	SetSessionVar("vendor", sessionVendor)
	SetSessionVar("ah", sessionAH)
	gphNeedsUpdate = true 
	self:RefreshMainWindow()
end 


-- EVENTS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Spell cast 

function FarmLog:OnSpellCastEvent(unit, target, guid, spellId)
	if spellId == SPELL_HERBING then 
		skillName = L["Herbalism"]
		skillNameTime = time()
	elseif spellId == SPELL_MINING then 
		skillName = L["Mining"]
		skillNameTime = time()
	elseif spellId == SPELL_FISHING then 
		skillName = L["Fishing"]
		skillNameTime = time()
	elseif SPELL_SKINNING[tostring(spellId)] == 1 then 
		skillName = L["Skinning"]
		skillNameTime = time()
	else 
		skillName = nil 
	end 
end 

-- Honor event

function FarmLog:OnCombatHonorEvent(text, playerName, languageName, channelName, playerName2, specialFlags)
	-- debug("FarmLog:OnCombatHonorEvent - text:"..text.." playerName:"..playerName.." languageName:"..languageName.." channelName:"..channelName.." playerName2:"..playerName2.." specialFlags:"..specialFlags)
end 

-- Trade skills event

local SkillGainStrings = {
	_G.ERR_SKILL_UP_SI,
}

function FarmLog:ParseSkillEvent(chatmsg)
	for _, st in ipairs(SkillGainStrings) do
		local skillName, level = FLogDeformat(chatmsg, st)
		if level then
			return skillName, level
		end
	end
end

function FarmLog:OnSkillsEvent(text)
	-- debug("FarmLog:OnSkillsEvent - text:"..text)
	local skillName, level = self:ParseSkillEvent(text)
	if level then 
		IncreaseSessionDictVar("skill", skillName, 1)
		self:RefreshMainWindow()
	end 
end 

-- XP events

local XPGainStrings = {
	_G.COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED,
	_G.COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED_GROUP,
	_G.COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED_RAID,
}

local XPGainMobKillStrings = {
	_G.COMBATLOG_XPGAIN_EXHAUSTION1,
	_G.COMBATLOG_XPGAIN_EXHAUSTION2,
	_G.COMBATLOG_XPGAIN_EXHAUSTION4,
	_G.COMBATLOG_XPGAIN_EXHAUSTION5,
	_G.COMBATLOG_XPGAIN_FIRSTPERSON,
	_G.COMBATLOG_XPGAIN_FIRSTPERSON_GROUP,
	_G.COMBATLOG_XPGAIN_FIRSTPERSON_RAID,
}

function FarmLog:ParseXPEvent(chatmsg)
	for _, st in ipairs(XPGainMobKillStrings) do
		local mobName, amount = FLogDeformat(chatmsg, st)
		if amount then
			return amount
		end
	end
	for _, st in ipairs(XPGainStrings) do
		local amount = FLogDeformat(chatmsg, st)
		if amount then
			return amount
		end
	end
end

function FarmLog:OnCombatXPEvent(text)
	local xp = self:ParseXPEvent(text)
	-- debug("FarmLog:OnCombatXPEvent - text:"..text.." playerName:"..playerName.." languageName:"..languageName.." channelName:"..channelName.." playerName2:"..playerName2.." specialFlags:"..specialFlags)
	IncreaseSessionVar("xp", xp)
	self:RefreshMainWindow()
end 

-- Faction change 

local FactionGainStrings = {
	_G.FACTION_STANDING_INCREASED,
	_G.FACTION_STANDING_INCREASED_BONUS,
}

function FarmLog:ParseRepEvent(chatmsg)
	for _, st in ipairs(FactionGainStrings) do
		local faction, amount = FLogDeformat(chatmsg, st)
		if amount then
			return faction, amount
		end
	end
end

function FarmLog:OnCombatFactionChange(text) 
	-- debug("FarmLog:OnCombatFactionChange - text:"..text)
	local faction, rep = self:ParseRepEvent(text)
	if rep then 
		IncreaseSessionDictVar("rep", faction, rep)
		self:RefreshMainWindow()
	end 
end 

-- Combat log event

function FarmLog:OnCombatLogEvent()
	local eventInfo = {CombatLogGetCurrentEventInfo()}
	local eventName = eventInfo[2]
	if eventName == "PARTY_KILL" then 
		local mobName = eventInfo[9]
		local sessionKills = GetSessionVar("kills")
		sessionKills[mobName] = (sessionKills[mobName] or 0) + 1
		-- debug("Player "..eventInfo[5].." killed "..eventInfo[9].." x "..tostring(sessionKills[mobName]))
		self:RefreshMainWindow()
	end 
end 

-- Loot window event

function FarmLog:OnLootOpened(autoLoot)
	local lootCount = GetNumLootItems()
	local mobName = nil 
	if not mobName and IsFishingLoot() then mobName = L["Fishing"] end 
	if not mobName and skillName then mobName = skillName end 
	if not mobName then mobName = UnitName("target") end 
	debug("|cff999999FarmLog:OnLootOpened|r mobName |cffff9900"..tostring(mobName))
	lastMobLoot = {}
	skillName = nil 
	skillNameTime = nil 
	local now = time()
	for i = 1, lootCount do 
		local link = GetLootSlotLink(i)
		if link then 
			debug("|cff999999FarmLog:OnLootOpened|r link |cffff9900"..link)
			lastMobLoot[link] = mobName
			if mobName and lastUnknownLoot[link] and now - lastUnknownLootTime < LOOT_AUTOFIX_TIMEOUT_SEC then 
				-- sometimes when "Fast auto loot" is enabled, OnLootEvent will be called before OnLootOpened
				-- so reattribute this loot now that we know from which mob it dropped
				debug("|cff999999FarmLog:OnLootOpened|r reattributing loot")
				local drops = GetSessionVar("drops")
				drops[UNKNOWN_MOBNAME][DROP_META_INDEX_COUNT] = drops[UNKNOWN_MOBNAME][DROP_META_INDEX_COUNT] - 1
				if drops[UNKNOWN_MOBNAME][DROP_META_INDEX_COUNT] == 0 then 
					drops[UNKNOWN_MOBNAME] = nil 
				end 
				local _, _, _, quality, _ = GetLootSlotInfo(slot)
				self:InsertLoot(mobName, normalizeLink(itemLink), quality or 1)
			end 
		end 
	end 
end 


-- Currency event

function FarmLog:OnCurrencyEvent(text)
	debug("|cffff9900FarmLog:OnCurrencyEvent|r "..text)
end 

-- Money event

local MoneyStrings = {
	_G.LOOT_MONEY_SPLIT,
	_G.LOOT_MONEY_SPLIT_GUILD,
	_G.YOU_LOOT_MONEY,
	_G.YOU_LOOT_MONEY_GUILD,
	_G.ERR_QUEST_REWARD_MONEY_S,
}
local GOLD_AMOUNT_inv = _G.GOLD_AMOUNT:gsub("%%d", "(%1+)")
local SILVER_AMOUNT_inv = _G.SILVER_AMOUNT:gsub("%%d", "(%1+)")
local COPPER_AMOUNT_inv = _G.COPPER_AMOUNT:gsub("%%d", "(%1+)")
local GOLD_AMOUNT_SYMBOL = _G.GOLD_AMOUNT_SYMBOL
local SILVER_AMOUNT_SYMBOL = _G.SILVER_AMOUNT_SYMBOL
local COPPER_AMOUNT_SYMBOL = _G.COPPER_AMOUNT_SYMBOL

local function ParseMoneyEvent(chatmsg)
	for _, moneyString in ipairs(MoneyStrings) do
		local amount = FLogDeformat(chatmsg, moneyString)
		if amount then
			local gold = chatmsg:match(GOLD_AMOUNT_inv) or 0
			local silver = chatmsg:match(SILVER_AMOUNT_inv) or 0
			local copper = chatmsg:match(COPPER_AMOUNT_inv) or 0
			return 10000 * gold + 100 * silver + copper
		end
	end
end

function FarmLog:OnMoneyEvent(text)
	local money = ParseMoneyEvent(text)
	IncreaseSessionVar("gold", money)
	self:RefreshMainWindow()
end 

-- Loot receive event

function FarmLog:InsertLoot(mobName, itemLink, count)
	if (mobName and itemLink and count) then		
		local sessionDrops = GetSessionVar("drops")
		if not sessionDrops[mobName] then		
			sessionDrops[mobName] = {}
		end 
		if sessionDrops[mobName][itemLink] then
			sessionDrops[mobName][itemLink][DROP_META_INDEX_COUNT] = sessionDrops[mobName][itemLink][DROP_META_INDEX_COUNT] + count
		else
			sessionDrops[mobName][itemLink] = {count};
		end
	end
end

local SelfLootStrings = {
	_G.LOOT_ITEM_PUSHED_SELF_MULTIPLE,
	_G.LOOT_ITEM_SELF_MULTIPLE,
	_G.LOOT_ITEM_PUSHED_SELF,
	_G.LOOT_ITEM_SELF,
}

local function ParseSelfLootEvent(chatmsg)
	for _, st in ipairs(SelfLootStrings) do
		local link, quantity = FLogDeformat(chatmsg, st)
		if quantity then 
			return link, quantity
		end 
		if link then 
			return link, 1
		end 
	end
end

function FarmLog:OnLootEvent(text)
	local now = time()
	local itemLink, quantity = ParseSelfLootEvent(text)
	if not itemLink then return end 
	local _, _, itemRarity, _, _, itemType, _, _, _, _, vendorPrice = GetItemInfo(itemLink);

	mobName = lastMobLoot[itemLink]

	if not mobName then 
		mobName = UNKNOWN_MOBNAME
		if now - lastUnknownLootTime > LOOT_AUTOFIX_TIMEOUT_SEC then lastUnknownLoot = {} end 
		lastUnknownLootTime = now 
		lastUnknownLoot[itemLink] = true 
	end 

	itemLink = normalizeLink(itemLink) -- removed player level from link

	debug("|cff999999FarmLog:OnLootEvent|r itemLink |cffff9900"..itemLink.."|r, mobName |cffff9900"..tostring(mobName))

	local inRaid = IsInRaid();
	local inParty = false;
	if GetNumGroupMembers() > 0 then
		inParty = true;
	end
	if (
		itemType ~= "Money" 
		-- and (
			-- (FLogGlobalVars.itemQuality[0] and itemRarity == 0) or
			-- (FLogGlobalVars.itemQuality[1] and itemRarity == 1) or
			-- (FLogGlobalVars.itemQuality[2] and itemRarity == 2) or
			-- (FLogGlobalVars.itemQuality[3] and itemRarity == 3) or
			-- (FLogGlobalVars.itemQuality[4] and itemRarity == 4) or
			-- (FLogGlobalVars.itemQuality[5] and itemRarity == 5) or
			-- (FLogGlobalVars.itemQuality[6] and itemRarity == 6) or 
			-- mobName == L["Herbalism"] or 
			-- mobName == L["Mining"] or 
			-- mobName == L["Fishing"] 
		-- )
		) 
	then	
		local ahValue = FLogGlobalVars.ahPrice[itemLink]
		if ahValue and ahValue > 0 then 
			IncreaseSessionVar("ah", ahValue)
		else
			IncreaseSessionVar("vendor", vendorPrice or 0) 		
		end 

		self:InsertLoot(mobName, itemLink, (quantity or 1));
		self:RefreshMainWindow();
	end
end

-- Addon Loaded

function FarmLog:OnAddonLoaded()
	out("|cffffbb00v"..tostring(VERSION).."|r "..CREDITS..", "..L["loaded-welcome"]);
	FarmLog:Migrate()	
	FarmLog_MainWindow_Title:Init()
	FarmLog_MinimapButton:Init()
	FarmLog_MainWindow:LoadPosition()
	FarmLog:InitSession()
end 

-- Entering World

function FarmLog:OnEnteringWorld() 
	local inInstance, _ = IsInInstance();
	inInstance = tobool(inInstance);
	local instanceName = GetInstanceInfo();		
	if not FLogVars.inInstance and inInstance and FLogVars.instanceName ~= instanceName then
		FLogVars.inInstance = true;
		FLogVars.instanceName = instanceName;
		if FLogGlobalVars.autoSwitchInstances then 
			self:StartSession(instanceName)
		end 
	elseif FLogVars.inInstance and inInstance == false then
		FLogVars.inInstance = false;
		if FLogGlobalVars.autoSwitchInstances then 
			self:PauseSession()
		end 
	end
	self:RefreshMainWindow();
end 

-- Instance info

function FarmLog:OnInstanceInfoEvent()
	-- local count = GetNumSavedInstances()
	-- debug("FarmLog:OnInstanceInfoEvent - GetNumSavedInstances = "..count)
	-- for i = 1, count do 
	-- 	local instanceName, instanceID, instanceReset, instanceDifficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, maxBosses, defeatedBosses = GetSavedInstanceInfo(i)
	-- 	debug("instanceName="..instanceName.." instanceID="..instanceID.." instanceReset="..tostring(instanceReset).." locked="..tostring(locked))
	-- end 
end 

-- OnEvent

function FarmLog:OnEvent(event, ...)
	if FLogVars.enabled then 
		-- debug(event)
		if event == "LOOT_OPENED" then
			self:OnLootOpened(...)			
		elseif event == "CHAT_MSG_LOOT" then
			if (... and (strfind(..., L["loot"]))) then
				self:OnLootEvent(...)		
			end	
		elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN" then 
			self:OnCombatHonorEvent(...);			
		elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then 
			self:OnCombatXPEvent(...);			
		elseif event == "CHAT_MSG_SKILL" then 
			self:OnSkillsEvent(...);			
		elseif event == "CHAT_MSG_OPENING" then 
			debug("|cffff9900CHAT_MSG_OPENING|r")
			debug(...)
		elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			self:OnCombatLogEvent(...);		
		elseif event == "CHAT_MSG_CURRENCY" then 
			self:OnCurrencyEvent(...)	
		elseif event == "CHAT_MSG_MONEY" then 
			self:OnMoneyEvent(...)	
		elseif event == "UNIT_SPELLCAST_SENT" then 
			self:OnSpellCastEvent(...)
		elseif event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then 
			self:OnCombatFactionChange(...)
		end 
	end 

	if event == "PLAYER_ENTERING_WORLD" then
		self:OnEnteringWorld(...)
	elseif event == "ADDON_LOADED" and ... == APPNAME then		
		self:OnAddonLoaded(...)
	elseif event == "PLAYER_LOGOUT" then 
		self:PauseSession(true)
	elseif event == "UPDATE_INSTANCE_INFO" then 
		self:OnInstanceInfoEvent(...)
	end
end

-- OnUpdate

function FarmLog:OnUpdate() 
	if not sessionListMode and (gphNeedsUpdate or FLogVars.enabled) then 
		local now = time()
		if now - lastUpdate >= 1 then 
			local sessionTime = self:GetCurrentSessionTime()
			FarmLog_MainWindow_Title_Text:SetText(self:GetSessionWindowTitle());
			if showingMinimapTip then 
				FarmLog_MinimapButton:UpdateTooltipText()
			end 
			lastUpdate = now 
			if gphNeedsUpdate or (now - lastGphUpdate >= 60 and sessionTime > 0) then 
				-- debug("Calculating GPH")
				goldPerHour = (GetSessionVar("ah") + GetSessionVar("vendor") + GetSessionVar("gold")) / (sessionTime / 3600)
				lastGphUpdate = now 
				gphNeedsUpdate = false 
				self:RefreshMainWindow()
			end 
		end 
	end 
	if skillNameTime then 
		local now = time()
		if now - skillNameTime >= SKILL_LOOTWINDOW_OPEN_TIMEOUT then 
			skillNameTime = nil 
			skillName = nil 
		end 
	end 
end 

-- UI ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function FarmLog_MainWindow:LoadPosition()
	self:ClearAllPoints()
	self:SetWidth(FLogVars.frameRect.width)
	self:SetHeight(FLogVars.frameRect.height)
	self:SetPoint(FLogVars.frameRect.point, FLogVars.frameRect.x, FLogVars.frameRect.y)
end

function FarmLog_MainWindow:ResetPosition()
	FLogVars.frameRect.width = 250
	FLogVars.frameRect.height = 200
	FLogVars.frameRect.x = 0
	FLogVars.frameRect.y = 0
	FLogVars.frameRect.point = "CENTER"
	self:LoadPosition()
end 

function FarmLog_MinimapButton:Init(reload) 
	FarmLog_MinimapButton:SetPoint(FLogVars.minimapButtonPosition.point, Minimap, FLogVars.minimapButtonPosition.x, FLogVars.minimapButtonPosition.y);
	if FLogVars.enableMinimapButton then
		self:Show();
	else
		self:Hide();
	end	
	if not FLogVars.lockMinimapButton and not reload then		
		self:RegisterForDrag("LeftButton");			
	end
end 

function FarmLog_MinimapButton:DragStopped() 
	local point, relativeTo, relativePoint, x, y = FarmLog_MinimapButton:GetPoint();
	FLogVars.minimapButtonPosition.point = point;													
	FLogVars.minimapButtonPosition.x = x;
	FLogVars.minimapButtonPosition.y = y;
end 

function FarmLog_MinimapButton:Clicked(button) 
	if button == "RightButton" then
		FarmLog:ToggleLogging()
	else
		FarmLog:ToggleWindow()
	end
end 

function FarmLog_MainWindow_Title:Init()
	if not FLogVars.lockFrames then		
		FarmLog_MainWindow_Title:RegisterForDrag("LeftButton");			
	end
end 

function FarmLog_MainWindow:SavePosition() 
	local point, relativeTo, relativePoint, x, y = FarmLog_MainWindow:GetPoint()
	FLogVars.frameRect.point = point
	FLogVars.frameRect.x = x
	FLogVars.frameRect.y = y
	FLogVars.frameRect.width = FarmLog_MainWindow:GetWidth()
	FLogVars.frameRect.height = FarmLog_MainWindow:GetHeight()
end 

function FarmLog_MainWindow_SessionsButton:Clicked() 
	sessionListMode = not sessionListMode 
	gphNeedsUpdate = true
	FarmLog:UpdateMainWindowTitle()
	FarmLog:RefreshMainWindow()
end 

function FarmLog_MainWindow_ResetButton:Clicked()
	FarmLog_QuestionDialog_Yes:SetScript("OnClick", function() 
		FarmLog:ResetSession()
		FarmLog_QuestionDialog:Hide()
	end)
	FarmLog_QuestionDialog_Title_Text:SetText(L["reset-title"])
	FarmLog_QuestionDialog_Question:SetText(L["reset-question"])
	FarmLog_QuestionDialog:Show()
end 

function FarmLog_MinimapButton:ShowTooltip() 
	GameTooltip:SetOwner(FarmLog_MinimapButton, "ANCHOR_BOTTOMLEFT")
	self:UpdateTooltipText()
	GameTooltip:Show()
	showingMinimapTip = true 
end 

function FarmLog_MinimapButton:UpdateTooltipText() 
	local sessionColor = "|cffffff00"
	if FLogVars.enabled then sessionColor = "|cff00ff00" end 
	local text = "|cff5CC4ff" .. APPNAME .. "|r|nSession: |cffeeeeee" .. FLogVars.currentSession .. "|r|nTime: " .. sessionColor .. secondsToClock(FarmLog:GetCurrentSessionTime()) .. "|r|nG/H: |cffeeeeee" .. GetShortCoinTextureString(goldPerHour) .. "|r|nLeft click: |cffeeeeeeopen main window|r|nRight click: |cffeeeeeepause/resume session|r"
	GameTooltip:SetText(text, nil, nil, nil, nil, true)
end 

function FarmLog_MinimapButton:HideTooltip() 
	showingMinimapTip = false
	GameTooltip:Hide()
end 

-- Slash Interface ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SLASH_LH1 = "/farmlog";
SLASH_LH2 = "/fl";
SlashCmdList.LH = function(msg)
	local _, _, cmd, arg1 = string.find(msg, "([%w]+)%s*(.*)$");
	if not cmd then
		FarmLog:ToggleLogging()
	else 
		cmd = string.upper(cmd)
		if  "SHOW" == cmd or "S" == cmd then
			FarmLog:ToggleWindow()
		elseif "DEBUG" == cmd then 
			FLogGlobalVars.debug = not FLogGlobalVars.debug
			if FLogGlobalVars.debug then 
				out("Debug mode |cff00ff00enabled")
			else 
				out("Debug mode |cffff0000disabled")
			end 
		elseif "HELP" == cmd or "H" == cmd then 
			out("Use FarmLog to track your grinding session yield. Options:")
			out(" |cff00ff00/fl|r toggle logging on/off")
			out(" |cff00ff00/fl s|r shows log window")
			out(" |cff00ff00/fl w|r <session_name>|r switch to a different session")
			out(" |cff00ff00/fl l|r lists all sessions")
			out(" |cff00ff00/fl delete <session_name>|r delete a session")
			out(" |cff00ff00/fl r|r reset current session")
			out(" |cff00ff00/fl set <item_link> <gold_value>|r sets AH value of an item, in gold")
			out(" |cff00ff00/fl i <item_link>|r adds/remove an item from ignore list")
			out(" |cff00ff00/fl asi|r enables/disables Auto Switch in Instances, if enabled, will automatically start a farm session for that instance. Instance name will be used for session name.")
			out(" |cff00ff00/fl ren <new_name>|r renames current session")
			out(" |cff00ff00/fl rmi|r resets minimap icon position")
			out(" |cff00ff00/fl rmw|r resets main window position")
		elseif "SET" == cmd then
			local startIndex, _ = string.find(arg1, "%|c");
			local _, endIndex = string.find(arg1, "%]%|h%|r");
			local itemLink = string.sub(arg1, startIndex, endIndex);	
			itemLink = normalizeLink(itemLink) -- remove player level

			if itemLink and GetItemInfo(itemLink) then 
				local value = nil 
				if ((endIndex + 2 ) <= (#arg1)) then
					local st = string.sub(arg1, endIndex + 2, #arg1)
					local priceGold = tonumber(st)
					if priceGold then 
						value = priceGold * 10000
					else 
						out("Incorrect usage of command write |cff00ff00/fl set [ITEM_LINK] [PRICE_GOLD]")
					end 
				end				
				FLogGlobalVars.ahPrice[itemLink] = value 
				if value and value > 0 then 
					out("Setting AH value of "..itemLink.." to "..GetShortCoinTextureString(value))
				else 
					out("Removing "..itemLink.." from AH value table")
				end 
				FarmLog:RecalcTotals()
			else 
				out("Incorrect usage of command write |cff00ff00/fl set [ITEM_LINK] [PRICE_GOLD]|r")
			end 
		elseif "IGNORE" == cmd or "I" == cmd then
			local startIndex, _ = string.find(arg1, "%|c");
			local _, endIndex = string.find(arg1, "%]%|h%|r");
			local itemLink = string.sub(arg1, startIndex, endIndex)
			itemLink = normalizeLink(itemLink) -- remove player level

			if itemLink and GetItemInfo(itemLink) then 
				if FLogGlobalVars.ignoredItems[itemLink] then 
					FLogGlobalVars.ignoredItems[itemLink] = nil 
					out("Removed "..itemLink.." from ignore list")
				else 
					FLogGlobalVars.ignoredItems[itemLink] = true
					out("Ignoring "..itemLink)
				end 
				FarmLog:RecalcTotals()
			else 
				out("Incorrect usage of command write |cff00ff00/fl i [ITEM_LINK]|r")
			end 
		elseif  "LIST" == cmd or "L" == cmd then
			out("Recorded sessions:")
			for sessionName, _ in pairs(FLogVars.sessions) do 
				out(" - |cff99ff00"..sessionName)
			end 
		elseif  "DELETE" == cmd then
			FarmLog:DeleteSession(arg1)
		elseif  "SWITCH" == cmd or "W" == cmd then
			if arg1 and #arg1 > 0 then 
				out("Switching session to |cff99ff00"..arg1)
				FarmLog:StartSession(arg1)
				FarmLog:RefreshMainWindow() 
			else 
				out("Wrong input, also write the name of the new session, as in |cff00ff00/fl w <session_name>")
			end 
		elseif  "REN" == cmd then
			out("Renaming session from |cff99ff00"..FLogVars.currentSession.."|r to |cff99ff00"..arg1)
			FLogVars.sessions[arg1] = FLogVars.sessions[FLogVars.currentSession]
			FLogVars.sessions[FLogVars.currentSession] = nil 
			FLogVars.currentSession = arg1 
			FarmLog:RefreshMainWindow() 
		elseif "ASI" == cmd then 
			FLogGlobalVars.autoSwitchInstances = not FLogGlobalVars.autoSwitchInstances 
			if not FLogGlobalVars.autoSwitchInstances then 
				out("Auto switching in instances |cffff4444"..L["disabled"])
			else 
				out("Auto switching in instances |cff44ff44"..L["enabled"])
			end 
		elseif  "RESET" == cmd or "R" == cmd then
			FarmLog:ResetSession()
		elseif  "RMI" == cmd then
			FLogVars.minimapButtonPosition.x = -165
			FLogVars.minimapButtonPosition.y = -127
			FLogVars.minimapButtonPosition.point = "TOPRIGHT"
			FLogVars.enableMinimapButton = true 
			FarmLog_MinimapButton:Init(true)
		elseif  "RMW" == cmd then
			FarmLog_MainWindow:ResetPosition()
		else 
			out("Unknown command "..cmd)
		end 
	end 
end
