# FarmLog
Logs loot, monster kills, honor and instances. Know exactly what your farm session has yielded.

### What it does
* Tracks 
    * Shows Gold/Hour of active farming session
    * Farm session time with a stopwatch
    * Mob kills, counts how many of each mob was killed
    * Loot from mobs and quests
    * Herbalism, skinning and mining yield
    * Money loot, displays total gold collected
    * Shows loot vendor value in gold
    * Reputation gain per faction
    * XP gained
    * Skill levels
    * Honor gain (not tested yet, will be available in phase 2)
* Allows reporting farm results
* Display farm yield in a window with all looted items
* Allows filtering item poor and common items

### What it is for
You can track your farming session and know how much gold/hour you make. Good for general grinding, instance item farming, rep farm, tradeskill work, honor farm, know how many you killed in a rare BoE farm, etc etc.

### How to install
* Download, extract (if zipped)
* Make sure folder doesn't have `-master` surffix
* Copy `FarmLog` folder to your `WoW\Interface\AddOns` folder

### How to use
* /fl - toggle logging on/off
* /fl r - reset log
* /fl s - shows log
* /fl set <ITEMLINK> <GOLDVALUE> - sets AH value of an item, in gold

### To do
* Count instance IDs (total & last hour)
* Allow named sessions, save data per session seperately
* Maybe treat instance name as a session name
* Calculate total AH value for items, set item AH value
* Track quest reward
* Track traded gold (for enchanting, etc)
* Support Chest / Container opening
* Track deaths
* Show repair bill

![Preview 1](https://github.com/E1ila/FarmLog/blob/master/Preview2.png)
![Preview 2](https://github.com/E1ila/FarmLog/blob/master/Preview.png)

This addon was based on the LootHistory addon which tracks who received which loot -
https://www.curseforge.com/wow/addons/loothistory
