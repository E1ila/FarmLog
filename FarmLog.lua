local VERSION = 1.5
local APPNAME = "FarmLog"
local CREDITS = "by |cff40C7EBKof|r @ |cffff2222Shazzrah|r"

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
	["minimapButtonPosision"] = {
		["point"] = "TOP",
		["x"] = 0,
		["y"] = 0,
	},
	["enableMinimapButton"] = true, 
	["itemTooltip"] = true,
	["version"] = VERSION,
}

local editName = "";
local editItem = "";
local editIdx = -1;
local maxWindowWidth = (GetScreenWidth() - 50);
local maxWindowHeight = (GetScreenHeight() - 50);
local FLogMinWidth = (300);
local minWindowHeight = (200);
local FLogFrameSChildContentTable = {};
local FLogFrameTitleText
local FLogFrameShowButton
local L = FarmLog_BuildLocalization()

local listMode = false
local gphNeedsUpdate = false 
local sessionStartTime = nil 
local lastMobLoot = {}
local skillName = nil 
local skillNameTime = nil 
local lastUpdate = 0
local lastGPHUpdate = 0
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
	if not money or tostring(money) == "nan"  then return "--" end 
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

-- Session management ------------------------------------------------------------

local function GetSessionVar(varName, sessionName)
	return (FLogVars["sessions"][sessionName or FLogVars["currentSession"]] or {})[varName]
end 

local function SetSessionVar(varName, value)
	FLogVars["sessions"][FLogVars["currentSession"]][varName] = value 
end 

local function IncreaseSessionVar(varName, incValue)
	FLogVars["sessions"][FLogVars["currentSession"]][varName] = (FLogVars["sessions"][FLogVars["currentSession"]][varName] or 0) + incValue 
end 

local function IncreaseSessionDictVar(varName, entry, incValue)
	FLogVars["sessions"][FLogVars["currentSession"]][varName][entry] = (FLogVars["sessions"][FLogVars["currentSession"]][varName][entry] or 0) + incValue 
end 

local function ResumeSession() 
	sessionStartTime = time()
	FLogFrameTitleText:SetTextColor(0, 1, 0, 1.0);
	FarmLog_MinimapButtonIcon:SetTexture("Interface\\AddOns\\FarmLog\\FarmLogIconON");
end 

local function PauseSession()
	if sessionStartTime then 
		local delta = time() - sessionStartTime
		IncreaseSessionVar("seconds", delta)
		sessionStartTime = nil
	end 

	FLogFrameTitleText:SetText(secondsToClock(GetSessionVar("seconds")));
	FLogFrameTitleText:SetTextColor(1, 0, 0, 1.0);
	FarmLog_MinimapButtonIcon:SetTexture("Interface\\AddOns\\FarmLog\\FarmLogIconOFF");
end 

local function ResetSessionVars()
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

local function StartSession(sessionName, dontPause) 
	if FLogVars["enabled"] then 
		gphNeedsUpdate = true 
		if not dontPause then 
			PauseSession() 
		end 
	end 

	FLogVars["currentSession"] = sessionName
	if not FLogVars["sessions"][sessionName] then 
		ResetSessionVars()
	end 
	ResumeSession()
	FLogVars["enabled"] = true 
end 

local function DeleteSession(name) 
	FLogVars["sessions"][name] = nil 
	if FLogVars["currentSession"] == name then 
		StartSession("default", true)
	end 
	if FLogVars["currentSession"] == name and name == "default" then 
		out("Reset the |cff99ff00"..name.."|r session")
	else 
		out("Deleted session |cff99ff00"..name)
	end 
end 

-- Reporting ------------------------------------------------------------

local function ResetSession()
	PauseSession()
	ResetSessionVars()
	out("Reset session |cff99ff00"..FLogVars["currentSession"])
	FLogRefreshSChildFrame()
end

local function InsertLoot(mobName, itemLink, quantity)
	-- out(mobName.." / "..itemLink.." / "..quantity);
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

local function SendReport(message)
	if FLogGlobalVars["reportTo"]["ChatFrame1"] then
		out(message);
	end
	if FLogGlobalVars["reportTo"]["Say"] then
		SendChatMessage(message, "SAY");
	end
	if FLogGlobalVars["reportTo"]["Yell"] then
		SendChatMessage(message, "YELL");
	end
	if FLogGlobalVars["reportTo"]["Party"] then
		if GetNumGroupMembers() > 0 then
			SendChatMessage(message, "PARTY");
		end
	end
	if ((FLogGlobalVars["reportTo"]["Raid"]) and (GetNumGroupMembers() > 0)) then
		SendChatMessage(message, "RAID");
	end
	if FLogGlobalVars["reportTo"]["Guild"] then
		local guild = GetGuildInfo("player");		
		if (not(guild == nil)) then
			SendChatMessage(message, "GUILD");
		end
	end
	if FLogGlobalVars["reportTo"]["Whisper"] then
		local h = FLogReportFrameWhisperBox:GetText();
		if (not (h == nil)) then
			SendChatMessage(message, "WHISPER", nil, h);
		end
	end
end

-- UI ------------------------------------------------------------

local function AddToChatFrameEditBox(itemLink)
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

local function GetOnLogItemClick(itemLink) 
	return function(self, button)
		if IsShiftKeyDown() then
		--copy into chatframe
			AddToChatFrameEditBox(itemLink);
		elseif IsControlKeyDown() then
		--preview item
			DressUpItemLink(itemLink);
		elseif IsAltKeyDown() then
		--edit
			editName = mobName;
			editItem = itemLink;
			editIdx = j;
			if quantity > 1 then
				FLogEditFrameItem:SetText(itemLink.."x"..quantity);
			else
				FLogEditFrameItem:SetText(itemLink);
			end																									
			FLogEditFrameOwnerBox:SetText(mobName);
			FLogEditFrame:Show();
			FLogEditFrameOwnerBox:SetFocus(true);												
		end
	end 
