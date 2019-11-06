local VERSION = "1.13.3"
local VERSION_INT = 1.1303
local APPNAME = "FarmLog"
local CREDITS = "by |cff40C7EBKof|r @ |cffff2222Shazzrah|r"
local FONT_NAME = "Fonts\\FRIZQT__.TTF"
local MAX_AH_RETRY = 0

local L = FarmLog_BuildLocalization()
local UNKNOWN_MOBNAME = L["Unknown"]
local REALM = GetRealmName()

local MAX_INSTANCES_SECONDS = 3600
local MAX_INSTANCES_COUNT = 5
local INSTANCE_RESET_SECONDS = 3600
local PURGE_LOOTED_MOBS_SECONDS = 5 * 60

local DROP_META_INDEX_COUNT =  1
local DROP_META_INDEX_VALUE =  2
local DROP_META_INDEX_VALUE_EACH =  3
local DROP_META_INDEX_VALUE_TYPE =  4

local VALUE_TYPE_MANUAL = 'M'
local VALUE_TYPE_SCAN = 'S'
local VALUE_TYPE_VENDOR = 'V'
local VALUE_TYPE_COLOR = {
	["M"] = "e1d592",
	["S"] = "95d6e5",
	["V"] = "fbf9ed",
	["?"] = "f3c0c0",
}

local SORT_BY_TEXT = "A"
local SORT_BY_GOLD = "$"
local SORT_BY_KILLS = "K"
local SORT_BY_USE = "U"

local LOOT_AUTOFIX_TIMEOUT_SEC = 1
local AH_SCAN_CHUNKS = 500

local TEXT_COLOR = {
	["xp"] = "6a78f9",
	["skill"] = "4e62f8",
	["rep"] = "7d87f9",
	["mob"] = "f29244",
	["money"] = "fffb49",
	["honor"] = "e1c73b",
	["deaths"] = "ee3333",
	["gathering"] = "38c98d",
	["unknown"] = "888888",
}

TEXT_COLOR[L["Skinning"]] = TEXT_COLOR["gathering"]
TEXT_COLOR[L["Herbalism"]] = TEXT_COLOR["gathering"]
TEXT_COLOR[L["Mining"]] = TEXT_COLOR["gathering"]
TEXT_COLOR[UNKNOWN_MOBNAME] = TEXT_COLOR["unknown"]

local TITLE_COLOR = "|cff4CB4ff"
local SPELL_HERBING = 2366
local SPELL_MINING = 2575
local SPELL_FISHING = 7620
local SPELL_OPEN = 3365
local SPELL_OPEN_NOTEXT = 22810
local SPELL_LOCKPICK = 1804
local SPELL_SKINNING = {
	["10768"] = 1,
	["8617"] = 1,
	["8618"] = 1,
	["8613"] = 1,
}
local SKILL_LOOTWINDOW_OPEN_TIMEOUT = 8 -- trade skill takes 5 sec to cast, after 8 discard it

local SKILL_HERB_TEXT = (string.gsub((GetSpellInfo(9134)),"%A",""))

local BL_SEEN_TIMEOUT = 20 * 60
local BL_TIMERS_DELAY = 5
local BL_SPAWN_TIME_SECONDS = 3600
local BL_ITEMID = 13468
local BL_ITEM_NAME = GetItemInfo(BL_ITEMID)
-- briarthorn FarmLog:SetBlackLotusItemId(2450)
-- peacebloom FarmLog:SetBlackLotusItemId(2447)
-- earthroot FarmLog:SetBlackLotusItemId(2449)
-- silverleaf FarmLog:SetBlackLotusItemId(765)
-- mageroyal FarmLog:SetBlackLotusItemId(785)
-- Stranglekelp FarmLog:SetBlackLotusItemId(3820)

