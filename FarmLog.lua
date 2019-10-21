local VERSION = 1.6
local APPNAME = "FarmLog"
local CREDITS = "by |cff40C7EBKof|r @ |cffff2222Shazzrah|r"

FarmLog_ScrollRows = {}

FLogGlobalVars = {
	["debug"] = false,
	["ahPrice"] = {},
	["autoSwitchInstances"] = true,
	["itemQuality"] = {true, true, true, true, true, true, true},
	["reportTo"] = {},
	["version"] = VERSION,
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
	["version"] = VERSION,
}

local editName = "";
local editItem = "";
local editIdx = -1;
local L = FarmLog_BuildLocalization()

local visibleRows = 0
local sessionListMode = false
local gphNeedsUpdate = false 
local sessionStartTime = nil 
local lastMobLoot = {}
local skillName = nil 
local skillNameTime = nil 
local lastUpdate = 0
local lastGphUpdate = 0
local goldPerHour = 0

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
	if FLogGlobalVars["debug"] then 
		out(text)
	end 
end 

local function tobool(arg1)
	return arg1 == 1 or arg1 == true
end

local function secondsToClock(seconds)
	local seconds = tonumber(seconds)

	if seconds <= 0 then
		return "00:00:00";
	else
		hours = string.format("%02.f", math.floor(seconds/3600));
		mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
		secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
		return hours..":"..mins..":"..secs
	end
end

local function GetShortCoinTextureString(money)
	if not money or tostring(money) == "nan" or tostring(money) == "inf"  then return "--" end 
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

