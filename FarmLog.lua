FarmLogNS = {}
FarmLogNS.FLogVersionNumber = "1.0"
FarmLogNS.FLogVersion = "FarmLog v"..FarmLogNS.FLogVersionNumber
FarmLogNS.FLogVersionShort = "(v"..FarmLogNS.FLogVersionNumber..")"

FLogSVGold = 0
FLogSVDrops = {}
FLogSVKills = {}
FLogSVVendor = 0
FLogSVXP = 0
FLogSVRep = {}
FLogSVHonor = 0
FLogSVDebug = true
FLogSVEnabled = false
FLogSVStartTime = nil 
FLogSVTotalSeconds = 0

local inIni = false;
local lastIni = nil;
local editName = "";
local editItem = "";
local editIdx = -1;
local FLogMaxWidth = (GetScreenWidth() - 50);
local FLogMaxHeight = (GetScreenHeight() - 50);
local FLogMinWidth = (300);
local FLogMinHeight = (200);
local FLogFrameSChildContentTable = {};
local FLogFrameTitleText
local L = FarmLog_BuildLocalization(FarmLogNS)

local LastMobLoot = {}
local SkillName = nil 
local LastUpdate = 0

local SPELL_HERBING = 2366
local SPELL_MINING = 2575
local SPELL_FISHING = 7620

local function debug(text)
	if FLogSVDebug then 
		print("|cffffff00FarmLog|r "..text)
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

local function ToggleWindow()
	if FLogFrame:IsShown() then
		FLogFrame:Hide()
		FLogOptionsFrame:Hide()
	elseif not FLogFrame:IsShown() then
		FLogFrame:Show()
	end
end

local function ToggleLogging() 
	if FLogSVEnabled then 
		FLogSVEnabled = false 
		local delta = time() - FLogSVStartTime
		FLogSVTotalSeconds = FLogSVTotalSeconds + delta 
		FLogSVStartTime = nil

		FLogFrameTitleText:SetText(secondsToClock(FLogSVTotalSeconds));
		FLogFrameTitleText:SetTextColor(1, 0, 0, 1.0);
		print("|cffffff00Farm session ended|r")
	else 
		FLogSVEnabled = true 
		FLogSVStartTime = time()

		FLogFrameTitleText:SetTextColor(0, 1, 0, 1.0);
		print("|cffffff00Farm session started|r")
	end 
end 

local function AddToChatFrameEditBox(itemLink)
-- Copy itemLink into ChatFrame
	local x = {SELECTED_DOCK_FRAME:GetChildren()};
	local editbox = x[4];
	if editbox then
		if editbox:HasFocus() then
			editbox:SetText(editbox:GetText()..itemLink);
		else
			editbox:SetFocus(true);
			editbox:SetText(itemLink);
		end
	end
end

local function SortLog(db)
-- Sort the userNames of the FarmLog alphabetically.
-- return as table.
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

local function SortItems(db)
-- Sort the ItemLinks of the ItemIDs of the FLogSVDrops[mobName] alphabetically.
-- return as table.
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

local function SendReport(message)
	if FLogSVOptionReportTo["ChatFrame1"] then
		print(message);
	end
	if FLogSVOptionReportTo["Say"] then
		SendChatMessage(message, "SAY");
	end
	if FLogSVOptionReportTo["Yell"] then
		SendChatMessage(message, "YELL");
	end
	if FLogSVOptionReportTo["Party"] then
		if GetNumGroupMembers() > 0 then
			SendChatMessage(message, "PARTY");
		end
	end
	if ((FLogSVOptionReportTo["Raid"]) and (GetNumGroupMembers() > 0)) then
		SendChatMessage(message, "RAID");
	end
	if FLogSVOptionReportTo["Guild"] then
		local guild = GetGuildInfo("player");		
		if (not(guild == nil)) then
			SendChatMessage(message, "GUILD");
		end
	end
	if FLogSVOptionReportTo["Whisper"] then
		local h = FLogReportFrameWhisperBox:GetText();
		if (not (h == nil)) then
			SendChatMessage(message, "WHISPER", nil, h);
		end
	end
end

local function ReportSession()
	if (FLogSVDrops and FLogFrameSChildContentTable[1][0]:IsShown()) then
		local sortedNames = SortLog(FLogSVDrops);
		SendReport(L["Report"]..FarmLogNS.FLogVersionShort..":");
		SendReport(L["Report2"]..tostring(SVLastChange));
		for _, mobName in ipairs(sortedNames) do
			local FLogSortedItemLinks = SortItems(FLogSVDrops[mobName]);
			SendReport(mobName..":");
			for _, itemLink in ipairs(FLogSortedItemLinks) do				
				for j = 1, #FLogSVDrops[mobName][itemLink] do
					local report = "  "..itemLink;
					local quantity = FLogSVDrops[mobName][itemLink][j][1];
					local rollType = FLogSVDrops[mobName][itemLink][j][2];
					local roll = FLogSVDrops[mobName][itemLink][j][3];
					if quantity > 1 then
						report = report.."x"..quantity;
					end
					if (rollType == LOOT_ROLL_TYPE_NEED) then
						report = report.." ("..L["need"]..roll..")";
					elseif (rollType == LOOT_ROLL_TYPE_GREED) then
						report = report.." ("..L["greed"]..roll..")";
					elseif (rollType == LOOT_ROLL_TYPE_DISENCHANT) then
						report = report.." ("..L["disenchant"]..roll..")";
					end
					SendReport(report);
				end
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