FLogGlobalVars = {
	["debug"] = false,
	["ahPrice"] = {},
	["ahScan"] = {},
	["ahMinQuality"] = 1,
	["ignoredItems"] = {},
	["autoSwitchInstances"] = false,
	["resumeSessionOnSwitch"] = true,
	["reportTo"] = {},
	["dismissLootWindowOnEsc"] = false,
	["groupByMobName"] = true,
	["instances"] = {},
	["blt"] = {}, -- BL timers
	["blp"] = {}, -- BL pick/fail counters
	["sortBy"] = SORT_BY_TEXT,
	["sortSessionBy"] = SORT_BY_TEXT,
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
		["visible"] = false,
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

local mouseOnMainWindow = false 
local lastShiftState = false
local showingMinimapTip = false
local sessionStartTime = nil 
local lastMobLoot = {}
local lastUnknownLoot = {}
local lastUnknownLootTime = 0
local skillName = nil 
local skillNameTime = nil 
local ahScanRequested = false
local ahScanIndex = 0
local ahScanItems = 0
local ahScanBadItems = 0
local ahScanning = false
local ahScanResultsShown = 0
local ahScanResultsTotal = 0
local ahScanPauseTime = 0
local sessionSearchResult = nil 
local addonLoadedTime = nil
local blSeen = nil
lastLootedMobs = {}

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

local function SortMapKeys(db, byValue, descending, keyExtract, valueExtract, searchText)
	local sorted = {}
	local compareIndex = 2
	if byValue then compareIndex = 3 end 
	for key, val in pairs(db) do
		if not searchText or #searchText == 0 or strfind(key:upper(), searchText:upper()) then 
			-- index 2 and 3 may be replaced with a sort values, but we will return the key
			local element = {key, key, val}
			if byValue and valueExtract then 
				element[3] = valueExtract(val)
			elseif not byValue and keyExtract then 
				element[2] = keyExtract(key)
			end  
			local i = 1
			local n = #sorted + 1
			while i <= n do			
				if i == n then
					tinsert(sorted, element)
				elseif not descending and element[compareIndex] <= sorted[i][compareIndex] then
					tinsert(sorted, i, element)			
					i = n		
				elseif descending and element[compareIndex] >= sorted[i][compareIndex] then
					tinsert(sorted, i, element)			
					i = n		
				end
				i = i + 1
			end
		end 
	end
	local result = {}
	for _, element in ipairs(sorted) do tinsert(result, element[1]) end 
	return result
end

local function normalizeLink(link)
	-- remove player level from item link
	local p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18 = _G.string.split(":", link)
	link = p1..":"..p2..":"..p3..":"..p4..":"..p5..":"..p6..":"..p7..":"..p8..":"..p9..":".."_"..":"..p11..":"..p12..":"..p13..":"..p14..":"..p15..":"..p16..":"..p17
	if p18 then 
		link = link..":"..p18
	end 
	return link 
end 

local function extractItemID(link)
	-- remove player level from item link
	local _, id = _G.string.split(":", link)
	return id 
end 


-- Auction house access 

local function GetAHScanPrice(itemLink)
	return FLogGlobalVars.ahScan[REALM][itemLink]
end 

local function GetManualPrice(itemLink)
	return FLogGlobalVars.ahPrice[REALM][itemLink]
end 

local function SetAHScanPrice(itemLink, price)
	FLogGlobalVars.ahScan[REALM][itemLink] = price 
end 

local function SetManualPrice(itemLink, price)
	FLogGlobalVars.ahPrice[REALM][itemLink] = price 
end 

-- Data migration 

local function migrateItemLinkTable(t) 
	local fixed = {}
	for itemLink, ahPrice in pairs(t) do
		fixed[normalizeLink(itemLink)] = ahPrice
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
			["bls"] = {},
			["deaths"] = 0,
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
						if type(meta[1]) == "table" then 
							fixedItems[fixedLink] = {meta[1][DROP_META_INDEX_COUNT]}
						else 
							fixedItems[fixedLink] = meta -- nothing to fix??
						end 
					end 
				end 
				session.drops[mobName] = fixedItems
			end 
		end 
		FLogVars.version = nil 
	end 

	if not FLogVars.ver or type(FLogVars.ver) == "string" then FLogVars.ver = 1.0802 end 
	if not FLogGlobalVars.ver or type(FLogGlobalVars.ver) == "string" then FLogGlobalVars.ver = 1.0802 end 

	if not FLogGlobalVars.ahScan then FLogGlobalVars.ahScan = {} end
	if not FLogGlobalVars.ahMinQuality then FLogGlobalVars.ahMinQuality = 1 end 

	if FLogVars.ver < 1.1102 then 
		-- make sure each killed mob has a drop table, even an empty one
		for sessionName, session in pairs(FLogVars.sessions) do 
			for mobName, _ in pairs(session.kills) do 
				if not session.drops[mobName] then 
					session.drops[mobName] = {}
				end 
			end 
			-- make sure each drop source has a kill count - herbalism, mining, unknown
			for mobName, _ in pairs(session.drops) do 
				if not session.kills[mobName] then 
					session.kills[mobName] = 1
				end 
			end 
		end 
	end 

	if FLogVars.ver < 1.1103 then FLogGlobalVars.groupByMobName = true end 

	if FLogVars.ver < 1.1105 then 
		for name, session in pairs(FLogVars.sessions) do 
			local gph = (session.ah + session.vendor + session.gold) / (session.seconds / 3600)
			session.goldPerHour = gph
		end 
	end 

	if not FLogGlobalVars.sortSessionBy then FLogGlobalVars.sortSessionBy = SORT_BY_TEXT end 

	if FLogGlobalVars.ver < 1.1203 then 
		FLogGlobalVars.ahScan = {[REALM] = FLogGlobalVars.ahScan}
		FLogGlobalVars.ahPrice = {[REALM] = FLogGlobalVars.ahPrice}
	end 

	if not FLogGlobalVars.instances then FLogGlobalVars.instances = {} end 

	if FLogVars.ver < 1.1205 then 
		for name, session in pairs(FLogVars.sessions) do 
			if not session.resets then session.resets = 0 end 
		end 
	end 

	if not FLogVars.bls then FLogVars.bls = {} end 
	if not FLogGlobalVars.blt then FLogGlobalVars.blt = {} end 
	if not FLogGlobalVars.blp then FLogGlobalVars.blp = {} end 

	if FLogVars.ver < 1.1303 then 
		for _, session in pairs(FLogVars.sessions) do 
			if not session.deaths then session.deaths = 0 end 
		end 
	end 

	FLogVars.ver = VERSION_INT
	FLogGlobalVars.ver = VERSION_INT
end 

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

-- Auction house access 

function FarmLog:UpdateInstanceCount()
	local c = #FLogGlobalVars.instances[REALM]
	FarmLog_MainWindow_Buttons_Instances_Text:SetText(c)
	if c <= 2 then 
		FarmLog_MainWindow_Buttons_Instances:SetBackdropBorderColor(0, 1, 0, 0.6)
		FarmLog_MainWindow_Buttons_Instances_Text:SetTextColor(0, 1, 0, 1)
	elseif c <= 4 then 
		FarmLog_MainWindow_Buttons_Instances:SetBackdropBorderColor(1, 1, 0, 0.6)
		FarmLog_MainWindow_Buttons_Instances_Text:SetTextColor(1, 1, 0, 1)
	else 
		FarmLog_MainWindow_Buttons_Instances:SetBackdropBorderColor(1, 0, 0, 0.6)
		FarmLog_MainWindow_Buttons_Instances_Text:SetTextColor(1, 0, 0, 1)
	end
end 

function FarmLog:AddInstance(name, enterTime)
	tinsert(FLogGlobalVars.instances[REALM], 1, {
		["name"] = name,
		["enter"] = enterTime or time(),
		["player"] = GetUnitName("player"),
	})
	self:UpdateInstanceCount()
	IncreaseSessionVar("resets", 1)
	self:RefreshMainWindow()
end 

function FarmLog:PurgeInstances()
	now = time()
	local newtable = {}
	for i, meta in ipairs(FLogGlobalVars.instances[REALM]) do 
		if meta.leave and now - meta.leave >= MAX_INSTANCES_SECONDS then break end 
		tinsert(newtable, meta)
	end 
	FLogGlobalVars.instances[REALM] = newtable
end 

function FarmLog:GetLastInstance(name)
	for i, meta in ipairs(FLogGlobalVars.instances[REALM]) do 
		if meta.name == name then 
			return meta, i
		end 
	end 
end 

function FarmLog:RepushInstance(index)
	local meta = tremove(FLogGlobalVars.instances[REALM], index)
	tinsert(FLogGlobalVars.instances[REALM], 1, meta)
	self:UpdateInstanceCount()
end 

function FarmLog:CloseOpenInstances()
	for _, meta in ipairs(FLogGlobalVars.instances[REALM]) do 
		if not meta.leave then 
			meta.leave = time()
		end 
	end 
end 

-- Session management ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function FarmLog:GetCurrentSessionTime()
	local now = time()
	return GetSessionVar("seconds") + now - (sessionStartTime or now)
end 

function FarmLog:ResumeSession() 
	sessionStartTime = time()
	SetSessionVar("lastUse", sessionStartTime)

	FLogVars.enabled = true  
	FarmLog_MinimapButtonIcon:SetTexture("Interface\\AddOns\\FarmLog\\FarmLogIconON");
	FarmLog_MainWindow:RecalcTotals()
	FarmLog_MainWindow:Refresh()
	FarmLog_MainWindow:UpdateTitle()
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
		FarmLog_MainWindow:UpdateTitle()
	end 
end 

function FarmLog:ResetSessionVars()
	local session = {
		["drops"] = {},
		["kills"] = {},
		["skill"] = {},
		["rep"] = {},
		["gold"] = 0,
		["vendor"] = 0,
		["goldPerHour"] = 0,
		["ah"] = 0,
		["xp"] = 0,
		["honor"] = 0,
		["deaths"] = 0,
		["seconds"] = 0,
		["resets"] = 0,
		["bls"] = {}, -- BL spawn log
	}
	if FLogVars.inInstance then 
		session.resets = 1
		session.instanceName = FLogVars.instanceName
	end 
	FLogVars.sessions[FLogVars.currentSession] = session 
end 

function FarmLog:StartSession(sessionName, pause, resume) 
	if FLogVars.enabled then 
		if pause then 
			self:PauseSession(true) 
		end 
	end 

	FLogVars.currentSession = sessionName
	if not FLogVars.sessions[FLogVars.currentSession] then 
		self:ResetSessionVars()
	end 
	if FLogVars.enabled or resume then 
		self:ResumeSession()
	else 
		FarmLog_MainWindow:RecalcTotals()
		FarmLog_MainWindow:UpdateTitle() -- done by resume, update text color
	end 

	local session = FLogVars.sessions[sessionName]
	if FLogVars.inInstance then 
		if not session.instanceName then 
			session.instanceName = FLogVars.instanceName
		elseif session.instanceName ~= FLogVars.instanceName then 
			session.instanceName = '*'
		end 
	end 

	self:RefreshMainWindow()
end 

function FarmLog:DeleteSession(name) 
	FLogVars.sessions[name] = nil 
	if FLogVars.currentSession == name then 
		self:StartSession("default", false, FLogVars.enabled)
		self:RefreshMainWindow()
		out("Switched to farm session |cff99ff00default|r")
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
	self:RefreshMainWindow()
end

function FarmLog:ToggleLogging() 
	if FLogVars.enabled then 
		self:PauseSession()
		out("Farm session |cff99ff00"..FLogVars.currentSession.."|r paused|r")
	else 
		self:StartSession(FLogVars.currentSession or "default", false, true)
		if GetSessionVar("seconds") == 0 then 
			out("Farm session |cff99ff00"..FLogVars.currentSession.."|r started")
		else 
			out("Farm session |cff99ff00"..FLogVars.currentSession.."|r resumed")
		end 	
	end 
end 

function FarmLog:RefreshMainWindow()
	FarmLog_MainWindow:Refresh()
end 

-- Question dialog

function FarmLog:AskQuestion(titleText, questionText, onYes, onNo, yesText, noText) 
	FarmLog_QuestionDialog_Yes:SetScript("OnClick", function () 
		FarmLog_QuestionDialog:Hide()
		onYes() 
	end)
	FarmLog_QuestionDialog_No:SetScript("OnClick", function () 
		FarmLog_QuestionDialog:Hide()
		if onNo then onNo() end 
	end)
	FarmLog_QuestionDialog_Title_Text:SetText(titleText)
	FarmLog_QuestionDialog_Question:SetText(questionText)
	FarmLog_QuestionDialog_Yes:SetText(yesText or L["Yes"])
	FarmLog_QuestionDialog_No:SetText(noText or L["No"])
	FarmLog_QuestionDialog:Show()
end 

-- Generic Rows Creation ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local function CreateRow_Text(existingRow, text, container)
	local row = existingRow or {};
	local previousType = row.type
	row.type = "text"

	if not row.root then 
		row.root = CreateFrame("FRAME", nil, container.scrollContent);		
		-- row.root:SetWidth(container.scrollContent:GetWidth() - 20);
		row.root:SetHeight(15);
		row.root:SetBackdropColor(1, 0, 0, 1)
		if #container.rows == 0 then 
			row.root:SetPoint("TOPLEFT", container.scrollContent);
			row.root:SetPoint("RIGHT", container.scroll, 0, 0);
		else 
			row.root:SetPoint("TOPLEFT", container.rows[#container.rows].root, "BOTTOMLEFT");
			row.root:SetPoint("TOPRIGHT", container.rows[#container.rows].root, "BOTTOMRIGHT");
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
		row.label:SetFont(FONT_NAME, 12)
	end 
	row.label:SetText(text);
	row.label:Show()

	if not existingRow then 
		tinsert(container.rows, row);
	end 
	return row
end

local function HideRowsBeyond(j, container)
	local n = #container.rows;
	if j <= n then 
		for i = j, n do
			container.rows[i].root:Hide()
		end
	end 
end

local function SetItemTooltip(row, itemLink, text)
	row.root:SetScript("OnEnter", function(self)
		FarmLog_MainWindow:MouseEnter()
		self:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background"})
		self:SetBackdropColor(0.8,0.8,0.8,0.6)
		if FLogVars.itemTooltip then
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			if itemLink then 
				GameTooltip:SetHyperlink(itemLink)
			elseif text then 
				GameTooltip:SetText(text)
			end 					
			GameTooltip:Show()
		end
	end);
	row.root:SetScript("OnLeave", function(self)
		FarmLog_MainWindow:MouseLeave()
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


-- Main Window UI ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function FarmLog_MainWindow:OnEvent(event, ...)
	if event == "MODIFIER_STATE_CHANGED" then 
		if IsShiftKeyDown() and not lastShiftState and mouseOnMainWindow then 
			lastShiftState = true 
			self:Refresh()
		elseif not IsShiftKeyDown() and lastShiftState then 
			lastShiftState = false 
			self:Refresh()
		end  
	end
end 

function FarmLog_MainWindow:MouseEnter()
	mouseOnMainWindow = true 
end 

function FarmLog_MainWindow:MouseLeave()
	mouseOnMainWindow = false
end 

function FarmLog_MainWindow:CreateRow(text, valueText)
	local row = CreateRow_Text(self.rows[self.visibleRows], text, self)

	if not row.valueLabel then 
		row.valueLabel = row.root:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
		row.valueLabel:SetTextColor(0.8, 0.8, 0.8, 1)
		row.valueLabel:SetPoint("RIGHT", 0, 0)
		row.valueLabel:SetFont(FONT_NAME, 12)
	end 
	-- debug("FarmLog_MainWindow:CreateRow "..text..tostring(valueText))
	row.valueLabel:SetText(valueText or "");
	row.valueLabel:Show()

	return row
end


function FarmLog_MainWindow:AddRow(text, valueText, quantity, color, valueColor) 
	self.visibleRows = self.visibleRows + 1
	text = "|cff"..(color or "dddddd")..text.."|r"
	if valueText and valueColor then 
		valueText = "|cff"..valueColor..valueText.."|r"
	end 
	if quantity and quantity > 1 then 
		text = text.." x"..tostring(quantity)
	end 
	return self:CreateRow(text, valueText)
end 

function FarmLog_MainWindow:GetTitleText()
	local text = FLogVars.currentSession or ""
	local time = FarmLog:GetCurrentSessionTime() or 0
	if time > 0 then 
		text = text .. "  --  " .. secondsToClock(time) 
	end 
	-- if goldPerHour and goldPerHour > 0 and tostring(goldPerHour) ~= "nan" tostring(goldPerHour) ~= "inf" then 
	-- 	text = text .. " / " .. GetShortCoinTextureString(goldPerHour) .. " g/h"
	-- end 
	return text
end 

function FarmLog_MainWindow:UpdateTitle()
	if FLogVars.enabled then 
		FarmLog_MainWindow_Title_Text:SetTextColor(0, 1, 0, 1.0);
	else 
		FarmLog_MainWindow_Title_Text:SetTextColor(1, 1, 0, 1.0);
		FarmLog_MainWindow_Title_Text:SetText(self:GetTitleText())
	end 
end 

function FarmLog_MainWindow:ToggleWindow()
	if self:IsShown() then
		self:Hide()
		self:SaveVisibility()
	else
		self:LoadPosition()
		self:Show()
		self:SaveVisibility()
	end
end

function FarmLog_MainWindow:PlaceLinkInChatEditBox(itemLink)
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

function FarmLog_MainWindow:GetOnLogItemClick(itemLink) 
	return function(self, button)
		if IsShiftKeyDown() then
			FarmLog_MainWindow:PlaceLinkInChatEditBox(itemLink) -- paste in chat box
		elseif IsControlKeyDown() then
			DressUpItemLink(itemLink) -- preview
		else 
			if extractItemID(itemLink) == tostring(BL_ITEMID) then 
				FarmLog:ShowBlackLotusLog()
			end 
		end
	end 
end

function FarmLog_MainWindow:Refresh()
	self.visibleRows = 0

	-- calculate GPH
	local sessionTime = FarmLog:GetCurrentSessionTime()
	local goldPerHour = 0
	if sessionTime > 0 then 
		goldPerHour = (GetSessionVar("ah") + GetSessionVar("vendor") + GetSessionVar("gold")) / (sessionTime / 3600)
	end 
	SetSessionVar("goldPerHour", goldPerHour)
	
	-- add special rows
	if goldPerHour and goldPerHour > 0 and tostring(goldPerHour) ~= "nan" and tostring(goldPerHour) ~= "inf" then 
		self:AddRow(L["Gold / Hour"], GetShortCoinTextureString(goldPerHour), nil, nil)
	end 
	if GetSessionVar("ah") > 0 then 
		self:AddRow(L["Auction House"], GetShortCoinTextureString(GetSessionVar("ah")), nil, TEXT_COLOR["money"]) 
	end 
	if GetSessionVar("gold") > 0 then 
		self:AddRow(L["Money"], GetShortCoinTextureString(GetSessionVar("gold")), nil, TEXT_COLOR["money"])
	end 
	if GetSessionVar("vendor") > 0 then 
		self:AddRow(L["Vendor"], GetShortCoinTextureString(GetSessionVar("vendor")), nil, TEXT_COLOR["money"]) 
	end 
	if GetSessionVar("xp") > 0 then 
		self:AddRow(GetSessionVar("xp").." "..L["XP"], nil, nil, TEXT_COLOR["xp"]) 
	end 
	if GetSessionVar("resets") > 0 then 
		self:AddRow(GetSessionVar("resets").." "..L["Instances"], nil, nil, TEXT_COLOR["xp"]) 
	end 
	if GetSessionVar("deaths") > 0 then 
		self:AddRow(GetSessionVar("deaths").." "..L["Deaths"], nil, nil, TEXT_COLOR["deaths"]) 
	end 
	for faction, rep in pairs(GetSessionVar("rep")) do 
		self:AddRow(rep.." "..faction.." "..L["reputation"], nil, nil, TEXT_COLOR["rep"]) 
	end 
	for skillName, levels in pairs(GetSessionVar("skill")) do 
		self:AddRow("+"..levels.." "..skillName, nil, nil, TEXT_COLOR["skill"])
	end 

	local sessionDrops = GetSessionVar("drops")
	local sortLinksByText = FLogGlobalVars.sortBy == SORT_BY_TEXT or FLogGlobalVars.sortBy == SORT_BY_KILLS
	local extractGold = function (meta) return meta[DROP_META_INDEX_VALUE] end  
	local extractLink = function (link) return GetItemInfo(link) or link end  
	local valueIndex = DROP_META_INDEX_VALUE
	if IsShiftKeyDown() then valueIndex = DROP_META_INDEX_VALUE_EACH end 

	local addDropRows = function (dropMap, indent) 
		local sortedItemLinks = SortMapKeys(dropMap, not sortLinksByText, not sortLinksByText, extractLink, extractGold)
		for _, itemLink in ipairs(sortedItemLinks) do			
			if not FLogGlobalVars.ignoredItems[itemLink] then 
				local meta = dropMap[itemLink]
				local colorType = meta[DROP_META_INDEX_VALUE_TYPE] or "?"
				local color = VALUE_TYPE_COLOR[colorType]
				-- debug("|cff999999FarmLog_MainWindow:Refresh|r link |cffff9900"..itemLink.."|r color |cffff9900"..color.."|r")
				local text = itemLink
				if indent then text = "    "..text end 
				local row = self:AddRow(text, GetShortCoinTextureString(meta[valueIndex]), meta[DROP_META_INDEX_COUNT], nil, color)
				SetItemTooltip(row, itemLink)
				SetItemActions(row, self:GetOnLogItemClick(itemLink))
				row.root:Show();
			end 
		end		
	end 

	if FLogGlobalVars.groupByMobName then 
		local sessionKills = GetSessionVar("kills")
		local sortedNames
		if FLogGlobalVars.sortBy == SORT_BY_GOLD then 
			local mobGold = {}
			for mobName, _ in pairs(sessionKills) do 
				local mobDrops = sessionDrops[mobName]
				local gold = 0
				if mobDrops then 
					for _, meta in pairs(mobDrops) do 
						gold = gold + (meta[DROP_META_INDEX_VALUE] or 0)
					end 
				end 
				mobGold[mobName] = gold 
			end 
			sortedNames = SortMapKeys(mobGold, true, true)
		else 
			local sortByKills = FLogGlobalVars.sortBy == SORT_BY_KILLS
			sortedNames = SortMapKeys(sessionKills, sortByKills, sortByKills)
		end 

		-- add mob rows

		for _, mobName in ipairs(sortedNames) do	
			self:AddRow(mobName, nil, sessionKills[mobName], TEXT_COLOR[mobName] or TEXT_COLOR["mob"])
			addDropRows(sessionDrops[mobName] or {}, true)
		end
	else 
		local mergedDrops = {}
		for _, drops in pairs(sessionDrops) do	
			for link, meta in pairs(drops) do 
				local mergedMeta = mergedDrops[link]
				if not mergedMeta then 
					mergedDrops[link] = { 
						meta[DROP_META_INDEX_COUNT], 
						meta[DROP_META_INDEX_VALUE], 
						meta[DROP_META_INDEX_VALUE_EACH], 
						meta[DROP_META_INDEX_VALUE_TYPE] 
					} 
				else 
					mergedMeta[DROP_META_INDEX_COUNT] = mergedMeta[DROP_META_INDEX_COUNT] + meta[DROP_META_INDEX_COUNT]
					mergedMeta[DROP_META_INDEX_VALUE] = mergedMeta[DROP_META_INDEX_VALUE] + meta[DROP_META_INDEX_VALUE]
				end 
			end
		end 
		addDropRows(mergedDrops)
	end 

	-- buttons state
	FarmLog_MainWindow_ClearButton.disabled = #self.rows == 0
	FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_ClearButton)

	-- hide unused rows
	HideRowsBeyond(self.visibleRows + 1, self)
end

function FarmLog_MainWindow:RecalcTotals()
	-- debug("|cff999999FarmLog_MainWindow:RecalcTotals()")
	local sessionVendor = 0
	local sessionAH = 0
	local sessionDrops = GetSessionVar("drops")
	for mobName, drops in pairs(sessionDrops) do	
		for itemLink, meta in pairs(drops) do 
			if not FLogGlobalVars.ignoredItems[itemLink] then 
				local ahPrice = GetManualPrice(itemLink)
				local priceType = VALUE_TYPE_MANUAL
				if not ahPrice then 
					ahPrice = GetAHScanPrice(itemLink)
					priceType = VALUE_TYPE_SCAN
				end 
				local count = meta[DROP_META_INDEX_COUNT]
				if ahPrice and ahPrice > 0 then 
					local value = ahPrice * count
					sessionAH = sessionAH + value 
					meta[DROP_META_INDEX_VALUE] = value
					meta[DROP_META_INDEX_VALUE_EACH] = ahPrice					
					meta[DROP_META_INDEX_VALUE_TYPE] = priceType
				else 
					local _, _, _, _, _, _, _, _, _, _, vendorPrice = GetItemInfo(itemLink);
					sessionVendor = sessionVendor + (vendorPrice or 0) * count
					meta[DROP_META_INDEX_VALUE] = (vendorPrice or 0) * count
					meta[DROP_META_INDEX_VALUE_EACH] = (vendorPrice or 0)					
					meta[DROP_META_INDEX_VALUE_TYPE] = VALUE_TYPE_VENDOR
				end 
			end 
		end 
	end 
	SetSessionVar("vendor", sessionVendor)
	SetSessionVar("ah", sessionAH)
end 

function FarmLog_MainWindow:UpdateTime()
	local sessionTime = FarmLog:GetCurrentSessionTime()
	FarmLog_MainWindow_Title_Text:SetText(self:GetTitleText());
	if showingMinimapTip then 
		FarmLog_MinimapButton:UpdateTooltipText()
	end 
end 


-- SESSIONS WINDOW ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function FarmLog_SessionsWindow:CreateRow(text, valueText)
	local row = CreateRow_Text(self.rows[self.visibleRows], text, self)

	if not row.valueLabel then 
		row.valueLabel = row.root:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
		row.valueLabel:SetTextColor(0.8, 0.8, 0.8, 1)
		row.valueLabel:SetPoint("RIGHT", 20, 0)
		row.valueLabel:SetFont(FONT_NAME, 12)
	end 	-- debug("FarmLog_MainWindow:CreateRow "..text..tostring(valueText))
	row.valueLabel:SetText(valueText or "");
	row.valueLabel:Show()

	return row
end

function FarmLog_SessionsWindow:AddRow(text, valueText, quantity, color) 
	self.visibleRows = self.visibleRows + 1
	text = "|cff"..(color or "dddddd")..text.."|r"
	if quantity and quantity > 1 then 
		text = text.." x"..tostring(quantity)
	end 
	return self:CreateRow(text, valueText)
end 

function FarmLog_SessionsWindow:Refresh()
	self.visibleRows = 0

	local searchText = FarmLog_SessionsWindow_Buttons_SearchBox:GetText()

	local sortedKeys
	if FLogGlobalVars.sortSessionBy == SORT_BY_TEXT then 
		sortedKeys = SortMapKeys(FLogVars.sessions, nil, nil, nil, nil, searchText)
	elseif FLogGlobalVars.sortSessionBy == SORT_BY_GOLD then 
		local gphExtract = function (session) return session.goldPerHour or 0 end
		sortedKeys = SortMapKeys(FLogVars.sessions, true, true, nil, gphExtract, searchText)
	elseif FLogGlobalVars.sortSessionBy == SORT_BY_USE then 
		local useExtract = function (session) return session.lastUse or 0 end
		sortedKeys = SortMapKeys(FLogVars.sessions, true, true, nil, useExtract, searchText)
	end 

	if #sortedKeys == 1 then sessionSearchResult = sortedKeys[1] else sessionSearchResult = nil end 

	for _, name in ipairs(sortedKeys) do 
		local session = FLogVars.sessions[name]
		local gph = session.goldPerHour or 0 -- (GetSessionVar("ah", name) + GetSessionVar("vendor", name) + GetSessionVar("gold", name)) / (GetSessionVar("seconds", name) / 3600)
		local text = name
		local valueText = nil 
		if gph and gph > 0 and tostring(gph) ~= "nan" and tostring(gph) ~= "inf" then 
			valueText = GetShortCoinTextureString(gph) .. " " .. L["g/h"]
		end 
		local row = self:AddRow(text, valueText)
		SetItemTooltip(row)
		SetItemActions(row, self:GetOnLogItemClick(name))
	end 
	HideRowsBeyond(self.visibleRows + 1, self)
end

function FarmLog_SessionsWindow:GetOnLogItemClick(sessionName) 
	return function(self, button)
		if button == "RightButton" then 
			FarmLog:AskQuestion(L["deletesession-title"], L["deletesession-question"], function() 
				FarmLog:DeleteSession(sessionName)
				FarmLog:RefreshMainWindow()
				FarmLog_SessionsWindow:Refresh()
				FarmLog_QuestionDialog:Hide()
			end)
		else 
			if IsAltKeyDown() then
				-- edit?
			else 
				out("Switched to farm session |cff99ff00"..sessionName.."|r")
				FarmLog:StartSession(sessionName, true, FLogGlobalVars.resumeSessionOnSwitch)
				FarmLog_SessionsWindow:Hide()
			end
		end 
	end 
end

-- Log window ------------------------------------

function FarmLog_LogWindow:CreateRow(text, valueText)
	local row = CreateRow_Text(self.rows[self.visibleRows], text, self)

	if not row.valueLabel then 
		row.valueLabel = row.root:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
		row.valueLabel:SetTextColor(0.8, 0.8, 0.8, 1)
		row.valueLabel:SetPoint("RIGHT", 0, 0)
		row.valueLabel:SetFont(FONT_NAME, 12)
	end 	-- debug("FarmLog_MainWindow:CreateRow "..text..tostring(valueText))
	row.valueLabel:SetText(valueText or "");
	row.valueLabel:Show()

	return row
end

function FarmLog_LogWindow:AddPickRow(map, coords, picked, time) 
	self.visibleRows = self.visibleRows + 1
	local text = "  |cff66aa33"..map.." |cff777777@|r "..coords.x.."|cff777777,|r"..coords.y
	if picked then text = text.." |cff888888("..L["picked"]..")|r" end 
	return self:CreateRow(text, time)
end 

function FarmLog_LogWindow:AddMapRow(map, count) 
	self.visibleRows = self.visibleRows + 1
	return self:CreateRow("|cff99ff00"..map.."|r |cff777777x|r"..count)
end 

function FarmLog_LogWindow:RefreshBlackLotusLog()
	self.visibleRows = 0

	for mapName, mapData in pairs(FLogVars.bls) do 
		self:AddMapRow(mapName, #mapData)
		for _, pickData in ipairs(mapData) do 
			local row = self:AddPickRow(pickData.zone, pickData.pos, pickData.picked, "|cffffffff"..pickData.time.."|r  "..pickData.date)
			-- SetItemTooltip(row)
			-- SetItemActions(row, self:GetOnLogItemClick(name))
		end 
	end 
	HideRowsBeyond(self.visibleRows + 1, self)
end

function FarmLog:ShowBlackLotusLog()
	FarmLog_LogWindow_Title_Text:SetTextColor(0.3, 0.7, 1, 1)
	FarmLog_LogWindow_Title_Text:SetText(L["bl-log-title"])
	FarmLog_LogWindow:RefreshBlackLotusLog()
	FarmLog_LogWindow:Show()
end 


-- EVENTS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Spell cast 

function FarmLog:OnSpellCastEvent(unit, target, guid, spellId)
	debug("|cff999999OnSpellCastEvent|r spellId |cffff9900"..tostring(spellId))

	if spellId == SPELL_HERBING then 
		skillName = L["Herbalism"]
		skillNameTime = time()
		skillTooltip1 = GameTooltipTextLeft1:GetText()
		if skillTooltip1 == BL_ITEM_NAME then 
			self:IncreaseBlackLotusPickStat("attempt")
		end 
	elseif spellId == SPELL_MINING then 
		skillName = L["Mining"]
		skillNameTime = time()
	elseif spellId == SPELL_FISHING then 
		skillName = L["Fishing"]
		skillNameTime = time()
	elseif spellId == SPELL_OPEN or spellId == SPELL_OPEN_NOTEXT then 
		skillName = L["Treasure"]
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

function FarmLog:OnPlayerDead()
	debug("|cff999999OnPlayerDead|r")
	IncreaseSessionVar("deaths", 1)
	self:RefreshMainWindow()
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
		local mobGuid = eventInfo[8]

		-- count mob kill
		local sessionKills = GetSessionVar("kills")
		sessionKills[mobName] = (sessionKills[mobName] or 0) + 1

		-- make sure this mob has a drops entry, even if it won't drop anything
		local sessionDrops = GetSessionVar("drops")
		if not sessionDrops[mobName] then 
			sessionDrops[mobName] = {}
		end 

		-- debug("Player "..eventInfo[5].." killed "..eventInfo[9].." x "..tostring(sessionKills[mobName]))
		self:RefreshMainWindow()
	end 
end 

-- Loot window event

function FarmLog:OnLootOpened(autoLoot)
	local lootCount = GetNumLootItems()
	local mobName = nil 
	if skillName then 
		mobName = skillName 
		-- count gathering skill act in kills table
		local sessionKills = GetSessionVar("kills")
		sessionKills[skillName] = (sessionKills[skillName] or 0) + 1
	end 
	if not mobName and UnitIsEnemy("player", "target") and UnitIsDead("target") and not lastLootedMobs[UnitGUID("target")] then 
		lastLootedMobs[UnitGUID("target")] = time()
		mobName = UnitName("target") 
	end 
	
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
			-- if mobName and lastUnknownLoot[link] and now - lastUnknownLootTime < LOOT_AUTOFIX_TIMEOUT_SEC then 
			-- 	-- sometimes when "Fast auto loot" is enabled, OnLootEvent will be called before OnLootOpened
			-- 	-- so reattribute this loot now that we know from which mob it dropped
			-- 	debug("|cff999999FarmLog:OnLootOpened|r reattributing loot")
			-- 	local drops = GetSessionVar("drops")
			-- 	drops[UNKNOWN_MOBNAME][DROP_META_INDEX_COUNT] = drops[UNKNOWN_MOBNAME][DROP_META_INDEX_COUNT] - 1
			-- 	if drops[UNKNOWN_MOBNAME][DROP_META_INDEX_COUNT] == 0 then 
			-- 		drops[UNKNOWN_MOBNAME] = nil 
			-- 	end 
			-- 	local _, _, _, quality, _ = GetLootSlotInfo(slot)
			-- 	self:InsertLoot(mobName, normalizeLink(itemLink), quality or 1)
			-- end 
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

-- Black lotus tracking

function FarmLog:SetBlackLotusItemId(itemId) 
	BL_ITEM_NAME = GetItemInfo(itemId)
	BL_ITEMID = itemId
	debug("|cff999999SetBlackLotusItemId|r BL_ITEM_NAME |cffff9900"..tostring(BL_ITEM_NAME).."|r BL_ITEMID |cffff9900"..tostring(BL_ITEMID))
end 

function FarmLog:LogBlackLotusCurrentLocation(byPlayer)
	-- log spawn
	local MapId = C_Map.GetBestMapForUnit("player")
	if not MapId then 
		out("|cffff0000Failed logging Black Lotus loot - no map id")
		return 
	end
	local map = C_Map.GetPlayerMapPosition(MapId, "player")
	if not map then 
		out("|cffff0000Failed logging Black Lotus loot - no map info")
		return 
	end
	local x = format("%.1f", (map.x or 0) * 100)
	local y = format("%.1f", (map.y or 0) * 100)

	local mapName = GetZoneText()
	local now = time()
	local pickMeta = {
		["ts"] = now,
		["time"] = date("%H:%M"),
		["date"] = date("%m-%d"),
		["pos"] = {["x"] = x, ["y"] = y},
		["zone"] = GetMinimapZoneText(),
		["picked"] = byPlayer,
	}
	if blSeen and blSeen.zone == mapName and now - blSeen.ts <= BL_SEEN_TIMEOUT then 
		pickMeta.seen = blSeen
	end 
	blSeen = nil 
	self:LogBlackLotus(mapName, pickMeta)
end 

function FarmLog:LogBlackLotus(mapName, pickMeta)
	if not FLogVars.bls[mapName] then FLogVars.bls[mapName] = {} end 
	tinsert(FLogVars.bls[mapName], pickMeta)
	debug("|cff999999LogBlackLotus|r logged Black Lotus pick at |cffff9900"..mapName)

	-- save time for timer
	FLogGlobalVars.blt[REALM][mapName] = pickMeta.ts
	self:ShowBlackLotusTimers()
end 

function FarmLog:IncreaseBlackLotusPickStat(statName)
	for skillIndex=1,50 do 
		local skillName, _, _, skillRank, _, skillGear = GetSkillLineInfo(skillIndex)
		if skillName == SKILL_HERB_TEXT then 
			local rank = tostring(skillRank + skillGear)
			-- debug("|cff999999IncreaseBlackLotusPickStat|r found |cffff9900"..tostring(skillName).."|r index |cffff9900"..skillIndex.."|r rank |cffff9900"..skillRank)
			local rankMeta = FLogGlobalVars.blp[rank]
			if not rankMeta then 
				rankMeta = {[statName] = 1}
				FLogGlobalVars.blp[rank] = rankMeta
			else 
				rankMeta[statName] = (rankMeta[statName] or 0) + 1
			end 
			debug("|cff999999IncreaseBlackLotusPickStat|r increased |cffff9900"..BL_ITEM_NAME.."|r stat |cffff9900"..statName.."|r to |cffff9900"..tostring(rankMeta[statName]))
			return true 
		end 
	end 
	out("|cffff0000Could not find Herbalism skill, failed logging pick")
end 

function FarmLog:ParseMinimapTooltip()
	local tooltip = GameTooltipTextLeft1:GetText()
	if tooltip == BL_ITEM_NAME and (not blSeen or blSeen.zone ~= GetZoneText() or time() - blSeen.ts > BL_SEEN_TIMEOUT) then
		blSeen = {
			["ts"] = time(),
			["time"] = date ("%H:%M:%S"),
			["date"] = date ("%Y-%m-%d"),
			["zone"] = GetZoneText(),
		}
		debug("|cff999999ParseMinimapTooltip|r blSeenTime |cffff9900"..blSeen.ts.."|r blSeenZone |cffff9900"..blSeen.zone)
	end
end 

function FarmLog:ShowBlackLotusTimers()
	local now = time()
	if DBM then 
		for realmName, timers in pairs(FLogGlobalVars.blt) do 
			if realmName == REALM then 
				for zoneName, lastPick in pairs(timers) do 
					local delta = now - lastPick
					if delta < BL_SPAWN_TIME_SECONDS then 
						DBM:CreatePizzaTimer(BL_SPAWN_TIME_SECONDS - delta, L["blacklotus-short"]..": "..zoneName)
					end 
				end 
			end 
		end 
	end 
end 

-- Loot receive event

function FarmLog:InsertLoot(mobName, itemLink, count, vendorPrice)
	if (mobName and itemLink and count) then		
		local value = GetManualPrice(itemLink)
		local priceType = VALUE_TYPE_MANUAL
		if not value then 
			value = GetAHScanPrice(itemLink)
			priceType = VALUE_TYPE_SCAN
		end 
		if not value or value == 0 then 
			value = vendorPrice or 0
			priceType = VALUE_TYPE_VENDOR
			IncreaseSessionVar("vendor", value * count)
		else 
			IncreaseSessionVar("ah", value * count)
		end 
		debug("|cff999999FarmLog:InsertLoot|r using |cffff9900"..priceType.."|r price of |cffff9900"..value)

		local sessionDrops = GetSessionVar("drops")
		if not sessionDrops[mobName] then		
			sessionDrops[mobName] = {}
		end 
		local meta = sessionDrops[mobName][itemLink]
		if meta then
			debug("|cff999999FarmLog:InsertLoot|r meta |cffff9900"..meta[1]..","..meta[2]..","..meta[3]..","..meta[4])
			meta[DROP_META_INDEX_COUNT] = meta[DROP_META_INDEX_COUNT] + count
			meta[DROP_META_INDEX_VALUE] = value * meta[DROP_META_INDEX_COUNT] 
			meta[DROP_META_INDEX_VALUE_EACH] = value				
			meta[DROP_META_INDEX_VALUE_TYPE] = priceType				
		else
			sessionDrops[mobName][itemLink] = {count, value * count, value, priceType};
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

	local itemId = extractItemID(itemLink)
	debug("|cff999999OnLootEvent|r itemId |cffff9900"..tostring(itemId))
	if itemId == tostring(BL_ITEMID) then 
		-- start timer even if not in session
		self:LogBlackLotusCurrentLocation(true)
		self:IncreaseBlackLotusPickStat("success")
	end 

	if not FLogVars.enabled then return end 

	local _, _, itemRarity, _, _, itemType, _, _, _, _, vendorPrice = GetItemInfo(itemLink);
	mobName = lastMobLoot[itemLink]

	if not mobName then 
		-- loot window hasn't opened yet
		if not UnitInParty("player") and not IsInRaid() and UnitIsEnemy("player", "target") and UnitIsDead("target") and not lastLootedMobs[UnitGUID("target")] then 
			debug("Assuming targeted mob for loot source, GUID "..UnitGUID("target")) 
			lastLootedMobs[UnitGUID("target")] = time()
			-- with fast loot the loot window opens late and is empty, we assume that our dead target is the source
			-- unless in party / raid where we can receive items from rolls / ML
			mobName = UnitName("target")
		else 
			mobName = UNKNOWN_MOBNAME
			if now - lastUnknownLootTime > LOOT_AUTOFIX_TIMEOUT_SEC then lastUnknownLoot = {} end 
			lastUnknownLootTime = now 
			lastUnknownLoot[itemLink] = true 
			GetSessionVar("kills")[UNKNOWN_MOBNAME] = 1
		end 
	end 

	itemLink = normalizeLink(itemLink) -- removed player level from link

	debug("|cff999999FarmLog:OnLootEvent|r itemLink |cffff9900"..itemLink.."|r, mobName |cffff9900"..tostring(mobName).."|r itemId |cffff9900"..tostring(itemId))

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
		self:InsertLoot(mobName, itemLink, (quantity or 1), vendorPrice or 0);
		self:RefreshMainWindow();
	end
end

-- Addon Loaded

function FarmLog:OnAddonLoaded()
	out("|cffffbb00v"..tostring(VERSION).."|r "..CREDITS..", "..L["loaded-welcome"]);

	FarmLog:Migrate()	

	if not FLogGlobalVars.ahScan[REALM] then FLogGlobalVars.ahScan[REALM] = {} end 
	if not FLogGlobalVars.ahPrice[REALM] then FLogGlobalVars.ahPrice[REALM] = {} end 
	if not FLogGlobalVars.instances[REALM] then FLogGlobalVars.instances[REALM] = {} end 
	if not FLogGlobalVars.blt[REALM] then FLogGlobalVars.blt[REALM] = {} end 

	if FLogGlobalVars.dismissLootWindowOnEsc then  
		tinsert(UISpecialFrames, FarmLog_MainWindow:GetName())
	end 

	if not FLogVars.lockFrames then		
		FarmLog_MainWindow_Title:RegisterForDrag("LeftButton");			
	end

	FarmLog_SessionsWindow_Title_Text:SetTextColor(0.3, 0.7, 1, 1)
	FarmLog_SessionsWindow_Title_Text:SetText(L["All Sessions"])

	-- loot window buttons
	if FLogGlobalVars.sortBy == SORT_BY_TEXT then 
		FarmLog_MainWindow_Buttons_SortAbcButton.selected = true 
	elseif FLogGlobalVars.sortBy == SORT_BY_GOLD then 
		FarmLog_MainWindow_Buttons_SortGoldButton.selected = true 
	elseif FLogGlobalVars.sortBy == SORT_BY_KILLS then 
		FarmLog_MainWindow_Buttons_SortKillsButton.selected = true 
	end 
	FarmLog_MainWindow_Buttons_ToggleMobNameButton.selected = FLogGlobalVars.groupByMobName
	FarmLog_MainWindow_Buttons_SortKillsButton.disabled = not FLogGlobalVars.groupByMobName
	FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_Buttons_SortAbcButton)
	FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_Buttons_SortGoldButton)
	FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_Buttons_SortKillsButton)
	FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_Buttons_ToggleMobNameButton)
	FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_SessionsButton)
	FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_ClearButton)

	-- sessions window buttons
	if FLogGlobalVars.sortSessionsBy == SORT_BY_TEXT then 
		FarmLog_SessionsWindow_Buttons_SortAbcButton.selected = true 
	elseif FLogGlobalVars.sortSessionsBy == SORT_BY_GOLD then 
		FarmLog_SessionsWindow_Buttons_SortGoldButton.selected = true 
	elseif FLogGlobalVars.sortSessionsBy == SORT_BY_USE then 
		FarmLog_SessionsWindow_Buttons_SortUseButton.selected = true 
	end 
	FarmLog_SetTextButtonBackdropColor(FarmLog_SessionsWindow_Buttons_SortAbcButton)
	FarmLog_SetTextButtonBackdropColor(FarmLog_SessionsWindow_Buttons_SortGoldButton)
	FarmLog_SetTextButtonBackdropColor(FarmLog_SessionsWindow_Buttons_SortUseButton)
	
	self:UpdateInstanceCount()

	-- init session
	if FLogVars.enabled then 
		self:ResumeSession()
	else 
		self:PauseSession()
		FarmLog_MainWindow:RecalcTotals()
	end 
	self:RefreshMainWindow()

	-- init window visibility
	FarmLog_MainWindow:LoadPosition()
	if FLogVars.frameRect.visible then 
		FarmLog_MainWindow:Show()
	else 
		FarmLog_MainWindow:Hide()
	end 
	addonLoadedTime = time()
