local VERSION = "1.19.3"
local VERSION_INT = 1.1903
local ADDON_NAME = "FarmLog"
local CREDITS = "by |cff40C7EBKof|r @ |cffff2222Shazzrah|r"
local FONT_NAME = "Fonts\\FRIZQT__.TTF"
local MAX_AH_RETRY = 0

local L = FarmLog_BuildLocalization()
local UNKNOWN_MOBNAME = L["Unknown"]
local CONSUMES_MOBNAME = L["Consumes"]
local REALM = GetRealmName()

FarmLog.L = L 
FarmLog.Version = VERSION
FarmLog.AddonName = ADDON_NAME

local MAX_INSTANCES_SECONDS = 3600
local MAX_INSTANCES_COUNT = 5
local INSTANCE_RESET_SECONDS = 3600
local PURGE_LOOTED_MOBS_SECONDS = 5 * 60

local DROP_META_INDEX_COUNT =  1
local DROP_META_INDEX_VALUE =  2
local DROP_META_INDEX_VALUE_EACH =  3
local DROP_META_INDEX_VALUE_TYPE =  4

local BG_INSTANCE_NAMES = {
	["Warsong Gulch"] = true,
	["Alterac Valley"] = true,
	["Arathi Basin"] = true,
}

local VALUE_TYPE_MANUAL = 'M'
local VALUE_TYPE_SCAN = 'S'
local VALUE_TYPE_VENDOR = 'V'
local VALUE_TYPE_NOVALUE = '0'
local VALUE_TYPE_COLOR = {
	["M"] = "e1d592",
	["S"] = "95d6e5",
	["V"] = "fbf9ed",
	["0"] = "fb3300",
	["?"] = "f3c0c0",
}

local HonorDRColor = {
	[100] = "2bff00",
	[75] = "99ff00",
	[50] = "fffb00",
	[25] = "ff9100",
	[0] = "ff1900",
}

local SORT_BY_TEXT = "A"
local SORT_BY_GOLD = "$"
local SORT_BY_KILLS = "K"
local SORT_BY_USE = "U"

local LOOT_AUTOFIX_TIMEOUT_SEC = 1
local AH_SCAN_CHUNKS = 500
local HUD_DRESSUP_TIME = 60
local HONOR_FRENZY_UPTIME = 10

local TEXT_COLOR = {
	["xp"] = "6a78f9",
	["skill"] = "4e62f8",
	["rep"] = "7d87f9",
	["mob"] = "f29244",
	["money"] = "fffb49",
	["honor"] = "e1c73b",
	["rank"] = "ffe499",
	["deaths"] = "ee3333",
	["gathering"] = "38c98d",
	["unknown"] = "888888",
	["consumes"] = "3ddb9f",
	["bgs"] = "6a78f9",
	["bgswin"] = "2ed154",
	["bgsloss"] = "d4422f",
}

TEXT_COLOR[L["Skinning"]] = TEXT_COLOR["gathering"]
TEXT_COLOR[L["Herbalism"]] = TEXT_COLOR["gathering"]
TEXT_COLOR[L["Mining"]] = TEXT_COLOR["gathering"]
TEXT_COLOR[L["Fishing"]] = TEXT_COLOR["gathering"]
TEXT_COLOR[UNKNOWN_MOBNAME] = TEXT_COLOR["unknown"]
TEXT_COLOR[CONSUMES_MOBNAME] = TEXT_COLOR["consumes"]

local TITLE_COLOR = "|cff4CB4ff"
local SPELL_HERBING = 2366
local SPELL_MINING = 2575
local SPELL_FISHING = {
	[7620] = true,
	[7731] = true,
	[7732] = true,
	[18248] = true,
}
local SPELL_FISHING_NAME = GetSpellInfo(7620)
local SPELL_OPEN = 3365
local SPELL_OPEN_NOTEXT = 22810
local SPELL_LOCKPICK = 1804
local SPELL_SKINNING = {
	[10768] = true,
	[8617] = true,
	[8618] = true,
	[8613] = true,
}
local SKILL_LOOTWINDOW_OPEN_TIMEOUT = { -- trade skill takes a few sec to cast
	[L["Fishing"]] = 35,
	[L["Skinning"]] = 8,
	[L["Herbalism"]] = 8,
	[L["Mining"]] = 8,
}

local SKILL_HERB_TEXT = (string.gsub((GetSpellInfo(9134)),"%A",""))

local PLAYER_WARN_COOLDOWN = 60
local BL_SEEN_TIMEOUT = 20 * 60
local BL_TIMERS_DELAY = 5
local BL_ITEMID = 13468
local BL_ITEM_NAME = ""

FLogGlobalVars = {
	debug = false,
	ahPrice = {},
	ahScan = {},
	ahMinQuality = 3,
	ignoredItems = {},
	track = {
		drops = true,
		kills = true,
		honor = true,
		hks = true,
		dks = true,
		ranks = true,
		consumes = true,
		money = true,
		xp = true,
		skill = false,
		rep = true,
		deaths = true,
		levelup = true,
		resets = true,
		bgs = true,
	},
	hud = {
		paddingX = 8,
		paddingY = 5,
		fontName = FONT_NAME,
		fontSize = 12,
		alpha = 0.7,
	},
	showBlackLotusTimer = true,
	autoSwitchInstances = false,
	autoResumeBGs = true,
	resumeSessionOnSwitch = true,
	honorDRinBGs = true,
	reportTo = {},
	dismissLootWindowOnEsc = false,
	groupByMobName = true,
	pauseOnLogin = true,
	showHonorPercentOnTooltip = true,
	showHonorFrenzyCounter = true,
	blackLotusTimeSeconds = 3600,
	instances = {},
	blt = {}, -- BL timers
	blp = {}, -- BL pick/fail counters
	bls = {}, -- BL pick log
	sortBy = SORT_BY_TEXT,
	sortSessionBy = SORT_BY_TEXT,
	ver = VERSION_INT,
}

FLogVars = {
	enabled = false,
	sessions = {},
	currentFarm = "default",
	inInstance = false,
	lockFrames = false,
	lockMinimapButton = false,
	frameRect = {
		width = 250,
		height = 200,
		point = "CENTER",
		x = 0,
		y = 0,
		visible = false,
	},
	minimapButtonPosition = {
		point = "TOPRIGHT",
		x = -165,
		y = -127,
	},
	enableMinimapButton = true, 
	itemTooltip = true,
	viewTotal = false,
	farms = {},
	todayKills = {},
	ver = VERSION_INT,
	hud = {
		show = false,
		locked = false,
	}
}

local function emptySession() 
	return {
		drops = {},
		kills = {},
		ranks = {},
		skill = {},
		consumes = {},
		rep = {},
		gold = 0,
		vendor = 0,
		ah = 0,
		xp = 0,
		honor = 0,
		hks = 0,
		dks = 0,
		deaths = 0,
		seconds = 0,
		resets = 0,
		bgs = {},
		bgsWin = {},
		bgsLoss = {},
	}
end 

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
local lastPlayerChecked = nil
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
local lastHudDressUp = 0
local hasBigwigs = false
local honorFrenzySetTime = nil 
local honorFrenzyTotal = 0
local honorFrenzyKills = 0
local honorFrenzyTest = false
local selfPlayerName = nil
local selfPlayerFaction = nil 
local bgResultRecorded = false

lastLootedMobs = {}

local function out(text)
	print(" |cffff8800<|cffffbb00FarmLog|cffff8800>|r "..text)
end 

local function debug(text)
	if FLogGlobalVars.debug then 
		out(text)
	end 
end 
FarmLog.debug = debug 

local function tobool(arg1)
	return arg1 == 1 or arg1 == true
end

local function isPositive(n)
	if not n then return false end 
	local st = tostring(n)
	return st ~= "nan" and st ~= "inf" and n > 0
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

local function secondsToClockShort(seconds)
	local seconds = tonumber(seconds)

	if not seconds or  seconds <= 0 then
		return "--";
	else
		hours = string.format("%2.f", math.floor(seconds/3600));
		mins = string.format("%2.f", math.floor(seconds/60 - (hours*60)));
		secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
		if seconds/3600 < 1 then 
			return mins.."m "..secs.."s"
		end 
		return hours.."h "..mins.."m"
	end
end

local function numberToString(str)
	str = tostring(str)
	if #str <= 3 then return str end 
	local prefix, number, suffix = str:match"(%D*%d)(%d+)(%D*)"
    return prefix .. number:reverse():gsub("(%d%d%d)","%1,"):reverse() .. suffix
end

local function GetShortCoinTextureString(money)
	if not money or tostring(money) == "nan" or tostring(money) == "inf" or money == 0 then return "--" end 
	-- out("money = "..tostring(money))
	if money > 100000 then 
		money = math.floor(money / 10000) * 10000
	elseif money > 10000 then 
		money = math.floor(money / 100) * 100
	end 
	if money < 0 then 
		return "-"..GetCoinTextureString(money * -1, 12)
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
	local parts = {_G.string.split(":", link)}
	parts[10] = "_"
	return table.concat(parts, ":") 
end 

local function extractItemID(link)
	-- remove player level from item link
	local _, id = _G.string.split(":", link)
	return id 
end 

function mergeDrops(a, b) 
	local merged = {}
	for link, meta in pairs(a) do 
		local newmeta = {
			meta[DROP_META_INDEX_COUNT] or 0,
			meta[DROP_META_INDEX_VALUE] or 0,
			meta[DROP_META_INDEX_VALUE_EACH] or 0,
			meta[DROP_META_INDEX_VALUE_TYPE] or VALUE_TYPE_VENDOR,
		}
		if b and b[link] then 
			newmeta[DROP_META_INDEX_COUNT] = newmeta[DROP_META_INDEX_COUNT] + (b[link][DROP_META_INDEX_COUNT] or 0)
			newmeta[DROP_META_INDEX_VALUE] = newmeta[DROP_META_INDEX_VALUE] + (b[link][DROP_META_INDEX_VALUE] or 0)
		end 
		merged[link] = newmeta 
	end 
	-- add missing items from b that doesn't exist on a
	if b then 
		for link, meta in pairs(b) do 
			if not a[link] then 
				merged[link] = meta
			end 
		end 
	end 
	return merged