local function RefreshSChildFrame()
--Refresh the SChildFrame
	local n = #FLogFrameSChildContentTable;
	local i = 1;

	local function AddItem(text) 
		if i > n then CreateSChild(1) end
		FLogFrameSChildContentTable[i][1]:SetText(text);
		FLogFrameSChildContentTable[i][2]:SetTexture(nil);
		FLogFrameSChildContentTable[i][3]:SetText("");
		FLogFrameSChildContentTable[i][0]:SetScript("OnEnter", nil);
		FLogFrameSChildContentTable[i][0]:SetScript("OnLeave", nil);
		FLogFrameSChildContentTable[i][0]:SetScript("OnMouseUp", nil);
		FLogFrameSChildContentTable[i][0]:Show();
		i = i + 1;
	end 

	if FLogSVGold > 0 then 
		AddItem(L["Money"])
		AddItem("    "..GetCoinTextureString(FLogSVGold))
	end 

	if FLogSVVendor > 0 then 
		AddItem(L["Vendor"])
		AddItem("    "..GetCoinTextureString(FLogSVVendor))
	end 

	if FLogSVXP > 0 then 
		AddItem(L["XP"])
		AddItem("    "..FLogSVXP)
	end 

	for faction, rep in pairs(FLogSVRep) do 
		AddItem(faction)
		AddItem("    "..rep.." "..L["reputation"])
	end 

	local sortedNames = SortLog(FLogSVKills);
	-- add missing mobNames like Herbalism / Mining / Fishing
	for name, _ in pairs(FLogSVDrops) do 
		if not FLogSVKills[name] then 
			tinsert(sortedNames, 1, name)
		end 
	end 
	for _, mobName in ipairs(sortedNames) do	
		local FLogSortedItemLinks = SortItems(FLogSVDrops[mobName] or {});	
		local section = mobName 
		if FLogSVKills[mobName] then 
			section = section .. " x" .. FLogSVKills[mobName]
		end 
		AddItem(section)	
		for _, itemLink in ipairs(FLogSortedItemLinks) do			
			for j = 1, #FLogSVDrops[mobName][itemLink] do
				if i > n then
					CreateSChild(1);
				end
				local quantity = FLogSVDrops[mobName][itemLink][j][1];
				-- local rollType = FLogSVDrops[mobName][itemLink][j][2];
				-- local roll = FLogSVDrops[mobName][itemLink][j][3];
				if quantity > 1 then
					FLogFrameSChildContentTable[i][1]:SetText("    "..itemLink.." x"..quantity);
					FLogFrameSChildContentTable[i][2]:SetTexture(nil);
					FLogFrameSChildContentTable[i][3]:SetText("");
				elseif quantity == 1 then
					FLogFrameSChildContentTable[i][1]:SetText("    "..itemLink);
					FLogFrameSChildContentTable[i][2]:SetTexture(nil);
					FLogFrameSChildContentTable[i][3]:SetText("");
				end				
				if (rollType == LOOT_ROLL_TYPE_NEED) then
					FLogFrameSChildContentTable[i][2]:SetTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up");
					FLogFrameSChildContentTable[i][3]:SetText(roll);
				elseif (rollType == LOOT_ROLL_TYPE_GREED) then
					FLogFrameSChildContentTable[i][2]:SetTexture("Interface\\Buttons\\UI-GroupLoot-Coin-Up");
					FLogFrameSChildContentTable[i][3]:SetText(roll);
				elseif (rollType == LOOT_ROLL_TYPE_DISENCHANT) then
					FLogFrameSChildContentTable[i][2]:SetTexture("Interface\\Buttons\\UI-GroupLoot-DE-Up");
					FLogFrameSChildContentTable[i][3]:SetText(roll);
				elseif (rollType == LOOT_ROLL_TYPE_PASS) then
					FLogFrameSChildContentTable[i][2]:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up");
				else
					FLogFrameSChildContentTable[i][2]:SetTexture(nil);
				end								
				FLogFrameSChildContentTable[i][0]:SetScript("OnEnter", function(self)
													self:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background"});
													self:SetBackdropColor(0.8,0.8,0.8,0.9);
													if FLogSVTooltip then
														GameTooltip:SetOwner(self, "ANCHOR_LEFT");
														GameTooltip:SetHyperlink(itemLink);
														GameTooltip:Show();
													end
													end);
				FLogFrameSChildContentTable[i][0]:SetScript("OnLeave", function(self)
													if FLogSVTooltip then
														GameTooltip_Hide();
													end
													self:SetBackdrop(nil);
												end);				
				FLogFrameSChildContentTable[i][0]:SetScript("OnMouseUp", function(self, button)
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
												end);
				FLogFrameSChildContentTable[i][0]:Show();
				i = i + 1;
			end
		end		
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

local function ClearLog()	
	FLogSVDrops = {}
	FLogSVKills = {}
	FLogSVGold = 0
	FLogSVVendor = 0
	FLogSVXP = 0
	FLogSVHonor = 0
	FLogSVRep = {}
	if FLogSVStartTime then 
		FLogSVStartTime = time()
	end 
	FLogSVTotalSeconds = 0

	HideSChildFrame(1);
	FLogFrameShowButton:Disable();
	FLogFrameClearButton:Disable();
	SVLastChange = date("%d.%m.%y - %H:%M");
end

local function tinsert(mobName, itemLink, quantity, rollType, roll)
-- inserts into FLogSVDrops
	-- print(tostring(mobName)..", "..tostring(itemLink)..", "..tostring(quantity)..", "..tostring(rollType)..", "..tostring(roll));
	if (mobName and itemLink and quantity and rollType and roll) then		
		if FLogSVDrops[mobName] then		
			if FLogSVDrops[mobName][itemLink] then				
				if rollType == -1 then
					local f = -1;
					for i = 1, #FLogSVDrops[mobName][itemLink] do
						if FLogSVDrops[mobName][itemLink][i][2] == -1 then
							f = i;
							i = #FLogSVDrops[mobName][itemLink] + 1;
						end
					end
					if f > 0 then
						FLogSVDrops[mobName][itemLink][f][1] = FLogSVDrops[mobName][itemLink][f][1] + quantity;
						SVLastChange = date("%d.%m.%y - %H:%M");
					else
						tinsert(FLogSVDrops[mobName][itemLink], {quantity, rollType, roll});
						SVLastChange = date("%d.%m.%y - %H:%M");
					end
				else
					tinsert(FLogSVDrops[mobName][itemLink], {quantity, rollType, roll});
					SVLastChange = date("%d.%m.%y - %H:%M");
				end
			else
				FLogSVDrops[mobName][itemLink] = {{quantity, rollType, roll}};
				SVLastChange = date("%d.%m.%y - %H:%M");
			end
		else
			FLogSVDrops[mobName] = {};
			FLogSVDrops[mobName][itemLink] = {{quantity, rollType, roll}};
			SVLastChange = date("%d.%m.%y - %H:%M");
		end
	end
end

-- EVENTS ----------------------------------------------------------------------------------------

-- Spell cast 

local function OnSpellCastEvent(unit, target, guid, spellId)
	if spellId == SPELL_HERBING then 
		SkillName = L["Herbalism"]
	elseif spellId == SPELL_MINING then 
		SkillName = L["Mining"]
	elseif spellId == SPELL_FISHING then 
		SkillName = L["Fishing"]
	else 
		SkillName = nil 
	end 
end 

-- Honor event

local function OnCombatHonorEvent(text, playerName, languageName, channelName, playerName2, specialFlags)
	debug("OnCombatHonorEvent - text:"..text.." playerName:"..playerName.." languageName:"..languageName.." channelName:"..channelName.." playerName2:"..playerName2.." specialFlags:"..specialFlags)
end 

-- XP events

local XPGainStrings = {
	_G.COMBATLOG_XPGAIN_EXHAUSTION1,
	_G.COMBATLOG_XPGAIN_EXHAUSTION2,
	_G.COMBATLOG_XPGAIN_EXHAUSTION4,
	_G.COMBATLOG_XPGAIN_EXHAUSTION5,
	_G.COMBATLOG_XPGAIN_FIRSTPERSON,
	_G.COMBATLOG_XPGAIN_FIRSTPERSON_GROUP,
	_G.COMBATLOG_XPGAIN_FIRSTPERSON_RAID,
}