end

local function GetOnLogSessionItemClick(sessionName) 
	return function(self, button)
		if button == "RightButton" then 
			DeleteSession(sessionName)
			FLogRefreshSChildFrame()
		else 
			if IsAltKeyDown() then
			--edit
				editName = sessionName;
				editItem = sessionName;
				editIdx = j;
				if quantity > 1 then
					FLogEditFrameItem:SetText(itemLink.."x"..quantity);
				else
					FLogEditFrameItem:SetText(itemLink);
				end																									
				FLogEditFrameOwnerBox:SetText(mobName);
				FLogEditFrame:Show();
				FLogEditFrameOwnerBox:SetFocus(true);												
			else 
				listMode = false 
				out("Farm session |cff99ff00"..sessionName.."|r resumed")
				StartSession(sessionName)
				FLogRefreshSChildFrame()
			end
		end 
	end 
end

local function CreateSChild(j)
	local x = #FLogFrameSChildContentTable;
	if x == 0 then
		local FLogFrameSChildContent = {};
				
		FLogFrameSChildContent[0] = CreateFrame("FRAME", nil, FLogFrameSChild);		
		FLogFrameSChildContent[0]:SetWidth(FLogFrameSChild:GetWidth() - 20);
		FLogFrameSChildContent[0]:SetHeight(15);
		FLogFrameSChildContent[0]:SetScript("OnEnter", function(self)
												self:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background"});
												self:SetBackdropColor(0.8,0.8,0.8,0.9);
												end);
		FLogFrameSChildContent[0]:SetScript("OnLeave", function(self)
												self:SetBackdrop(nil);
												end);
		FLogFrameSChildContent[0]:SetPoint("TOPLEFT");
		FLogFrameSChildContent[0]:Show();
		
		FLogFrameSChildContent[1] = FLogFrameSChildContent[0]:CreateFontString(nil, "Artwork", "ChatFontNormal");
		FLogFrameSChildContent[1]:SetTextColor(1, 1, 1, 0.8);	
		FLogFrameSChildContent[1]:SetPoint("TOPLEFT");
		
		FLogFrameSChildContent[2] = FLogFrameSChildContent[0]:CreateTexture(nil, "OVERLAY");
		FLogFrameSChildContent[2]:SetTexture(nil);
		FLogFrameSChildContent[2]:SetWidth(15);
		FLogFrameSChildContent[2]:SetHeight(15);
		FLogFrameSChildContent[2]:SetPoint("TOPLEFT", FLogFrameSChildContent[1], "TOPRIGHT", 5, 0);
		
		FLogFrameSChildContent[3] = FLogFrameSChildContent[0]:CreateFontString(nil, "Artwork", "ChatFontNormal");
		FLogFrameSChildContent[3]:SetTextColor(1, 1, 1, 0.8);	
		FLogFrameSChildContent[3]:SetPoint("TOPLEFT", FLogFrameSChildContent[2], "TOPRIGHT");

		FLogFrameSChildContent[0]:Hide();
		
		tinsert(FLogFrameSChildContentTable, FLogFrameSChildContent);
	else
		for i = x + 1, j + x do
			local FLogFrameSChildContent = {};
			
			FLogFrameSChildContent[0] = CreateFrame("FRAME", nil, FLogFrameSChild);		
			FLogFrameSChildContent[0]:SetWidth(FLogFrameSChild:GetWidth() - 20);
			FLogFrameSChildContent[0]:SetHeight(15);
			FLogFrameSChildContent[0]:SetPoint("TOPLEFT", FLogFrameSChildContentTable[i-1][0], "BOTTOMLEFT");
			FLogFrameSChildContent[0]:Show();
			
			FLogFrameSChildContent[1] = FLogFrameSChildContent[0]:CreateFontString(nil, "Artwork", "ChatFontNormal");
			FLogFrameSChildContent[1]:SetTextColor(1, 1, 1, 0.8);	
			FLogFrameSChildContent[1]:SetPoint("TOPLEFT");
			
			FLogFrameSChildContent[2] = FLogFrameSChildContent[0]:CreateTexture(nil, "OVERLAY");
			FLogFrameSChildContent[2]:SetTexture(nil);
			FLogFrameSChildContent[2]:SetWidth(15);
			FLogFrameSChildContent[2]:SetHeight(15);
			FLogFrameSChildContent[2]:SetPoint("TOPLEFT", FLogFrameSChildContent[1], "TOPRIGHT", 5, 0);
			
			FLogFrameSChildContent[3] = FLogFrameSChildContent[0]:CreateFontString(nil, "Artwork", "ChatFontNormal");
			FLogFrameSChildContent[3]:SetTextColor(1, 1, 1, 0.8);	
			FLogFrameSChildContent[3]:SetPoint("TOPLEFT", FLogFrameSChildContent[2], "TOPRIGHT");

			FLogFrameSChildContent[0]:Hide();
			
			tinsert(FLogFrameSChildContentTable, FLogFrameSChildContent);
		end
	end
end

local function HideSChildFrame(j)
--Hides all SChildFrames, beginning at Position j
	local n = #FLogFrameSChildContentTable;
	for i = j, n do
		FLogFrameSChildContentTable[i][0]:Hide();
	end
end

