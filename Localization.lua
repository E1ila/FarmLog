
function FarmLog_BuildLocalization(context)
    local L = {};
    L["All Sessions"] = "All Sessions"
    L["disabled"] = "disabled"
    L["enabled"] = "enabled"
    L["yes"] = "Yes";
    L["no"] = "No";
    L["reset-question"] = "Clear current session's data?";	
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
    L["Report"] = "FLogSVDrops-Report ";
    L["Report2"] = "Last change on ";
    L["Report:"] = "Report to:";
    L["Money"] = "Money"
    L["Money Looted"] = "Money Looted"
    L["Vendor"] = "Vendor"
    L["XP"] = "XP"
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
    L["LDBClick"] = "Left-Click to open FarmLog|nRight-Click to open Blizzard-FarmLog";
    L["Help"] = "O = Show Options|n? = Show Help|nX = Close Frame|n|n- Mouseover a row to highlight and to show Item-Tooltip|n- Shift-Click to copy the ItemLink into the Chatframe-EditBox|n- Alt-Click to to edit the owner of selected Item(s)|n|nReport = Report current FLogSVDrops|nReset = Reset the current FLogSVDrops";
    L["tooltip"] = "Show Item-Tolltip";
    L["loaded-welcome"] = "type |cff00ff00/fl|r or |cff00ff00/farmlog|r to start/end a farm session, |cff00ff00/fl help|r for more options";
    L["window-title"] = "Session Yield";
    L["reset-title"] = "Clear Session"
    L["Auction House"] = "Auction House"
    L["Session"] = "Session"
    L["reputation"] = "reputation"
    L["levels"] = "levels"
    L["Skills"] = "Skills"
    L["Herbalism"] = "Herbalism"
    L["Fishing"] = "Fishing"
    L["Mining"] = "Mining"
    L["Skinning"] = "Skinning"
    L["Unknown"] = "Unknown"
    L["Gold / Hour"] = "Gold / Hour"
    L["G/H"] = "G/H"
    L["need"] = "N: ";
    L["greed"] = "G: ";
    L["disenchant"] = "D: ";
    L["loot"] = "loot: ";
    L["you"] = "You";
    L["Resume"] = "Resume";
    L["Pause"] = "Pause";
    L["deletesession-title"] = "Delete Session"
    L["deletesession-question"] = "Do you want to delete this session?"
    if (GetLocale() == "enUS") then
    end
    return L
end