-- Data migration ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function FarmLog:Migrate() 
	-- migration
	if FLogSVTotalSeconds and FLogSVTotalSeconds > 0 then 
		-- migrate 1 session into multi session DB
		FLogVars["sessions"][FLogVars["currentSession"]] = {
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
	elseif not FLogVars["sessions"][FLogVars["currentSession"]] then 
		self:ResetSessionVars()
	end 

	if FLogSVAHValue then 
		FLogGlobalVars["autoSwitchInstances"] = FLogSVAutoSwitchOnInstances
		FLogGlobalVars["debug"] = FLogSVDebugMode
		FLogGlobalVars["ahPrice"] = FLogSVAHValue
		FLogGlobalVars["itemQuality"] = FLogSVItemRarity
		FLogGlobalVars["reportTo"] = FLogSVOptionReportTo
		FLogSVAHValue = nil 
		out("Migrated old global vars into new database format.")
	end 

	if FLogSVSessions then 
		FLogVars["sessions"] = FLogSVSessions
		FLogVars["enabled"] = FLogSVEnabled
		FLogVars["currentSession"] = FLogSVCurrentSession
		FLogVars["instanceName"] = FLogSVLastInstance
		FLogVars["inInstance"] = FLogSVInInstance

		FLogVars["lockFrames"] = FLogSVLockFrames
		FLogVars["lockMinimapButton"] = FLogSVLockMinimapButton
		FLogVars["frameRect"] = FLogSVFrame
		FLogVars["minimapButtonPosition"] = FLogSVMinimapButtonPosition
		FLogVars["enableMinimapButton"] = FLogSVEnableMinimapButton
		FLogVars["itemTooltip"] = FLogSVTooltip
		FLogSVSessions = nil 
		out("Migrated old character vars into new database format.")
	end 

	if FLogVars["minimapButtonPosision"] then 
		FLogVars["minimapButtonPosition"] = FLogVars["minimapButtonPosision"]
		FLogVars["minimapButtonPosision"] = nil 
	end 
end 

-- Session management ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local function GetSessionVar(varName, sessionName)
	return (FLogVars["sessions"][sessionName or FLogVars["currentSession"]] or {})[varName]
end 

local function SetSessionVar(varName, value)
	FLogVars["sessions"][FLogVars["currentSession"]][varName] = value 
end 

local function IncreaseSessionVar(varName, incValue)
	debug("IncreaseSessionVar varName: "..varName..", incValue: "..tostring(incValue))
	FLogVars["sessions"][FLogVars["currentSession"]][varName] = ((FLogVars["sessions"][FLogVars["currentSession"]] or {})[varName] or 0) + incValue 
end 

local function IncreaseSessionDictVar(varName, entry, incValue)
	FLogVars["sessions"][FLogVars["currentSession"]][varName][entry] = ((FLogVars["sessions"][FLogVars["currentSession"]] or {})[varName][entry] or 0) + incValue 
end 

function FarmLog:GetSessionWindowTitle(customTime)
	local text = FLogVars["currentSession"] or ""
	local time = customTime or GetSessionVar("seconds") or 0
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
		if FLogVars["enabled"] then 
			FarmLog_MainWindow_Title_Text:SetTextColor(0, 1, 0, 1.0);
		else 
			FarmLog_MainWindow_Title_Text:SetTextColor(1, 1, 0, 1.0);
			FarmLog_MainWindow_Title_Text:SetText(self:GetSessionWindowTitle())
		end 
	end 
end 

function FarmLog:ResumeSession() 
	sessionStartTime = time()

	FLogVars["enabled"] = true  
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
		FLogVars["enabled"] = false 
		FarmLog_MinimapButtonIcon:SetTexture("Interface\\AddOns\\FarmLog\\FarmLogIconOFF");
		self:UpdateMainWindowTitle()
	end 
end 

function FarmLog:ResetSessionVars()
	FLogVars["sessions"][FLogVars["currentSession"]] = {
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

function FarmLog:StartSession(sessionName, dontPause) 
	if FLogVars["enabled"] then 
		gphNeedsUpdate = true 
		if not dontPause then 
			self:PauseSession(true) 
		end 
	end 

	FLogVars["currentSession"] = sessionName
	if not FLogVars["sessions"][FLogVars["currentSession"]] then 
		self:ResetSessionVars()
	end 
	self:ResumeSession()
end 

function FarmLog:DeleteSession(name) 
	FLogVars["sessions"][name] = nil 
	if FLogVars["currentSession"] == name then 
		self:StartSession("default", true)
	end 
	if FLogVars["currentSession"] == name and name == "default" then 
		out("Reset the |cff99ff00"..name.."|r session")
	else 
		out("Deleted session |cff99ff00"..name)
	end 
end 

function FarmLog:ResetSession()
	self:PauseSession(true)
	self:ResetSessionVars()
	self:ResumeSession()
	out("Reset session |cff99ff00"..FLogVars["currentSession"])
	gphNeedsUpdate = true 
	self:RefreshSession()
end

function FarmLog:InitSession()
	if FLogVars["enabled"] then 
		self:ResumeSession()
	else 
		self:PauseSession()
	end 
	gphNeedsUpdate = true
	self:RefreshSession()
end 

function FarmLog:ToggleLogging() 
	if FLogVars["enabled"] then 
		self:PauseSession()
		out("Farm session |cff99ff00"..FLogVars["currentSession"].."|r paused|r")
	else 
		self:StartSession(FLogVars["currentSession"] or "default")
		if GetSessionVar("seconds") == 0 then 
			out("Farm session |cff99ff00"..FLogVars["currentSession"].."|r started")
		else 
			out("Farm session |cff99ff00"..FLogVars["currentSession"].."|r resumed")
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
			FLogOptionsFrame:Hide()
		else
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
			self:PlaceLinkInChatEditBox(itemLink) -- paste in chat box
		elseif IsControlKeyDown() then
			DressUpItemLink(itemLink) -- preview
		end
	end 
end

function FarmLog:GetOnLogSessionItemClick(sessionName) 
	return function(self, button)
		if button == "RightButton" then 
			self:DeleteSession(sessionName)
			self:RefreshSession()
		else 
			if IsAltKeyDown() then
				-- edit?
			else 
				sessionListMode = false 
				out("Farm session |cff99ff00"..sessionName.."|r resumed")
				self:StartSession(sessionName)
				self:RefreshSession()
			end
		end 
	end 
end

local function CreateRow_Text(existingRow, text)
	local row = existingRow or {};
	local previousType = row["type"]
	row["type"] = "text"

	if not row["root"] then 
		row["root"] = CreateFrame("FRAME", nil, FarmLog_MainWindow_Scroll_Content);		
		row["root"]:SetWidth(FarmLog_MainWindow_Scroll_Content:GetWidth() - 20);
		row["root"]:SetHeight(15);
		if #FarmLog_ScrollRows == 0 then 
			row["root"]:SetPoint("TOPLEFT", FarmLog_MainWindow_Scroll_Content, "TOPLEFT");
		else 
			row["root"]:SetPoint("TOPLEFT", FarmLog_ScrollRows[#FarmLog_ScrollRows]["root"], "BOTTOMLEFT");
		end 
	end 
	if previousType ~= "text" then 
		row["root"]:SetScript("OnEnter", nil);
		row["root"]:SetScript("OnLeave", nil);
		row["root"]:SetScript("OnMouseUp", nil);	
	end 
	row["root"]:Show();
	
	if not row["label"] then 
		row["label"] = row["root"]:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
		row["label"]:SetTextColor(1, 1, 1, 0.8)
		row["label"]:SetPoint("LEFT")
		row["label"]:SetFont("FarmLogRowFont", 10)
	end 
	row["label"]:SetText(text);
	row["label"]:Show()

	if not existingRow then 
		tinsert(FarmLog_ScrollRows, row);
	end 
	return row
end

local function HideRowsBeyond(j)
	local n = #FarmLog_ScrollRows;
	if j <= n then 
		for i = j, n do
			FarmLog_ScrollRows[i]["root"]:Hide()
		end
	end 
end

local function AddItem_Text(text) 
	visibleRows = visibleRows + 1
	return CreateRow_Text(FarmLog_ScrollRows[visibleRows], text)
end 

local function SetItemTooltip(row, itemLink, text)
	row["root"]:SetScript("OnEnter", function(self)
		self:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background"});
		self:SetBackdropColor(0.8,0.8,0.8,0.6);
		if FLogVars["itemTooltip"] then
			GameTooltip:SetOwner(self, "ANCHOR_LEFT");
			if itemLink then 
				GameTooltip:SetHyperlink(itemLink);
			elseif text then 
				GameTooltip:SetText(text);
			end 					
			GameTooltip:Show();
		end
	end);
	row["root"]:SetScript("OnLeave", function(self)
		if FLogVars["itemTooltip"] then
			GameTooltip_Hide();
		end
		self:SetBackdrop(nil);
	end);		
end 

local function SetItemActions(row, callback) 
	row["root"]:SetScript("OnMouseUp", function(self, ...)
		self:SetBackdrop(nil);
		callback(self, ...)
	end);
end 

function FarmLog:AddSessionYieldItems() 
	if goldPerHour and goldPerHour > 0 and tostring(goldPerHour) ~= "nan" and tostring(goldPerHour) ~= "inf" then AddItem_Text(L["Gold / Hour"] .. " " .. GetShortCoinTextureString(goldPerHour)) end 
	if GetSessionVar("ah") > 0 then AddItem_Text(L["Auction House"].." "..GetShortCoinTextureString(GetSessionVar("ah"))) end 
	if GetSessionVar("gold") > 0 then AddItem_Text(L["Money"].." "..GetShortCoinTextureString(GetSessionVar("gold"))) end 
	if GetSessionVar("vendor") > 0 then AddItem_Text(L["Vendor"].." "..GetShortCoinTextureString(GetSessionVar("vendor"))) end 
	if GetSessionVar("xp") > 0 then AddItem_Text(L["XP"].." "..GetSessionVar("xp")) end 
	for faction, rep in pairs(GetSessionVar("rep")) do AddItem_Text(rep.." "..faction.." "..L["reputation"]) end 
	for skillName, levels in pairs(GetSessionVar("skill")) do AddItem_Text("+"..levels.." "..skillName) end 

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
		if sessionKills[mobName] then 
			section = section .. " x" .. sessionKills[mobName]
		end 
		AddItem_Text(section)	
		for _, itemLink in ipairs(sortedItemLinks) do			
			for j = 1, #sessionDrops[mobName][itemLink] do
				local quantity = sessionDrops[mobName][itemLink][j][1];
				local itemText = "    "..itemLink
				if quantity > 1 then itemText = itemText.." x"..quantity end
				local row = AddItem_Text(itemText)
				SetItemTooltip(row, itemLink)
				SetItemActions(row, self:GetOnLogItemClick(itemLink))
				row["root"]:Show();
			end
		end		
	end
end 

function FarmLog:AddSessionListItems() 
	for name, session in pairs(FLogVars["sessions"]) do 
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

function FarmLog:RefreshSession()
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
		for itemLink, metalist in pairs(drops) do 
			for j = 1, #metalist do
				local meta = metalist[j]
				local _, _, _, _, _, _, _, _, _, _, vendorPrice = GetItemInfo(itemLink);
				local value = FLogGlobalVars["ahPrice"][itemLink]
				local quantity = meta[1]
				if value and value > 0 then 
					sessionAH = sessionAH + value * quantity
				else
					sessionVendor = sessionVendor + (vendorPrice or 0) * quantity
				end 
			end 
		end 
	end 
	SetSessionVar("vendor", sessionVendor)
	SetSessionVar("ah", sessionAH)
	gphNeedsUpdate = true 
	self:RefreshSession()
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
		self:RefreshSession()
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
	self:RefreshSession()
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
		IncreaseSessionVar("rep", rep)
		self:RefreshSession()
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
		self:RefreshSession()
	end 
end 

-- Loot window event

function FarmLog:OnLootOpened(autoLoot)
	local lootCount = GetNumLootItems()
	local mobName = nil 
	if not mobName and IsFishingLoot() then mobName = L["Fishing"] end 
	if not mobName and skillName then mobName = skillName end 
	if not mobName then mobName = UnitName("target") end 
	-- debug("FarmLog:OnLootOpened - mobName = "..mobName)
	lastMobLoot = {}
	skillName = nil 
	skillNameTime = nil 
	for i = 1, lootCount do 
		local link = GetLootSlotLink(i)
		if link then 
			lastMobLoot[link] = mobName
		end 
	end 
end 


-- Currency event

function FarmLog:OnCurrencyEvent(text)
	debug("FarmLog:OnCurrencyEvent - "..text)
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
	self:RefreshSession()
end 

-- Loot receive event

function FarmLog:InsertLoot(mobName, itemLink, quantity)
	if (mobName and itemLink and quantity) then		
		local sessionDrops = GetSessionVar("drops")
		if not sessionDrops[mobName] then		
			sessionDrops[mobName] = {}
		end 
		if sessionDrops[mobName][itemLink] then
			sessionDrops[mobName][itemLink][1][1] = sessionDrops[mobName][itemLink][1][1] + quantity
		else
			sessionDrops[mobName][itemLink] = {{quantity}};
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
	local itemLink, quantity = ParseSelfLootEvent(text)
	if not itemLink then return end 
	local _, _, itemRarity, _, _, itemType, _, _, _, _, vendorPrice = GetItemInfo(itemLink);

	mobName = lastMobLoot[itemLink] or "Unknown"

	local inRaid = IsInRaid();
	local inParty = false;
	if GetNumGroupMembers() > 0 then
		inParty = true;
	end
	if (
		itemType ~= "Money" and 
		(
			(FLogGlobalVars["itemQuality"][0] and itemRarity == 0) or
			(FLogGlobalVars["itemQuality"][1] and itemRarity == 1) or
			(FLogGlobalVars["itemQuality"][2] and itemRarity == 2) or
			(FLogGlobalVars["itemQuality"][3] and itemRarity == 3) or
			(FLogGlobalVars["itemQuality"][4] and itemRarity == 4) or
			(FLogGlobalVars["itemQuality"][5] and itemRarity == 5) or
			(FLogGlobalVars["itemQuality"][6] and itemRarity == 6) or 
			mobName == L["Herbalism"] or 
			mobName == L["Mining"] or 
			mobName == L["Fishing"] 
		)) 
	then	
		local ahValue = FLogGlobalVars["ahPrice"][itemLink]
		if ahValue and ahValue > 0 then 
			IncreaseSessionVar("ah", ahValue)
		else
			IncreaseSessionVar("vendor", vendorPrice or 0) 		
		end 

		self:InsertLoot(mobName, itemLink, (quantity or 1));
		self:RefreshSession();
	end
end

-- Addon Loaded

function FarmLog:OnAddonLoaded()
	out("|cffffbb00v"..tostring(VERSION).."|r "..CREDITS..", "..L["loaded-welcome"]);

	FarmLog:Migrate()

	-- init UI
	FLogOptionsCheckButtonLog0:SetChecked(FLogGlobalVars["itemQuality"][0]);
	FLogOptionsCheckButtonLog1:SetChecked(FLogGlobalVars["itemQuality"][1]);
	FLogOptionsCheckButtonLog2:SetChecked(FLogGlobalVars["itemQuality"][2]);
	FLogOptionsCheckButtonLog3:SetChecked(FLogGlobalVars["itemQuality"][3]);
	FLogOptionsCheckButtonLog4:SetChecked(FLogGlobalVars["itemQuality"][4]);
	FLogOptionsCheckButtonLog5:SetChecked(FLogGlobalVars["itemQuality"][5]);
	FLogOptionsCheckButtonLog6:SetChecked(FLogGlobalVars["itemQuality"][6]);

	FLogOptionsCheckButtonLockFrames:SetChecked(FLogVars["lockFrames"]);
	FLogOptionsCheckButtonEnableMinimapButton:SetChecked(FLogVars["enableMinimapButton"]);
	FLogOptionsCheckButtonLockMinimapButton:SetChecked(FLogVars["lockMinimapButton"]);
	FLogOptionsCheckButtonTooltip:SetChecked(FLogVars["itemTooltip"]);	
	
	FarmLog_MainWindow_Title:Init()
	FarmLog_MinimapButton:Init()
	FarmLog:InitSession()
end 

-- Entering World

function FarmLog:OnEnteringWorld() 
	local inInstance, _ = IsInInstance();
	inInstance = tobool(inInstance);
	local instanceName = GetInstanceInfo();		
	if not FLogVars["inInstance"] and inInstance and FLogVars["instanceName"] ~= instanceName then
		FLogVars["inInstance"] = true;
		FLogVars["instanceName"] = instanceName;
		if FLogGlobalVars["autoSwitchInstances"] then 
			self:StartSession(instanceName)
		end 
	elseif FLogVars["inInstance"] and inInstance == false then
		FLogVars["inInstance"] = false;
		if FLogGlobalVars["autoSwitchInstances"] then 
			self:PauseSession()
		end 
	end
	self:RefreshSession();
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
	if FLogVars["enabled"] then 
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
			debug("CHAT_MSG_OPENING")
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
	if not sessionListMode and (gphNeedsUpdate or FLogVars["enabled"]) then 
		local now = time()
		if now - lastUpdate >= 1 then 
			local sessionTime = GetSessionVar("seconds") + now - (sessionStartTime or now)
			FarmLog_MainWindow_Title_Text:SetText(self:GetSessionWindowTitle(sessionTime));
			lastUpdate = now 
			if gphNeedsUpdate or (now - lastGphUpdate >= 60 and sessionTime > 0) then 
				-- debug("Calculating GPH")
				goldPerHour = (GetSessionVar("ah") + GetSessionVar("vendor") + GetSessionVar("gold")) / (sessionTime / 3600)
				lastGphUpdate = now 
				gphNeedsUpdate = false 
				self:RefreshSession()
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

function FarmLog_MainWindow:Init() 
	FarmLog_MainWindow:SetWidth(FLogVars["frameRect"]["width"]);
	FarmLog_MainWindow:SetHeight(FLogVars["frameRect"]["height"]);
	FarmLog_MainWindow:SetPoint(FLogVars["frameRect"]["point"], FLogVars["frameRect"]["x"], FLogVars["frameRect"]["y"]);
end

function FarmLog_MainWindow:ResetPosition()
	FLogVars["frameRect"]["width"] = 250
	FLogVars["frameRect"]["height"] = 200
	FLogVars["frameRect"]["x"] = 0
	FLogVars["frameRect"]["y"] = 0
	FLogVars["frameRect"]["point"] = "CENTER"
	FarmLog_MainWindow:Init(true)
end 

function FarmLog_MinimapButton:Init(reload) 
	FarmLog_MinimapButton:SetPoint(FLogVars["minimapButtonPosition"]["point"], Minimap, FLogVars["minimapButtonPosition"]["x"], FLogVars["minimapButtonPosition"]["y"]);
	if FLogVars["enableMinimapButton"] then
		self:Show();
	else
		self:Hide();
	end	
	if not FLogVars["lockMinimapButton"] and not reload then		
		self:RegisterForDrag("LeftButton");			
	end
end 

function FarmLog_MinimapButton:DragStopped() 
	local point, relativeTo, relativePoint, x, y = FarmLog_MinimapButton:GetPoint();
	FLogVars["minimapButtonPosition"]["point"] = point;													
	FLogVars["minimapButtonPosition"]["x"] = x;
	FLogVars["minimapButtonPosition"]["y"] = y;
end 

function FarmLog_MinimapButton:Clicked(button) 
	if button == "RightButton" then
		FarmLog:ToggleLogging()
	else
		FarmLog:ToggleWindow()
	end
end 

function FarmLog_MainWindow_Title:Init()
	if not FLogVars["lockFrames"] then		
		FarmLog_MainWindow_Title:RegisterForDrag("LeftButton");			
	end
end 

function FarmLog_MainWindow_Title:DragStopped() 
	local point, relativeTo, relativePoint, x, y = FarmLog_MainWindow:GetPoint();
	FLogVars["frameRect"]["point"] = point;													
	FLogVars["frameRect"]["x"] = x;
	FLogVars["frameRect"]["y"] = y;
	FLogVars["frameRect"]["width"] = FarmLog_MainWindow:GetWidth();
	FLogVars["frameRect"]["height"] = FarmLog_MainWindow:GetHeight();
end 

function FarmLog_MainWindow_SessionsButton:Clicked() 
	sessionListMode = not sessionListMode 
	gphNeedsUpdate = true
	FarmLog:UpdateMainWindowTitle()
	FarmLog:RefreshSession()
end 

function FarmLog_MainWindow_ResetButton:Clicked()
	FarmLog_QuestionDialog_Yes:SetScript("OnClick", function() 
		FarmLog:ResetSession()
		FarmLog_QuestionDialog:Hide()
	end)
	FarmLog_QuestionDialog_TitleText:SetText(L["reset-title"])
	FarmLog_QuestionDialog_Question:SetText(L["reset-question"])
	FarmLog_QuestionDialog:Show()
end 

function FarmLog_MainWindow_Resize:MouseUp() 
	local point, _, _, x, y = FarmLog_MainWindow:GetPoint()
	FLogVars["frameRect"]["point"] = point									
	FLogVars["frameRect"]["x"] = x
	FLogVars["frameRect"]["y"] = y
	FLogVars["frameRect"]["width"] = FarmLog_MainWindow:GetWidth()
	FLogVars["frameRect"]["height"] = FarmLog_MainWindow:GetHeight()
end 

-- begin UI ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
										

local FLogOptionsFrame = CreateFrame("FRAME", "FLogOptionsFrame", UIParent);
FLogOptionsFrame:SetWidth(FarmLog_MainWindow:GetWidth());
FLogOptionsFrame:SetHeight(280);
FLogOptionsFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/DialogFrame/UI-Dialogbox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }});
FLogOptionsFrame:SetBackdropColor(0.0,0.0,0.0,0.9);
FLogOptionsFrame:SetPoint("TOPLEFT", FarmLog_MainWindow, "BOTTOMLEFT", 0, 0);
tinsert(UISpecialFrames, FLogOptionsFrame:GetName());
FLogOptionsFrame:Hide();

local FLogOptionsText1 = FLogOptionsFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogOptionsText1:SetTextColor(1.0, 0.8, 0, 0.8);
FLogOptionsText1:SetWidth(175);
FLogOptionsText1:SetJustifyH("LEFT");
FLogOptionsText1:SetText(L["Log-Options:"]);
FLogOptionsText1:SetPoint("TOPLEFT", 5, -5);

local FLogOptionsLog0 = FLogOptionsFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogOptionsLog0:SetTextColor(1, 1, 1, 0.8);
FLogOptionsLog0:SetWidth(175);
FLogOptionsLog0:SetHeight(15);
FLogOptionsLog0:SetJustifyH("LEFT");
FLogOptionsLog0:SetTextColor(GetItemQualityColor(0));
FLogOptionsLog0:SetText(L["poor"]);
FLogOptionsLog0:SetPoint("TOP", FLogOptionsText1, "BOTTOM", 25, -5);

local FLogOptionsCheckButtonLog0 = CreateFrame("CHECKBUTTON", "FLogOptionsCheckButtonLog0", FLogOptionsFrame);
FLogOptionsCheckButtonLog0:SetWidth(15);
FLogOptionsCheckButtonLog0:SetHeight(15);
FLogOptionsCheckButtonLog0:SetPoint("RIGHT", FLogOptionsLog0, "LEFT", -5, 0);
FLogOptionsCheckButtonLog0:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
FLogOptionsCheckButtonLog0:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
FLogOptionsCheckButtonLog0:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD");
FLogOptionsCheckButtonLog0:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
FLogOptionsCheckButtonLog0:SetScript("OnClick", function() FLogGlobalVars["itemQuality"][0] = tobool(FLogOptionsCheckButtonLog0:GetChecked()); end);
FLogOptionsCheckButtonLog0:Show();

local FLogOptionsLog1 = FLogOptionsFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogOptionsLog1:SetTextColor(1, 1, 1, 0.8);
FLogOptionsLog1:SetWidth(175);
FLogOptionsLog1:SetHeight(15);
FLogOptionsLog1:SetJustifyH("LEFT");
FLogOptionsLog1:SetTextColor(GetItemQualityColor(1));
FLogOptionsLog1:SetText(L["common"]);
FLogOptionsLog1:SetPoint("TOP", FLogOptionsLog0, "BOTTOM", 0, 0);

local FLogOptionsCheckButtonLog1 = CreateFrame("CHECKBUTTON", "FLogOptionsCheckButtonLog1", FLogOptionsFrame);
FLogOptionsCheckButtonLog1:SetWidth(15);
FLogOptionsCheckButtonLog1:SetHeight(15);
FLogOptionsCheckButtonLog1:SetPoint("RIGHT", FLogOptionsLog1, "LEFT", -5, 0);
FLogOptionsCheckButtonLog1:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
FLogOptionsCheckButtonLog1:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
FLogOptionsCheckButtonLog1:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD");
FLogOptionsCheckButtonLog1:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
FLogOptionsCheckButtonLog1:SetScript("OnClick", function() FLogGlobalVars["itemQuality"][1] = tobool(FLogOptionsCheckButtonLog1:GetChecked()); end);
FLogOptionsCheckButtonLog1:Show();

local FLogOptionsLog2 = FLogOptionsFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogOptionsLog2:SetTextColor(1, 1, 1, 0.8);
FLogOptionsLog2:SetWidth(175);
FLogOptionsLog2:SetHeight(15);
FLogOptionsLog2:SetJustifyH("LEFT");
FLogOptionsLog2:SetTextColor(GetItemQualityColor(2));
FLogOptionsLog2:SetText(L["uncommon"]);
FLogOptionsLog2:SetPoint("TOP", FLogOptionsLog1, "BOTTOM", 0, 0);

local FLogOptionsCheckButtonLog2= CreateFrame("CHECKBUTTON", "FLogOptionsCheckButtonLog2", FLogOptionsFrame);
FLogOptionsCheckButtonLog2:SetWidth(15);
FLogOptionsCheckButtonLog2:SetHeight(15);
FLogOptionsCheckButtonLog2:SetPoint("RIGHT", FLogOptionsLog2, "LEFT", -5, 0);
FLogOptionsCheckButtonLog2:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
FLogOptionsCheckButtonLog2:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
FLogOptionsCheckButtonLog2:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD");
FLogOptionsCheckButtonLog2:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
FLogOptionsCheckButtonLog2:SetScript("OnClick", function() FLogGlobalVars["itemQuality"][2] = tobool(FLogOptionsCheckButtonLog2:GetChecked()); end);
FLogOptionsCheckButtonLog2:Show();

local FLogOptionsLog3 = FLogOptionsFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogOptionsLog3:SetTextColor(1, 1, 1, 0.8);
FLogOptionsLog3:SetWidth(175);
FLogOptionsLog3:SetHeight(15);
FLogOptionsLog3:SetJustifyH("LEFT");
FLogOptionsLog3:SetTextColor(GetItemQualityColor(3));
FLogOptionsLog3:SetText(L["rare"]);
FLogOptionsLog3:SetPoint("TOP", FLogOptionsLog2, "BOTTOM", 0, 0);

local FLogOptionsCheckButtonLog3 = CreateFrame("CHECKBUTTON", "FLogOptionsCheckButtonLog3", FLogOptionsFrame);
FLogOptionsCheckButtonLog3:SetWidth(15);
FLogOptionsCheckButtonLog3:SetHeight(15);
FLogOptionsCheckButtonLog3:SetPoint("RIGHT", FLogOptionsLog3, "LEFT", -5, 0);
FLogOptionsCheckButtonLog3:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
FLogOptionsCheckButtonLog3:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
FLogOptionsCheckButtonLog3:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD");
FLogOptionsCheckButtonLog3:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
FLogOptionsCheckButtonLog3:SetScript("OnClick", function() FLogGlobalVars["itemQuality"][3] = tobool(FLogOptionsCheckButtonLog3:GetChecked()); end);
FLogOptionsCheckButtonLog3:Show();

local FLogOptionsLog4 = FLogOptionsFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogOptionsLog4:SetTextColor(1, 1, 1, 0.8);
FLogOptionsLog4:SetWidth(175);
FLogOptionsLog4:SetHeight(15);
FLogOptionsLog4:SetJustifyH("LEFT");
FLogOptionsLog4:SetTextColor(GetItemQualityColor(4));
FLogOptionsLog4:SetText(L["epic"]);
FLogOptionsLog4:SetPoint("TOP", FLogOptionsLog3, "BOTTOM", 0, 0);

local FLogOptionsCheckButtonLog4 = CreateFrame("CHECKBUTTON", "FLogOptionsCheckButtonLog4", FLogOptionsFrame);
FLogOptionsCheckButtonLog4:SetWidth(15);
FLogOptionsCheckButtonLog4:SetHeight(15);
FLogOptionsCheckButtonLog4:SetPoint("RIGHT", FLogOptionsLog4, "LEFT", -5, 0);
FLogOptionsCheckButtonLog4:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
FLogOptionsCheckButtonLog4:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
FLogOptionsCheckButtonLog4:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD");
FLogOptionsCheckButtonLog4:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
FLogOptionsCheckButtonLog4:SetScript("OnClick", function() FLogGlobalVars["itemQuality"][4] = tobool(FLogOptionsCheckButtonLog4:GetChecked()); end);
FLogOptionsCheckButtonLog4:Show();

local FLogOptionsLog5 = FLogOptionsFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogOptionsLog5:SetTextColor(1, 1, 1, 0.8);
FLogOptionsLog5:SetWidth(175);
FLogOptionsLog5:SetHeight(15);
FLogOptionsLog5:SetJustifyH("LEFT");
FLogOptionsLog5:SetTextColor(GetItemQualityColor(5));
FLogOptionsLog5:SetText(L["legendary"]);
FLogOptionsLog5:SetPoint("TOP", FLogOptionsLog4, "BOTTOM", 0, 0);

local FLogOptionsCheckButtonLog5 = CreateFrame("CHECKBUTTON", "FLogOptionsCheckButtonLog5", FLogOptionsFrame);
FLogOptionsCheckButtonLog5:SetWidth(15);
FLogOptionsCheckButtonLog5:SetHeight(15);
FLogOptionsCheckButtonLog5:SetPoint("RIGHT", FLogOptionsLog5, "LEFT", -5, 0);
FLogOptionsCheckButtonLog5:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
FLogOptionsCheckButtonLog5:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
FLogOptionsCheckButtonLog5:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD");
FLogOptionsCheckButtonLog5:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
FLogOptionsCheckButtonLog5:SetScript("OnClick", function() FLogGlobalVars["itemQuality"][5] = tobool(FLogOptionsCheckButtonLog5:GetChecked()); end);
FLogOptionsCheckButtonLog5:Show();

local FLogOptionsLog6 = FLogOptionsFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogOptionsLog6:SetTextColor(1, 1, 1, 0.8);
FLogOptionsLog6:SetWidth(175);
FLogOptionsLog6:SetHeight(15);
FLogOptionsLog6:SetJustifyH("LEFT");
FLogOptionsLog6:SetTextColor(GetItemQualityColor(7));
FLogOptionsLog6:SetText(L["artifact"]);
FLogOptionsLog6:SetPoint("TOP", FLogOptionsLog5, "BOTTOM", 0, 0);

local FLogOptionsCheckButtonLog6 = CreateFrame("CHECKBUTTON", "FLogOptionsCheckButtonLog6", FLogOptionsFrame);
FLogOptionsCheckButtonLog6:SetWidth(15);
FLogOptionsCheckButtonLog6:SetHeight(15);
FLogOptionsCheckButtonLog6:SetPoint("RIGHT", FLogOptionsLog6, "LEFT", -5, 0);
FLogOptionsCheckButtonLog6:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
FLogOptionsCheckButtonLog6:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
FLogOptionsCheckButtonLog6:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD");
FLogOptionsCheckButtonLog6:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
FLogOptionsCheckButtonLog6:SetScript("OnClick", function() FLogGlobalVars["itemQuality"][6] = tobool(FLogOptionsCheckButtonLog6:GetChecked()); end);
FLogOptionsCheckButtonLog6:Show();

local FLogOptionsText3 = FLogOptionsFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogOptionsText3:SetTextColor(1.0, 0.8, 0, 0.8);
FLogOptionsText3:SetWidth(150);
FLogOptionsText3:SetJustifyH("LEFT");
FLogOptionsText3:SetText(L["General-Options:"]);
FLogOptionsText3:SetPoint("TOPLEFT", FLogOptionsLogRaid, "BOTTOMLEFT", -25, -10);

local FLogOptionsLockFrames = FLogOptionsFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogOptionsLockFrames:SetTextColor(1, 1, 1, 0.8);
FLogOptionsLockFrames:SetWidth(175);
FLogOptionsLockFrames:SetHeight(15);
FLogOptionsLockFrames:SetJustifyH("LEFT");
FLogOptionsLockFrames:SetText(L["lockFrames"]);
FLogOptionsLockFrames:SetPoint("TOPLEFT", FLogOptionsText3, "BOTTOMLEFT", 25, -5);

local FLogOptionsCheckButtonLockFrames = CreateFrame("CHECKBUTTON", "FLogOptionsCheckButtonLockFrames", FLogOptionsFrame);
FLogOptionsCheckButtonLockFrames:SetWidth(15);
FLogOptionsCheckButtonLockFrames:SetHeight(15);
FLogOptionsCheckButtonLockFrames:SetPoint("RIGHT", FLogOptionsLockFrames, "LEFT", -5, 0);
FLogOptionsCheckButtonLockFrames:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
FLogOptionsCheckButtonLockFrames:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
FLogOptionsCheckButtonLockFrames:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD");
FLogOptionsCheckButtonLockFrames:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
FLogOptionsCheckButtonLockFrames:SetScript("OnClick", function() 
	FLogVars["lockFrames"] = tobool(FLogOptionsCheckButtonLockFrames:GetChecked());
	if FLogOptionsCheckButtonLockFrames:GetChecked() then
		FarmLog_MainWindow:RegisterForDrag("");
	elseif not FLogOptionsCheckButtonLockFrames:GetChecked() then
		FarmLog_MainWindow:RegisterForDrag("LeftButton");
	end
end);
FLogOptionsCheckButtonLockFrames:Show();

local FLogOptionsEnableMinimapButton = FLogOptionsFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogOptionsEnableMinimapButton:SetTextColor(1, 1, 1, 0.8);
FLogOptionsEnableMinimapButton:SetWidth(175);
FLogOptionsEnableMinimapButton:SetHeight(15);
FLogOptionsEnableMinimapButton:SetJustifyH("LEFT");
FLogOptionsEnableMinimapButton:SetText(L["enableMinimapButton"]);
FLogOptionsEnableMinimapButton:SetPoint("TOPLEFT", FLogOptionsLockFrames, "BOTTOMLEFT", 0, 0);

local FLogOptionsCheckButtonEnableMinimapButton = CreateFrame("CHECKBUTTON", "FLogOptionsCheckButtonEnableMinimapButton", FLogOptionsFrame);
FLogOptionsCheckButtonEnableMinimapButton:SetWidth(15);
FLogOptionsCheckButtonEnableMinimapButton:SetHeight(15);
FLogOptionsCheckButtonEnableMinimapButton:SetPoint("RIGHT", FLogOptionsEnableMinimapButton, "LEFT", -5, 0);
FLogOptionsCheckButtonEnableMinimapButton:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
FLogOptionsCheckButtonEnableMinimapButton:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
FLogOptionsCheckButtonEnableMinimapButton:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD");
FLogOptionsCheckButtonEnableMinimapButton:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
FLogOptionsCheckButtonEnableMinimapButton:SetScript("OnClick", function() 
	FLogVars["enableMinimapButton"] = tobool(FLogOptionsCheckButtonEnableMinimapButton:GetChecked());
	if FLogOptionsCheckButtonEnableMinimapButton:GetChecked() then
		FarmLog_MinimapButton:Show();
	elseif not FLogOptionsCheckButtonEnableMinimapButton:GetChecked() then
		FarmLog_MinimapButton:Hide();
	end
end);
FLogOptionsCheckButtonEnableMinimapButton:Show();

local FLogOptionsLockMinimapButton = FLogOptionsFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogOptionsLockMinimapButton:SetTextColor(1, 1, 1, 0.8);
FLogOptionsLockMinimapButton:SetWidth(175);
FLogOptionsLockMinimapButton:SetHeight(15);
FLogOptionsLockMinimapButton:SetJustifyH("LEFT");
FLogOptionsLockMinimapButton:SetText(L["lockMinimapButton"]);
FLogOptionsLockMinimapButton:SetPoint("TOPLEFT", FLogOptionsEnableMinimapButton, "BOTTOMLEFT", 0, 0);

local FLogOptionsCheckButtonLockMinimapButton = CreateFrame("CHECKBUTTON", "FLogOptionsCheckButtonLockMinimapButton", FLogOptionsFrame);
FLogOptionsCheckButtonLockMinimapButton:SetWidth(15);
FLogOptionsCheckButtonLockMinimapButton:SetHeight(15);
FLogOptionsCheckButtonLockMinimapButton:SetPoint("RIGHT", FLogOptionsLockMinimapButton, "LEFT", -5, 0);
FLogOptionsCheckButtonLockMinimapButton:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
FLogOptionsCheckButtonLockMinimapButton:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
FLogOptionsCheckButtonLockMinimapButton:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD");
FLogOptionsCheckButtonLockMinimapButton:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
FLogOptionsCheckButtonLockMinimapButton:SetScript("OnClick", function()
	FLogVars["lockMinimapButton"] = tobool(FLogOptionsCheckButtonLockMinimapButton:GetChecked());
	if FLogOptionsCheckButtonLockMinimapButton:GetChecked() then
		FarmLog_MinimapButton:RegisterForDrag(""); 
	elseif not FLogOptionsCheckButtonLockMinimapButton:GetChecked() then																			
		FarmLog_MinimapButton:RegisterForDrag("LeftButton");
	end
end);
FLogOptionsCheckButtonLockMinimapButton:Show();

local FLogOptionsTooltip = FLogOptionsFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogOptionsTooltip:SetTextColor(1, 1, 1, 0.8);
FLogOptionsTooltip:SetWidth(175);
FLogOptionsTooltip:SetHeight(15);
FLogOptionsTooltip:SetJustifyH("LEFT");
FLogOptionsTooltip:SetText(L["tooltip"]);
FLogOptionsTooltip:SetPoint("TOPLEFT", FLogOptionsLockMinimapButton, "BOTTOMLEFT", 0, 0);

local FLogOptionsCheckButtonTooltip = CreateFrame("CHECKBUTTON", "FLogOptionsCheckButtonTooltip", FLogOptionsFrame);
FLogOptionsCheckButtonTooltip:SetWidth(15);
FLogOptionsCheckButtonTooltip:SetHeight(15);
FLogOptionsCheckButtonTooltip:SetPoint("RIGHT", FLogOptionsTooltip, "LEFT", -5, 0);
FLogOptionsCheckButtonTooltip:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
FLogOptionsCheckButtonTooltip:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
FLogOptionsCheckButtonTooltip:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD");
FLogOptionsCheckButtonTooltip:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
FLogOptionsCheckButtonTooltip:SetScript("OnClick", function()
	FLogVars["itemTooltip"] = tobool(FLogOptionsCheckButtonTooltip:GetChecked());
end);
FLogOptionsCheckButtonTooltip:Show();

local FLogEditFrame = CreateFrame("FRAME", "FLogEditFrame", UIParent);
FLogEditFrame:SetFrameStrata("HIGH"); 
FLogEditFrame:SetWidth(310);
FLogEditFrame:SetHeight(85);
FLogEditFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/DialogFrame/UI-Dialogbox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }});
FLogEditFrame:SetBackdropColor(0.0,0.0,0.0,0.9);
FLogEditFrame:SetPoint("CENTER");
FLogEditFrame:EnableMouse(true);
FLogEditFrame:RegisterForDrag("LeftButton");
FLogEditFrame:SetMovable(true);
FLogEditFrame:SetUserPlaced(true);
FLogEditFrame:SetScript("OnDragStart", function(this) this:StartMoving(); end);
FLogEditFrame:SetScript("OnDragStop", function(this) this:StopMovingOrSizing(); end);
FLogEditFrame:Hide();
tinsert(UISpecialFrames, FLogEditFrame:GetName());