function FLogRefreshSChildFrame()
--Refresh the SChildFrame
	local n = #FLogFrameSChildContentTable;
	local i = 1;

	local function AddItem(text, dontIncrease) 
		if i > n then CreateSChild(1) end
		FLogFrameSChildContentTable[i][1]:SetText(text);
		FLogFrameSChildContentTable[i][2]:SetTexture(nil);
		FLogFrameSChildContentTable[i][3]:SetText("");
		FLogFrameSChildContentTable[i][0]:SetScript("OnEnter", nil);
		FLogFrameSChildContentTable[i][0]:SetScript("OnLeave", nil);
		FLogFrameSChildContentTable[i][0]:SetScript("OnMouseUp", nil);
		FLogFrameSChildContentTable[i][0]:Show();
		if not dontIncrease then 
			i = i + 1
		end 
	end 

	local function SetItemTooltip(itemLink, text)
		FLogFrameSChildContentTable[i][0]:SetScript("OnEnter", function(self)
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
		FLogFrameSChildContentTable[i][0]:SetScript("OnLeave", function(self)
			if FLogVars["itemTooltip"] then
				GameTooltip_Hide();
			end
			self:SetBackdrop(nil);
		end);		
	end 

	local function SetItemActions(callback) 
		FLogFrameSChildContentTable[i][0]:SetScript("OnMouseUp", function(self, ...)
			self:SetBackdrop(nil);
			callback(self, ...)
		end);
	end 

	local function AddSessionYieldItems() 
		AddItem(" --- "..L["Session"]..": "..FLogVars["currentSession"].." ---")
		if goldPerHour and goldPerHour > 0 and tostring(goldPerHour) ~= "nan" then AddItem(L["Gold / Hour"] .. " " .. GetShortCoinTextureString(goldPerHour)) end 
		if GetSessionVar("ah") > 0 then AddItem(L["Auction House"].." "..GetShortCoinTextureString(GetSessionVar("ah"))) end 
		if GetSessionVar("gold") > 0 then AddItem(L["Money"].." "..GetShortCoinTextureString(GetSessionVar("gold"))) end 
		if GetSessionVar("vendor") > 0 then AddItem(L["Vendor"].." "..GetShortCoinTextureString(GetSessionVar("vendor"))) end 
		if GetSessionVar("xp") > 0 then AddItem(L["XP"].." "..GetSessionVar("xp")) end 
		for faction, rep in pairs(GetSessionVar("rep")) do AddItem(rep.." "..faction.." "..L["reputation"]) end 
		for skillName, levels in pairs(GetSessionVar("skill")) do AddItem("+"..levels.." "..skillName) end 

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
			AddItem(section)	
			for _, itemLink in ipairs(sortedItemLinks) do			
				for j = 1, #sessionDrops[mobName][itemLink] do
					if i > n then
						CreateSChild(1);
					end
					local quantity = sessionDrops[mobName][itemLink][j][1];
					local itemText = "    "..itemLink
					if quantity > 1 then itemText = itemText.." x"..quantity end
					AddItem(itemText, true)
					SetItemTooltip(itemLink)
					SetItemActions(GetOnLogItemClick(itemLink))
					FLogFrameSChildContentTable[i][0]:Show();
					i = i + 1
				end
			end		
		end
	end 

	local function AddSessionListItems() 
		for name, session in pairs(FLogVars["sessions"]) do 
			local gph = (GetSessionVar("ah", name) + GetSessionVar("vendor", name) + GetSessionVar("gold", name)) / (GetSessionVar("seconds", name) / 3600)
			local text = name
			if gph and gph > 0 and tostring(gph) ~= "nan" then 
				text = text .. " " .. GetShortCoinTextureString(gph) .. " " .. L["G/H"]
			end 
			AddItem(text, true)
			SetItemTooltip()
			SetItemActions(GetOnLogSessionItemClick(name))
			i = i + 1
		end 
	end 

	if listMode then 
		AddSessionListItems()
	else 
		AddSessionYieldItems()
	end 

	HideSChildFrame(i);	
	if (FLogFrameSChildContentTable[1] and FLogFrameSChildContentTable[1][0] and FLogFrameSChildContentTable[1][0]:IsShown()) then		
		FLogFrameShowButton:Enable();		
		FLogFrameClearButton:Enable();
	else
		FLogFrameShowButton:Disable();
		FLogFrameClearButton:Disable();
	end
end

local function ToggleWindow()
	if FLogFrame:IsShown() then
		FLogFrame:Hide()
		FLogOptionsFrame:Hide()
	elseif not FLogFrame:IsShown() then
		FLogFrame:Show()
	end
end

local function ToggleLogging() 
	if FLogVars["enabled"] then 
		FLogVars["enabled"] = false 
		PauseSession()
		out("Farm session |cff99ff00"..FLogVars["currentSession"].."|r paused|r")
		FLogFrameShowButton:SetText(L["Resume"]);
	else 
		StartSession(FLogVars["currentSession"] or "default")
		if GetSessionVar("seconds") == 0 then 
			out("Farm session |cff99ff00"..FLogVars["currentSession"].."|r started")
		else 
			out("Farm session |cff99ff00"..FLogVars["currentSession"].."|r resumed")
		end 	
		FLogFrameShowButton:SetText(L["Pause"]);
	end 
end 

-- EVENTS ----------------------------------------------------------------------------------------

-- Spell cast 

local function OnSpellCastEvent(unit, target, guid, spellId)
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

local function OnCombatHonorEvent(text, playerName, languageName, channelName, playerName2, specialFlags)
	-- debug("OnCombatHonorEvent - text:"..text.." playerName:"..playerName.." languageName:"..languageName.." channelName:"..channelName.." playerName2:"..playerName2.." specialFlags:"..specialFlags)
end 

-- Trade skills event

local SkillGainStrings = {
	_G.ERR_SKILL_UP_SI,
}

local function ParseSkillEvent(chatmsg)
	for _, st in ipairs(SkillGainStrings) do
		local skillName, level = FLogDeformat(chatmsg, st)
		if level then
			return skillName, level
		end
	end
end

local function OnSkillsEvent(text)
	-- debug("OnSkillsEvent - text:"..text)
	local skillName, level = ParseSkillEvent(text)
	if level then 
		IncreaseSessionDictVar("skill", skillName, 1)
		FLogRefreshSChildFrame()
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

local function ParseXPEvent(chatmsg)
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

local function OnCombatXPEvent(text)
	local xp = ParseXPEvent(text)
	-- debug("OnCombatXPEvent - text:"..text.." playerName:"..playerName.." languageName:"..languageName.." channelName:"..channelName.." playerName2:"..playerName2.." specialFlags:"..specialFlags)
	IncreaseSessionVar("xp", xp)
	FLogRefreshSChildFrame()
end 

-- Faction change 

local FactionGainStrings = {
	_G.FACTION_STANDING_INCREASED,
	_G.FACTION_STANDING_INCREASED_BONUS,
}

local function ParseRepEvent(chatmsg)
	for _, st in ipairs(FactionGainStrings) do
		local faction, amount = FLogDeformat(chatmsg, st)
		if amount then
			return faction, amount
		end
	end
end

local function OnCombatFactionChange(text) 
	-- debug("OnCombatFactionChange - text:"..text)
	local faction, rep = ParseRepEvent(text)
	if rep then 
		IncreaseSessionVar("rep", rep)
		FLogRefreshSChildFrame()
	end 
end 

-- Combat log event

local function OnCombatLogEvent()
	local eventInfo = {CombatLogGetCurrentEventInfo()}
	local eventName = eventInfo[2]
	if eventName == "PARTY_KILL" then 
		local mobName = eventInfo[9]
		local sessionKills = GetSessionVar("kills")
		sessionKills[mobName] = (sessionKills[mobName] or 0) + 1
		-- debug("Player "..eventInfo[5].." killed "..eventInfo[9].." x "..tostring(sessionKills[mobName]))
		FLogRefreshSChildFrame()
	end 
end 

-- Loot window event

local function OnLootOpened(autoLoot)
	local lootCount = GetNumLootItems()
	local mobName = nil 
	if not mobName and IsFishingLoot() then mobName = L["Fishing"] end 
	if not mobName and skillName then mobName = skillName end 
	if not mobName then mobName = UnitName("target") end 
	-- debug("OnLootOpened - mobName = "..mobName)
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

local function OnCurrencyEvent(text)
	debug("OnCurrencyEvent - "..text)
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

local function OnMoneyEvent(text)
	local money = ParseMoneyEvent(text)
	IncreaseSessionVar("gold", money)
	FLogRefreshSChildFrame()
end 

-- Loot receive event

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

local function OnLootEvent(text)
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

		InsertLoot(mobName, itemLink, (quantity or 1));
		FLogRefreshSChildFrame();
	end
end

-- Addon Loaded

local function OnAddonLoaded()
	out("|cffffbb00v"..tostring(VERSION).."|r "..CREDITS..", "..L["loaded-welcome"]);

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
		ResetSessionVars()
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
		FLogVars["minimapButtonPosision"] = FLogSVMinimapButtonPosition
		FLogVars["enableMinimapButton"] = FLogSVEnableMinimapButton
		FLogVars["itemTooltip"] = FLogSVTooltip
		FLogSVSessions = nil 
		out("Migrated old character vars into new database format.")
	end 

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
	
	FLogFrame:SetWidth(FLogVars["frameRect"]["width"]);
	FLogFrame:SetHeight(FLogVars["frameRect"]["height"]);
	FLogFrame:SetPoint(FLogVars["frameRect"]["point"], FLogVars["frameRect"]["x"], FLogVars["frameRect"]["y"]);
	
	if FLogVars["enabled"] then 
		ResumeSession(true)
		FarmLog_MinimapButtonIcon:SetTexture("Interface\\AddOns\\FarmLog\\FarmLogIconON");
		FLogFrameShowButton:SetText(L["Pause"])
	else 
		FarmLog_MinimapButtonIcon:SetTexture("Interface\\AddOns\\FarmLog\\FarmLogIconOFF");
		FLogFrameShowButton:SetText(L["Resume"])
		FLogFrameTitleText:SetTextColor(1, 0, 0, 1.0);
		gphNeedsUpdate = true 
	end 
	FLogFrameTitleText:SetText(secondsToClock(GetSessionVar("seconds")));

	if not FLogVars["lockFrames"] then		
		FLogTopFrame:RegisterForDrag("LeftButton");			
	end
			
	FarmLog_MinimapButton:SetPoint(FLogVars["minimapButtonPosision"]["point"], Minimap, FLogVars["minimapButtonPosision"]["x"], FLogVars["minimapButtonPosision"]["y"]);
	if FLogVars["enableMinimapButton"] then
		FarmLog_MinimapButton:Show();
	else
		FarmLog_MinimapButton:Hide();
	end	
	if not FLogVars["lockMinimapButton"] then		
		FarmLog_MinimapButton:RegisterForDrag("LeftButton");			
	end
	FLogRefreshSChildFrame();
end 

-- Entering World

local function OnEnteringWorld() 
	local inInstance, _ = IsInInstance();
	inInstance = tobool(inInstance);
	local instanceName = GetInstanceInfo();		
	if not FLogVars["inInstance"] and inInstance and FLogVars["instanceName"] ~= instanceName then
		FLogVars["inInstance"] = true;
		FLogVars["instanceName"] = instanceName;
		if FLogGlobalVars["autoSwitchInstances"] then 
			StartSession(instanceName)
		end 
	elseif FLogVars["inInstance"] and inInstance == false then
		FLogVars["inInstance"] = false;
		if FLogGlobalVars["autoSwitchInstances"] then 
			PauseSession(instanceName)
		end 
	end
	FLogRefreshSChildFrame();
end 

-- Instance info

local function OnInstanceInfoEvent()
	-- local count = GetNumSavedInstances()
	-- debug("OnInstanceInfoEvent - GetNumSavedInstances = "..count)
	-- for i = 1, count do 
	-- 	local instanceName, instanceID, instanceReset, instanceDifficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, maxBosses, defeatedBosses = GetSavedInstanceInfo(i)
	-- 	debug("instanceName="..instanceName.." instanceID="..instanceID.." instanceReset="..tostring(instanceReset).." locked="..tostring(locked))
	-- end 
end 

-- OnEvent

function FarmLog_MainFrame:OnEvent(event, ...)
	if FLogVars["enabled"] then 
		-- debug(event)
		if event == "LOOT_OPENED" then
			OnLootOpened(...)			
		elseif event == "CHAT_MSG_LOOT" then
			if (... and (strfind(..., L["loot"]))) then
				OnLootEvent(...)		
			end	
		elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN" then 
			OnCombatHonorEvent(...);			
		elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then 
			OnCombatXPEvent(...);			
		elseif event == "CHAT_MSG_SKILL" then 
			OnSkillsEvent(...);			
		elseif event == "CHAT_MSG_OPENING" then 
			debug("CHAT_MSG_OPENING")
			debug(...)
		elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			OnCombatLogEvent(...);		
		elseif event == "CHAT_MSG_CURRENCY" then 
			OnCurrencyEvent(...)	
		elseif event == "CHAT_MSG_MONEY" then 
			OnMoneyEvent(...)	
		elseif event == "UNIT_SPELLCAST_SENT" then 
			OnSpellCastEvent(...)
		elseif event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then 
			OnCombatFactionChange(...)
		end 
	end 

	if event == "PLAYER_ENTERING_WORLD" then
		OnEnteringWorld(...)
	elseif event == "ADDON_LOADED" and ... == APPNAME then		
		OnAddonLoaded(...)
	elseif event == "PLAYER_LOGOUT" then 
		PauseSession(...)
	elseif event == "UPDATE_INSTANCE_INFO" then 
		OnInstanceInfoEvent(...)
	end
end

-- OnUpdate

function FarmLog_MainFrame:OnUpdate() 
	if gphNeedsUpdate or FLogVars["enabled"] then 
		local now = time()
		if now - lastUpdate >= 1 then 
			local sessionTime = GetSessionVar("seconds") + now - (sessionStartTime or now)
			FLogFrameTitleText:SetText(secondsToClock(sessionTime));
			lastUpdate = now 
			if gphNeedsUpdate or (now - lastGPHUpdate >= 60 and sessionTime > 0) then 
				-- debug("Calculating GPH")
				goldPerHour = (GetSessionVar("ah") + GetSessionVar("vendor") + GetSessionVar("gold")) / (sessionTime / 3600)
				lastGPHUpdate = now 
				gphNeedsUpdate = false 
				FLogRefreshSChildFrame()
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

-- UI
function FarmLog_MinimapButton:DragStopped() 
	local point, relativeTo, relativePoint, x, y = FarmLog_MinimapButton:GetPoint();
	FLogVars["minimapButtonPosision"]["point"] = point;													
	FLogVars["minimapButtonPosision"]["x"] = x;
	FLogVars["minimapButtonPosision"]["y"] = y;
end 

function FarmLog_MinimapButton:Clicked(button) 
	if button == "RightButton" then
		ToggleLogging()
	else
		ToggleWindow();
	end
end 

-- begin UI ------------------------------------------------------------------------------------------------

local FLogResetFrame = CreateFrame("FRAME", "FLogResetFrame", UIParent);
FLogResetFrame:SetWidth(160);
FLogResetFrame:SetHeight(70);
FLogResetFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/DialogFrame/UI-Dialogbox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }});
FLogResetFrame:SetBackdropColor(0.0,0.0,0.0,0.9);
FLogResetFrame:EnableMouse(true);
FLogResetFrame:RegisterForDrag("LeftButton");
FLogResetFrame:SetMovable(true);
FLogResetFrame:SetUserPlaced(true);
FLogResetFrame:SetScript("OnDragStart", function(this) this:StartMoving(); end);
FLogResetFrame:SetScript("OnDragStop", function(this) this:StopMovingOrSizing(); end);
FLogResetFrame:SetPoint("Center", 0, 100);
FLogResetFrame:Hide();
tinsert(UISpecialFrames, FLogResetFrame:GetName());