end 


-- Auction house access 

local function GetAHScanPrice(itemLink)
	return FLogGlobalVars.ahScan[REALM][itemLink]
end 

function FarmLog:GetManualPrice(itemLink)
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
	if FLogVars.currentSession then 
		FLogVars.currentFarm = FLogVars.currentSession
		FLogVars.currentSession = nil 
	end 

	-- migration
	if FLogSVTotalSeconds and FLogSVTotalSeconds > 0 then 
		-- migrate 1 session into multi session DB
		FLogVars.sessions[FLogVars.currentFarm] = {
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
			["deaths"] = 0,
			["hks"] = 0,
			["dks"] = 0,
			["ranks"] = {},
			["consumes"] = {},
		}
		FLogSVTotalSeconds = nil 
		out("Migrated previous session into session 'default'.")
	elseif FLogVars.sessions and not FLogVars.sessions[FLogVars.currentFarm] then 
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
		FLogVars.currentFarm = FLogSVCurrentSession
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

	if not FLogGlobalVars.blt then FLogGlobalVars.blt = {} end 
	if not FLogGlobalVars.blp then FLogGlobalVars.blp = {} end 

	if not FLogGlobalVars.bls then FLogGlobalVars.bls = {} end 
	if FLogVars.bls and not FLogGlobalVars.bls then 
		FLogGlobalVars.bls[REALM] = FLogVars.bls
		FLogVars.bls = nil 
	end 

	if FLogVars.ver < 1.1303 then 
		for _, session in pairs(FLogVars.sessions) do 
			if not session.deaths then session.deaths = 0 end 
		end 
	end 

	if FLogVars.sessions then 
		FLogVars.viewTotal = true -- old users would want this off by default
		FLogVars.farms = {}
		for name, session in pairs(FLogVars.sessions) do 
			if session.bls then session.bls = nil end 
			FLogVars.farms[name] = {
				["past"] = session,
				["current"] = emptySession(),
				["goldPerHour"] = session.goldPerHour,
				["goldPerHourTotal"] = session.goldPerHour,
				["xpPerHour"] = session.xpPerHour,
				["lastUse"] = session.lastUse,
			}
			session.goldPerHour = nil 
			session.xpPerHour = nil 
			session.lastUse = nil 
		end 
		FLogVars.sessions = nil 
	end 

	if not FLogVars.todayKills then FLogVars.todayKills = {} end 

	if FLogVars.ver < 1.1502 then 
		for _, farm in pairs(FLogVars.farms) do 
			if not farm.current.ranks then farm.current.ranks = {} end 
			if not farm.past.ranks then farm.past.ranks = {} end 
		end 
	end 

	if not FLogGlobalVars.track then 
		FLogGlobalVars.track = {
			drops = true,
			kills = true,
			honor = true,
			hks = true,
			dks = true,
			ranks = true,
			consumes = true,
			money = true,
			xp = true,
			skill = true,
			rep = true,
			deaths = true,
			resets = true,
		}
	end 

	if not FLogGlobalVars.hud then 
		FLogGlobalVars.hud = {
			paddingX = 8,
			paddingY = 5,
			fontName = FONT_NAME,
			fontSize = 12,
			alpha = 0.7,
			locked = false,
			show = false,
		}
	end 

	if FLogGlobalVars.ver < 1.1705 then 
		FLogGlobalVars.showBlackLotusTimer = true
		FLogGlobalVars.showHonorPercentOnTooltip = true
	end 

	if FLogGlobalVars.ver < 1.1708 then 
		FLogGlobalVars.showHonorFrenzyCounter = true		
	end 

	if FLogVars.ver < 1.1800 then 
		for _, farm in pairs(FLogVars.farms) do 
			if not farm.current.consumes then farm.current.consumes = {} end 
			if not farm.past.consumes then farm.past.consumes = {} end 
		end 
	end 

	if FLogVars.ver < 1.1801 then 
		FLogVars.hud = {
			show = FLogGlobalVars.hud.show,
			locked = FLogGlobalVars.hud.locked,
		}
	end 

	if FLogGlobalVars.ver < 1.1803 then 
		FLogGlobalVars.track.levelup = true 
	end 

	if FLogVars.ver < 1.1900 then 
		for _, farm in pairs(FLogVars.farms) do 
			if not farm.current.bgs then farm.current.bgs = {} end 
			if not farm.past.bgs then farm.past.bgs = {} end 
			if not farm.current.bgsWin then farm.current.bgsWin = {} end 
			if not farm.past.bgsWin then farm.past.bgsWin = {} end 
			if not farm.current.bgsLoss then farm.current.bgsLoss = {} end 
			if not farm.past.bgsLoss then farm.past.bgsLoss = {} end 
		end 
		FLogGlobalVars.track.bgs = true
		FLogGlobalVars.honorDRinBGs = true 
		FLogGlobalVars.autoResumeBGs = true 
	end 

	if not FLogGlobalVars.blackLotusTimeSeconds then FLogGlobalVars.blackLotusTimeSeconds = 3600 end 

	FLogVars.ver = VERSION_INT
	FLogGlobalVars.ver = VERSION_INT
end 

local function GetSessionVar(varName, total, sessionName, mergeFunc)
	local name = sessionName or FLogVars.currentFarm
	local farm = FLogVars.farms[name]
	if not farm then 
		farm = {["past"] = emptySession(), ["current"] = emptySession()}
	end 
	if total then 
		if type(farm.past[varName]) == "table" then 
			if not mergeFunc then mergeFunc = function (a, b) return (a or 0) + (b or 0) end end
			local summed = {}
			for key, val in pairs(farm.past[varName]) do 
				summed[key] = mergeFunc(val, farm.current[varName][key])
			end 
			for key, val in pairs(farm.current[varName]) do 
				if summed[key] == nil then 
					summed[key] = mergeFunc(val, nil)
				end 
			end 
			return summed 
		else 
			return (farm.past[varName] or 0) + (farm.current[varName] or 0)
		end 
	end 
	return farm.current[varName]
end 

local function GetFarmVar(varName)
	local farm = FLogVars.farms[FLogVars.currentFarm]
	if not farm then return nil end 
	return farm[varName]
end 

local function SetFarmVar(varName, value)
	local farm = FLogVars.farms[FLogVars.currentFarm]
	if not farm then 
		farm = {["past"] = emptySession(), ["current"] = emptySession()}
		FLogVars.farms[FLogVars.currentFarm] = farm 
	end 
	farm[varName] = value 
end 

local function IncreaseSessionVar(varName, incValue)
	debug("|cff999999IncreaseSessionVar|r currentFarm |cffff9900"..FLogVars.currentFarm.."|r, varName |cffff9900"..varName.."|r, incValue |cffff9900"..tostring(incValue))
	local farm = FLogVars.farms[FLogVars.currentFarm]
	if not farm then return nil end 
	farm.current[varName] = (farm.current[varName] or 0) + incValue 
end 

local function IncreaseSessionDictVar(varName, entry, incValue)
	local farm = FLogVars.farms[FLogVars.currentFarm]
	if not farm then return nil end 
	farm.current[varName][entry] = (farm.current[varName][entry] or 0) + incValue 
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
	FarmLog_MainWindow:Refresh()
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
	return GetSessionVar("seconds", FLogVars.viewTotal) + now - (sessionStartTime or now)
end 

function FarmLog:ResumeSession() 
	sessionStartTime = time()
	SetFarmVar("lastUse", sessionStartTime)
	FLogVars.enabled = true  

	FarmLog_MinimapButtonIcon:SetTexture("Interface\\AddOns\\FarmLog\\assets\\FarmLogIconON");
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
		FarmLog_MinimapButtonIcon:SetTexture("Interface\\AddOns\\FarmLog\\assets\\FarmLogIconOFF");
		FarmLog_MainWindow:UpdateTitle()
		FarmLog_HUD:Refresh()
	end 
end 

function FarmLog:ResetSessionVars()
	local session = emptySession()
	if FLogVars.inInstance and not BG_INSTANCE_NAMES[FLogVars.instanceName] then 
		session.resets = 1
	end 
	local farm = FLogVars.farms[FLogVars.currentFarm]
	if farm then 
		farm.current = session 
	else 
		FLogVars.farms[FLogVars.currentFarm] = {["past"] = emptySession(), ["current"] = session}
	end 
end 

function FarmLog:SwitchFarm(farmName, pause, resume) 
	if FLogVars.enabled then 
		if pause then 
			self:PauseSession(true) 
		end 
	end 

	FLogVars.currentFarm = farmName
	if not FLogVars.farms[FLogVars.currentFarm] then 
		self:ResetSessionVars()
	end 
	if FLogVars.enabled or resume then 
		self:ResumeSession()
	else 
		FarmLog_MainWindow:RecalcTotals()
		FarmLog_MainWindow:UpdateTitle() -- done by resume, update text color
	end 

	local farm = FLogVars.farms[farmName]
	if FLogVars.inInstance then 
		if not farm.instanceName then 
			farm.instanceName = FLogVars.instanceName
		elseif farm.instanceName ~= FLogVars.instanceName then 
			farm.instanceName = '*'
		end 
	end 

	FarmLog_MainWindow_Buttons_TogglePvPButton.selected = GetFarmVar("pvpMode") == true
	FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_Buttons_TogglePvPButton)

	FarmLog_MainWindow:Refresh()
	FarmLog_HUD:DressUp()
end 

function FarmLog:DeleteFarm(name) 
	FLogVars.farms[name] = nil 
	if FLogVars.currentFarm == name then 
		self:SwitchFarm("default", false, FLogVars.enabled)
		FarmLog_MainWindow:Refresh()
		out("Switched to |cff99ff00default|r farm")
	end 
	if FLogVars.currentFarm == name and name == "default" then 
		out("Reset the |cff99ff00"..name.."|r farm")
	else 
		out("Deleted |cff99ff00"..name.."|r farm")
	end 