local function ParseXPEvent(chatmsg)
	for _, xpString in ipairs(XPGainStrings) do
		local mobName, amount = FLogDeformat(chatmsg, xpString)
		if amount then
			return amount
		end
	end
end

local function OnCombatXPEvent(text)
	local xp = ParseXPEvent(text)
	-- debug("OnCombatXPEvent - text:"..text.." playerName:"..playerName.." languageName:"..languageName.." channelName:"..channelName.." playerName2:"..playerName2.." specialFlags:"..specialFlags)
	FLogSVXP = (FLogSVXP or 0) + xp 
	RefreshSChildFrame()
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
	FLogSVRep[faction] = (FLogSVRep[faction] or 0) + rep 
	RefreshSChildFrame()
end 

-- Combat log event

local function OnCombatLogEvent()
	local eventInfo = {CombatLogGetCurrentEventInfo()}
	local eventName = eventInfo[2]
	if eventName == "PARTY_KILL" then 
		local mobName = eventInfo[9]
		FLogSVKills[mobName] = (FLogSVKills[mobName] or 0) + 1
		-- debug("Player "..eventInfo[5].." killed "..eventInfo[9].." x "..tostring(FLogSVKills[mobName]))
		RefreshSChildFrame()
	end 
end 

-- Loot window event

local function OnLootOpened(autoLoot)
	local lootCount = GetNumLootItems()
	local mobName = UnitName("target")
	if not mobName and IsFishingLoot() then mobName = L["Fishing"] end 
	if not mobName and SkillName then mobName = SkillName end 
	LastMobLoot = {}
	SkillName = nil 
	for i = 1, lootCount do 
		local link = GetLootSlotLink(i)
		if link then 
			LastMobLoot[link] = mobName
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
	_G.LOOT_MONEY_REFUND,
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
	FLogSVGold = FLogSVGold + money 
	RefreshSChildFrame()
end 

-- Loot receive event