local FLogResetTopFrame = CreateFrame("FRAME", nil, FLogResetFrame);
FLogResetTopFrame:SetWidth(120);
FLogResetTopFrame:SetHeight(25);
FLogResetTopFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/DialogFrame/UI-Dialogbox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }});
FLogResetTopFrame:SetBackdropColor(0.0,0.0,0.0,0.9);
FLogResetTopFrame:SetPoint("TOP", 0, 10);
FLogResetTopFrame:Show();

local FLogResetFrameText = FLogResetTopFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogResetFrameText:SetTextColor(1, 0, 0, 1.0);
FLogResetFrameText:SetText(L["reset-title"]);
FLogResetFrameText:SetPoint("CENTER");

local FLogResetFrameText2 = FLogResetFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogResetFrameText2:SetTextColor(1, 1, 1, 1.0);
FLogResetFrameText2:SetText(L["reset"]);
FLogResetFrameText2:SetPoint("CENTER", 0, 5);

local FLogResetFrameClose = CreateFrame("BUTTON", nil, FLogResetFrame, "UIPanelButtonTemplate");
FLogResetFrameClose:SetWidth(15);
FLogResetFrameClose:SetHeight(15);
FLogResetFrameClose:SetText("X");
FLogResetFrameClose:SetPoint("TOPRIGHT", -5, -5);
FLogResetFrameClose:SetScript("OnClick", function()
											FLogResetFrame:Hide();											
										   end);
