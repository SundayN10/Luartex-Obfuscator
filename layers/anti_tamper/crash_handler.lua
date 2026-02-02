--[[
    Crash Handler
    Various ways to crash the script on tamper detection
]]

local CrashHandler = {}
CrashHandler.__index = CrashHandler

function CrashHandler.new(random)
    local self = setmetatable({}, CrashHandler)
    self.random = random
    return self
end

function CrashHandler:generate()
    local methods = {
        self:infiniteLoop(),
        self:stackOverflow(),
        self:memoryExhaust(),
        self:nilCall(),
        self:divideByZero(),
    }
    
    return methods[self.random:int(1, #methods)]
end

function CrashHandler:infiniteLoop()
    return "while true do end"
end

function CrashHandler:stackOverflow()
    local funcName = self.random:identifier(10)
    return string.format([[
local function %s() %s() end
%s()
]], funcName, funcName, funcName)
end

function CrashHandler:memoryExhaust()
    local tableVar = self.random:identifier(10)
    return string.format([[
local %s = {}
while true do
    %s[#%s + 1] = string.rep("x", 1000000)
end
]], tableVar, tableVar, tableVar)
end

function CrashHandler:nilCall()
    return "local _ = nil; _()"
end

function CrashHandler:divideByZero()
    return "local _ = 1/0; while _ == _ do _ = _/0 end"
end

return CrashHandler