end 

function FarmLog:ClearSession(all)
	self:PauseSession(true)
	if all then 
		FLogVars.farms[FLogVars.currentFarm] = nil 
	end 
	self:ResetSessionVars()
	if FLogVars.enabled then 
		self:ResumeSession()
	end 
	out("Cleared |cff99ff00"..FLogVars.currentFarm.."|r farm")
	FarmLog_MainWindow:Refresh()
end

function FarmLog:NewSession()
	self:PauseSession(true)
	local newSession = emptySession()
	local mergedSessions = {}
	for key, _ in pairs(newSession) do 
		local mergeFunc = nil 
		if key == "drops" or key == "consumes" then mergeFunc = mergeDrops end 
		mergedSessions[key] = GetSessionVar(key, true, nil, mergeFunc)
	end 	
	SetFarmVar("past", mergedSessions)
	SetFarmVar("current", newSession)
	self:ResumeSession()
	out("Started a new session")
end 

function FarmLog:ToggleLogging() 
	if FLogVars.enabled then 
		self:PauseSession()
		out("Session for |cff99ff00"..FLogVars.currentFarm.."|r farm |cffffff00paused|r")
	else 
		self:SwitchFarm(FLogVars.currentFarm or "default", false, true)
		if GetSessionVar("seconds") == 0 then 
			out("Session for |cff99ff00"..FLogVars.currentFarm.."|r farm |cff00ff00started")
		else 
			out("Session for |cff99ff00"..FLogVars.currentFarm.."|r farm |cff00ff00resumed")
		end 	
	end 
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
		text = text.." x"..numberToString(quantity)
	end 
	return self:CreateRow(text, valueText)
end 

function FarmLog_MainWindow:GetTitleText()
	local text = FLogVars.currentFarm or ""
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
	-- if not FLogVars.farms[FLogVars.currentFarm] then return end 

	-- calculate GPH
	local sessionTime = FarmLog:GetCurrentSessionTime()
	local pvpMode = GetFarmVar("pvpMode") == true

	local goldPerHour = 0
	local ahProfit = GetSessionVar("ah", FLogVars.viewTotal)
	local vendorProfit = GetSessionVar("vendor", FLogVars.viewTotal)
	local goldProfit = GetSessionVar("gold", FLogVars.viewTotal)
	if sessionTime > 0 then 
		goldPerHour = (ahProfit + vendorProfit + goldProfit) / (sessionTime / 3600)
	end 
	if FLogVars.viewTotal then 
		SetFarmVar("goldPerHourTotal", goldPerHour)
		SetFarmVar("goldTotal", ahProfit + vendorProfit + goldProfit)
	else 
		SetFarmVar("goldPerHour", goldPerHour)
		SetFarmVar("gold", ahProfit + vendorProfit + goldProfit)
	end 

	if FLogGlobalVars.track.money and not pvpMode then 
		if isPositive(goldPerHour) then 
			self:AddRow(L["Gold / Hour"], GetShortCoinTextureString(goldPerHour), nil, nil)
		end 
		if isPositive(ahProfit) then 
			self:AddRow(L["Auction House"], GetShortCoinTextureString(ahProfit), nil, TEXT_COLOR["money"]) 
		end 
		if isPositive(goldProfit) then 
			self:AddRow(L["Money"], GetShortCoinTextureString(goldProfit), nil, TEXT_COLOR["money"])
		end 
		if isPositive(vendorProfit) then 
			self:AddRow(L["Vendor"], GetShortCoinTextureString(vendorProfit), nil, TEXT_COLOR["money"]) 
		end 
	end 
	
	local xp = FLogGlobalVars.track.xp and GetSessionVar("xp", FLogVars.viewTotal)
	if isPositive(xp) then 
		local xpPerHour = 0
		if sessionTime > 0 then 
			xpPerHour = xp / (sessionTime / 3600)
		end 
		if FLogVars.viewTotal then 
			SetFarmVar("xpPerHourTotal", xpPerHour)
		else 
			SetFarmVar("xpPerHour", xpPerHour)
		end 

		local text = numberToString(xp).." "..L["XP"]
		if FLogGlobalVars.track.xp and isPositive(xpPerHour) then 
			text = text .. ", " .. numberToString(math.floor(xpPerHour)) .. " " .. L["XP / hour"]
		end 
		self:AddRow(text, nil, nil, TEXT_COLOR["xp"]) 
	end 

	local resets = not pvpMode and FLogGlobalVars.track.resets and GetSessionVar("resets", FLogVars.viewTotal)
	if isPositive(resets) then 
		self:AddRow(resets.." "..L["Instances"], nil, nil, TEXT_COLOR["xp"]) 
	end

	local honor = FLogGlobalVars.track.honor and GetSessionVar("honor", FLogVars.viewTotal)
	local honorPerHour = 0
	if isPositive(honor) then 
		local text = numberToString(honor).." "..L["Honor"]
		if sessionTime > 0 then 
			honorPerHour = math.floor(honor / (sessionTime / 3600))
			text = text .. ", " .. numberToString(honorPerHour) .. " " .. L["honor/hour"]
		end
		self:AddRow(text, nil, nil, TEXT_COLOR["honor"]) 
	end 
	local hks = FLogGlobalVars.track.hks and GetSessionVar("hks", FLogVars.viewTotal)
	if isPositive(hks) then 
		self:AddRow(numberToString(hks).." "..L["Honorable kills"], nil, nil, TEXT_COLOR["honor"]) 
	end 
	local dks = FLogGlobalVars.track.dks and GetSessionVar("dks", FLogVars.viewTotal)
	if isPositive(dks) then 
		self:AddRow(dks.." "..L["Dishonorable kills"], nil, nil, TEXT_COLOR["deaths"]) 
	end 
	if FLogVars.viewTotal then 
		SetFarmVar("honorPerHourTotal", honorPerHour)
		SetFarmVar("honorTotal", honor)
	else 
		SetFarmVar("honorPerHour", honorPerHour)
		SetFarmVar("honor", honor)
	end 

	if FLogGlobalVars.track.bgs then 
		local wins = GetSessionVar("bgsWin", FLogVars.viewTotal)
		local losses = GetSessionVar("bgsLoss", FLogVars.viewTotal)
		for bg, count in pairs(GetSessionVar("bgs", FLogVars.viewTotal)) do 
			self:AddRow(bg, nil, count, TEXT_COLOR["bgs"]) 
			if wins and isPositive(wins[bg]) then 
				self:AddRow("    "..L["Won"], nil, wins[bg], TEXT_COLOR["bgswin"]) 
			end 
			if losses and isPositive(losses[bg]) then 
				self:AddRow("    "..L["Lost"], nil, losses[bg], TEXT_COLOR["bgsloss"]) 
			end 
		end 
	end 

	local deaths = FLogGlobalVars.track.deaths and GetSessionVar("deaths", FLogVars.viewTotal)
	if isPositive(deaths) then 
		self:AddRow(numberToString(deaths).." "..L["Deaths"], nil, nil, TEXT_COLOR["deaths"]) 
	end 
	if FLogGlobalVars.track.rep then 
		for faction, rep in pairs(GetSessionVar("rep", FLogVars.viewTotal)) do 
			self:AddRow(numberToString(rep).." "..faction.." "..L["reputation"], nil, nil, TEXT_COLOR["rep"]) 
		end 
	end 
	if FLogGlobalVars.track.skill then 
		for skillName, levels in pairs(GetSessionVar("skill", FLogVars.viewTotal)) do 
			self:AddRow("+"..levels.." "..skillName, nil, nil, TEXT_COLOR["skill"])
		end
	end 
	local levelup = FLogGlobalVars.track.levelup and GetSessionVar("levelup", FLogVars.viewTotal)
	if isPositive(levelup) then 
		self:AddRow(levelup.." "..L["Character levels"], nil, nil, TEXT_COLOR["skill"]) 
	end 

	if FLogGlobalVars.track.ranks then 
		local sessionRanks = GetSessionVar("ranks", FLogVars.viewTotal)
		local sortedRanks = SortMapKeys(sessionRanks, true, true)
		for _, rank in ipairs(sortedRanks) do	
			self:AddRow(L["HK"]..": "..rank, nil, sessionRanks[rank], TEXT_COLOR["rank"])
		end
	end 

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

	if FLogGlobalVars.track.consumes then 
		local sessionConsumes = GetSessionVar("consumes", FLogVars.viewTotal, nil, mergeDrops)
		if sessionConsumes[CONSUMES_MOBNAME] then 
			self:AddRow(CONSUMES_MOBNAME, nil, 1, TEXT_COLOR[CONSUMES_MOBNAME])
			addDropRows(sessionConsumes[CONSUMES_MOBNAME] or {}, true)
		end 
	end 

	if FLogGlobalVars.track.kills and not pvpMode then 
		local sessionDrops = GetSessionVar("drops", FLogVars.viewTotal, nil, mergeDrops)

		if FLogGlobalVars.groupByMobName then 
			local sessionKills = GetSessionVar("kills", FLogVars.viewTotal)
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
				if mobName ~= L["Unknown"] or sessionDrops[mobName] then 
					self:AddRow(mobName, nil, sessionKills[mobName], TEXT_COLOR[mobName] or TEXT_COLOR["mob"])
				end 
				if FLogGlobalVars.track.drops then 
					addDropRows(sessionDrops[mobName] or {}, true)
				end 
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
			if FLogGlobalVars.track.drops then 
				addDropRows(mergedDrops)
			end 
		end 
	end 

	-- buttons state
	FarmLog_MainWindow_ClearButton.disabled = #self.rows == 0
	FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_ClearButton)

	-- hide unused rows
	HideRowsBeyond(self.visibleRows + 1, self)

	FarmLog_HUD:Refresh()
end