FLogResetFrameClose:SetAlpha(1);
FLogResetFrameClose:Show();

local FLogResetFrameNoButton = CreateFrame("BUTTON", nil, FLogResetFrame, "UIPanelButtonTemplate");
FLogResetFrameNoButton:SetWidth(70);
FLogResetFrameNoButton:SetHeight(20);
FLogResetFrameNoButton:SetText(L["no"]);
FLogResetFrameNoButton:SetPoint("BOTTOMRIGHT", -7, 5);
FLogResetFrameNoButton:SetScript("OnClick", function()
											FLogResetFrame:Hide();
										   end);
FLogResetFrameNoButton:SetAlpha(1);
FLogResetFrameNoButton:Show();

local FLogResetFrameYesButton = CreateFrame("BUTTON", nil, FLogResetFrame, "UIPanelButtonTemplate");
FLogResetFrameYesButton:SetWidth(70);
FLogResetFrameYesButton:SetHeight(20);
FLogResetFrameYesButton:SetText(L["yes"]);
FLogResetFrameYesButton:SetPoint("BOTTOMLEFT", 7, 5);
FLogResetFrameYesButton:SetScript("OnClick", function()
	ResetSession()
		FLogResetFrame:Hide();
end);
FLogResetFrameYesButton:SetAlpha(1);
FLogResetFrameYesButton:Show();