L["owner"] = "Owner:";
L["item"] = "Item:";
L["edit"] = "Edit";
L["cancel"]= "Cancel"; 

local FLogEditFrameItemText = FLogEditFrame:CreateFontString("FLogEditFrameItemText", "Artwork", "ChatFontNormal");
FLogEditFrameItemText:SetTextColor(1, 1, 1, 0.8);
FLogEditFrameItemText:SetWidth(65);
FLogEditFrameItemText:SetHeight(15);
FLogEditFrameItemText:SetText(L["item"]);
FLogEditFrameItemText:SetJustifyH("LEFT");
FLogEditFrameItemText:SetPoint("TOPLEFT", FLogEditFrame, "TOPLEFT", 10, -10);
FLogEditFrameItemText:Show();

local FLogEditFrameOwnerText = FLogEditFrame:CreateFontString("FLogEditFrameOwner", "Artwork", "ChatFontNormal");
FLogEditFrameOwnerText:SetTextColor(1, 1, 1, 0.8);
FLogEditFrameOwnerText:SetWidth(65);
FLogEditFrameOwnerText:SetHeight(15);
FLogEditFrameOwnerText:SetText(L["owner"]);
FLogEditFrameOwnerText:SetJustifyH("LEFT");
FLogEditFrameOwnerText:SetPoint("TOPLEFT", FLogEditFrameItemText, "BOTTOMLEFT", 0, -5);
FLogEditFrameOwnerText:Show();

