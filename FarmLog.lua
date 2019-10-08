SLASH_LH1 = "/farmlog";
local FLogVersionNumber = "1.0";
local FLogVersion = "FarmLog v"..FLogVersionNumber;
local FLogVersionShort = "(v"..FLogVersionNumber..")";
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

--begin localization
local L = {};
L["yes"] = "Yes";
L["no"] = "No";
L["reset"] = "Reset Data?";	
L["clear"] = "Reset";
L["report"] = "Report";
L["Log-Options:"] = "Log-Options:";
L["poor"] = "Poor Items";
L["common"] = "Common Items";
L["uncommon"] = "Uncommon Items";
L["rare"] = "Rare Items";
L["epic"] = "Epic Items";
L["legendary"] = "Legendary Items";
L["artifact"] = "Artifact Items";
L["heirloom"] = "Heirloom"
L["solo"] = "Solo";
L["party"] = "Party";
L["raid"] = "Raid";
L["Report"] = "FLog-Report ";
L["Report2"] = "Last change on ";
L["Report:"] = "Report to:";
L["ChatFrame1"] = "ChatFrame1";
L["/say"] = "/say";
L["/yell"] = "/yell";
L["/party"] = "/party";
L["/raid"] = "/raid";
L["/guild"] = "/guild";
L["/whisper:"] = "/whisper:";
L["General-Options:"] = "General-Options:";
L["lockFrames"] = "Lock Frames";
L["enableMinimapButton"] = "Enable Minimap-Button";
L["lockMinimapButton"] = "Lock Minimap-Button";
L["LDBClick"] = "Left-Click to open "..FLogVersion.."|nRight-Click to open Blizzard-FarmLog";
L["Help"] = "O = Show Options|n? = Show Help|nX = Close Frame|n|n- Mouseover a row to highlight and to show Item-Tooltip|n- Shift-Click to copy the ItemLink into the Chatframe-EditBox|n- Alt-Click to to edit the owner of selected Item(s)|n|nReport = Report current FLog|nReset = Reset the current FLog";
L["tooltip"] = "Show Item-Tolltip";
L["updated"] = "|cffff0000FarmLog updated to Version v"..FLogVersionNumber..".|r";
L["updated2"] = "|cffff0000The complete FarmLog-Data has been reset, caused by compatibility-reasons.|r";
L["need"] = "N: ";
L["greed"] = "G: ";
L["disenchant"] = "D: ";
L["loot"] = "loot: "; --AddOn needs correct localization to work!!!
L["you"] = "You"; --AddOn needs correct localization to work!!!
if (GetLocale() == "enUS") then
elseif (GetLocale() == "deDE") then
	L["yes"] = "Ja";
	L["no"] = "Nein";
	L["reset"] = "Daten löschen?";	
	L["clear"] = "Löschen";
	L["report"] = "Berichten";
	L["Log-Options:"] = "Log-Optionen:";
	L["poor"] = "Schlechte Gegenstände";
	L["common"] = "Gewöhnliche Gegenstände";
	L["uncommon"] = "Gute Gegenstände";
	L["rare"] = "Rare Gegenstände";
	L["epic"] = "Epische Gegenstände";
	L["legendary"] = "Legendäre Gegenstände";
	L["artifact"] = "Artefakte";
	L["heirloom"] = "Erbstücke"
	L["solo"] = "Solo";
	L["party"] = "Gruppe";
	L["raid"] = "Schlachtzug";
	L["Report"] = "FLog-Bericht ";
	L["Report2"] = "Letzte Änderung am ";
	L["Report:"] = "Bericht an:";
	L["ChatFrame1"] = "ChatFrame1";
	L["/say"] = "/sagen";
	L["/yell"] = "/schreien";
	L["/party"] = "/gruppe";
	L["/raid"] = "/schlachtzug";
	L["/guild"] = "/gilde";
	L["/whisper:"] = "/flüstern:";
	L["General-Options:"] = "Allgemeine Optionen:";
	L["lockFrames"] = "Fenster sperren";
	L["enableMinimapButton"] = "Minimap-Button anzeigen";
	L["lockMinimapButton"] = "Minimap-Button sperren";
	L["LDBClick"] = "Links-Klicken um "..FLogVersion.." zu öffnen|nRechts-Klicken um Blizzard-FarmLog zu öffnen";
	L["Help"] = "O = Optionen|n? = Hilfe|nX = Fenster schließen|n|n- Mouseover zum hervorheben der Zeile und um den Item-Tooltip anzuzeigen|n- Shift-Klick um den ItemLink in die Chatframe-EditBox einzufügen|n- Alt-Klick um den Besitzer der / des ausgewählten Items zu ändern|n|nBerichten = FLog-Bericht erstellen|nReset = FLog zurücksetzen";
	L["tooltip"] = "Item-Tolltip anzeigen";
	L["updated"] = "|cffff0000FarmLog wurde auf Version v"..FLogVersionNumber.." geupdated.|r";
	L["updated2"] = "|cffff0000Die komplette FarmLog-Datenbank musste aus Kompatibilitätsgründen zurückgesetzt werden.|r";
	L["need"] = "B: ";
	L["greed"] = "G: ";
	L["disenchant"] = "E: ";
	L["loot"] = "Beute: ";
	L["you"] = "Ihr";