local FLogFrame = CreateFrame("FRAME", "FLogFrame", UIParent);
FLogFrame:SetFrameStrata("HIGH"); 
--FLogFrame:RegisterEvent("LOOT_ROLLS_COMPLETE");
FLogFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/DialogFrame/UI-Dialogbox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }});
FLogFrame:SetBackdropColor(0.0,0.0,0.0,0.9);
FLogFrame:EnableMouse(true);
FLogFrame:SetMovable(true);
FLogFrame:SetUserPlaced(true);
FLogFrame:SetScript("OnSizeChanged", function()
												FLogFrameSChild:SetWidth(FLogFrame:GetWidth() - 30);
												FLogSFrame:SetWidth(FLogFrameSChild:GetWidth() - 18);
												FLogSFrame:SetHeight(FLogFrame:GetHeight() - 65);
												FLogOptionsFrame:SetWidth(FLogFrame:GetWidth());
												FLogHelpFrame:SetWidth(FLogFrame:GetWidth());
												for i = 1 , #FLogFrameSChildContentTable do
													FLogFrameSChildContentTable[i][0]:SetWidth(FLogFrameSChild:GetWidth() - 20);
												end
											end);
FLogFrame:SetResizable(true);
FLogFrame:SetMaxResize(maxWindowWidth, maxWindowHeight);
FLogFrame:SetMinResize(FLogMinWidth, minWindowHeight);										  
FLogFrame:Hide();
tinsert(UISpecialFrames, FLogFrame:GetName());

local FLogTopFrame = CreateFrame("FRAME", "FLogTopFrame", FLogFrame);
FLogTopFrame:SetWidth(120);
FLogTopFrame:SetHeight(25);
FLogTopFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/DialogFrame/UI-Dialogbox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }});
FLogTopFrame:SetBackdropColor(0.0,0.0,0.0,0.9);
FLogTopFrame:SetPoint("TOP", 0, 10);
FLogTopFrame:EnableMouse(true);
FLogTopFrame:SetScript("OnDragStart", function()
												FLogFrame:StartMoving(); 
												FLogTopFrame:SetBackdropColor(1.0,1.0,1.0,0.9);
											end);
FLogTopFrame:SetScript("OnDragStop", function()
											FLogFrame:StopMovingOrSizing();
											local point, relativeTo, relativePoint, x, y = FLogFrame:GetPoint();
											FLogVars["frameRect"]["point"] = point;													
											FLogVars["frameRect"]["x"] = x;
											FLogVars["frameRect"]["y"] = y;
											FLogVars["frameRect"]["width"] = FLogFrame:GetWidth();
											FLogVars["frameRect"]["height"] = FLogFrame:GetHeight();
											if (not MouseIsOver(FLogTopFrame)) then
												FLogTopFrame:SetBackdropColor(0.0,0.0,0.0,0.9);
											end
										  end);
FLogTopFrame:SetScript("OnEnter", function()
													FLogTopFrame:SetBackdropColor(1.0,1.0,1.0,0.9);
												end);
FLogTopFrame:SetScript("OnLeave", function()
													if (not IsMouseButtonDown("LeftButton")) then
														FLogTopFrame:SetBackdropColor(0.0,0.0,0.0,0.9);
													end
												end);										  
FLogTopFrame:Show();

FLogFrameTitleText = FLogTopFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogFrameTitleText:SetText(L["window-title"]);
FLogFrameTitleText:SetPoint("CENTER");