end 

-- Entering World

function FarmLog:OnEnteringWorld() 
	self:PurgeInstances()
	self:UpdateInstanceCount()

	local inInstance, _ = IsInInstance()
	inInstance = tobool(inInstance)
	local instanceName = GetInstanceInfo()
	local now = time()
	debug("|cff999999FarmLog:OnEnteringWorld|r FLogVars.inInstance |cffff9900"..tostring(FLogVars.inInstance).."|r inInstance |cffff9900"..tostring(inInstance))

	if FLogVars.inInstance and not inInstance then 
		FLogVars.inInstance = false
		FLogVars.instanceName = nil
		self:CloseOpenInstances()
		if FLogGlobalVars.autoSwitchInstances then 
			self:PauseSession()
		end 
	elseif inInstance then
		local lastInstance, lastIndex = self:GetLastInstance(instanceName)
		if lastInstance and lastInstance.leave and now - lastInstance.leave >= INSTANCE_RESET_SECONDS then 
			-- after 1 hour of not being inside the instance, treat this instance as reset
			lastInstance = nil 
		end 
		FLogVars.inInstance = true
		FLogVars.instanceName = instanceName
		if FLogGlobalVars.autoSwitchInstances then 
			self:StartSession(instanceName, true, true)
		end 
		if not lastInstance then 
			FarmLog:AddInstance(instanceName, now)
		else 
			self:AskQuestion(L["new-instance-title"], L["new-instance-question"], function () 
				-- yes
				FarmLog:AddInstance(instanceName, now)
			end, function () 
				-- no
				lastInstance.leave = nil 
				FarmLog:RepushInstance(lastIndex)
			end)
		end 
	end
	self:RefreshMainWindow()
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