function FarmLog_MainWindow:RecalcTotals()
	local recalcMeta = function (session) 
		local sessionVendor = 0
		local sessionAH = 0

		local function recalc(section, mul) 
			for mobName, drops in pairs(session[section]) do
				for itemLink, meta in pairs(drops) do
					if not FLogGlobalVars.ignoredItems[itemLink] then
						local vendorPrice = meta[DROP_META_INDEX_VALUE_TYPE] == VALUE_TYPE_VENDOR and meta[DROP_META_INDEX_VALUE_EACH]
						local value, priceType = FarmLog:GetItemValue(itemLink)
						local count = meta[DROP_META_INDEX_COUNT]
						local totalValue = value * count
	
						meta[DROP_META_INDEX_VALUE] = totalValue
						meta[DROP_META_INDEX_VALUE_EACH] = value
						meta[DROP_META_INDEX_VALUE_TYPE] = priceType
	
						if priceType == VALUE_TYPE_VENDOR then
							sessionVendor = sessionVendor + totalValue * mul
						elseif priceType == VALUE_TYPE_MANUAL or priceType == VALUE_TYPE_SCAN then
							sessionAH = sessionAH + totalValue * mul
						end
						-- debug("section "..section.." totalValue "..totalValue.." mul "..mul.." sessionVendor "..sessionVendor)
					end
				end
			end	
		end 

		if FLogGlobalVars.track.drops then 
			recalc("drops", 1)
		end 
		if FLogGlobalVars.track.consumes then 
			recalc("consumes", -1)
		end 

		session.vendor = sessionVendor
		session.ah = sessionAH
	end 

	local farm = FLogVars.farms[FLogVars.currentFarm]
	if farm then 
		recalcMeta(farm.past)
		recalcMeta(farm.current)
	end 
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
		sortedKeys = SortMapKeys(FLogVars.farms, nil, nil, nil, nil, searchText)
	elseif FLogGlobalVars.sortSessionBy == SORT_BY_GOLD then 
		local gphExtract = function (farm) return farm.goldPerHourTotal or farm.goldPerHour or 0 end
		sortedKeys = SortMapKeys(FLogVars.farms, true, true, nil, gphExtract, searchText)
	elseif FLogGlobalVars.sortSessionBy == SORT_BY_USE then 
		local useExtract = function (farm) return farm.lastUse or 0 end
		sortedKeys = SortMapKeys(FLogVars.farms, true, true, nil, useExtract, searchText)
	end 

	if #sortedKeys == 1 then sessionSearchResult = sortedKeys[1] else sessionSearchResult = nil end 

	for _, name in ipairs(sortedKeys) do 
		local farm = FLogVars.farms[name]
		local gph = farm.goldPerHourTotal or farm.goldPerHour or 0 
		local text = name
		local valueText = nil 
		if isPositive(gph) then 
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
				FarmLog:DeleteFarm(sessionName)
				FarmLog_MainWindow:Refresh()
				FarmLog_SessionsWindow:Refresh()
				FarmLog_QuestionDialog:Hide()
			end)
		else 
			if IsAltKeyDown() then
				-- edit?
			else 
				out("Switched to farm session |cff99ff00"..sessionName.."|r")
				FarmLog:SwitchFarm(sessionName, true, FLogGlobalVars.resumeSessionOnSwitch)
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

function FarmLog_LogWindow:AddPickRow(map, coords, picked, pickedBy, time) 
	self.visibleRows = self.visibleRows + 1
	text = "  |cff66aa33"..(map or "??").." "
	if coords then 
		text = text.."|cff777777@|r "..coords.x.."|cff777777,|r"..coords.y
	end 
	if picked then 
		text = text.." |cff1fd149"..L["picked"].."|r" 
	elseif pickedBy then  
		text = text.." |cffd65420"..L["picked-by"].." "..pickedBy.."|r" 
	end 
	return self:CreateRow(text, time)
end 

function FarmLog_LogWindow:AddMapRow(map, count) 
	self.visibleRows = self.visibleRows + 1
	return self:CreateRow("|cff99ff00"..map.."|r |cff777777x|r"..count)
end 

function FarmLog_LogWindow:RefreshBlackLotusLog()
	self.visibleRows = 0

	for realmName, realmData in pairs(FLogGlobalVars.bls) do 
		if realmName == REALM then 
			for mapName, mapData in pairs(realmData) do 
				self:AddMapRow(mapName, #mapData)
				for _, pickData in ipairs(mapData) do 
					local row = self:AddPickRow(pickData.zone, pickData.pos, pickData.picked, pickData.pickedBy, "|cffffffff"..pickData.time.."|r  "..pickData.date)
					-- SetItemTooltip(row)
					-- SetItemActions(row, self:GetOnLogItemClick(name))
				end 
			end 
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

function FarmLog:ParseCSV(csv)
	arg = {_G.string.split(",", csv)}
	local map = {}
	for _, v in ipairs(arg) do
        map[v] = 1
	end
	return map 
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
	elseif SPELL_FISHING[spellId] then
		skillName = L["Fishing"]
		skillNameTime = time()
	elseif spellId == SPELL_OPEN or spellId == SPELL_OPEN_NOTEXT then 
		skillName = L["Treasure"]
		skillNameTime = time()
	elseif SPELL_SKINNING[spellId] then 
		skillName = L["Skinning"]
		skillNameTime = time()
	else 
		skillName = nil 
	end 
end 

function FarmLog:OnSpellCastSuccessEvent(unit, target, spellId)
	debug("|cff999999OnSpellCastSuccessEvent|r spellId |cffff9900"..tostring(spellId).."|r unit |cffff9900"..tostring(unit))
	if not FLogGlobalVars.track.consumes or unit ~= "player" then return end 
	local buffmeta = FarmLog.Consumes[tostring(spellId)]
	if buffmeta and buffmeta.item then 
		-- item has/had to be in bags for get by name to work
		local _, itemLink, _, _, _, _, _, _, _, _, vendorPrice = GetItemInfo(buffmeta.item)
		if itemLink then 
			itemLink = normalizeLink(itemLink) -- remove player level from link
			FarmLog:InsertLoot(CONSUMES_MOBNAME, itemLink, buffmeta.quantity or 1, vendorPrice, "consumes", -1)
			FarmLog_MainWindow:Refresh()
		else 
			debug("Could not fetch item link for "..buffmeta.item)
		end 
	end 
end 

-- Honor event

function FarmLog:EstimatedHonorPercent(unitName)
	if not FLogGlobalVars.honorDRinBGs and FLogVars.inInstance then 
		return 1
	else 
		local timesKilledToday = FLogVars.todayKills[unitName] or 0
		return 1 - min(0.25 * timesKilledToday, 1)
	end 
end 

function FarmLog:CheckPvPDayReset()
	local todayHKs = GetPVPSessionStats()
	if todayHKs == 0 and next(FLogVars.todayKills) ~= nil then 
		-- new pvp day, reset diminishing returns 
		FLogVars.todayKills = {}
		debug("PvP diminishing returns was reset.")
	end 
end 

function FarmLog:OnCombatHonorEvent(text)
	debug("|cff999999OnCombatHonorEvent|r "..tostring(text))

	FarmLog:CheckPvPDayReset()

	local name = FLogDeformat(text, _G.COMBATLOG_DISHONORGAIN)
	if name then 
		if FLogVars.enabled and FLogGlobalVars.track.dks then 
			IncreaseSessionVar("dks", 1)
		end 
		if FLogVars.enabled then FarmLog_MainWindow:Refresh() end 
		return 
	end 

	local rank, honor
	name, rank, honor = FLogDeformat(text, _G.COMBATLOG_HONORGAIN) -- %s dies, honorable kill Rank: %s (Estimated Honor Points: %d)
	if name and #name > 0 then 
		if FLogVars.enabled and FLogGlobalVars.track.hks then 
			IncreaseSessionVar("hks", 1)
		end 

		-- count character kills for honor diminishing returns effect 
		local honorDR = self:EstimatedHonorPercent(name)
		if FLogGlobalVars.honorDRinBGs or not FLogVars.inInstance then 
			local timesKilledToday = (FLogVars.todayKills[name] or 0) + 1
			FLogVars.todayKills[name] = timesKilledToday
		end 

		if isPositive(honor) then 
			local adjustedHonor = math.floor(tonumber(honor) * honorDR)
			if FLogGlobalVars.showHonorFrenzyCounter then 
				FarmLog_HonorFrenzyMeter:Add(adjustedHonor)
			end 
			if FLogVars.enabled and FLogGlobalVars.track.honor then 
				IncreaseSessionVar("honor", adjustedHonor)
			end 
			debug("|cff999999OnCombatHonorEvent|r |cffff9900"..name.."|r estimated honor |cffff9900"..tostring(honor).."|r DR |cffff99ff"..tostring(honorDR).."|r adjusted |cffff9900"..adjustedHonor)
		end 

		if FLogVars.enabled and FLogGlobalVars.track.ranks and rank and #rank > 0 then 
			local sessionRanks = GetSessionVar("ranks", false)
			sessionRanks[rank] = (sessionRanks[rank] or 0) + 1
		end 	
		if FLogVars.enabled then FarmLog_MainWindow:Refresh() end 
		return 
	end 

	honor = FLogDeformat(text, _G.COMBATLOG_HONORAWARD) -- You have been awarded %d honor points.
	if isPositive(honor) then 
		if FLogVars.enabled and FLogGlobalVars.track.honor then 
			IncreaseSessionVar("honor", honor)
		end 
		debug("|cff999999OnCombatHonorEvent|r honor award |cffff9900"..tostring(honor))
		if FLogVars.enabled then FarmLog_MainWindow:Refresh() end 
		return 
	end 

	debug("|cff999999OnCombatHonorEvent|r unrecognized honor event |cffff9900"..tostring(text))
end 

function FarmLog:OnPlayerDead()
	if not FLogGlobalVars.track.deaths then return end 
	-- debug("|cff999999OnPlayerDead|r")
	IncreaseSessionVar("deaths", 1)
	FarmLog_MainWindow:Refresh()
end 

function FarmLog:OnPlayerLevelUp()
	if not FLogGlobalVars.track.levelup then return end 
	-- debug("|cff999999OnPlayerDead|r")
	IncreaseSessionVar("levelup", 1)
	FarmLog_MainWindow:Refresh()
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
	if not FLogGlobalVars.track.skill then return end 

	-- debug("FarmLog:OnSkillsEvent - text:"..text)
	local skillName, level = self:ParseSkillEvent(text)
	if level then 
		IncreaseSessionDictVar("skill", skillName, 1)
		FarmLog_MainWindow:Refresh()
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
	if not FLogGlobalVars.track.xp then return end 

	local xp = self:ParseXPEvent(text)
	if xp then 
		IncreaseSessionVar("xp", xp)
		FarmLog_MainWindow:Refresh()
	end 
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
	if not FLogGlobalVars.track.rep then return end 

	-- debug("FarmLog:OnCombatFactionChange - text:"..text)
	local faction, rep = self:ParseRepEvent(text)
	if rep then 
		IncreaseSessionDictVar("rep", faction, rep)
		FarmLog_MainWindow:Refresh()
	end 
end 

-- Combat log event

function FarmLog:OnCombatLogEvent()
	local eventInfo = {CombatLogGetCurrentEventInfo()}
	local eventName = eventInfo[2]

	if eventName == "PARTY_KILL" then 
		if not FLogGlobalVars.track.kills then return end 

		local mobName = eventInfo[9]
		local mobGuid = eventInfo[8]
		local mobFlags = eventInfo[10]
		
		if bit.band(mobFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) == 0 then 
			-- count mob kill
			local sessionKills = GetSessionVar("kills", false)
			sessionKills[mobName] = (sessionKills[mobName] or 0) + 1

			if FLogGlobalVars.track.drops then 
				-- make sure this mob has a drops entry, even if it won't drop anything
				local sessionDrops = GetSessionVar("drops", false)
				if not sessionDrops[mobName] then 
					sessionDrops[mobName] = {}
				end 
			end 
			debug("Player "..eventInfo[5].." killed NPC "..mobName)
		end 
		FarmLog_MainWindow:Refresh()
	end 
end 

-- Loot window event

function FarmLog:OnLootOpened(autoLoot)
	if not FLogGlobalVars.track.drops then return end 

	local lootCount = GetNumLootItems()
	local mobName = nil

	if skillName then
		mobName = skillName
		-- count gathering skill act in kills table
		local sessionKills = GetSessionVar("kills", false)
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
	if money then 
		IncreaseSessionVar("gold", money)
		FarmLog_MainWindow:Refresh()
	end 
end 

-- Black lotus tracking

function FarmLog:SetBlackLotusItemId(itemId) 
	BL_ITEM_NAME = GetItemInfo(itemId)
	BL_ITEMID = itemId
	debug("|cff999999SetBlackLotusItemId|r BL_ITEM_NAME |cffff9900"..tostring(BL_ITEM_NAME).."|r BL_ITEMID |cffff9900"..tostring(BL_ITEMID))
end 

function FarmLog:GetBlackLotusItemName() 
	return BL_ITEM_NAME
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
		ts = now,
		time = date("%H:%M:%S"),
		date = date("%m-%d"),
		pos = {["x"] = x, ["y"] = y},
		zone = GetMinimapZoneText(),
		picked = byPlayer,
	}
	if blSeen and blSeen.zone == mapName and now - blSeen.ts <= BL_SEEN_TIMEOUT then 
		pickMeta.seen = blSeen
	end 
	blSeen = nil 
	self:LogBlackLotus(mapName, pickMeta)
