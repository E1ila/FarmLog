local next, ipairs, assert, loadstring = next, ipairs, assert, loadstring
local tconcat = table.concat
local function donothing() end

local cache = {}
local sequences = {
    ["%d*d"] = "%%-?%%d+",
    ["s"] = ".+",
    ["[fg]"] = "%%-?%%d+%%.?%%d*",
    ["%%%.%d[fg]"] = "%%-?%%d+%%.?%%d*",
    ["c"] = ".",
}

local function get_first_pattern(s)
    local first_pos, first_pattern
    for pattern in next, sequences do
        local pos = s:find("%%%%"..pattern)
        if pos and (not first_pos or pos < first_pos) then
            first_pos, first_pattern = pos, pattern
        end
    end
    return first_pattern
end

local function get_indexed_pattern(s, i)
    for pattern in next, sequences do
        if s:find("%%%%" .. i .. "%%%$" .. pattern) then
            return pattern
        end
    end
end

local function unpattern_unordered(unpattern, f)
    local i = 1
    while true do
        local pattern = get_first_pattern(unpattern)
        if not pattern then return unpattern, i > 1 end

        unpattern = unpattern:gsub("%%%%" .. pattern, "(" .. sequences[pattern] .. ")", 1)
        f[i] = (pattern ~= "c" and pattern ~= "s")
        i = i + 1
    end
end

local function unpattern_ordered(unpattern, f)
    local i = 1
    while true do
        local pattern = get_indexed_pattern(unpattern, i)
        if not pattern then return unpattern, i > 1 end

        unpattern = unpattern:gsub("%%%%" .. i .. "%%%$" .. pattern, "(" .. sequences[pattern] .. ")", 1)
        f[i] = (pattern ~= "c" and pattern ~= "s")
        i = i + 1
    end
end

function GetPattern(pattern)
    local unpattern, f, matched = '^' .. pattern:gsub("([%(%)%.%*%+%-%[%]%?%^%$%%])", "%%%1") .. '$', {}
    if not pattern:find("%1$", nil, true) then
        unpattern, matched = unpattern_unordered(unpattern, f)
        if not matched then
            return donothing
        else
            local locals, returns = {}, {}
            for index, number in ipairs(f) do
                local l = ("v%d"):format(index)
                locals[index] = l
                if number then
                    returns[#returns + 1] = "n("..l..")"
                else
                    returns[#returns + 1] = l
                end
            end
            locals = tconcat(locals, ",")
            returns = tconcat(returns, ",")
            local code = ("local m, n = string.match, tonumber return function(s) local %s = m(s, %q) return %s end"):format(locals, unpattern, returns)
            return assert(loadstring(code))()
        end
    else
        unpattern, matched = unpattern_ordered(unpattern, f)
        if not matched then
            return donothing
        else
            local i, o = 1, {}
            pattern:gsub("%%(%d)%$", function(w) o[i] = tonumber(w); i = i + 1; end)
            local sorted_locals, returns = {}, {}
            for index, number in ipairs(f) do
                local l = ("v%d"):format(index)
                sorted_locals[index] = ("v%d"):format(o[index])
                if number then
                    returns[#returns + 1] = "n("..l..")"
                else
                    returns[#returns + 1] = l
                end
            end
            sorted_locals = tconcat(sorted_locals, ",")
            returns = tconcat(returns, ",")
            local code =("local m, n = string.match, tonumber return function(s) local %s = m(s, %q) return %s end"):format(sorted_locals, unpattern, returns)
            return assert(loadstring(code))()
        end
    end
end

function FLogDeformat(text, pattern)
    local func = cache[pattern]
    if not func then
        func = GetPattern(pattern)
        cache[pattern] = func
    end
    return func(text)
end