-- Enter combat 

function FarmLog:OnEnterCombat()
	local now = time()
	for guid, t in pairs(lastLootedMobs) do
		if now - t >= PURGE_LOOTED_MOBS_SECONDS then 
			lastLootedMobs[guid] = nil
		end 
	end 
end 

-- Auction House Scan --------------------------------------------------------------------------

function FarmLog:ScanAuctionHouse()
	canQuery, canMassQuery = CanSendAuctionQuery("list")
	if not canMassQuery then 
		out("|cffff4444Can't mass scan yet. You can do this once in 15 minutes.")
		return 
	end 
	out("|cffffee44Starting Auction House scan... ")
	out("|cffaaaaaaThis may take around 30 seconds, depending on how many items are on the AH.")
	ahScanRequested = true 
	QueryAuctionItems("", nil, nil, 0, false, FLogGlobalVars.ahMinQuality, true)
end

function FarmLog:OnAuctionUpdate()
	if ahScanRequested then 
		debug("|cff00ffffOnAuctionUpdate|r Results arrived")
		self:PrepareAuctionHouseResults()
		self:AnalyzeAuctionHouseResults()
	end 
end

function FarmLog:PrepareAuctionHouseResults()
	ahScanResultsShown, ahScanResultsTotal = GetNumAuctionItems("list");
	ahScanRequested = false 
	ahScanning = true 
	ahScanIndex = 1
	ahScanItems = 0
	ahScanBadItems = 0
	FLogGlobalVars.ahScan[REALM] = {}
	out("Scanning "..ahScanResultsShown.." Auction House results...")