local FLogEditFrameItem = FLogEditFrame:CreateFontString("FLogEditFrameItem", "Artwork", "ChatFontNormal");
FLogEditFrameItem:SetTextColor(1, 1, 1, 0.8);
FLogEditFrameItem:SetWidth(225);
FLogEditFrameItem:SetHeight(15);
FLogEditFrameItem:SetJustifyH("LEFT");
FLogEditFrameItem:SetPoint("LEFT", FLogEditFrameItemText, "RIGHT", 5, 0);
FLogEditFrameItem:Show();

local FLogEditFrameOwnerBox = CreateFrame("EDITBOX", "FLogEditFrameOwnerBox", FLogEditFrame, "InputBoxTemplate")
FLogEditFrameOwnerBox:SetWidth(225);
FLogEditFrameOwnerBox:SetHeight(15);
FLogEditFrameOwnerBox:SetPoint("LEFT", FLogEditFrameOwnerText, "RIGHT", 5, 0);
FLogEditFrameOwnerBox:SetScript("OnEnterPressed", function() FLogEditFrameEditButton:Click(); end);
FLogEditFrameOwnerBox:SetAutoFocus(false);
FLogEditFrameOwnerBox:Show();

local FLogEditFrameEditButton = CreateFrame("BUTTON", "FLogEditFrameEditButton", FLogEditFrame, "UIPanelButtonTemplate");
FLogEditFrameEditButton:SetWidth(50);
FLogEditFrameEditButton:SetHeight(25);
FLogEditFrameEditButton:SetText(L["edit"]);
FLogEditFrameEditButton:SetPoint("BOTTOM", FLogEditFrame, "BOTTOM", -55, 5);
FLogEditFrameEditButton:SetScript("OnClick", function()
													local newName = FLogEditFrameOwnerBox:GetText();
													if editName ~= newName then
														local sessionDrops = GetSessionVar("drops")
														if #sessionDrops[editName][editItem] == 1 then
															FarmLog:InsertLoot(newName, editItem, sessionDrops[editName][editItem][editIdx][1]);
															sessionDrops[editName][editItem] = nil;
															local x = 0;
															for a, _ in pairs (sessionDrops[editName]) do																
																x = x + 1;
															end
															if x == 0 then
																sessionDrops[editName] = nil;
															end
														else
															FarmLog:InsertLoot(newName, editItem, sessionDrops[editName][editItem][editIdx][1]);
															tremove(sessionDrops[editName][editItem], editIdx);
														end
														FarmLog:RefreshSession();
													end
													FLogEditFrame:Hide();													
												end);