end 

function FarmLog:LogBlackLotus(mapName, pickMeta)
	local realmBls = FLogGlobalVars.bls[REALM]
	if not realmBls[mapName] then realmBls[mapName] = {} end 
	tinsert(realmBls[mapName], pickMeta)
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
			debug("|cff999999IncreaseBlackLotusPickStat|r increased BL stat |cffff9900"..statName.."|r to |cffff9900"..tostring(rankMeta[statName]))
			return true 
		end 
	end 
	out("|cffff0000Could not find Herbalism skill, failed logging pick")
end 

function FarmLog:ParseMinimapTooltip()
	local tooltip = GameTooltipTextLeft1:GetText()
	if tooltip == BL_ITEM_NAME and (not blSeen or blSeen.zone ~= GetZoneText() or time() - blSeen.ts > BL_SEEN_TIMEOUT) then
		FarmLog:SaveBLSeenTime() 
	end
end 

function FarmLog:SaveBLSeenTime() 
	blSeen = {
		ts = time(),
		time = date ("%H:%M:%S"),
		date = date ("%Y-%m-%d"),
		zone = GetZoneText(),
	}
	debug("|cff999999SaveBLSeenTime|r blSeenTime |cffff9900"..blSeen.ts.."|r blSeenZone |cffff9900"..blSeen.zone)
end 

function FarmLog:CheckTimerAddons()
	if FLogGlobalVars.showBlackLotusTimer then 
		local bigwigsAddons = {'BigWigs_Core', 'BigWigs_Options', 'BigWigs_Plugins',}
		hasBigwigs = true
		for i=1, #bigwigsAddons do
			if IsAddOnLoadOnDemand(bigwigsAddons[i]) then 
				LoadAddOn(bigwigsAddons[i])
			else 
				if not IsAddOnLoaded(bigwigsAddons[i]) then
					hasBigwigs = false
					break
				end
			end 
		end
	end 
end 

function FarmLog:ShowBlackLotusTimers()
	if FLogGlobalVars.showBlackLotusTimer and (DBM or hasBigwigs) then 
		local now = time()
		for realmName, timers in pairs(FLogGlobalVars.blt) do 
			if realmName == REALM then 
				for zoneName, lastPick in pairs(timers) do 
					local delta = now - lastPick
					if delta < FLogGlobalVars.blackLotusTimeSeconds then 
						local seconds = FLogGlobalVars.blackLotusTimeSeconds - delta
						local text = L["blacklotus-short"]..": "..zoneName
						if DBM then 
							DBM:CreatePizzaTimer(seconds, text)
						elseif SlashCmdList.BIGWIGSLOCALBAR then 
							SlashCmdList.BIGWIGSLOCALBAR(seconds.." "..text)
						end 
					end 
				end 
			end 
		end 
	end 
end 

-- Loot helper
function FarmLog:GetItemValue(itemLink)
	local _, _, quality, _, _, _, _, _, _, _, vendorPrice = GetItemInfo(itemLink)
	local normLink = normalizeLink(itemLink)
	local ahValue = FarmLog:GetManualPrice(normLink)
	if ahValue then
		return ahValue, VALUE_TYPE_MANUAL
	elseif not quality or quality >= FLogGlobalVars.ahMinQuality then 
		-- debug("GetItemValue   "..itemLink.."   quality "..quality)
		local GetTSMPrice = TSM_API and function(link) 
			local TSM_ItemString = TSM_API.ToItemString(normLink)
			return TSM_API.GetCustomPriceValue("dbmarket", TSM_ItemString)
		end
		local PriceCheck = Atr_GetAuctionBuyout or GetTSMPrice or GetAHScanPrice
		ahValue = PriceCheck(normLink)
	end

	-- check if AH price (-15%) > vendor price + 1s
	if isPositive(ahValue) and (not isPositive(vendorPrice) or ahValue * 0.85 > vendorPrice + 100) then
		return ahValue, VALUE_TYPE_SCAN
	elseif isPositive(vendorPrice) then 
		return vendorPrice, VALUE_TYPE_VENDOR
	end
	return 0, VALUE_TYPE_NOVALUE
end

-- Loot receive event

function FarmLog:InsertLoot(mobName, itemLink, count, vendorPrice, section, mul)
	section = section or "drops"
	mul = mul or 1
	if not FLogGlobalVars.track[section] or not mobName or not itemLink or not count then return end 

	local value, priceType = FarmLog:GetItemValue(itemLink)

	if priceType == VALUE_TYPE_VENDOR then
		IncreaseSessionVar("vendor", value * count * mul)
	elseif priceType == VALUE_TYPE_MANUAL or priceType == VALUE_TYPE_SCAN then
		IncreaseSessionVar("ah", value * count * mul)
	end 
	debug("|cff999999FarmLog:InsertLoot|r using |cffff9900"..priceType.."|r price of |cffff9900"..value)

	local sessionDrops = GetSessionVar(section, false)
	if not sessionDrops[mobName] then		
		sessionDrops[mobName] = {}
	end 
	local meta = sessionDrops[mobName][itemLink]
	if meta then
		debug("|cff999999FarmLog:InsertLoot|r meta |cffff9900"..meta[1]..","..tostring(meta[2])..","..tostring(meta[3])..","..tostring(meta[4]))
		local totalCount = meta[DROP_META_INDEX_COUNT] + count
		meta[DROP_META_INDEX_COUNT] = totalCount
		meta[DROP_META_INDEX_VALUE] = value * totalCount
		meta[DROP_META_INDEX_VALUE_EACH] = value
		meta[DROP_META_INDEX_VALUE_TYPE] = priceType				
	else
		sessionDrops[mobName][itemLink] = {count, value * count, value, priceType}
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
			GetSessionVar("kills", false)[UNKNOWN_MOBNAME] = 1
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
		FarmLog_MainWindow:Refresh();
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
	if not FLogGlobalVars.bls[REALM] then FLogGlobalVars.bls[REALM] = {} end 

	if FLogGlobalVars.dismissLootWindowOnEsc then  
		tinsert(UISpecialFrames, FarmLog_MainWindow:GetName())
	end 

	if not FLogVars.lockFrames then		
		FarmLog_MainWindow_Title:RegisterForDrag("LeftButton");			
	end

	FarmLog_SessionsWindow_Title_Text:SetTextColor(0.3, 0.7, 1, 1)
	FarmLog_SessionsWindow_Title_Text:SetText(L["farms-title"])

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
	FarmLog_MainWindow_Buttons_ToggleCurrentButton.selected = not FLogVars.viewTotal
	FarmLog_MainWindow_Buttons_TogglePvPButton.selected = GetFarmVar("pvpMode") == true
	FarmLog_MainWindow_ToggleHUDButton.selected = FLogVars.hud.show == true
	FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_ToggleHUDButton)
	FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_Buttons_SortAbcButton)
	FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_Buttons_SortGoldButton)
	FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_Buttons_SortKillsButton)
	FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_Buttons_ToggleMobNameButton)
	FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_Buttons_ToggleCurrentButton)
	FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_Buttons_TogglePvPButton)
	FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_SessionsButton)
	FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_ClearButton)
	FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_NewSessionButton)
	FarmLog_SetTextButtonBackdropColor(FarmLog_SessionsWindow_Buttons_NewFarmButton)

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

	-- init window visibility
	FarmLog_MainWindow:LoadPosition()
	if FLogVars.frameRect.visible then 
		FarmLog_MainWindow:Show()
	else 
		FarmLog_MainWindow:Hide()
	end 
	if not FarmLog_MainWindow:GetPoint() then 
		FarmLog_MainWindow:ResetPosition()
	end 

	if FLogVars.hud.show then 
		FarmLog_HUD:Show()
	else 
		FarmLog_HUD:Hide()
	end 
	if not FarmLog_HUD:GetPoint() then 
		FarmLog_HUD:ResetPosition()
	end 
	addonLoadedTime = time()

	if FLogPlayerAlert then 
		for alertName, db in pairs(FLogPlayerAlert) do
			if type(db) == "string" then 
				FLogPlayerAlert[alertName] = self:ParseCSV(db)
			end 
		end 
	end 

	-- Options UI
	FarmLog.InterfacePanel:AddonLoaded()
	FarmLog_HUD:DressUp()

	FarmLog:HookTooltip()