end 

function FarmLog:AnalyzeAuctionHouseResults()
	if ahScanResultsShown > 0 and ahScanIndex < ahScanResultsShown then
		local x = ahScanIndex
		local tries = 0
		while x <= ahScanResultsShown do
			local 	name, texture, count, quality, canUse, level, unknown1, minBid, minIncrement, buyoutPrice, bidAmount, 
					highestBidder, unknown2, owner, unknown3, sold, unknown4 = GetAuctionItemInfo( "list", x )
			local 	link = GetAuctionItemLink( "list", x )
			
			if name == nil or name == "" or link == nil then
				-- debug(" scan -- bad item " .. x .. " link " .. tostring(link) .. " name ".. tostring(name))
				if tries < MAX_AH_RETRY then 
					x = x - 1
					tries = tries + 1
				else 
					ahScanBadItems = ahScanBadItems + 1 -- removed items?? no idea why some are missing
				end 
			else
				tries = 0
				ahScanItems = ahScanItems + 1
				-- ignore items without buyout
				if buyoutPrice and buyoutPrice > 0 and quality >= FLogGlobalVars.ahMinQuality then 
					link = normalizeLink(link)
					local price = GetAHScanPrice(link)
					-- debug(" scan -- link "..link.."  buyoutPrice "..tostring(buyoutPrice))
					if not price or price > buyoutPrice then 
						SetAHScanPrice(link, buyoutPrice)
					end 
				end 
			end  

			-- analyze fast scan data in chunks so as not to cause client to timeout?
			if ( x % AH_SCAN_CHUNKS ) == 0 and x < ahScanResultsShown then
				ahScanIndex = x + 1
				ahScanPauseTime = time()
				out('Processed '..x..' / '..ahScanResultsShown..'...')
				return
			end
			x = x + 1
		end
	end
	ahScanning = false 
	out('Scanned price for '..ahScanItems..' items.')
	FarmLog_MainWindow:RecalcTotals()
