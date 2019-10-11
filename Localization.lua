
function FarmLog_BuildLocalization(context)
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
    L["Report"] = "FLogSVDrops-Report ";
    L["Report2"] = "Last change on ";
    L["Report:"] = "Report to:";
    L["Money"] = "Money"
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
    L["LDBClick"] = "Left-Click to open "..context.FLogVersion.."|nRight-Click to open Blizzard-FarmLog";
    L["Help"] = "O = Show Options|n? = Show Help|nX = Close Frame|n|n- Mouseover a row to highlight and to show Item-Tooltip|n- Shift-Click to copy the ItemLink into the Chatframe-EditBox|n- Alt-Click to to edit the owner of selected Item(s)|n|nReport = Report current FLogSVDrops|nReset = Reset the current FLogSVDrops";
    L["tooltip"] = "Show Item-Tolltip";
    L["updated"] = "|cffffff00FarmLog|r Updated to Version "..context.FLogVersionNumber..".";
    L["updated2"] = "|cffffff00FarmLog|r The complete data has been reset, caused by compatibility-reasons.";
    L["loaded-welcome"] = "|cffffff00FarmLog|r Loaded, type |cff00ffff/farmlog|r to start/end a farm session";
    L["window-title"] = "Farm Yield";
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
        L["Report"] = "FLogSVDrops-Bericht ";
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
        L["LDBClick"] = "Links-Klicken um "..context.FLogVersion.." zu öffnen|nRechts-Klicken um Blizzard-FarmLog zu öffnen";
        L["Help"] = "O = Optionen|n? = Hilfe|nX = Fenster schließen|n|n- Mouseover zum hervorheben der Zeile und um den Item-Tooltip anzuzeigen|n- Shift-Klick um den ItemLink in die Chatframe-EditBox einzufügen|n- Alt-Klick um den Besitzer der / des ausgewählten Items zu ändern|n|nBerichten = FLogSVDrops-Bericht erstellen|nReset = FLogSVDrops zurücksetzen";
        L["tooltip"] = "Item-Tolltip anzeigen";
        L["updated"] = "|cffff0000FarmLog wurde auf Version v"..context.FLogVersionNumber.." geupdated.|r";
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
        print("|cffff0000"..context.FLogVersion..": Your WoW-Version isn't compatible. This is caused by localization issues.|r");
    end
    --end localization
    return L
end