end 

-- Entering World

function FarmLog:OnEnteringWorld(isInitialLogin, isReload) 
	self:PurgeInstances()
	self:UpdateInstanceCount()

	BL_ITEM_NAME = GetItemInfo(BL_ITEMID)
	local playerNameParts = {_G.string.split("-", (UnitFullName("player")))}
	selfPlayerName = playerNameParts[1]
	if (UnitFactionGroup("player")) == "Horde" then 
		selfPlayerFaction = 0
	else 
		selfPlayerFaction = 1
	end 

	if isInitialLogin or isReload then 
		-- init session
		if FLogVars.enabled and (not isInitialLogin or not FLogGlobalVars.pauseOnLogin) then 
			self:ResumeSession()
		else 
			self:PauseSession()
			FarmLog_MainWindow:RecalcTotals()
		end 
		FarmLog_MainWindow:Refresh()
		FarmLog_HUD:Refresh()
		FarmLog_HUD:DressUp()
	end 

	local inInstance, _ = IsInInstance()
	inInstance = tobool(inInstance)
	local instanceName = GetInstanceInfo()
	local now = time()
	local farm = FLogVars.farms[FLogVars.currentFarm]
	debug("|cff999999FarmLog:OnEnteringWorld|r FLogVars.inInstance |cffff9900"..tostring(FLogVars.inInstance).."|r inInstance |cffff9900"..tostring(inInstance))

	if FLogVars.inInstance and not inInstance then 
		FLogVars.inInstance = false
		FLogVars.instanceName = nil
		self:CloseOpenInstances()
		if BG_INSTANCE_NAMES[farm.instanceName] or FLogGlobalVars.autoSwitchInstances then 
			self:PauseSession()
		end 
	elseif inInstance then
		if FLogGlobalVars.autoSwitchInstances or (FLogGlobalVars.autoResumeBGs and BG_INSTANCE_NAMES[farm.instanceName] and farm.instanceName == instanceName) then 
			if farm.instanceName == instanceName then 
				self:ResumeSession()
			else 
				self:SwitchFarm(instanceName, true, true)
			end
		end 
		-- ignore BGs
		if BG_INSTANCE_NAMES[instanceName] then 
			if FLogGlobalVars.track.bgs and not FLogVars.inInstance then 
				bgResultRecorded = false 
				IncreaseSessionDictVar("bgs", instanceName, 1)
			end 
		else 		
			if FLogGlobalVars.track.resets then 
				local lastInstance, lastIndex = self:GetLastInstance(instanceName)
				if lastInstance and lastInstance.leave and now - lastInstance.leave >= INSTANCE_RESET_SECONDS then 
					-- after 1 hour of not being inside the instance, treat this instance as reset
					lastInstance = nil 
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
		end 
		FLogVars.inInstance = true
		FLogVars.instanceName = instanceName
	end
	FarmLog_MainWindow:Refresh()
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

-- Battleground events 

function FarmLog:OnUpdateBattlefieldStatus(arg1, arg2, arg3) 
	debug("OnUpdateBattlefieldStatus - "..tostring(arg1 or "").."  "..tostring(arg2 or "").."  "..tostring(arg3 or ""))
	local winner = GetBattlefieldWinner()
	debug("GetBattlefieldWinner() = "..tostring(winner))
	debug("FLogVars.instanceName = "..(FLogVars.instanceName or ""))
	if selfPlayerFaction and FLogVars.instanceName and winner and not bgResultRecorded then 
		bgResultRecorded = true
		if winner == selfPlayerFaction then 
			IncreaseSessionDictVar("bgsWin", FLogVars.instanceName, 1)
			debug("Battlefield won")
		else 
			IncreaseSessionDictVar("bgsLoss", FLogVars.instanceName, 1)
			debug("Battlefield lost")
		end 
	end 
end 

-- Tooltip extend --------------------------------------------------------------------------

local OriginalOnTooltipSetUnit = nil 

local function OnTooltipSetUnit(...)
	OriginalOnTooltipSetUnit(GameTooltip, ...)

	local _, unit = GameTooltip:GetUnit()
	if FLogGlobalVars.honorDRinBGs or not FLogVars.inInstance then 
		if unit and UnitExists(unit) and UnitIsEnemy(unit, "player") and UnitIsPlayer(unit) and UnitLevel(unit) >= UnitLevel("player") - 10 then 
			local name = UnitName(unit)
			local honor = FarmLog:EstimatedHonorPercent(name) * 100
			GameTooltip:AddLine("|cff"..HonorDRColor[honor]..honor.."% "..L["Honor"])
		end
	end  
	
	GameTooltip:Show()
end

function FarmLog:HookTooltip() 
	if FLogGlobalVars.showHonorPercentOnTooltip and OriginalOnTooltipSetUnit == nil then
		OriginalOnTooltipSetUnit = GameTooltip:GetScript("OnTooltipSetUnit") or false
		GameTooltip:SetScript("OnTooltipSetUnit", OnTooltipSetUnit)
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
	ahScanResultsShown, ahScanResultsTotal = GetNumAuctionItems("list")
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
		elseif event == "UNIT_SPELLCAST_SUCCEEDED" then 
			self:OnSpellCastSuccessEvent(...)
		elseif event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then 
			self:OnCombatFactionChange(...)
		elseif event == "PLAYER_DEAD" then 
			self:OnPlayerDead(...)
		elseif event == "PLAYER_LEVEL_UP" then 
			self:OnPlayerLevelUp(...)
		elseif event == "UPDATE_BATTLEFIELD_STATUS" then 
			self:OnUpdateBattlefieldStatus()
		end 
	end 

	if event == "PLAYER_ENTERING_WORLD" then
		self:OnEnteringWorld(...)
	elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN" then 
		self:OnCombatHonorEvent(...);			
	elseif event == "CHAT_MSG_LOOT" then
		self:OnLootEvent(...)		
	elseif event == "ADDON_LOADED" and ... == ADDON_NAME then		
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
	local now = time()
	if FLogVars.enabled then 
		FarmLog_MainWindow:UpdateTime()
		if FLogVars.hud.show then 
			FarmLog_HUD:Refresh()
			if now - lastHudDressUp >= HUD_DRESSUP_TIME then 
				FarmLog_HUD:DressUp()
				lastHudDressUp = now
			end 
		end 
	end 
	if skillNameTime then 
		local timeout = SKILL_LOOTWINDOW_OPEN_TIMEOUT[skillName or ""] or 0
		if now - skillNameTime >= timeout then 
			skillNameTime = nil 
			skillName = nil 
		end 
	end 
	if ahScanning then 
		self:AnalyzeAuctionHouseResults()
	end 
	if addonLoadedTime and time() - addonLoadedTime > BL_TIMERS_DELAY then 
		addonLoadedTime = nil 
		self:CheckTimerAddons()
		self:ShowBlackLotusTimers()
		self:CheckPvPDayReset() -- this may return 0 if called too soon
	end 
	if GameTooltip:IsShown() then
		if GameTooltip:IsOwned(Minimap) then 
			self:ParseMinimapTooltip()
		end 
	end
	if honorFrenzySetTime and now - honorFrenzySetTime >= HONOR_FRENZY_UPTIME then 
		if FarmLog_HonorFrenzyMeter:GetAlpha() > 0 then 
			UIFrameFadeOut(FarmLog_HonorFrenzyMeter, 1, 1, 0)
		end 
		honorFrenzySetTime = nil 
		honorFrenzyTotal = 0
		honorFrenzyKills = 0
		if honorFrenzyTest then 
			FarmLog_HonorFrenzyMeter:EnableMouse(false)
			FarmLog_HonorFrenzyMeter:SetBackdropColor(0, 0, 0, 0)
			honorFrenzyTest = false
		end 
	end 
	if FLogPlayerAlert and UnitPlayerControlled("mouseover") then 
		local name = UnitName("mouseover") 
		if name ~= lastPlayerChecked then 
			lastPlayerChecked = name 
			for alertName, db in pairs(FLogPlayerAlert) do 
				local t = db[name]
				if t and time() - t > PLAYER_WARN_COOLDOWN then 
					out("|cffc350f9Unit |r"..name.."|cffc350f9 is a "..alertName.."!")
					db[name] = time()
				end 
			end 
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

function FarmLog_MinimapButton:ResetPosition()
	FLogVars.minimapButtonPosition.x = -165
	FLogVars.minimapButtonPosition.y = -127
	FLogVars.minimapButtonPosition.point = "TOPRIGHT"
	FLogVars.enableMinimapButton = true 
	FarmLog_MinimapButton:Init(true)