local function OnLootEvent(arg1)
	-- parse the chat-message and add the item to the FLogSVDrops, if the following conditions are fullfilled.
	local startIndex, _ = string.find(arg1, "%|c");
	local _, endIndex = string.find(arg1, "%]%|h%|r");
	local itemLink = string.sub(arg1, startIndex, endIndex);	
	local _, _, itemRarity, _, _, itemType, _, _, _, _, vendorPrice = GetItemInfo(itemLink);

	mobName = LastMobLoot[itemLink] or "Unknown"

	local receiver = string.sub(arg1, 0, (string.find(arg1, " ")-1))

	local inRaid = IsInRaid();
	local inParty = false;
	if GetNumGroupMembers() > 0 then
		inParty = true;
	end
	if (
		-- ((FLogSVOptionGroupType["Raid"] and inRaid) or 
		-- (FLogSVOptionGroupType["Party"] and inParty and not inRaid) or
		-- (FLogSVOptionGroupType["Solo"] and not inParty and not inRaid))
		-- and 
		receiver == L["you"] and 
		itemType ~= "Money" and 
		(
			(FLogSVItemRarity[0] and itemRarity == 0) or
			(FLogSVItemRarity[1] and itemRarity == 1) or
			(FLogSVItemRarity[2] and itemRarity == 2) or
			(FLogSVItemRarity[3] and itemRarity == 3) or
			(FLogSVItemRarity[4] and itemRarity == 4) or
			(FLogSVItemRarity[5] and itemRarity == 5) or
			(FLogSVItemRarity[6] and itemRarity == 6) or 
			mobName == L["Herbalism"] or 
			mobName == L["Mining"] or 
			mobName == L["Fishing"] 
		)) 
	then	
		-- parse quantity from chat-message
		local quantity = 1;		
		if ((endIndex + 2 ) <= (#arg1 - 1)) then
			quantity = tonumber(string.sub(arg1, endIndex + 2, #arg1 - 1));
		end				
		
		FLogSVVendor = (FLogSVVendor or 0) + (vendorPrice or 0)

		tinsert(mobName, itemLink, quantity, -1, -1);
		RefreshSChildFrame();
	end
end

-- Addon Loaded

local function OnAddonLoaded()
	print(L["loaded-welcome"]);
	if FLogSVItemRarity == nil then
		FLogSVItemRarity = {};
		FLogSVItemRarity[0]=false; --poor (grey)
		FLogSVItemRarity[1]=false; --common (white)
		FLogSVItemRarity[2]=true; --uncommon (green)
		FLogSVItemRarity[3]=true; --rare (blue)
		FLogSVItemRarity[4]=true; --epic (purple)
		FLogSVItemRarity[5]=true; --legendary (orange)
		FLogSVItemRarity[6]=false; --artifact
		--FLogSVItemRarity[7]=false; --heirloom
	end
	if FLogSVOptionReportTo == nil then
		FLogSVOptionReportTo = {};
		FLogSVOptionReportTo["ChatFrame1"]=true;
		FLogSVOptionReportTo["Say"]=false;
		FLogSVOptionReportTo["Yell"]=false;
		FLogSVOptionReportTo["Party"]=false;
		FLogSVOptionReportTo["Raid"]=false;
		FLogSVOptionReportTo["Guild"]=false;
		FLogSVOptionReportTo["Whisper"]=false;
	end
	if FLogSVOptionGroupType == nil then 
		FLogSVOptionGroupType = {};
		FLogSVOptionGroupType["Solo"]=false;
		FLogSVOptionGroupType["Party"]=true;
		FLogSVOptionGroupType["Raid"]=true;
	end
	if FLogSVLockFrames == nil then
		FLogSVLockFrames = false;
	end
	if FLogSVLockMinimapButton == nil then
		FLogSVLockMinimapButton = false;
	end
	if FLogSVFrame == nil then
		FLogSVFrame = {};
		FLogSVFrame["width"] = 250;
		FLogSVFrame["height"] = 200;
		FLogSVFrame["point"] = "CENTER";
		FLogSVFrame["x"] = 0;
		FLogSVFrame["y"] = 0;
	end
	if FLogSVMinimapButtonPosition == nil then
		FLogSVMinimapButtonPosition = {};
		FLogSVMinimapButtonPosition["point"] = "TOP";
		FLogSVMinimapButtonPosition["x"] = 0;
		FLogSVMinimapButtonPosition["y"] = 0;
	end
	if FLogSVEnableMinimapButton == nil then
		FLogSVEnableMinimapButton = true;
	end
	if FLog_LockShowLootFrame == nil then
		FLog_LockShowLootFrame = false;
	end	
	if FLogSVTooltip == nil then
		FLogSVTooltip = true;
	end
	--compatibility fix for older Versions ( < 3.0)
	if SVVersion == nil then
		print(L["updated"]);
		print(L["updated2"]);
		ClearLog();
		SVVersion = tonumber(FarmLogNS.FLogVersionNumber);
	else
		if SVVersion < 1.0 then
			print(L["updated"]);
			print(L["updated2"]);
			ClearLog();
			SVVersion = tonumber(FarmLogNS.FLogVersionNumber);
		elseif SVVersion < tonumber(FarmLogNS.FLogVersionNumber) then
			print(L["updated"]);
			SVVersion = tonumber(FarmLogNS.FLogVersionNumber);
		elseif SVVersion > tonumber(FarmLogNS.FLogVersionNumber) then
			print(L["updated"]);
			SVVersion = tonumber(FarmLogNS.FLogVersionNumber);
		end
	end
	if SVLastChange == nil then
		SVLastChange = date("%d.%m.%y - %H:%M");
	end
	
	FLogOptionsCheckButtonLog0:SetChecked(FLogSVItemRarity[0]);
	FLogOptionsCheckButtonLog1:SetChecked(FLogSVItemRarity[1]);
	FLogOptionsCheckButtonLog2:SetChecked(FLogSVItemRarity[2]);
	FLogOptionsCheckButtonLog3:SetChecked(FLogSVItemRarity[3]);
	FLogOptionsCheckButtonLog4:SetChecked(FLogSVItemRarity[4]);
	FLogOptionsCheckButtonLog5:SetChecked(FLogSVItemRarity[5]);
	FLogOptionsCheckButtonLog6:SetChecked(FLogSVItemRarity[6]);
	
	FLogOptionsCheckButtonLogSolo:SetChecked(FLogSVOptionGroupType["Solo"]);
	FLogOptionsCheckButtonLogParty:SetChecked(FLogSVOptionGroupType["Party"]);
	FLogOptionsCheckButtonLogRaid:SetChecked(FLogSVOptionGroupType["Raid"]);
	
	FLogReportFrameCheckButtonChatFrame:SetChecked(FLogSVOptionReportTo["ChatFrame1"]);
	FLogReportFrameCheckButtonSay:SetChecked(FLogSVOptionReportTo["Say"]);
	FLogReportFrameCheckButtonYell:SetChecked(FLogSVOptionReportTo["Yell"]);
	FLogReportFrameCheckButtonParty:SetChecked(FLogSVOptionReportTo["Party"]);
	FLogReportFrameCheckButtonRaid:SetChecked(FLogSVOptionReportTo["Raid"]);
	FLogReportFrameCheckButtonGuild:SetChecked(FLogSVOptionReportTo["Guild"]);
	FLogReportFrameCheckButtonWhisper:SetChecked(FLogSVOptionReportTo["Whisper"]);
	
	FLogOptionsCheckButtonLockFrames:SetChecked(FLogSVLockFrames);
	FLogOptionsCheckButtonEnableMinimapButton:SetChecked(FLogSVEnableMinimapButton);
	FLogOptionsCheckButtonLockMinimapButton:SetChecked(FLogSVLockMinimapButton);
	FLogOptionsCheckButtonTooltip:SetChecked(FLogSVTooltip);	
	
	FLogFrame:SetWidth(FLogSVFrame["width"]);
	FLogFrame:SetHeight(FLogSVFrame["height"]);
	FLogFrame:SetPoint(FLogSVFrame["point"], FLogSVFrame["x"], FLogSVFrame["y"]);
	
	if FLogSVEnabled then 
		FLogFrameTitleText:SetTextColor(0, 1, 0, 1.0);
	else 
		FLogFrameTitleText:SetTextColor(1, 0, 0, 1.0);
	end 
	FLogFrameTitleText:SetText(secondsToClock(FLogSVTotalSeconds));

	if not FLogSVLockFrames then		
		FLogTopFrame:RegisterForDrag("LeftButton");			
	end
			
	FLogMinimapButton:SetPoint(FLogSVMinimapButtonPosition["point"], Minimap, FLogSVMinimapButtonPosition["x"], FLogSVMinimapButtonPosition["y"]);
	if FLogSVEnableMinimapButton then
		FLogMinimapButton:Show();
	else
		FLogMinimapButton:Hide();
	end	
	if not FLogSVLockMinimapButton then		
		FLogMinimapButton:RegisterForDrag("LeftButton");			
	end
	RefreshSChildFrame();
end 

-- Entering World

local function OnEnteringWorld() 
	local inInstance, _ = IsInInstance();
	inInstance = tobool(inInstance);
	local iniName = GetInstanceInfo();		
	if ((inIni == false and inInstance) and not(lastIni == iniName)) then
		inIni = true;
		lastIni = iniName;
		if ((IsInRaid() and FLogSVOptionGroupType["Raid"]) or (UnitInParty("Player") and not IsInRaid() and FLogSVOptionGroupType["Party"]) or (FLogSVOptionGroupType["Solo"] and not IsInRaid() and not UnitInParty("Player"))) then
			FLogResetFrame:Show();
		end
	elseif (inIni and inInstance == false) then
		inIni = false;			
	end
	RefreshSChildFrame();
end 

-- OnEvent

local function OnEvent(event, ...)
	if FLogSVEnabled then 
		if event == "LOOT_OPENED" then
			OnLootOpened(...);			
		elseif event == "CHAT_MSG_LOOT" then
			if (... and (strfind(..., L["loot"]))) then
				OnLootEvent(...);			
			end	
		elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN" then 
			OnCombatHonorEvent(...);			
		elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then 
			OnCombatXPEvent(...);			
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
		OnEnteringWorld()
	elseif (event == "ADDON_LOADED" and ... == "FarmLog") then		
		OnAddonLoaded()
	end
end

local function OnUpdate() 
	if FLogSVEnabled then 
		local now = time()
		if now - LastUpdate >= 1 then 
			FLogFrameTitleText:SetText(secondsToClock(FLogSVTotalSeconds + now - FLogSVStartTime));
			LastUpdate = now 
		end 
	end 
end 

--LDB
local ldb = LibStub:GetLibrary("LibDataBroker-1.1");
local dataobj = ldb:GetDataObjectByName("FarmLog") or ldb:NewDataObject("FarmLog", {
	type = "data source", icon = [[Interface\AddOns\FarmLog\FarmLogLDBIcon]], text = "FarmLog",
	OnClick = function(self, button)
				if button == "RightButton" then
					ToggleLogging()
				else
					ToggleWindow()
				end
	end,
	OnTooltipShow = function(tip)
		tip:AddLine(L["LDBClick"]);
	end,
})
--end LDB

-- begin UI
local FLogMinimapButton = CreateFrame("BUTTON", "FLogMinimapButton", Minimap);
FLogMinimapButton:SetWidth(31);
FLogMinimapButton:SetHeight(31);
FLogMinimapButton:SetFrameStrata("LOW");
FLogMinimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight");
FLogMinimapButton:SetPoint("RIGHT", Minimap, "LEFT");
FLogMinimapButtonIcon = FLogMinimapButton:CreateTexture(nil, "BACKGROUND");
FLogMinimapButtonIcon:SetTexture("Interface\\AddOns\\FarmLog\\FarmLogIcon");
FLogMinimapButtonIcon:SetPoint("TOPLEFT", 6, -6);
FLogMinimapButtonIcon:SetPoint("BOTTOMRIGHT", -6, 6);
FLogMinimapButtonOverlay = FLogMinimapButton:CreateTexture(nil, "OVERLAY");
FLogMinimapButtonOverlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder");
FLogMinimapButtonOverlay:SetWidth(53);
FLogMinimapButtonOverlay:SetHeight(53);
FLogMinimapButtonOverlay:SetPoint("TOPLEFT");
FLogMinimapButton:SetMovable(true);
FLogMinimapButton:EnableMouse(true);
FLogMinimapButton:SetScript("OnDragStart", function() FLogMinimapButton:StartMoving() end);
FLogMinimapButton:SetScript("OnDragStop", function()
													FLogMinimapButton:StopMovingOrSizing();
													local point, relativeTo, relativePoint, x, y = FLogMinimapButton:GetPoint();
													FLogSVMinimapButtonPosition["point"] = point;													
													FLogSVMinimapButtonPosition["x"] = x;
													FLogSVMinimapButtonPosition["y"] = y;
												 end);
FLogMinimapButton:SetScript("OnClick", function(self, button)											
											if button == "RightButton" then
												FarmLogToggle();
											else
												ToggleWindow();
											end
										end);
FLogMinimapButton:Hide();

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
														ClearLog();
														FLogResetFrame:Hide();
												end);
FLogResetFrameYesButton:SetAlpha(1);
FLogResetFrameYesButton:Show();

local FLogFrame = CreateFrame("FRAME", "FLogFrame", UIParent);
FLogFrame:SetFrameStrata("HIGH"); 
FLogFrame:RegisterEvent("ADDON_LOADED");
FLogFrame:RegisterEvent("CHAT_MSG_LOOT");
FLogFrame:RegisterEvent("LOOT_OPENED")
FLogFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
FLogFrame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
FLogFrame:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")
FLogFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
FLogFrame:RegisterEvent("CHAT_MSG_CURRENCY")
FLogFrame:RegisterEvent("CHAT_MSG_MONEY")
FLogFrame:RegisterEvent("UNIT_SPELLCAST_SENT")
FLogFrame:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
--FLogFrame:RegisterEvent("LOOT_ROLLS_COMPLETE");
FLogFrame:SetScript("OnEvent", function(self, event, ...) OnEvent(event, ...) end);
FLogFrame:SetScript("OnUpdate", function(self, ...) OnUpdate(...) end);
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
FLogFrame:SetMaxResize(FLogMaxWidth, FLogMaxHeight);
FLogFrame:SetMinResize(FLogMinWidth, FLogMinHeight);										  
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
											FLogSVFrame["point"] = point;													
											FLogSVFrame["x"] = x;
											FLogSVFrame["y"] = y;
											FLogSVFrame["width"] = FLogFrame:GetWidth();
											FLogSVFrame["height"] = FLogFrame:GetHeight();
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
FLogFrameOptions:SetWidth(15);
FLogFrameOptions:SetHeight(15);
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

local FLogFrameShowButton = CreateFrame("BUTTON", "FLogFrameShowButton", FLogFrame, "UIPanelButtonTemplate");
FLogFrameShowButton:SetWidth(105);
FLogFrameShowButton:SetHeight(20);
FLogFrameShowButton:SetText(L["report"]);
FLogFrameShowButton:SetPoint("BOTTOM", 55, 10);
FLogFrameShowButton:SetScript("OnClick", function()if FLogReportFrame:IsShown() then
													FLogReportFrame:Hide();													
												elseif not FLogReportFrame:IsShown() then
													FLogReportFrame:Show();
												end	
												end);
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
												FLogSVFrame["point"] = point;													
												FLogSVFrame["x"] = x;
												FLogSVFrame["y"] = y;
												FLogSVFrame["width"] = FLogFrame:GetWidth();
												FLogSVFrame["height"] = FLogFrame:GetHeight();
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
												FLogSVFrame["point"] = point;													
												FLogSVFrame["x"] = x;
												FLogSVFrame["y"] = y;
												FLogSVFrame["width"] = FLogFrame:GetWidth();
												FLogSVFrame["height"] = FLogFrame:GetHeight();
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
FLogOptionsCheckButtonLog0:SetScript("OnClick", function() FLogSVItemRarity[0] = tobool(FLogOptionsCheckButtonLog0:GetChecked()); end);
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
FLogOptionsCheckButtonLog1:SetScript("OnClick", function() FLogSVItemRarity[1] = tobool(FLogOptionsCheckButtonLog1:GetChecked()); end);
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
FLogOptionsCheckButtonLog2:SetScript("OnClick", function() FLogSVItemRarity[2] = tobool(FLogOptionsCheckButtonLog2:GetChecked()); end);
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
FLogOptionsCheckButtonLog3:SetScript("OnClick", function() FLogSVItemRarity[3] = tobool(FLogOptionsCheckButtonLog3:GetChecked()); end);
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
FLogOptionsCheckButtonLog4:SetScript("OnClick", function() FLogSVItemRarity[4] = tobool(FLogOptionsCheckButtonLog4:GetChecked()); end);
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
FLogOptionsCheckButtonLog5:SetScript("OnClick", function() FLogSVItemRarity[5] = tobool(FLogOptionsCheckButtonLog5:GetChecked()); end);
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
FLogOptionsCheckButtonLog6:SetScript("OnClick", function() FLogSVItemRarity[6] = tobool(FLogOptionsCheckButtonLog6:GetChecked()); end);
FLogOptionsCheckButtonLog6:Show();

local FLogOptionsLogSolo = FLogOptionsFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogOptionsLogSolo:SetTextColor(1, 1, 1, 0.8);
FLogOptionsLogSolo:SetWidth(175);
FLogOptionsLogSolo:SetHeight(15);
FLogOptionsLogSolo:SetJustifyH("LEFT");
FLogOptionsLogSolo:SetText(L["solo"]);
FLogOptionsLogSolo:SetPoint("TOP", FLogOptionsLog6, "BOTTOM", 0, -10);

local FLogOptionsCheckButtonLogSolo = CreateFrame("CHECKBUTTON", "FLogOptionsCheckButtonLogSolo", FLogOptionsFrame);
FLogOptionsCheckButtonLogSolo:SetWidth(15);
FLogOptionsCheckButtonLogSolo:SetHeight(15);
FLogOptionsCheckButtonLogSolo:SetPoint("RIGHT", FLogOptionsLogSolo, "LEFT", -5, 0);
FLogOptionsCheckButtonLogSolo:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
FLogOptionsCheckButtonLogSolo:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
FLogOptionsCheckButtonLogSolo:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD");
FLogOptionsCheckButtonLogSolo:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
FLogOptionsCheckButtonLogSolo:SetScript("OnClick", function() FLogSVOptionGroupType["Solo"] = tobool(FLogOptionsCheckButtonLogSolo:GetChecked()); end);
FLogOptionsCheckButtonLogSolo:Show();

local FLogOptionsLogParty = FLogOptionsFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogOptionsLogParty:SetTextColor(1, 1, 1, 0.8);
FLogOptionsLogParty:SetWidth(175);
FLogOptionsLogParty:SetHeight(15);
FLogOptionsLogParty:SetJustifyH("LEFT");
FLogOptionsLogParty:SetText(L["party"]);
FLogOptionsLogParty:SetPoint("TOP", FLogOptionsLogSolo, "BOTTOM", 0, 0);

local FLogOptionsCheckButtonLogParty = CreateFrame("CHECKBUTTON", "FLogOptionsCheckButtonLogParty", FLogOptionsFrame);
FLogOptionsCheckButtonLogParty:SetWidth(15);
FLogOptionsCheckButtonLogParty:SetHeight(15);
FLogOptionsCheckButtonLogParty:SetPoint("RIGHT", FLogOptionsLogParty, "LEFT", -5, 0);
FLogOptionsCheckButtonLogParty:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
FLogOptionsCheckButtonLogParty:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
FLogOptionsCheckButtonLogParty:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD");
FLogOptionsCheckButtonLogParty:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
FLogOptionsCheckButtonLogParty:SetScript("OnClick", function() FLogSVOptionGroupType["Party"] = tobool(FLogOptionsCheckButtonLogParty:GetChecked()); end);
FLogOptionsCheckButtonLogParty:Show();

local FLogOptionsLogRaid = FLogOptionsFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogOptionsLogRaid:SetTextColor(1, 1, 1, 0.8);
FLogOptionsLogRaid:SetWidth(175);
FLogOptionsLogRaid:SetHeight(15);
FLogOptionsLogRaid:SetJustifyH("LEFT");
FLogOptionsLogRaid:SetText(L["raid"]);
FLogOptionsLogRaid:SetPoint("TOP", FLogOptionsLogParty, "BOTTOM", 0, 0);

local FLogOptionsCheckButtonLogRaid = CreateFrame("CHECKBUTTON", "FLogOptionsCheckButtonLogRaid", FLogOptionsFrame);
FLogOptionsCheckButtonLogRaid:SetWidth(15);
FLogOptionsCheckButtonLogRaid:SetHeight(15);
FLogOptionsCheckButtonLogRaid:SetPoint("RIGHT", FLogOptionsLogRaid, "LEFT", -5, 0);
FLogOptionsCheckButtonLogRaid:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
FLogOptionsCheckButtonLogRaid:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
FLogOptionsCheckButtonLogRaid:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD");
FLogOptionsCheckButtonLogRaid:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
FLogOptionsCheckButtonLogRaid:SetScript("OnClick", function() FLogSVOptionGroupType["Raid"] = tobool(FLogOptionsCheckButtonLogRaid:GetChecked()); end);
FLogOptionsCheckButtonLogRaid:Show();

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
																FLogSVLockFrames = tobool(FLogOptionsCheckButtonLockFrames:GetChecked());
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
																		FLogSVEnableMinimapButton = tobool(FLogOptionsCheckButtonEnableMinimapButton:GetChecked());
																		if FLogOptionsCheckButtonEnableMinimapButton:GetChecked() then
																			FLogMinimapButton:Show();
																		elseif not FLogOptionsCheckButtonEnableMinimapButton:GetChecked() then
																			FLogMinimapButton:Hide();
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
																		FLogSVLockMinimapButton = tobool(FLogOptionsCheckButtonLockMinimapButton:GetChecked());
																		if FLogOptionsCheckButtonLockMinimapButton:GetChecked() then
																			FLogMinimapButton:RegisterForDrag(""); 
																		elseif not FLogOptionsCheckButtonLockMinimapButton:GetChecked() then																			
																			FLogMinimapButton:RegisterForDrag("LeftButton");
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
															FLogSVTooltip = tobool(FLogOptionsCheckButtonTooltip:GetChecked());
														end);
FLogOptionsCheckButtonTooltip:Show();

local FLogReportFrame = CreateFrame("FRAME", "FLogReportFrame", UIParent);
FLogReportFrame:SetFrameStrata("HIGH"); 
FLogReportFrame:SetWidth(200);
FLogReportFrame:SetHeight(210);
FLogReportFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/DialogFrame/UI-Dialogbox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }});
FLogReportFrame:SetBackdropColor(0.0,0.0,0.0,0.9);
FLogReportFrame:SetPoint("CENTER");
FLogReportFrame:EnableMouse(true);
FLogReportFrame:RegisterForDrag("LeftButton");
FLogReportFrame:SetMovable(true);
FLogReportFrame:SetUserPlaced(true);
FLogReportFrame:SetScript("OnDragStart", function(this) this:StartMoving(); end);
FLogReportFrame:SetScript("OnDragStop", function(this) this:StopMovingOrSizing(); end);
FLogReportFrame:Hide();
tinsert(UISpecialFrames, FLogReportFrame:GetName());

