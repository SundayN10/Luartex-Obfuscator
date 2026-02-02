--[[
    Luartex Obfuscator - Advanced Usage Example
]]

local Luartex = require("init")

-- Complex source code
local source = [[
local Calculator = {}
Calculator.__index = Calculator

function Calculator.new()
    local self = setmetatable({}, Calculator)
    self.result = 0
    return self
end

function Calculator:add(n)
    self.result = self.result + n
    return self
end

function Calculator:subtract(n)
    self.result = self.result - n
    return self
end

function Calculator:multiply(n)
    self.result = self.result * n
    return self
end

function Calculator:divide(n)
    if n ~= 0 then
        self.result = self.result / n
    end
    return self
end

function Calculator:getResult()
    return self.result
end

-- Usage
local calc = Calculator.new()
local result = calc:add(10):multiply(5):subtract(20):getResult()
print("Result: " .. result)
]]

-- Create obfuscator with custom settings
local obfuscator = Luartex.new({
    logLevel = "debug",
    seed = 12345,  -- For reproducible results
})

-- Use maximum preset
obfuscator:usePreset("maximum")

-- Obfuscate
local result, err = obfuscator:obfuscate(source)

if result then
    print("Obfuscation successful!")
    print("Original size: " .. #source .. " bytes")
    print("Obfuscated size: " .. #result .. " bytes")
    print("Ratio: " .. string.format("%.2fx", #result / #source))
    
    -- Save to file
    local file = io.open("output.lua", "w")
    if file then
        file:write(result)
        file:close()
        print("Saved to output.lua")
    end
else
    print("Error: " .. tostring(err))
end
