--[[
    Luartex Obfuscator - Basic Usage Example
]]

local Luartex = require("init")

-- Simple obfuscation
local source = [[
local function greet(name)
    print("Hello, " .. name .. "!")
end

greet("World")
]]

-- Create obfuscator with default settings
local obfuscator = Luartex.new()
obfuscator:usePreset("standard")

-- Obfuscate
local result = obfuscator:obfuscate(source)

print("=== Original ===")
print(source)

print("\n=== Obfuscated ===")
print(result)

-- Verify it works
print("\n=== Execution Test ===")
local fn = loadstring(result)
if fn then
    fn()
else
    print("Error: Could not load obfuscated code")
end