FLogEditFrameEditButton:SetAlpha(1);
FLogEditFrameEditButton:Show();

local FLogEditFrameCancelButton = CreateFrame("BUTTON", "FLogEditFrameCancelButton", FLogEditFrame, "UIPanelButtonTemplate");
FLogEditFrameCancelButton:SetWidth(50);
FLogEditFrameCancelButton:SetHeight(25);
FLogEditFrameCancelButton:SetText(L["cancel"]);
FLogEditFrameCancelButton:SetPoint("BOTTOM", FLogEditFrame, "BOTTOM", 55, 5);
FLogEditFrameCancelButton:SetScript("OnClick", function() FLogEditFrame:Hide(); end);
FLogEditFrameCancelButton:SetAlpha(1);
FLogEditFrameCancelButton:Show();

local FLogHelpFrame = CreateFrame("FRAME", "FLogHelpFrame", UIParent);
FLogHelpFrame:SetFrameStrata("HIGH"); 
FLogHelpFrame:SetWidth(FarmLog_MainWindow:GetWidth());
FLogHelpFrame:SetHeight(200);
if (GetLocale() == "deDE") then
	FLogHelpFrame:SetHeight(215);
end
FLogHelpFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/DialogFrame/UI-Dialogbox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }});
FLogHelpFrame:SetBackdropColor(0.0,0.0,0.0,0.9);
FLogHelpFrame:SetPoint("BOTTOM", FarmLog_MainWindow, "TOP", 0, 0);
FLogHelpFrame:SetScript("OnDragStart", function(this) this:StartMoving(); end);
FLogHelpFrame:SetScript("OnDragStop", function(this) this:StopMovingOrSizing(); end);
FLogHelpFrame:Hide();
tinsert(UISpecialFrames, FLogHelpFrame:GetName());