elseif (GetLocale() == "zhCN") then
    L["loot"] = "获得了物品: "; 
    L["you"] = "你";
else
	--[[ 
	feel free to create the following localizations (you can contact me via curse.com):
	"frFR": French
	"koKR": Korean
	"zhCN": Chinese (simplified)
	"zhTW": Chinese (traditional)
	"ruRU": Russian (UI AddOn)
	"esES": Spanish (Spain)
	"esMX": Spanish (Mexico)
	]]--
	print("|cffff0000"..FLogVersion..": Your WoW-Version isn't compatible. This is caused by localization issues.|r");
end
--end localization

local function FLogtobool(arg1)
	if arg1 == 1 or arg1 == true then	
		return true;
	else
		return false;
	end
end

local function FarmLogFrameToggle()
	if FarmLogFrame:IsShown() then
		FarmLogFrame:Hide();		
	elseif not FarmLogFrame:IsShown() then
		FarmLogFrame:Show();
	end
end

local function FLogToggle()
	if FLogFrame:IsShown() then
		FLogFrame:Hide();
		FLogOptionsFrame:Hide();
	elseif not FLogFrame:IsShown() then
		FLogFrame:Show();
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

local function FLogSort(db)
-- Sort the userNames of the LoHI alphabetically.
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

local function FLogSortItemLinks(db)
-- Sort the ItemLinks of the ItemIDs of the FLog[userName] alphabetically.
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

local function FLogReport(message)
	if FLogReportTo["ChatFrame1"] then
		print(message);
	end
	if FLogReportTo["Say"] then
		SendChatMessage(message, "SAY");
	end
	if FLogReportTo["Yell"] then
		SendChatMessage(message, "YELL");
	end
	if FLogReportTo["Party"] then
		if GetNumGroupMembers() > 0 then
			SendChatMessage(message, "PARTY");
		end
	end
	if ((FLogReportTo["Raid"]) and (GetNumGroupMembers() > 0)) then
		SendChatMessage(message, "RAID");
	end
	if FLogReportTo["Guild"] then
		local guild = GetGuildInfo("player");		
		if (not(guild == nil)) then
			SendChatMessage(message, "GUILD");
		end
	end
	if FLogReportTo["Whisper"] then
		local h = FLogReportFrameWhisperBox:GetText();
		if (not (h == nil)) then
			SendChatMessage(message, "WHISPER", nil, h);
		end
	end
end