local FLogReportFrameTop = CreateFrame("FRAME", nil, FLogReportFrame);
FLogReportFrameTop:SetWidth(120);
FLogReportFrameTop:SetHeight(25);
FLogReportFrameTop:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/DialogFrame/UI-Dialogbox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }});
FLogReportFrameTop:SetBackdropColor(0.0,0.0,0.0,0.9);
FLogReportFrameTop:SetPoint("TOP", 0, 10);
FLogReportFrameTop:Show();

local FLogReportFrameText = FLogReportFrameTop:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogReportFrameText:SetTextColor(1, 0, 0, 1.0);
FLogReportFrameText:SetText(L["Report"]);
FLogReportFrameText:SetPoint("CENTER");

local FLogReportFrameClose = CreateFrame("BUTTON", nil, FLogReportFrame, "UIPanelButtonTemplate");
FLogReportFrameClose:SetWidth(15);
FLogReportFrameClose:SetHeight(15);
FLogReportFrameClose:SetText("X");
FLogReportFrameClose:SetPoint("TOPRIGHT", -5, -5);
FLogReportFrameClose:SetScript("OnClick", function()
											FLogReportFrame:Hide();											
										   end);
FLogReportFrameClose:SetAlpha(1);
FLogReportFrameClose:Show();

local FLogReportFrameText = FLogReportFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogReportFrameText:SetTextColor(1.0, 0.8, 0, 0.8);
FLogReportFrameText:SetWidth(175);
FLogReportFrameText:SetJustifyH("LEFT");
FLogReportFrameText:SetText(L["Report:"]);
FLogReportFrameText:SetPoint("TOPLEFT", 5, -30);