local FLogHelpFrameText = FLogHelpFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogHelpFrameText:SetTextColor(1.0, 0.8, 0, 0.8);
FLogHelpFrameText:SetWidth(230);
FLogHelpFrameText:SetJustifyH("LEFT");
FLogHelpFrameText:SetText(L["Help"]);
FLogHelpFrameText:SetPoint("TOPLEFT", 5, -10);
-- end UI

-- Slash Interface ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SLASH_LH1 = "/farmlog";
SLASH_LH2 = "/fl";
SlashCmdList["LH"] = function(msg)
	local _, _, cmd, arg1 = string.find(msg, "([%w]+)%s*(.*)$");
	if not cmd then
		FarmLog:ToggleLogging()
	else 
		cmd = string.upper(cmd)
		if  "SHOW" == cmd or "S" == cmd then
			FarmLog:ToggleWindow()
		elseif "DEBUG" == cmd then 
			FLogGlobalVars["debug"] = not FLogGlobalVars["debug"]
			if FLogGlobalVars["debug"] then 
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
			out(" |cff00ff00/fl asi|r enables/disables Auto Switch in Instances, if enabled, will automatically start a farm session for that instance. Instance name will be used for session name.")
			out(" |cff00ff00/fl ren <new_name>|r renames current session")
			out(" |cff00ff00/fl rmi|r resets minimap icon position")
			out(" |cff00ff00/fl rmw|r resets main window position")
		elseif "SET" == cmd then
			local startIndex, _ = string.find(arg1, "%|c");
			local _, endIndex = string.find(arg1, "%]%|h%|r");
			local itemLink = string.sub(arg1, startIndex, endIndex);	
		
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
				FLogGlobalVars["ahPrice"][itemLink] = value 
				if value and value > 0 then 
					out("Setting AH value of "..itemLink.." to "..GetShortCoinTextureString(value))
				else 
					out("Removing "..itemLink.." from AH value table")
				end 
				FarmLog:RecalcTotals()
			else 
				out("Incorrect usage of command write |cff00ff00/fl set [ITEM_LINK] [PRICE_GOLD]|r")
			end 
		elseif  "LIST" == cmd or "L" == cmd then
			out("Recorded sessions:")
			for sessionName, _ in pairs(FLogVars["sessions"]) do 
				out(" - |cff99ff00"..sessionName)
			end 
		elseif  "DELETE" == cmd then
			FarmLog:DeleteSession(arg1)
		elseif  "SWITCH" == cmd or "W" == cmd then
			if arg1 and #arg1 > 0 then 
				out("Switching session to |cff99ff00"..arg1)
				FarmLog:StartSession(arg1)
				FarmLog:RefreshSession() 
			else 
				out("Wrong input, also write the name of the new session, as in |cff00ff00/fl w <session_name>")
			end 
		elseif  "REN" == cmd then
			out("Renaming session from |cff99ff00"..FLogVars["currentSession"].."|r to |cff99ff00"..arg1)
			FLogVars["sessions"][arg1] = FLogVars["sessions"][FLogVars["currentSession"]]
			FLogVars["sessions"][FLogVars["currentSession"]] = nil 
			FLogVars["currentSession"] = arg1 
			FarmLog:RefreshSession() 
		elseif "ASI" == cmd then 
			FLogGlobalVars["autoSwitchInstances"] = not FLogGlobalVars["autoSwitchInstances"] 
			if not FLogGlobalVars["autoSwitchInstances"] then 
				out("Auto switching in instances |cffff4444"..L["disabled"])
			else 
				out("Auto switching in instances |cff44ff44"..L["enabled"])
			end 
		elseif  "RESET" == cmd or "R" == cmd then
			FarmLog:ResetSession()
		elseif  "RMI" == cmd then
			FLogVars["minimapButtonPosition"]["x"] = -165
			FLogVars["minimapButtonPosition"]["y"] = -127
			FLogVars["minimapButtonPosition"]["point"] = "TOPRIGHT"
			FLogVars["enableMinimapButton"] = true 
			FarmLog_MinimapButton:Init(true)
		elseif  "RMW" == cmd then
			FarmLog_MainWindow:ResetPosition()
		else 
			out("Unknown command "..cmd)
		end 
	end 
end