local function FLogReportData()
	if (FLog and FLogFrameSChildContentTable[1][0]:IsShown()) then
		local FLogSortedNames = FLogSort(FLog);
		FLogReport(L["Report"]..FLogVersionShort..":");
		FLogReport(L["Report2"]..tostring(FLogLastChange));
		for _, userName in ipairs(FLogSortedNames) do
			local FLogSortedItemLinks = FLogSortItemLinks(FLog[userName]);
			FLogReport(userName..":");
			for _, itemLink in ipairs(FLogSortedItemLinks) do				
				for j = 1, #FLog[userName][itemLink] do
					local report = "  "..itemLink;
					local num = FLog[userName][itemLink][j][1];
					local rollType = FLog[userName][itemLink][j][2];
					local roll = FLog[userName][itemLink][j][3];
					if num > 1 then
						report = report.."x"..num;
					end
					if (rollType == LOOT_ROLL_TYPE_NEED) then
						report = report.." ("..L["need"]..roll..")";
					elseif (rollType == LOOT_ROLL_TYPE_GREED) then
						report = report.." ("..L["greed"]..roll..")";
					elseif (rollType == LOOT_ROLL_TYPE_DISENCHANT) then
						report = report.." ("..L["disenchant"]..roll..")";
					end
					FLogReport(report);
				end
			end
		end		
	end
end

local function FLogCreateSChild(j)
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

local function FLogHideSChildFrame(j)
--Hides all SChildFrames, beginning at Position j
	local n = #FLogFrameSChildContentTable;
	for i = j, n do
		FLogFrameSChildContentTable[i][0]:Hide();
	end
end

local function FLogRefreshSChildFrame()
--Refresh the SChildFrame
	local n = #FLogFrameSChildContentTable;
	local i = 1;
	local FLogSortedNames = FLogSort(FLog);
	for _, userName in ipairs(FLogSortedNames) do	
		local FLogSortedItemLinks = FLogSortItemLinks(FLog[userName]);		
		if i > n then
			FLogCreateSChild(1);
		end
		FLogFrameSChildContentTable[i][1]:SetText(userName..":");
		FLogFrameSChildContentTable[i][2]:SetTexture(nil);
		FLogFrameSChildContentTable[i][3]:SetText("");
		FLogFrameSChildContentTable[i][0]:SetScript("OnEnter", nil);
		FLogFrameSChildContentTable[i][0]:SetScript("OnLeave", nil);
		FLogFrameSChildContentTable[i][0]:SetScript("OnMouseUp", nil);
		FLogFrameSChildContentTable[i][0]:Show();
		i = i + 1;
		for _, itemLink in ipairs(FLogSortedItemLinks) do			
			for j = 1, #FLog[userName][itemLink] do
				if i > n then
					FLogCreateSChild(1);
				end
				local num = FLog[userName][itemLink][j][1];
				local rollType = FLog[userName][itemLink][j][2];
				local roll = FLog[userName][itemLink][j][3];
				if num > 1 then
					FLogFrameSChildContentTable[i][1]:SetText("    "..itemLink.."x"..num);
					FLogFrameSChildContentTable[i][2]:SetTexture(nil);
					FLogFrameSChildContentTable[i][3]:SetText("");
				elseif num == 1 then
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
													if FLog_Tooltip then
														GameTooltip:SetOwner(self, "ANCHOR_LEFT");
														GameTooltip:SetHyperlink(itemLink);
														GameTooltip:Show();
													end
													end);
				FLogFrameSChildContentTable[i][0]:SetScript("OnLeave", function(self)
													if FLog_Tooltip then
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
														editName = userName;
														editItem = itemLink;
														editIdx = j;
														if num > 1 then
															FLogEditFrameItem:SetText(itemLink.."x"..num);
														else
															FLogEditFrameItem:SetText(itemLink);
														end																									
														FLogEditFrameOwnerBox:SetText(userName);
														FLogEditFrame:Show();
														FLogEditFrameOwnerBox:SetFocus(true);												
													end
												end);
				FLogFrameSChildContentTable[i][0]:Show();
				i = i + 1;
			end
		end		
	end
	FLogHideSChildFrame(i);	
	if (FLogFrameSChildContentTable[1] and FLogFrameSChildContentTable[1][0] and FLogFrameSChildContentTable[1][0]:IsShown()) then		
		FLogFrameShowButton:Enable();		
		FLogFrameClearButton:Enable();
	else
		FLogFrameShowButton:Disable();
		FLogFrameClearButton:Disable();
	end
end