local FLogFrameOptions = CreateFrame("BUTTON", nil, FLogFrame, "UIPanelButtonTemplate");
FLogFrameOptions:SetWidth(20);
FLogFrameOptions:SetHeight(20);
FLogFrameOptions:SetText("O");
FLogFrameOptions:SetPoint("TOPLEFT", 5, -5);
FLogFrameOptions:SetScript("OnClick", function()
	if FLogOptionsFrame:IsShown() then
		FLogOptionsFrame:Hide();													
	elseif not FLogOptionsFrame:IsShown() then
		FLogOptionsFrame:Show();
	end											
end);
FLogFrameOptions:SetAlpha(1);
FLogFrameOptions:Show();

local FLogFrameList = CreateFrame("BUTTON", nil, FLogFrame, "UIPanelButtonTemplate");
FLogFrameList:SetWidth(20);
FLogFrameList:SetHeight(20);
FLogFrameList:SetText("L");
FLogFrameList:SetPoint("TOPLEFT", 25, -5);
FLogFrameList:SetScript("OnClick", function()
	listMode = not listMode
	FLogRefreshSChildFrame()
end);
FLogFrameList:SetAlpha(1);
FLogFrameList:Show();

local FLogFrameClose = CreateFrame("BUTTON", nil, FLogFrame, "UIPanelButtonTemplate");
FLogFrameClose:SetWidth(15);
FLogFrameClose:SetHeight(15);
FLogFrameClose:SetText("X");
FLogFrameClose:SetPoint("TOPRIGHT", -5, -5);
FLogFrameClose:SetScript("OnClick", function()
											FLogFrame:Hide();
											FLogOptionsFrame:Hide();
											FLogHelpFrame:Hide();
										   end);
FLogFrameClose:SetAlpha(1);
FLogFrameClose:Show();

local FLogFrameHelp = CreateFrame("BUTTON", nil, FLogFrame, "UIPanelButtonTemplate");
FLogFrameHelp:SetWidth(15);
FLogFrameHelp:SetHeight(15);
FLogFrameHelp:SetText("?");
FLogFrameHelp:SetPoint("RIGHT", FLogFrameClose, "LEFT", -5, 0);
FLogFrameHelp:SetScript("OnClick", function()
											if FLogHelpFrame:IsShown() then
												FLogHelpFrame:Hide();
											else
												FLogHelpFrame:Show();
											end
										   end);
FLogFrameHelp:SetAlpha(1);
FLogFrameHelp:Show();

local FLogSFrame = CreateFrame("SCROLLFRAME", "FLogSFrame", FLogFrame, "UIPanelScrollFrameTemplate");
local FLogFrameSChild = CreateFrame("FRAME", "FLogFrameSChild", FLogSFrame);
FLogSFrame:SetScrollChild(FLogFrameSChild);
FLogSFrame:SetPoint("TOPLEFT", FLogFrame, "TOPLEFT", 10, -25);
FLogSFrame:SetWidth(FLogFrame:GetWidth() - 48);
FLogSFrame:SetHeight(FLogFrame:GetHeight() - 65);
FLogSFrame:SetHorizontalScroll(0);
FLogSFrame:SetVerticalScroll(20);
FLogSFrame:EnableMouse(true);
FLogSFrame:Show();
FLogFrameSChild:SetPoint("TOPLEFT");
FLogFrameSChild:SetWidth(FLogFrame:GetWidth() - 30);
FLogFrameSChild:SetHeight(50);
FLogFrameSChild:Show();

local FLogFrameClearButton = CreateFrame("BUTTON", "FLogFrameClearButton", FLogFrame, "UIPanelButtonTemplate");
FLogFrameClearButton:SetWidth(105);
FLogFrameClearButton:SetHeight(20);
FLogFrameClearButton:SetText(L["clear"]);
FLogFrameClearButton:SetPoint("BOTTOM", -55, 10);
FLogFrameClearButton:SetScript("OnClick", function() FLogResetFrame:Show(); end);
FLogFrameClearButton:SetAlpha(1);
FLogFrameClearButton:Show();

FLogFrameShowButton = CreateFrame("BUTTON", "FLogFrameShowButton", FLogFrame, "UIPanelButtonTemplate");
FLogFrameShowButton:SetWidth(105);
FLogFrameShowButton:SetHeight(20);
FLogFrameShowButton:SetText(L["Resume"])
FLogFrameShowButton:SetPoint("BOTTOM", 55, 10);
FLogFrameShowButton:SetScript("OnClick", function() ToggleLogging() end)
FLogFrameShowButton:SetAlpha(1);
FLogFrameShowButton:Show();

local FLogFrameResize = CreateFrame("BUTTON", "FLogFrameResize", FLogFrame);
FLogFrameResize:SetWidth(16);
FLogFrameResize:SetHeight(16);
FLogFrameResize:SetPoint("BOTTOMRIGHT", FLogFrame, "BOTTOMRIGHT", -2, 2);
FLogFrameResize:SetNormalTexture("Interface\\AddOns\\FarmLog\\FarmLogResizeButton");
FLogFrameResize:SetHighlightTexture("Interface\\AddOns\\FarmLog\\FarmLogResizeButton");
FLogFrameResize:SetScript("OnMouseDown", function()
													FLogFrame:StartSizing("BOTTOMRIGHT");
												end);
FLogFrameResize:SetScript("OnMouseUp", function()
												FLogFrame:StopMovingOrSizing();
												FLogFrameSChild:SetWidth(FLogFrame:GetWidth() - 30);
												FLogSFrame:SetWidth(FLogFrameSChild:GetWidth() - 18);
												FLogSFrame:SetHeight(FLogFrame:GetHeight() - 65);
												local point, _, _, x, y = FLogFrame:GetPoint();
												FLogVars["frameRect"]["point"] = point;													
												FLogVars["frameRect"]["x"] = x;
												FLogVars["frameRect"]["y"] = y;
												FLogVars["frameRect"]["width"] = FLogFrame:GetWidth();
												FLogVars["frameRect"]["height"] = FLogFrame:GetHeight();
											end);

