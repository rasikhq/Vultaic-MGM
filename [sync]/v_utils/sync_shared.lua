-- Integers are faster than strings.
-- Convert string to integer > sync > convert integers to string
local replace = {
    "arena",
    "state",
    "spectating",
    "waiting",
    "alive", 
    "dead",
    "spectating",        
    "training"  
}
local replace_dict = {}
for id, value in pairs(replace) do
    replace_dict[value] = id
end

function transformData(key, value)
    local key = replace_dict[key] or key
    local value = replace_dict[value] or value
    return key, value
end

function replaceDataIDs(key, value)
    local key = replace[key] or key
    local value = replace[value] or value
    return key, value
end