local function ClearFLog()	
	wipe(FLog);
	FLogHideSChildFrame(1);
	FLogFrameShowButton:Disable();
	FLogFrameClearButton:Disable();
	FLogLastChange = date("%d.%m.%y - %H:%M");
end

local function FLog_tinsert(userName, itemLink, num, rollType, roll)
-- inserts into FLog
-- print(tostring(userName)..", "..tostring(itemName)..", "..tostring(num)..", "..tostring(rollType)..", "..tostring(roll));
	if (userName and itemLink and num and rollType and roll) then		
		if FLog[userName] then		
			if FLog[userName][itemLink] then				
				if rollType == -1 then
					local f = -1;
					for i = 1, #FLog[userName][itemLink] do
						if FLog[userName][itemLink][i][2] == -1 then
							f = i;
							i = #FLog[userName][itemLink] + 1;
						end
					end
					if f > 0 then
						FLog[userName][itemLink][f][1] = FLog[userName][itemLink][f][1] + num;
						FLogLastChange = date("%d.%m.%y - %H:%M");
					else
						tinsert(FLog[userName][itemLink], {num, rollType, roll});
						FLogLastChange = date("%d.%m.%y - %H:%M");
					end
				else
					tinsert(FLog[userName][itemLink], {num, rollType, roll});
					FLogLastChange = date("%d.%m.%y - %H:%M");
				end
			else
				FLog[userName][itemLink] = {{num, rollType, roll}};
				FLogLastChange = date("%d.%m.%y - %H:%M");
			end
		else
			FLog[userName] = {};
			FLog[userName][itemLink] = {{num, rollType, roll}};
			FLogLastChange = date("%d.%m.%y - %H:%M");
		end
	end
end