end


-- OnEvent

function FarmLog:OnEvent(event, ...)
	if FLogVars.enabled then 
		-- debug(event)
		if event == "LOOT_OPENED" then
			self:OnLootOpened(...)			
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
		elseif event == "PLAYER_DEAD" then 
			self:OnPlayerDead(...)
		end 
	end 

	if event == "PLAYER_ENTERING_WORLD" then
		self:OnEnteringWorld(...)
	elseif event == "CHAT_MSG_LOOT" then
		if (... and (strfind(..., L["loot"]))) then
			self:OnLootEvent(...)		
		end	
	elseif event == "ADDON_LOADED" and ... == APPNAME then		
		self:OnAddonLoaded(...)
	elseif event == "PLAYER_LOGOUT" then 
		self:CloseOpenInstances()
		self:PauseSession(true)
	elseif event == "UPDATE_INSTANCE_INFO" then 
		self:OnInstanceInfoEvent(...)
	elseif event == "AUCTION_ITEM_LIST_UPDATE" then
		self:OnAuctionUpdate()
	elseif event == "PLAYER_REGEN_DISABLED" then 
		self:OnEnterCombat()
	elseif event == "UI_ERROR_MESSAGE" then 
		self:UIError(...)
	end
end

-- OnUpdate

function FarmLog:OnUpdate() 
	if FLogVars.enabled then 
		FarmLog_MainWindow:UpdateTime()
	end 
	if skillNameTime then 
		local now = time()
		if now - skillNameTime >= SKILL_LOOTWINDOW_OPEN_TIMEOUT then 
			skillNameTime = nil 
			skillName = nil 
		end 
	end 
	if ahScanning then 
		self:AnalyzeAuctionHouseResults()
	end 
	if addonLoadedTime and time() - addonLoadedTime > BL_TIMERS_DELAY then 
		addonLoadedTime = nil 
		self:ShowBlackLotusTimers()
	end 
	if GameTooltip:IsShown() then
		if GameTooltip:IsOwned(Minimap) then 
			self:ParseMinimapTooltip()
		end 
	end