local FLogReportFrameChatFrame = FLogReportFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogReportFrameChatFrame:SetTextColor(1, 1, 1, 0.8);
FLogReportFrameChatFrame:SetWidth(175);
FLogReportFrameChatFrame:SetHeight(15);
FLogReportFrameChatFrame:SetJustifyH("LEFT");
FLogReportFrameChatFrame:SetText(L["ChatFrame1"]);
FLogReportFrameChatFrame:SetPoint("TOP", FLogReportFrameText, "BOTTOM", 25, -5);

local FLogReportFrameCheckButtonChatFrame = CreateFrame("CHECKBUTTON", "FLogReportFrameCheckButtonChatFrame", FLogReportFrame);
FLogReportFrameCheckButtonChatFrame:SetWidth(15);
FLogReportFrameCheckButtonChatFrame:SetHeight(15);
FLogReportFrameCheckButtonChatFrame:SetPoint("RIGHT", FLogReportFrameChatFrame, "LEFT", -5, 0);
FLogReportFrameCheckButtonChatFrame:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
FLogReportFrameCheckButtonChatFrame:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
FLogReportFrameCheckButtonChatFrame:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD");
FLogReportFrameCheckButtonChatFrame:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
FLogReportFrameCheckButtonChatFrame:SetScript("OnClick", function() FLogSVOptionReportTo["ChatFrame1"] = tobool(FLogReportFrameCheckButtonChatFrame:GetChecked()); end);
FLogReportFrameCheckButtonChatFrame:Show();