local function FLog_CHAT_MSG_LOOT(arg1)
-- parse the chat-message and add the item to the FLog, if the following conditions are fullfilled.
	local s, _ = string.find(arg1, "%|c");
	local _, e = string.find(arg1, "%]%|h%|r");
	local itemLink = string.sub(arg1, s, e);	
	local _, _, itemRarity, _, _, itemType, _, _, _, _, _ = GetItemInfo(itemLink);
	local inRaid = IsInRaid();
	local inParty = false;
	if GetNumGroupMembers() > 0 then
		inParty = true;
	end
	if (((FLogLog["Raid"] and inRaid) or 
		(FLogLog["Party"] and inParty and not inRaid) or
		(FLogLog["Solo"] and not inParty and not inRaid))
		and 
		(not(itemType == "Money")) 
		and 
		((FLogItemRarity[0] and itemRarity == 0) or
		(FLogItemRarity[1] and itemRarity == 1) or
		(FLogItemRarity[2] and itemRarity == 2) or
		(FLogItemRarity[3] and itemRarity == 3) or
		(FLogItemRarity[4] and itemRarity == 4) or
		(FLogItemRarity[5] and itemRarity == 5) or
		(FLogItemRarity[6] and itemRarity == 6))) 
	then	
		-- get correct userName:
		-- case 1 = Player
		-- case 2a = Group-Member, same Realm
		-- case 2b = Group-Member, different Realm
		local userName = string.sub(arg1, 0, (string.find(arg1, " ")-1));	
		if userName == L["you"] then
			userName = UnitName("PLAYER");		
		else
			local h = "party"
			if inRaid then
				h = "raid"
			end
			for i = 1, GetNumGroupMembers() do
				local x = h..i;
				local n, r = UnitName(x);
				if userName == n then
					if (not (UnitIsSameServer(x, "PLAYER"))) then		
						if r then
							userName = n.."-"..r;
							i = GetNumGroupMembers() + 1;
						end
					end
				end
			end				
		end
		
		-- parse num from chat-message
		local num = 1;		
		if ((e + 2 ) <= (#arg1 - 1)) then
			num = tonumber(string.sub(arg1, e + 2, #arg1 - 1));
		end		

		-- if possible, get rollType and roll from Blizzard-FarmLog
		local rollType = -1;
		local roll = -1;
		if itemRarity >= 2 then
			for itemIdx = 1, C_FarmLog.GetNumItems() do
				local _, itemLink2, _, _, winnerIdx = C_FarmLog.GetItem(itemIdx);			
				--[[print(" -- "..itemIdx);
				print(tostring(gsub(itemLink, "\124", "\124\124")));
				print(tostring(gsub(itemLink2, "\124", "\124\124")));]]--
				if ((itemLink == itemLink2) and winnerIdx) then					
					local userName2, _, rT, r, _ = C_FarmLog.GetPlayerInfo(itemIdx, winnerIdx);
					if userName == userName2 then
						rollType = rT;
						roll = r;
						itemIdx = C_FarmLog.GetNumItems() + 1;
					end
				end
			end
		end		
		FLog_tinsert(userName, itemLink, num, rollType, roll);
		FLogRefreshSChildFrame();
	end
end

function lohitest()
	local FLogSortedNames = FLogSort(FLog);
	for _, userName in ipairs(FLogSortedNames) do
		local FLogSortedItemLinks = FLogSortItemLinks(FLog[userName]);		
		for _, itemLink in ipairs(FLogSortedItemLinks) do
			print(userName..": "..itemLink);
			print(tostring(gsub(itemLink, "\124", "\124\124")));
		end
	end
end

SlashCmdList["LH"] = function(args)
	if args == "toggle" then
		FLogToggle();
	end	
end

local function FLogOnEvent(event, ...)
	if event == "CHAT_MSG_LOOT" then
		if (... and (strfind(..., L["loot"]))) then
			FLog_CHAT_MSG_LOOT(...);			
		end	
	elseif event == "PLAYER_ENTERING_WORLD" then
		local inInstance, _ = IsInInstance();
		inInstance = FLogtobool(inInstance);
		local iniName = GetInstanceInfo();		
		if ((inIni == false and inInstance) and not(lastIni == iniName)) then
			inIni = true;
			lastIni = iniName;
			if ((IsInRaid() and FLogLog["Raid"]) or (UnitInParty("Player") and not IsInRaid() and FLogLog["Party"]) or (FLogLog["Solo"] and not IsInRaid() and not UnitInParty("Player"))) then
				FLogResetFrame:Show();
			end
		elseif (inIni and inInstance == false) then
			inIni = false;			
		end
		FLogRefreshSChildFrame();
	elseif (event == "ADDON_LOADED" and ... == "FarmLog") then		
		if FLog == nil then
			FLog = {};
		end
		if FLogItemRarity == nil then
			FLogItemRarity = {};
			FLogItemRarity[0]=false; --poor (grey)
			FLogItemRarity[1]=false; --common (white)
			FLogItemRarity[2]=true; --uncommon (green)
			FLogItemRarity[3]=true; --rare (blue)
			FLogItemRarity[4]=true; --epic (purple)
			FLogItemRarity[5]=true; --legendary (orange)
			FLogItemRarity[6]=false; --artifact
			--FLogItemRarity[7]=false; --heirloom
		end
		if FLogReportTo == nil then
			FLogReportTo = {};
			FLogReportTo["ChatFrame1"]=true;
			FLogReportTo["Say"]=false;
			FLogReportTo["Yell"]=false;
			FLogReportTo["Party"]=false;
			FLogReportTo["Raid"]=false;
			FLogReportTo["Guild"]=false;
			FLogReportTo["Whisper"]=false;
		end
		if FLogLog == nil then 
			FLogLog = {};
			FLogLog["Solo"]=false;
			FLogLog["Party"]=true;
			FLogLog["Raid"]=true;
		end
		if FLog_LockFrames == nil then
			FLog_LockFrames = false;
		end
		if FLog_LockMinimapButton == nil then
			FLog_LockMinimapButton = false;
		end
		if FLog_Frame == nil then
			FLog_Frame = {};
			FLog_Frame["width"] = 250;
			FLog_Frame["height"] = 200;
			FLog_Frame["point"] = "CENTER";
			FLog_Frame["x"] = 0;
			FLog_Frame["y"] = 0;
		end
		if FLog_MinimapButtonPosition == nil then
			FLog_MinimapButtonPosition = {};
			FLog_MinimapButtonPosition["point"] = "TOP";
			FLog_MinimapButtonPosition["x"] = 0;
			FLog_MinimapButtonPosition["y"] = 0;
		end
		if FLog_EnableMinimapButton == nil then
			FLog_EnableMinimapButton = true;
		end
		if FLog_LockShowLootFrame == nil then
			FLog_LockShowLootFrame = false;
		end	
		if FLog_Tooltip == nil then
			FLog_Tooltip = true;
		end
		--compatibility fix for older Versions ( < 3.0)
		if FLog_Version == nil then
			print(L["updated"]);
			print(L["updated2"]);
			ClearFLog(FLog);
			FLog_Version = tonumber(FLogVersionNumber);
		else
			if FLog_Version < 3.0 then
				print(L["updated"]);
				print(L["updated2"]);
				ClearFLog(FLog);
				FLog_Version = tonumber(FLogVersionNumber);
			elseif FLog_Version < tonumber(FLogVersionNumber) then
				print(L["updated"]);
				FLog_Version = tonumber(FLogVersionNumber);
			elseif FLog_Version > tonumber(FLogVersionNumber) then
				print(L["updated"]);
				FLog_Version = tonumber(FLogVersionNumber);
			end
		end
		if FLogLastChange == nil then
			FLogLastChange = date("%d.%m.%y - %H:%M");
		end
		
		FLogOptionsCheckButtonLog0:SetChecked(FLogItemRarity[0]);
		FLogOptionsCheckButtonLog1:SetChecked(FLogItemRarity[1]);
		FLogOptionsCheckButtonLog2:SetChecked(FLogItemRarity[2]);
		FLogOptionsCheckButtonLog3:SetChecked(FLogItemRarity[3]);
		FLogOptionsCheckButtonLog4:SetChecked(FLogItemRarity[4]);
		FLogOptionsCheckButtonLog5:SetChecked(FLogItemRarity[5]);
		FLogOptionsCheckButtonLog6:SetChecked(FLogItemRarity[6]);
		
		FLogOptionsCheckButtonLogSolo:SetChecked(FLogLog["Solo"]);
		FLogOptionsCheckButtonLogParty:SetChecked(FLogLog["Party"]);
		FLogOptionsCheckButtonLogRaid:SetChecked(FLogLog["Raid"]);
		
		FLogReportFrameCheckButtonChatFrame:SetChecked(FLogReportTo["ChatFrame1"]);
		FLogReportFrameCheckButtonSay:SetChecked(FLogReportTo["Say"]);
		FLogReportFrameCheckButtonYell:SetChecked(FLogReportTo["Yell"]);
		FLogReportFrameCheckButtonParty:SetChecked(FLogReportTo["Party"]);
		FLogReportFrameCheckButtonRaid:SetChecked(FLogReportTo["Raid"]);
		FLogReportFrameCheckButtonGuild:SetChecked(FLogReportTo["Guild"]);
		FLogReportFrameCheckButtonWhisper:SetChecked(FLogReportTo["Whisper"]);
		
		FLogOptionsCheckButtonLockFrames:SetChecked(FLog_LockFrames);
		FLogOptionsCheckButtonEnableMinimapButton:SetChecked(FLog_EnableMinimapButton);
		FLogOptionsCheckButtonLockMinimapButton:SetChecked(FLog_LockMinimapButton);
		FLogOptionsCheckButtonTooltip:SetChecked(FLog_Tooltip);	
		
		FLogFrame:SetWidth(FLog_Frame["width"]);
		FLogFrame:SetHeight(FLog_Frame["height"]);
		FLogFrame:SetPoint(FLog_Frame["point"], FLog_Frame["x"], FLog_Frame["y"]);
		
		if not FLog_LockFrames then		
			FLogTopFrame:RegisterForDrag("LeftButton");			
		end
				
		FLogMinimapButton:SetPoint(FLog_MinimapButtonPosition["point"], Minimap, FLog_MinimapButtonPosition["x"], FLog_MinimapButtonPosition["y"]);
		if FLog_EnableMinimapButton then
			FLogMinimapButton:Show();
		else
			FLogMinimapButton:Hide();
		end	
		if not FLog_LockMinimapButton then		
			FLogMinimapButton:RegisterForDrag("LeftButton");			
		end
		FLogRefreshSChildFrame();
	end
end

--LDB
local ldb = LibStub:GetLibrary("LibDataBroker-1.1");
local dataobj = ldb:GetDataObjectByName("FarmLog") or ldb:NewDataObject("FarmLog", {
	type = "data source", icon = [[Interface\AddOns\FarmLog\FarmLogLDBIcon]], text = "FarmLog",
	OnClick = function(self, button)
                if button == "RightButton" then
					FarmLogFrameToggle()
				else
					FLogToggle()
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
													FLog_MinimapButtonPosition["point"] = point;													
													FLog_MinimapButtonPosition["x"] = x;
													FLog_MinimapButtonPosition["y"] = y;
												 end);
FLogMinimapButton:SetScript("OnClick", function(self, button)											
											if button == "RightButton" then
												FarmLogToggle();
											else
												FLogToggle();
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
FLogResetFrameText:SetText(FLogVersion);
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
														ClearFLog();
														FLogResetFrame:Hide();
												end);
FLogResetFrameYesButton:SetAlpha(1);
FLogResetFrameYesButton:Show();

local FLogFrame = CreateFrame("FRAME", "FLogFrame", UIParent);
FLogFrame:SetFrameStrata("HIGH"); 
FLogFrame:RegisterEvent("ADDON_LOADED");
FLogFrame:RegisterEvent("CHAT_MSG_LOOT");
FLogFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
--FLogFrame:RegisterEvent("LOOT_ROLLS_COMPLETE");
FLogFrame:SetScript("OnEvent", function(self, event, ...)
										FLogOnEvent(event, ...);
										end);
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
											FLog_Frame["point"] = point;													
											FLog_Frame["x"] = x;
											FLog_Frame["y"] = y;
											FLog_Frame["width"] = FLogFrame:GetWidth();
											FLog_Frame["height"] = FLogFrame:GetHeight();
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

local FLogFrameText = FLogTopFrame:CreateFontString(nil, "Artwork", "ChatFontNormal");
FLogFrameText:SetTextColor(1, 0, 0, 1.0);
FLogFrameText:SetText(FLogVersion);
FLogFrameText:SetPoint("CENTER");

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
												FLog_Frame["point"] = point;													
												FLog_Frame["x"] = x;
												FLog_Frame["y"] = y;
												FLog_Frame["width"] = FLogFrame:GetWidth();
												FLog_Frame["height"] = FLogFrame:GetHeight();
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
												FLog_Frame["point"] = point;													
												FLog_Frame["x"] = x;
												FLog_Frame["y"] = y;
												FLog_Frame["width"] = FLogFrame:GetWidth();
												FLog_Frame["height"] = FLogFrame:GetHeight();
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
FLogOptionsCheckButtonLog0:SetScript("OnClick", function() FLogItemRarity[0] = FLogtobool(FLogOptionsCheckButtonLog0:GetChecked()); end);
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
FLogOptionsCheckButtonLog1:SetScript("OnClick", function() FLogItemRarity[1] = FLogtobool(FLogOptionsCheckButtonLog1:GetChecked()); end);
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
FLogOptionsCheckButtonLog2:SetScript("OnClick", function() FLogItemRarity[2] = FLogtobool(FLogOptionsCheckButtonLog2:GetChecked()); end);
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
FLogOptionsCheckButtonLog3:SetScript("OnClick", function() FLogItemRarity[3] = FLogtobool(FLogOptionsCheckButtonLog3:GetChecked()); end);
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
FLogOptionsCheckButtonLog4:SetScript("OnClick", function() FLogItemRarity[4] = FLogtobool(FLogOptionsCheckButtonLog4:GetChecked()); end);
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
FLogOptionsCheckButtonLog5:SetScript("OnClick", function() FLogItemRarity[5] = FLogtobool(FLogOptionsCheckButtonLog5:GetChecked()); end);
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
FLogOptionsCheckButtonLog6:SetScript("OnClick", function() FLogItemRarity[6] = FLogtobool(FLogOptionsCheckButtonLog6:GetChecked()); end);
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
FLogOptionsCheckButtonLogSolo:SetScript("OnClick", function() FLogLog["Solo"] = FLogtobool(FLogOptionsCheckButtonLogSolo:GetChecked()); end);
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
FLogOptionsCheckButtonLogParty:SetScript("OnClick", function() FLogLog["Party"] = FLogtobool(FLogOptionsCheckButtonLogParty:GetChecked()); end);
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
FLogOptionsCheckButtonLogRaid:SetScript("OnClick", function() FLogLog["Raid"] = FLogtobool(FLogOptionsCheckButtonLogRaid:GetChecked()); end);
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
																FLog_LockFrames = FLogtobool(FLogOptionsCheckButtonLockFrames:GetChecked());
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
																		FLog_EnableMinimapButton = FLogtobool(FLogOptionsCheckButtonEnableMinimapButton:GetChecked());
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
																		FLog_LockMinimapButton = FLogtobool(FLogOptionsCheckButtonLockMinimapButton:GetChecked());
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
															FLog_Tooltip = FLogtobool(FLogOptionsCheckButtonTooltip:GetChecked());
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
FLogReportFrameCheckButtonChatFrame:SetScript("OnClick", function() FLogReportTo["ChatFrame1"] = FLogtobool(FLogReportFrameCheckButtonChatFrame:GetChecked()); end);
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
FLogReportFrameCheckButtonSay:SetScript("OnClick", function() FLogReportTo["Say"] = FLogtobool(FLogReportFrameCheckButtonSay:GetChecked()); end);
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
FLogReportFrameCheckButtonYell:SetScript("OnClick", function() FLogReportTo["Yell"] = FLogtobool(FLogReportFrameCheckButtonYell:GetChecked()); end);
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
FLogReportFrameCheckButtonParty:SetScript("OnClick", function() FLogReportTo["Party"] = FLogtobool(FLogReportFrameCheckButtonParty:GetChecked()); end);
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
FLogReportFrameCheckButtonRaid:SetScript("OnClick", function() FLogReportTo["Raid"] = FLogtobool(FLogReportFrameCheckButtonRaid:GetChecked()); end);
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
FLogReportFrameCheckButtonGuild:SetScript("OnClick", function() FLogReportTo["Guild"] = FLogtobool(FLogReportFrameCheckButtonGuild:GetChecked()); end);
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
FLogReportFrameCheckButtonWhisper:SetScript("OnClick", function() FLogReportTo["Whisper"] = FLogtobool(FLogReportFrameCheckButtonWhisper:GetChecked()); end);
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
	FLogWhisperBox = FLogReportFrameWhisperBox:GetText();
end);
FLogReportFrameWhisperBox:SetAutoFocus(false);
FLogReportFrameWhisperBox:Show();

local FLogReportFrameReportButton = CreateFrame("BUTTON", "FLogReportFrameReportButton", FLogReportFrame, "UIPanelButtonTemplate");
FLogReportFrameReportButton:SetWidth(180);
FLogReportFrameReportButton:SetHeight(30);
FLogReportFrameReportButton:SetText(L["report"]);
FLogReportFrameReportButton:SetPoint("BOTTOM", FLogReportFrame, "BOTTOM", 0, 10);
FLogReportFrameReportButton:SetScript("OnClick", function()													
													FLogReportData();													
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
														if #FLog[editName][editItem] == 1 then
															FLog_tinsert(newName, editItem, FLog[editName][editItem][editIdx][1], FLog[editName][editItem][editIdx][2], FLog[editName][editItem][editIdx][3]);
															FLog[editName][editItem] = nil;
															local x = 0;
															for a, _ in pairs (FLog[editName]) do																
																x = x + 1;
															end
															if x == 0 then
																FLog[editName] = nil;
															end
														else
															FLog_tinsert(newName, editItem, FLog[editName][editItem][editIdx][1], FLog[editName][editItem][editIdx][2], FLog[editName][editItem][editIdx][3]);
															tremove(FLog[editName][editItem], editIdx);
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