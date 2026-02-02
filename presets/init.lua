--[[
    Luartex Presets Loader
]]

local Presets = {}

local registry = {}

-- Load all presets
local presetFiles = {
    "light",
    "standard",
    "hardened",
    "maximum",
    "roblox",
}

for _, name in ipairs(presetFiles) do
    local success, preset = pcall(require, "presets." .. name)
    if success then
        registry[name] = preset
    end
end

function Presets.get(name)
    return registry[name]
end

function Presets.list()
    local names = {}
    for name in pairs(registry) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

function Presets.register(name, preset)
    registry[name] = preset
end

return Presets