local FLogReportFrameSay = FLogReportFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogReportFrameSay:SetTextColor(1, 1, 1, 0.8);
FLogReportFrameSay:SetWidth(175);
FLogReportFrameSay:SetHeight(15);
FLogReportFrameSay:SetJustifyH("LEFT");
FLogReportFrameSay:SetText(L["/say"]);
FLogReportFrameSay:SetPoint("TOP", FLogReportFrameChatFrame, "BOTTOM", 0, 0);

local FLogReportFrameCheckButtonSay = CreateFrame("CHECKBUTTON", "FLogReportFrameCheckButtonSay", FLogReportFrame);
FLogReportFrameCheckButtonSay:SetWidth(15);
FLogReportFrameCheckButtonSay:SetHeight(15);
FLogReportFrameCheckButtonSay:SetPoint("RIGHT", FLogReportFrameSay, "LEFT", -5, 0);
FLogReportFrameCheckButtonSay:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
FLogReportFrameCheckButtonSay:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
FLogReportFrameCheckButtonSay:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD");
FLogReportFrameCheckButtonSay:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
FLogReportFrameCheckButtonSay:SetScript("OnClick", function() FLogSVOptionReportTo["Say"] = tobool(FLogReportFrameCheckButtonSay:GetChecked()); end);
FLogReportFrameCheckButtonSay:Show();

local FLogReportFrameYell = FLogReportFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogReportFrameYell:SetTextColor(1, 1, 1, 0.8);
FLogReportFrameYell:SetWidth(175);
FLogReportFrameYell:SetHeight(15);
FLogReportFrameYell:SetJustifyH("LEFT");
FLogReportFrameYell:SetText(L["/yell"]);
FLogReportFrameYell:SetPoint("TOP", FLogReportFrameSay, "BOTTOM", 0, 0);

local FLogReportFrameCheckButtonYell = CreateFrame("CHECKBUTTON", "FLogReportFrameCheckButtonYell", FLogReportFrame);
FLogReportFrameCheckButtonYell:SetWidth(15);
FLogReportFrameCheckButtonYell:SetHeight(15);
FLogReportFrameCheckButtonYell:SetPoint("RIGHT", FLogReportFrameYell, "LEFT", -5, 0);
FLogReportFrameCheckButtonYell:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
FLogReportFrameCheckButtonYell:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
FLogReportFrameCheckButtonYell:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD");
FLogReportFrameCheckButtonYell:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
FLogReportFrameCheckButtonYell:SetScript("OnClick", function() FLogSVOptionReportTo["Yell"] = tobool(FLogReportFrameCheckButtonYell:GetChecked()); end);
FLogReportFrameCheckButtonYell:Show();

local FLogReportFrameParty = FLogReportFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogReportFrameParty:SetTextColor(1, 1, 1, 0.8);
FLogReportFrameParty:SetWidth(175);
FLogReportFrameParty:SetHeight(15);
FLogReportFrameParty:SetJustifyH("LEFT");
FLogReportFrameParty:SetText(L["/party"]);
FLogReportFrameParty:SetPoint("TOP", FLogReportFrameYell, "BOTTOM", 0, 0);

local FLogReportFrameCheckButtonParty = CreateFrame("CHECKBUTTON", "FLogReportFrameCheckButtonParty", FLogReportFrame);
FLogReportFrameCheckButtonParty:SetWidth(15);
FLogReportFrameCheckButtonParty:SetHeight(15);
FLogReportFrameCheckButtonParty:SetPoint("RIGHT", FLogReportFrameParty, "LEFT", -5, 0);
FLogReportFrameCheckButtonParty:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
FLogReportFrameCheckButtonParty:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
FLogReportFrameCheckButtonParty:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD");
FLogReportFrameCheckButtonParty:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
FLogReportFrameCheckButtonParty:SetScript("OnClick", function() FLogSVOptionReportTo["Party"] = tobool(FLogReportFrameCheckButtonParty:GetChecked()); end);
FLogReportFrameCheckButtonParty:Show();

local FLogReportFrameRaid = FLogReportFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogReportFrameRaid:SetTextColor(1, 1, 1, 0.8);
FLogReportFrameRaid:SetWidth(175);
FLogReportFrameRaid:SetHeight(15);
FLogReportFrameRaid:SetJustifyH("LEFT");
FLogReportFrameRaid:SetText(L["/raid"]);
FLogReportFrameRaid:SetPoint("TOP", FLogReportFrameParty, "BOTTOM", 0, 0);