end 

function FarmLog_MinimapButton:DragStopped() 
	local point, relativeTo, relativePoint, x, y = FarmLog_MinimapButton:GetPoint()
	FLogVars.minimapButtonPosition.point = point;													
	FLogVars.minimapButtonPosition.x = x;
	FLogVars.minimapButtonPosition.y = y;
end 

function FarmLog_MinimapButton:Clicked(button) 
	if button == "RightButton" then
		FarmLog:ToggleLogging()
	else
		if IsShiftKeyDown() then 
			InterfaceOptionsFrame_OpenToCategory(FarmLog.InterfacePanel)
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

-- heads up display

function FarmLog_HUD:ResetPosition()
	self:ClearAllPoints()
	self:SetPoint("CENTER", 0, 200)
end 

function FarmLog_HUD:Refresh()
	local sessionColor = "|cffffff00"
	if FLogVars.enabled then sessionColor = "|cff00ff00" end 
	local perHour, total
	local pvpMode = GetFarmVar("pvpMode") == true
	if pvpMode then 
		if FLogVars.viewTotal then 
			perHour = "|cffffef96"..numberToString(GetFarmVar("honorPerHourTotal") or 0)
			total = "|cffffef96"..numberToString(GetFarmVar("honorTotal") or 0)
		else 
			perHour = "|cffffef96"..numberToString(GetFarmVar("honorPerHour") or 0)
			total = "|cffffef96"..numberToString(GetFarmVar("honor") or 0)
		end 
	else 
		if FLogVars.viewTotal then 
			perHour = GetShortCoinTextureString(GetFarmVar("goldPerHourTotal") or 0)
			total = GetShortCoinTextureString(GetFarmVar("goldTotal") or 0)
		else 
			perHour = GetShortCoinTextureString(GetFarmVar("goldPerHour") or 0)
			total = GetShortCoinTextureString(GetFarmVar("gold") or 0)
		end 
	end 
	FarmLog_HUD_Line1N:SetText(sessionColor..secondsToClockShort(FarmLog:GetCurrentSessionTime()))
	FarmLog_HUD_Line1:SetText(TITLE_COLOR..FLogVars.currentFarm)
	FarmLog_HUD_Line2N:SetText(perHour)
	FarmLog_HUD_Line3N:SetText(total)
	if pvpMode then 
		local _, _, yesterdayHonor = GetPVPYesterdayStats()
		local _, thisweekHonor = GetPVPThisWeekStats()
		FarmLog_HUD_Line2:SetText("|cff"..TEXT_COLOR["honor"] .. L["honor/hour"])
		FarmLog_HUD_Line3:SetText("|cff"..TEXT_COLOR["honor"] .. L["Honor"])
		FarmLog_HUD_Line4N:SetText("|cffbbbbbb"..numberToString(yesterdayHonor))
		FarmLog_HUD_Line4:SetText("|cff"..TEXT_COLOR["honor"] .. L["Yesterday"])
		FarmLog_HUD_Line5N:SetText("|cffbbbbbb"..numberToString(thisweekHonor))
		FarmLog_HUD_Line5:SetText("|cff"..TEXT_COLOR["honor"] .. L["This week"])
	else 
		FarmLog_HUD_Line2:SetText("|cff"..TEXT_COLOR["money"] .. L["Gold / Hour"])
		FarmLog_HUD_Line3:SetText("|cff"..TEXT_COLOR["money"] .. L["Gold"])
		FarmLog_HUD_Line4N:SetText("")
		FarmLog_HUD_Line4:SetText("")
		FarmLog_HUD_Line5N:SetText("")
		FarmLog_HUD_Line5:SetText("")
	end 
end 

function FarmLog_HUD:DressUp()
	local paddingX = FLogGlobalVars.hud.paddingX
	local paddingY = FLogGlobalVars.hud.paddingY
	local fontName = FLogGlobalVars.hud.fontName
	local fontSize = FLogGlobalVars.hud.fontSize
	local pvpMode = GetFarmVar("pvpMode") == true

	self:SetBackdropColor(0, 0, 0, FLogGlobalVars.hud.alpha)
	self:SetBackdropBorderColor(0, 0, 0, 1)
	self:RegisterForDrag("LeftButton")

	local textLabels = {FarmLog_HUD_Line1, FarmLog_HUD_Line2, FarmLog_HUD_Line3, FarmLog_HUD_Line4, FarmLog_HUD_Line5}
	local textMaxwidth = 0
	local height = paddingX 
	for _, label in ipairs(textLabels) do 
		label:ClearAllPoints()
		label:SetFont(fontName, fontSize)
		if label:GetStringWidth() > textMaxwidth then textMaxwidth = label:GetStringWidth() end 
		height = height + label:GetStringHeight() + paddingY
	end 
	height = height - paddingY + paddingX

	local numberLabels = {FarmLog_HUD_Line1N, FarmLog_HUD_Line2N, FarmLog_HUD_Line3N, FarmLog_HUD_Line4N, FarmLog_HUD_Line5N}
	local numberMaxwidth = 0
	for _, label in ipairs(numberLabels) do 
		label:ClearAllPoints()
		label:SetFont(fontName, fontSize)
		if label:GetStringWidth() > numberMaxwidth then numberMaxwidth = label:GetStringWidth() end 
	end 
	numberMaxwidth = max(numberMaxwidth + 5, 50)

	for _, label in ipairs(numberLabels) do 
		label:SetWidth(numberMaxwidth)
	end 

	FarmLog_HUD_Sep:ClearAllPoints()

	FarmLog_HUD_Line1N:SetPoint("TOPLEFT", paddingX, -paddingX)
	FarmLog_HUD_Line1:SetPoint("TOPLEFT", FarmLog_HUD_Line1N, "TOPRIGHT", paddingX / 2, 0)

	FarmLog_HUD_Line2N:SetPoint("TOPLEFT", FarmLog_HUD_Line1N, "BOTTOMLEFT", 0, -paddingY)
	FarmLog_HUD_Line2:SetPoint("TOPLEFT", FarmLog_HUD_Line2N, "TOPRIGHT", paddingX / 2, 0)

	FarmLog_HUD_Line3N:SetPoint("TOPLEFT", FarmLog_HUD_Line2N, "BOTTOMLEFT", 0, -paddingY)
	FarmLog_HUD_Line3:SetPoint("TOPLEFT", FarmLog_HUD_Line3N, "TOPRIGHT", paddingX / 2, 0)

	if pvpMode then 
		height = height + 10

		FarmLog_HUD_Sep:SetPoint("TOPLEFT", FarmLog_HUD_Line3N, "BOTTOMLEFT", 0, -3)
		FarmLog_HUD_Sep:SetPoint("RIGHT", -paddingX, 0)
		FarmLog_HUD_Line4N:SetPoint("TOPLEFT", FarmLog_HUD_Sep, "BOTTOMLEFT", 0, -paddingY)
		FarmLog_HUD_Line4:SetPoint("TOPLEFT", FarmLog_HUD_Line4N, "TOPRIGHT", paddingX / 2, 0)
		FarmLog_HUD_Line5N:SetPoint("TOPLEFT", FarmLog_HUD_Line4N, "BOTTOMLEFT", 0, -paddingY)
		FarmLog_HUD_Line5:SetPoint("TOPLEFT", FarmLog_HUD_Line5N, "TOPRIGHT", paddingX / 2, 0)

		FarmLog_HUD_Sep:Show()
		FarmLog_HUD_Line4N:Show()
		FarmLog_HUD_Line4:Show()
		FarmLog_HUD_Line5N:Show()
		FarmLog_HUD_Line5:Show()		
	else 
		height = height - 10

		FarmLog_HUD_Sep:Hide()
		FarmLog_HUD_Line4N:Hide()
		FarmLog_HUD_Line4:Hide()
		FarmLog_HUD_Line5N:Hide()
		FarmLog_HUD_Line5:Hide()
	end 

	FarmLog_HUD:SetWidth(textMaxwidth + paddingX * 4 + numberMaxwidth)
	FarmLog_HUD:SetHeight(height)
end 

function FarmLog_HUD:DragStart() 
	if not FLogVars.hud.locked then 
		self:StartMoving()
	end 
end 

function FarmLog_HUD:DragStop() 
	if not FLogVars.hud.locked then 
		self:StopMovingOrSizing()
	end 
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
			btn.label:SetTextColor(255/255, 238/255, 0/255, 1)
		else 
			btn:SetBackdropColor(0.3, 0.3, 0.3, 0.2)
			btn:SetBackdropBorderColor(1, 1, 1, 0.15)
			btn.label:SetTextColor(0.8, 0.8, 0.8, 1)
		end 
	else 
		if btn.selected then 
			btn:SetBackdropColor(0.4, 0.4, 0.4, 0.3)
			btn:SetBackdropBorderColor(1, 1, 1, 0.2)
			btn.label:SetTextColor(245/255, 233/255, 66/255, 1)
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
	FarmLog_MainWindow:Refresh()
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
	FarmLog_MainWindow:Refresh()
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
	FarmLog_MainWindow:Refresh()
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
		FarmLog_MainWindow:Refresh()
	end 
	FarmLog_SetTextButtonBackdropColor(self, false)
	FarmLog_SetTextButtonBackdropColor(FarmLog_MainWindow_Buttons_SortKillsButton, false)
end 

function FarmLog_MainWindow_Buttons_ToggleCurrentButton:Clicked() 
	FLogVars.viewTotal = not FLogVars.viewTotal
	self.selected = not FLogVars.viewTotal
	FarmLog_MainWindow:Refresh()
	FarmLog_MainWindow:UpdateTitle()
	FarmLog_SetTextButtonBackdropColor(self, true)
end 

function FarmLog_MainWindow_Buttons_ToggleCurrentButton:MouseEnter()
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:SetText(L["toggle-current-help"])
	GameTooltip:Show()
end 

function FarmLog_MainWindow_Buttons_ToggleCurrentButton:MouseLeave()
	GameTooltip_Hide();