end 


-- UI ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- dragging & positioning

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
		if IsShiftKeyDown() then 
			FarmLog_MainWindow:ResetPosition()
			FarmLog_MainWindow:Show()
		elseif IsControlKeyDown() then 
			FarmLog_MainWindow_SessionsButton:Clicked() 
		else  
			FarmLog_MainWindow:ToggleWindow()
		end 
	end
end 

function FarmLog_MainWindow:SaveVisibility() 
	FLogVars.frameRect.visible = FarmLog_MainWindow:IsShown()
end 

function FarmLog_MainWindow:SavePosition() 
	local point, relativeTo, relativePoint, x, y = FarmLog_MainWindow:GetPoint()
	FLogVars.frameRect.point = point
	FLogVars.frameRect.x = x
	FLogVars.frameRect.y = y
	FLogVars.frameRect.width = FarmLog_MainWindow:GetWidth()
	FLogVars.frameRect.height = FarmLog_MainWindow:GetHeight()
end 

-- loot buttons

function FarmLog_SetTextButtonBackdropColor(btn, hovering)
	if btn.disabled then 
		btn:SetBackdropColor(0.3, 0.3, 0.3, 0.1)
		btn:SetBackdropBorderColor(1, 1, 1, 0.08)
		btn.label:SetTextColor(0.8, 0.8, 0.8, 0.5)
	elseif hovering then 
		if btn.selected then 
			btn:SetBackdropColor(0.4, 0.4, 0.4, 0.4)
			btn:SetBackdropBorderColor(1, 1, 1, 0.25)
			btn.label:SetTextColor(1, 1, 1, 1)
		else 
			btn:SetBackdropColor(0.3, 0.3, 0.3, 0.2)
			btn:SetBackdropBorderColor(1, 1, 1, 0.15)
			btn.label:SetTextColor(0.8, 0.8, 0.8, 1)
		end 
	else 
		if btn.selected then 
			btn:SetBackdropColor(0.4, 0.4, 0.4, 0.3)
			btn:SetBackdropBorderColor(1, 1, 1, 0.2)
			btn.label:SetTextColor(1, 1, 1, 1)
		else 
			btn:SetBackdropColor(0, 0, 0, 0.4)
			btn:SetBackdropBorderColor(1, 1, 1, 0.1)
			btn.label:SetTextColor(0.8, 0.8, 0.8, 1)
		end 
	end 
end 

function FarmLog_MainWindow_Buttons_SortAbcButton:Clicked() 
	if self.disabled then return end 
	if FarmLog_MainWindow_Buttons_SortGoldButton.selected then 
		FarmLog_MainWindow_Buttons_SortGoldButton.selected = false 
		FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_Buttons_SortGoldButton, false)
	end 
	if FarmLog_MainWindow_Buttons_SortKillsButton.selected then 
		FarmLog_MainWindow_Buttons_SortKillsButton.selected = false 
		FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_Buttons_SortKillsButton, false)
	end 
	self.selected = true
	FLogGlobalVars.sortBy = SORT_BY_TEXT
	FarmLog:RefreshMainWindow()
	FarmLog_SetTextButtonBackdropColor(self, false)
end 

function FarmLog_MainWindow_Buttons_SortGoldButton:Clicked() 
	if self.disabled then return end 
	if FarmLog_MainWindow_Buttons_SortAbcButton.selected then 
		FarmLog_MainWindow_Buttons_SortAbcButton.selected = false 
		FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_Buttons_SortAbcButton, false)
	end 
	if FarmLog_MainWindow_Buttons_SortKillsButton.selected then 
		FarmLog_MainWindow_Buttons_SortKillsButton.selected = false 
		FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_Buttons_SortKillsButton, false)
	end 
	self.selected = true
	FLogGlobalVars.sortBy = SORT_BY_GOLD
	FarmLog:RefreshMainWindow()
	FarmLog_SetTextButtonBackdropColor(self, false)
end 

function FarmLog_MainWindow_Buttons_SortKillsButton:Clicked() 
	if self.disabled then return end 
	if FarmLog_MainWindow_Buttons_SortAbcButton.selected then 
		FarmLog_MainWindow_Buttons_SortAbcButton.selected = false 
		FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_Buttons_SortAbcButton, false)
	end 
	if FarmLog_MainWindow_Buttons_SortGoldButton.selected then 
		FarmLog_MainWindow_Buttons_SortGoldButton.selected = false 
		FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_Buttons_SortGoldButton, false)
	end 
	self.selected = true
	FLogGlobalVars.sortBy = SORT_BY_KILLS
	FarmLog:RefreshMainWindow()
	FarmLog_SetTextButtonBackdropColor(self, false)
end 

function FarmLog_MainWindow_Buttons_ToggleMobNameButton:Clicked() 
	if self.disabled then return end 
	self.selected = not self.selected
	FLogGlobalVars.groupByMobName = self.selected
	FarmLog_MainWindow_Buttons_SortKillsButton.disabled = not self.selected
	if not self.selected and FarmLog_MainWindow_Buttons_SortKillsButton.selected then 
		FarmLog_MainWindow_Buttons_SortAbcButton:Clicked()
	else 
		FarmLog:RefreshMainWindow()
	end 
	FarmLog_SetTextButtonBackdropColor(self, false)
	FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_Buttons_SortKillsButton, false)
end 

function FarmLog_MainWindow_SessionsButton:Clicked() 
	if FarmLog_SessionsWindow:IsShown() then 
		FarmLog_SessionsWindow:Hide()
	else 
		FarmLog_SessionsWindow_Buttons_SearchBox:SetText("")
		FarmLog_SessionsWindow:Refresh()
		FarmLog_SessionsWindow:Show()
		FarmLog_SessionsWindow_Buttons_SearchBox:SetFocus()
	end 
end 

function FarmLog_MainWindow_ClearButton:Clicked()
	if self.disabled then return end 
	FarmLog:AskQuestion(L["reset-title"], L["reset-question"], function() 
		FarmLog:ResetSession()
		FarmLog_QuestionDialog:Hide()
	end)
end 

-- sessions buttons


function FarmLog_SessionsWindow_Buttons_SortAbcButton:Clicked() 
	if self.disabled then return end 
	if FarmLog_SessionsWindow_Buttons_SortGoldButton.selected then 
		FarmLog_SessionsWindow_Buttons_SortGoldButton.selected = false 
		FarmLog_SetTextButtonBackdropColor(FarmLog_SessionsWindow_Buttons_SortGoldButton, false)
	end 
	if FarmLog_SessionsWindow_Buttons_SortUseButton.selected then 
		FarmLog_SessionsWindow_Buttons_SortUseButton.selected = false 
		FarmLog_SetTextButtonBackdropColor(FarmLog_SessionsWindow_Buttons_SortUseButton, false)
	end 
	self.selected = true
	FLogGlobalVars.sortSessionBy = SORT_BY_TEXT
	FarmLog_SessionsWindow:Refresh()
	FarmLog_SetTextButtonBackdropColor(self, false)