local FLogReportFrameCheckButtonRaid = CreateFrame("CHECKBUTTON", "FLogReportFrameCheckButtonRaid", FLogReportFrame);
FLogReportFrameCheckButtonRaid:SetWidth(15);
FLogReportFrameCheckButtonRaid:SetHeight(15);
FLogReportFrameCheckButtonRaid:SetPoint("RIGHT", FLogReportFrameRaid, "LEFT", -5, 0);
FLogReportFrameCheckButtonRaid:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
FLogReportFrameCheckButtonRaid:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
FLogReportFrameCheckButtonRaid:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD");
FLogReportFrameCheckButtonRaid:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");	
FLogReportFrameCheckButtonRaid:SetScript("OnClick", function() FLogSVOptionReportTo["Raid"] = tobool(FLogReportFrameCheckButtonRaid:GetChecked()); end);
FLogReportFrameCheckButtonRaid:Show();

local FLogReportFrameGuild = FLogReportFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogReportFrameGuild:SetTextColor(1, 1, 1, 0.8);
FLogReportFrameGuild:SetWidth(175);
FLogReportFrameGuild:SetHeight(15);
FLogReportFrameGuild:SetJustifyH("LEFT");
FLogReportFrameGuild:SetText(L["/guild"]);
FLogReportFrameGuild:SetPoint("TOP", FLogReportFrameRaid, "BOTTOM", 0, 0);

local FLogReportFrameCheckButtonGuild = CreateFrame("CHECKBUTTON", "FLogReportFrameCheckButtonGuild", FLogReportFrame);
FLogReportFrameCheckButtonGuild:SetWidth(15);
FLogReportFrameCheckButtonGuild:SetHeight(15);
FLogReportFrameCheckButtonGuild:SetPoint("RIGHT", FLogReportFrameGuild, "LEFT", -5, 0);
FLogReportFrameCheckButtonGuild:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
FLogReportFrameCheckButtonGuild:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
FLogReportFrameCheckButtonGuild:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD");
FLogReportFrameCheckButtonGuild:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
FLogReportFrameCheckButtonGuild:SetScript("OnClick", function() FLogSVOptionReportTo["Guild"] = tobool(FLogReportFrameCheckButtonGuild:GetChecked()); end);
FLogReportFrameCheckButtonGuild:Show();

local FLogReportFrameWhisper = FLogReportFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogReportFrameWhisper:SetTextColor(1, 1, 1, 0.8);
FLogReportFrameWhisper:SetWidth(100);
FLogReportFrameWhisper:SetHeight(15);
FLogReportFrameWhisper:SetJustifyH("LEFT");
FLogReportFrameWhisper:SetText(L["/whisper:"]);
FLogReportFrameWhisper:SetPoint("TOPLEFT", FLogReportFrameGuild, "BOTTOMLEFT");

local FLogReportFrameCheckButtonWhisper = CreateFrame("CHECKBUTTON", "FLogReportFrameCheckButtonWhisper", FLogReportFrame);
FLogReportFrameCheckButtonWhisper:SetWidth(15);
FLogReportFrameCheckButtonWhisper:SetHeight(15);
FLogReportFrameCheckButtonWhisper:SetPoint("RIGHT", FLogReportFrameWhisper, "LEFT", -5, 0);
FLogReportFrameCheckButtonWhisper:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
FLogReportFrameCheckButtonWhisper:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
FLogReportFrameCheckButtonWhisper:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD");
FLogReportFrameCheckButtonWhisper:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
FLogReportFrameCheckButtonWhisper:SetScript("OnClick", function() FLogSVOptionReportTo["Whisper"] = tobool(FLogReportFrameCheckButtonWhisper:GetChecked()); end);
FLogReportFrameCheckButtonWhisper:Show();

local FLogReportFrameWhisperBox = CreateFrame("EDITBOX", "FLogReportFrameWhisperBox", FLogReportFrame, "InputBoxTemplate")
FLogReportFrameWhisperBox:SetWidth(90);
FLogReportFrameWhisperBox:SetHeight(15);
FLogReportFrameWhisperBox:SetPoint("LEFT", FLogReportFrameWhisper, "RIGHT", -40, -2);
FLogReportFrameWhisperBox:SetMaxLetters(12);
FLogReportFrameWhisperBox:SetScript("OnTabPressed", function()
													local n, r = UnitName("TARGET");
														if not (n == nil) then
														FLogReportFrameWhisperBox:SetText(n);
													end
												end);

FLogReportFrameWhisperBox:SetScript("OnEnterPressed", function() FLogReportFrameWhisperBox:ClearFocus(); end);
FLogReportFrameWhisperBox:SetScript("OnTextChanged", function()
	local h = FLogReportFrameWhisperBox:GetText()
	if #h == 1 then
		FLogReportFrameWhisperBox:SetText(strupper(h));
	elseif #h > 1 then
		local a = strsub(h, 1, 1);
		local b = strsub(h, 2);		
		FLogReportFrameWhisperBox:SetText(strupper(a)..strlower(b));
	end
	SVWhisperBox = FLogReportFrameWhisperBox:GetText();
end);
FLogReportFrameWhisperBox:SetAutoFocus(false);
FLogReportFrameWhisperBox:Show();

local FLogReportFrameReportButton = CreateFrame("BUTTON", "FLogReportFrameReportButton", FLogReportFrame, "UIPanelButtonTemplate");
FLogReportFrameReportButton:SetWidth(180);
FLogReportFrameReportButton:SetHeight(30);
FLogReportFrameReportButton:SetText(L["report"]);
FLogReportFrameReportButton:SetPoint("BOTTOM", FLogReportFrame, "BOTTOM", 0, 10);
FLogReportFrameReportButton:SetScript("OnClick", function()													
													ReportSession();													
												end);
FLogReportFrameReportButton:SetAlpha(1);
FLogReportFrameReportButton:Show();

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
														if #FLogSVDrops[editName][editItem] == 1 then
															tinsert(newName, editItem, FLogSVDrops[editName][editItem][editIdx][1], FLogSVDrops[editName][editItem][editIdx][2], FLogSVDrops[editName][editItem][editIdx][3]);
															FLogSVDrops[editName][editItem] = nil;
															local x = 0;
															for a, _ in pairs (FLogSVDrops[editName]) do																
																x = x + 1;
															end
															if x == 0 then
																FLogSVDrops[editName] = nil;
															end
														else
															tinsert(newName, editItem, FLogSVDrops[editName][editItem][editIdx][1], FLogSVDrops[editName][editItem][editIdx][2], FLogSVDrops[editName][editItem][editIdx][3]);
															tremove(FLogSVDrops[editName][editItem], editIdx);
														end
														RefreshSChildFrame();
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

-- slash
SLASH_LH1 = "/farmlog";
SlashCmdList["LH"] = function(args)
	if args == "show" then
		ToggleWindow()
	else 
		ToggleLogging()
	end	
end