end 

function FarmLog_MainWindow_Buttons_TogglePvPButton:Clicked() 
	local enabled = not (GetFarmVar("pvpMode") == true)
	SetFarmVar("pvpMode", enabled)
	self.selected = enabled
	FarmLog_MainWindow:Refresh()
	FarmLog_HUD:DressUp()
end 

function FarmLog_MainWindow_Buttons_TogglePvPButton:MouseEnter()
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:SetText(L["toggle-pvp-help"])
	GameTooltip:Show()
end 

function FarmLog_MainWindow_Buttons_TogglePvPButton:MouseLeave()
	GameTooltip_Hide();
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
	FarmLog:AskQuestion(L["clear-session-title"], L["clear-session-question"], function() 
		FarmLog:ClearSession()
		FarmLog_QuestionDialog:Hide()
		if FLogVars.viewTotal then 
			-- starting a new session will do nothing if current session isn't toggled
			FarmLog_MainWindow_Buttons_ToggleCurrentButton:Clicked() 
		end 
	end)
end 

function FarmLog_MainWindow_NewSessionButton:Clicked()
	if self.disabled then return end 
	FarmLog:NewSession()
	if FLogVars.viewTotal then 
		-- starting a new session will do nothing if current session isn't toggled
		FarmLog_MainWindow_Buttons_ToggleCurrentButton:Clicked() 
	end 
end 

function FarmLog_MainWindow_ToggleHUDButton:Clicked(button) 
	if button == "RightButton" then 
		FarmLog_HUD:ResetPosition()
		FLogVars.hud.show = true 
	else 
		FLogVars.hud.show = not FLogVars.hud.show
	end 

	self.selected = FLogVars.hud.show
	if FLogVars.hud.show then 
		FarmLog_HUD:Refresh()
		FarmLog_HUD:DressUp()
		FarmLog_HUD:Show()
	else 
		FarmLog_HUD:Hide()
	end 
end 

function FarmLog_SessionsWindow_Buttons_NewFarmButton:Clicked()
	local searchText = FarmLog_SessionsWindow_Buttons_SearchBox:GetText()
	if FLogVars.farms[searchText] then 
		out("|cffff0000There's already a farm with that name, choose an unused name, or choose the existing one to use it")
		return 
	end 
	out("Starting a new farm |cff99ff00"..searchText)
	FarmLog:SwitchFarm(searchText, true, true)
	FarmLog_MainWindow:Refresh() 
	FarmLog_HUD:DressUp() 
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
		FarmLog:SwitchFarm(sessionSearchResult, true, FLogGlobalVars.resumeSessionOnSwitch)
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
	local goldPerHour
	local xpPerHour
	if FLogVars.viewTotal then 
		goldPerHour = GetFarmVar("goldPerHourTotal") or 0
		xpPerHour = GetFarmVar("xpPerHourTotal") or 0
	else 
		goldPerHour = GetFarmVar("goldPerHour") or 0
		xpPerHour = GetFarmVar("xpPerHour") or 0
	end 
	local text = "|cff5CC4ff" .. ADDON_NAME
	text = text .. "|r|nSession: " text = text .. sessionColor text = text .. FLogVars.currentFarm 
	text = text .. "|r|nTime: " text = text .. sessionColor text = text .. secondsToClock(FarmLog:GetCurrentSessionTime()) 
	if FLogGlobalVars.track.money and isPositive(goldPerHour) then
		text = text .. "|r|n" .. L["g/h"] .. ": |cffeeeeee" text = text .. GetShortCoinTextureString(goldPerHour) 
	end
	if FLogGlobalVars.track.xp and isPositive(xpPerHour) then
		text = text .. "|r|n" .. L["xp/h"] .. ": |cffeeeeee" text = text .. math.floor(xpPerHour) 
	end
	text = text .. "|cff999999|nLeft click: |cffeeeeeeopen main window"
	text = text .. "|cff999999|nRight click: |cffeeeeeepause/resume session"
	text = text .. "|cff999999|nCtrl click: |cffeeeeeeopen session list"
	text = text .. "|cff999999|nShift click: |cffeeeeeeshow options"
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


-- Honor frenzy counter

function FarmLog_HonorFrenzyMeter:Add(honor, test)
	if test then 
		self:EnableMouse(true)
		self:SetBackdropColor(0, 0, 0, 0.5)
		honorFrenzyTest = true
	end 
	if honorFrenzyTotal > 0 or test then 
		self:Show()
		if self:GetAlpha() == 0 then 
			UIFrameFadeIn(self, 0.1, 0, 1)
		end 
	end 
	honorFrenzyKills = honorFrenzyKills + 1
	honorFrenzyTotal = honorFrenzyTotal + honor
	FarmLog_HonorFrenzyMeter_Text:SetText(numberToString(honorFrenzyTotal))
	FarmLog_HonorFrenzyMeter_Kills_Text:SetText(tostring(honorFrenzyKills))
	honorFrenzySetTime = time()
end 

-- UI errors

function FarmLog:UIError(event,msg)
	if skillNameTime and msg == _G.SPELL_FAILED_TRY_AGAIN then 
		-- Failed attempt
		local now = time()
		debug("|cff999999UIError|r msg |cffff9900"..tostring(msg).."|r skillTooltip1 |cffff9900"..tostring(skillTooltip1).."|r time delta |cffff9900"..tostring(now - skillNameTime))
		local timeout = SKILL_LOOTWINDOW_OPEN_TIMEOUT[skillName or ""] or 0
		if now - skillNameTime < timeout and skillTooltip1 == BL_ITEM_NAME then 
			-- failed picking BL
			self:IncreaseBlackLotusPickStat("fail")
		end 
	end 
--[[
	local what = tooltipLeftText1:GetText();
	if not what then return end
	if strfind(msg, miningSpell) or (miningSpell2 and strfind(msg, miningSpell2)) then
		self:addItem(miningSpell,what)
	elseif strfind(msg, herbSkill) then
		self:addItem(herbSpell,what)
	elseif strfind(msg, pickSpell) or strfind(msg, openSpell) then -- locked box or failed pick
		self:addItem(openSpell, what)
	elseif strfind(msg, NL["Lumber Mill"]) then -- timber requires lumber mill
		self:addItem(loggingSpell, what)
	end
--]]
end

-- Slash Interface ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SLASH_FARMLOGTOGGLE1 = "/farm";
SlashCmdList.FARMLOGTOGGLE = function(msg)
	FarmLog:ToggleLogging()
end 

SLASH_FARMLOG1 = "/farmlog";
SLASH_FARMLOG2 = "/fl";
SlashCmdList.FARMLOG = function(msg)
	local _, _, cmd, arg1 = string.find(msg, "([%w]+)%s*(.*)$")
	if not cmd then
		-- FarmLog:ToggleLogging()
		InterfaceOptionsFrame_OpenToCategory(FarmLog.InterfacePanel)
		if not FLogVars.enabled then 
			out("|cffff7722To resume session, right click the minimap button.")
		end 
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
		elseif  "DELETE" == cmd then
			FarmLog:DeleteFarm(arg1)
		elseif  "SWITCH" == cmd or "W" == cmd then
			if not arg1 or #arg1 == 0 then arg1 = GetMinimapZoneText() end 
			out("Switching session to |cff99ff00"..arg1)
			FarmLog:SwitchFarm(arg1, true, true)
			FarmLog_MainWindow:Refresh() 
			FarmLog_HUD:DressUp() 
		elseif  "REN" == cmd then
			out("Renaming session from |cff99ff00"..FLogVars.currentFarm.."|r to |cff99ff00"..arg1)
			FLogVars.farms[arg1] = FLogVars.farms[FLogVars.currentFarm]
			FLogVars.farms[FLogVars.currentFarm] = nil 
			FLogVars.currentFarm = arg1 
			FarmLog_MainWindow:Refresh() 
			FarmLog_MainWindow:UpdateTitle()
		elseif  "INC" == cmd then
			local mobName = GetUnitName("target")
			out("Increasing kill count of |cff00ff99"..mobName)
			IncreaseSessionDictVar("kills", mobName, 1)
			FarmLog_MainWindow:Refresh() 
		elseif  "DEC" == cmd then
			local mobName = GetUnitName("target")
			out("Increasing kill count of |cff00ff99"..mobName)
			IncreaseSessionDictVar("kills", mobName, -1)
			FarmLog_MainWindow:Refresh() 
		elseif "ASI" == cmd then 
			FLogGlobalVars.autoSwitchInstances = not FLogGlobalVars.autoSwitchInstances 
			if not FLogGlobalVars.autoSwitchInstances then 
				out("Auto switching in instances |cffff4444"..L["disabled"])
			else 
				out("Auto switching in instances |cff44ff44"..L["enabled"])
			end 
		elseif  "RESET" == cmd or "R" == cmd then
			FarmLog:ClearSession()
		elseif  "RMI" == cmd then
			FarmLog_MinimapButton:ResetPosition()
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
		elseif "HUD" == cmd then 
			if FarmLog_HUD:IsShown() then 
				FarmLog_HUD:Hide()
				FLogVars.hud.show = false
			else 
				FarmLog_HUD:Show()
				FLogVars.hud.show = true
			end 
		elseif "BL" == cmd then 
			FarmLog:ShowBlackLotusLog()
		elseif "BLP" == cmd then 
			local pickedBy, pickZone = _G.string.split(" ", arg1)
			if pickedBy and #pickedBy == 0 then pickedBy = nil end 
			local pickMeta = {
				ts = time(),
				time = date("%H:%M:%S"),
				date = date("%m-%d"),
				pickedBy = pickedBy,
				zone = pickZone,
			}
			if blSeen and time() - blSeen.ts <= BL_SEEN_TIMEOUT then 
				pickMeta.seen = blSeen
			end 
			FarmLog:LogBlackLotus(GetZoneText(), pickMeta)
		elseif "BLS" == cmd then 
			FarmLog:SaveBLSeenTime() 
		else 
			out("Unknown command "..cmd)
		end 
	end 
end