end 

function FarmLog_SessionsWindow_Buttons_SortGoldButton:Clicked() 
	if self.disabled then return end 
	if FarmLog_SessionsWindow_Buttons_SortAbcButton.selected then 
		FarmLog_SessionsWindow_Buttons_SortAbcButton.selected = false 
		FarmLog_SetTextButtonBackdropColor(FarmLog_SessionsWindow_Buttons_SortAbcButton, false)
	end 
	if FarmLog_SessionsWindow_Buttons_SortUseButton.selected then 
		FarmLog_SessionsWindow_Buttons_SortUseButton.selected = false 
		FarmLog_SetTextButtonBackdropColor(FarmLog_SessionsWindow_Buttons_SortUseButton, false)
	end 
	self.selected = true
	FLogGlobalVars.sortSessionBy = SORT_BY_GOLD
	FarmLog_SessionsWindow:Refresh()
	FarmLog_SetTextButtonBackdropColor(self, false)
end 

function FarmLog_SessionsWindow_Buttons_SortUseButton:Clicked() 
	if self.disabled then return end 
	if FarmLog_SessionsWindow_Buttons_SortAbcButton.selected then 
		FarmLog_SessionsWindow_Buttons_SortAbcButton.selected = false 
		FarmLog_SetTextButtonBackdropColor(FarmLog_SessionsWindow_Buttons_SortAbcButton, false)
	end 
	if FarmLog_SessionsWindow_Buttons_SortGoldButton.selected then 
		FarmLog_SessionsWindow_Buttons_SortGoldButton.selected = false 
		FarmLog_SetTextButtonBackdropColor(FarmLog_SessionsWindow_Buttons_SortGoldButton, false)
	end 
	self.selected = true
	FLogGlobalVars.sortSessionBy = SORT_BY_USE
	FarmLog_SessionsWindow:Refresh()
	FarmLog_SetTextButtonBackdropColor(self, false)
end 

function FarmLog_SessionsWindow_Buttons_SearchBox:EnterPressed() 
	if sessionSearchResult then 
		out("Switching session to |cff99ff00"..sessionSearchResult)
		FarmLog:StartSession(sessionSearchResult, true, FLogGlobalVars.resumeSessionOnSwitch)
		FarmLog_SessionsWindow:Hide()
	end 
end 

-- tooltip

function FarmLog_MinimapButton:ShowTooltip() 
	GameTooltip:SetOwner(FarmLog_MinimapButton, "ANCHOR_BOTTOMLEFT")
	self:UpdateTooltipText()
	GameTooltip:Show()
	showingMinimapTip = true 
end 

function FarmLog_MinimapButton:UpdateTooltipText() 
	local sessionColor = "|cffffff00"
	if FLogVars.enabled then sessionColor = "|cff00ff00" end 
	local goldPerHour = GetSessionVar("goldPerHour") or 0
	local text = "|cff5CC4ff" .. APPNAME .. "|r|nSession: " .. sessionColor .. FLogVars.currentSession .. "|r|nTime: " .. sessionColor .. secondsToClock(FarmLog:GetCurrentSessionTime()) .. "|r|ng/h: |cffeeeeee" .. GetShortCoinTextureString(goldPerHour) .. "|r|nLeft click: |cffeeeeeeopen main window|r|nRight click: |cffeeeeeepause/resume session|r|nCtrl click: |cffeeeeeeopen session list|r"
	GameTooltip:SetText(text, nil, nil, nil, nil, true)
end 

function FarmLog_MinimapButton:HideTooltip() 
	showingMinimapTip = false
	GameTooltip:Hide()
end 

-- instance count UI

function FarmLog_MainWindow_Buttons_Instances:MouseEnter()
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:SetText(L["instance-count-help"])
	GameTooltip:Show()
end 

function FarmLog_MainWindow_Buttons_Instances:MouseLeave()
	GameTooltip_Hide();
end 


-- UI errors

function FarmLog:UIError(event,msg)
	if skillNameTime and msg == _G.SPELL_FAILED_TRY_AGAIN then 
		-- Failed attempt
		local now = time()
		debug("|cff999999UIError|r msg |cffff9900"..tostring(msg).."|r skillTooltip1 |cffff9900"..tostring(skillTooltip1).."|r time delta |cffff9900"..tostring(now - skillNameTime))
		if now - skillNameTime < SKILL_LOOTWINDOW_OPEN_TIMEOUT and skillTooltip1 == BL_ITEM_NAME then 
			-- failed picking BL
			self:IncreaseBlackLotusPickStat("fail")
		end 
	end 

	-- local what = tooltipLeftText1:GetText();
	-- if not what then return end
	-- if strfind(msg, miningSpell) or (miningSpell2 and strfind(msg, miningSpell2)) then
	-- 	self:addItem(miningSpell,what)
	-- elseif strfind(msg, herbSkill) then
	-- 	self:addItem(herbSpell,what)
	-- elseif strfind(msg, pickSpell) or strfind(msg, openSpell) then -- locked box or failed pick
	-- 	self:addItem(openSpell, what)
	-- elseif strfind(msg, NL["Lumber Mill"]) then -- timber requires lumber mill
	-- 	self:addItem(loggingSpell, what)
	-- end
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
			FarmLog_MainWindow:ToggleWindow()
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
			out(" |cff00ff00/fl set <item_link> <gold_value>|r sets AH ahPrice of an item, in gold")
			out(" |cff00ff00/fl i <item_link>|r adds/remove an item from ignore list")
			out(" |cff00ff00/fl asi|r enables/disables Auto Switch in Instances, if enabled, will automatically start a farm session for that instance. Instance name will be used for session name.")
			out(" |cff00ff00/fl ar|r enables/disables auto session resume when choosing one from the list")
			out(" |cff00ff00/fl ren <new_name>|r renames current session")
			out(" |cff00ff00/fl rmi|r resets minimap icon position")
			out(" |cff00ff00/fl rmw|r resets main window position")
			out(" |cff00ff00/fl inc|r increase kill count of selected target")
			out(" |cff00ff00/fl dec|r decrease kill count of selected target")
			out(" |cff00ff00/fl bl|r show black lotus log")
			out(" |cff00ff00/fl ah|r scan AH for current prices, must have AH window open")
		elseif "SET" == cmd then
			local startIndex, _ = string.find(arg1, "%|c");
			local _, endIndex = string.find(arg1, "%]%|h%|r");
			local itemLink = string.sub(arg1, startIndex, endIndex);	
			itemLink = normalizeLink(itemLink) -- remove player level

			if itemLink and GetItemInfo(itemLink) then 
				local ahPrice = nil 
				if ((endIndex + 2 ) <= (#arg1)) then
					local st = string.sub(arg1, endIndex + 2, #arg1)
					local priceGold = tonumber(st)
					if priceGold then 
						ahPrice = priceGold * 10000
					else 
						out("Incorrect usage of command write |cff00ff00/fl set [ITEM_LINK] [PRICE_GOLD]")
					end 
				end				
				SetManualPrice(itemLink, ahPrice)
				if ahPrice and ahPrice > 0 then 
					out("Setting AH ahPrice of "..itemLink.." to "..GetShortCoinTextureString(ahPrice))
				else 
					out("Removing "..itemLink.." from AH ahPrice table")
				end 
				FarmLog_MainWindow:RecalcTotals()
				FarmLog_MainWindow:Refresh()
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
				FarmLog_MainWindow:RecalcTotals()
				FarmLog_MainWindow:Refresh()
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
			if not arg1 or #arg1 == 0 then arg1 = GetMinimapZoneText() end 
			out("Switching session to |cff99ff00"..arg1)
			FarmLog:StartSession(arg1, true, true)
			FarmLog:RefreshMainWindow() 
		elseif  "REN" == cmd then
			out("Renaming session from |cff99ff00"..FLogVars.currentSession.."|r to |cff99ff00"..arg1)
			FLogVars.sessions[arg1] = FLogVars.sessions[FLogVars.currentSession]
			FLogVars.sessions[FLogVars.currentSession] = nil 
			FLogVars.currentSession = arg1 
			FarmLog:RefreshMainWindow() 
		elseif  "INC" == cmd then
			local mobName = GetUnitName("target")
			out("Increasing kill count of |cff00ff99"..mobName)
			IncreaseSessionDictVar("kills", mobName, 1)
			FarmLog:RefreshMainWindow() 
		elseif  "DEC" == cmd then
			local mobName = GetUnitName("target")
			out("Increasing kill count of |cff00ff99"..mobName)
			IncreaseSessionDictVar("kills", mobName, -1)
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
		elseif  "AR" == cmd then
			FLogGlobalVars.resumeSessionOnSwitch = not (FLogGlobalVars.resumeSessionOnSwitch or false) 
			if not FLogGlobalVars.resumeSessionOnSwitch then 
				out("Auto resume |cffff4444"..L["disabled"])
			else 
				out("Auto resume |cff44ff44"..L["enabled"])
			end 
		elseif "AH" == cmd then 
			FarmLog:ScanAuctionHouse()
		elseif "BL" == cmd then 
			FarmLog:ShowBlackLotusLog()
		else 
			out("Unknown command "..cmd)
		end 
	end 
end