local FLogFrameResize2 = CreateFrame("BUTTON", "FLogFrameResize2", FLogFrame);
FLogFrameResize2:SetWidth(16);
FLogFrameResize2:SetHeight(16);
FLogFrameResize2:SetPoint("BOTTOMLEFT", FLogFrame, "BOTTOMLEFT", 2, 2);
FLogFrameResize2:SetNormalTexture("Interface\\AddOns\\FarmLog\\FarmLogResizeButton2");
FLogFrameResize2:SetHighlightTexture("Interface\\AddOns\\FarmLog\\FarmLogResizeButton2");
FLogFrameResize2:SetScript("OnMouseDown", function()
													FLogFrame:StartSizing("BOTTOMLEFT");
												end);
FLogFrameResize2:SetScript("OnMouseUp", function()
												FLogFrame:StopMovingOrSizing();
												FLogFrameSChild:SetWidth(FLogFrame:GetWidth() - 30);
												FLogSFrame:SetWidth(FLogFrameSChild:GetWidth() - 18);
												FLogSFrame:SetHeight(FLogFrame:GetHeight() - 65);
												local point, _, _, x, y = FLogFrame:GetPoint();
												FLogVars["frameRect"]["point"] = point;													
												FLogVars["frameRect"]["x"] = x;
												FLogVars["frameRect"]["y"] = y;
												FLogVars["frameRect"]["width"] = FLogFrame:GetWidth();
												FLogVars["frameRect"]["height"] = FLogFrame:GetHeight();
											end);											

local FLogOptionsFrame = CreateFrame("FRAME", "FLogOptionsFrame", UIParent);
FLogOptionsFrame:SetWidth(FLogFrame:GetWidth());
FLogOptionsFrame:SetHeight(280);
FLogOptionsFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/DialogFrame/UI-Dialogbox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }});
FLogOptionsFrame:SetBackdropColor(0.0,0.0,0.0,0.9);
FLogOptionsFrame:SetPoint("TOPLEFT", FLogFrame, "BOTTOMLEFT", 0, 0);
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
		FLogFrame:RegisterForDrag("");
	elseif not FLogOptionsCheckButtonLockFrames:GetChecked() then
		FLogFrame:RegisterForDrag("LeftButton");
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
															InsertLoot(newName, editItem, sessionDrops[editName][editItem][editIdx][1]);
															sessionDrops[editName][editItem] = nil;
															local x = 0;
															for a, _ in pairs (sessionDrops[editName]) do																
																x = x + 1;
															end
															if x == 0 then
																sessionDrops[editName] = nil;
															end
														else
															InsertLoot(newName, editItem, sessionDrops[editName][editItem][editIdx][1]);
															tremove(sessionDrops[editName][editItem], editIdx);
														end
														FLogRefreshSChildFrame();
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
FLogHelpFrame:SetWidth(FLogFrame:GetWidth());
FLogHelpFrame:SetHeight(200);
if (GetLocale() == "deDE") then
	FLogHelpFrame:SetHeight(215);
end
FLogHelpFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/DialogFrame/UI-Dialogbox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }});
FLogHelpFrame:SetBackdropColor(0.0,0.0,0.0,0.9);
FLogHelpFrame:SetPoint("BOTTOM", FLogFrame, "TOP", 0, 0);
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

local function RecalcLootProfit()
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
	FLogRefreshSChildFrame()
end 

-- slash
SLASH_LH1 = "/farmlog";
SLASH_LH2 = "/fl";
SlashCmdList["LH"] = function(msg)
	local _, _, cmd, arg1 = string.find(msg, "([%w]+)%s*(.*)$");
	if not cmd then
		ToggleLogging()
	else 
		cmd = string.upper(cmd)
		if  "SHOW" == cmd or "S" == cmd then
			ToggleWindow()
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
				RecalcLootProfit()
			else 
				out("Incorrect usage of command write |cff00ff00/fl set [ITEM_LINK] [PRICE_GOLD]|r")
			end 
		elseif  "LIST" == cmd or "L" == cmd then
			out("Recorded sessions:")
			for sessionName, _ in pairs(FLogVars["sessions"]) do 
				out(" - |cff99ff00"..sessionName)
			end 
		elseif  "DELETE" == cmd then
			DeleteSession(arg1)
		elseif  "SWITCH" == cmd or "W" == cmd then
			if arg1 and #arg1 > 0 then 
				out("Switching session to |cff99ff00"..arg1)
				StartSession(arg1)
				FLogRefreshSChildFrame() 
			else 
				out("Wrong input, also write the name of the new session, as in |cff00ff00/fl w <session_name>")
			end 
		elseif  "REN" == cmd then
			out("Renaming session from |cff99ff00"..FLogVars["currentSession"].."|r to |cff99ff00"..arg1)
			FLogVars["sessions"][arg1] = FLogVars["sessions"][FLogVars["currentSession"]]
			FLogVars["sessions"][FLogVars["currentSession"]] = nil 
			FLogVars["currentSession"] = arg1 
			FLogRefreshSChildFrame() 
		elseif "ASI" == cmd then 
			FLogGlobalVars["autoSwitchInstances"] = not FLogGlobalVars["autoSwitchInstances"] 
			if not FLogGlobalVars["autoSwitchInstances"] then 
				out("Auto switching in instances |cffff4444"..L["disabled"])
			else 
				out("Auto switching in instances |cff44ff44"..L["enabled"])
			end 
		elseif  "RESET" == cmd or "R" == cmd then
			ResetSession()
		else 
			out("Unknown command "..cmd)
		end 
	end 
end
