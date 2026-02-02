--[[
    Anti-Debug Protection
    Detects and prevents debugging
]]

local AntiDebug = {}
AntiDebug.__index = AntiDebug

function AntiDebug.new(parent)
    local self = setmetatable({}, AntiDebug)
    
    self.parent = parent
    self.random = parent.random
    
    return self
end

function AntiDebug:generate()
    local checkVar = self.random:identifier(16)
    local timerVar = self.random:identifier(14)
    local lastTimeVar = self.random:identifier(12)
    local detectVar = self.random:identifier(12)
    
    local code = string.format([[
do
    local %s = os.clock and os.clock() or 0
    
    local %s = function()
        -- Check for debug library hooks
        if debug then
            if debug.gethook and debug.gethook() then
                return true
            end
            
            -- Check if debug.getinfo is hooked
            local info = debug.getinfo and debug.getinfo(1)
            if info and info.func then
                local ok, dump = pcall(string.dump, info.func)
                if not ok then
                    return true
                end
            end
            
            -- Check for debug.sethook being called
            local oldHook = debug.sethook
            if type(oldHook) ~= "function" then
                return true
            end
        end
        
        -- Timing check - detect if execution was paused
        local now = os.clock and os.clock() or 0
        local delta = now - %s
        %s = now
        
        if delta > 2 then
            return true
        end
        
        -- Check for common debugger globals
        if _G.mobdebug or _G.debugger or _G.lldebugger then
            return true
        end
        
        return false
    end
    
    local %s = function()
        if %s() then
            -- Detected! Crash the script
            local crash = nil
            crash()
        end
    end
    
    -- Initial check
    %s()
    
    -- Set up periodic checks if possible
    if type(spawn) == "function" then
        spawn(function()
            while true do
                local w = wait or function(t) 
                    local s = os.clock() 
                    while os.clock() - s < t do end 
                end
                w(0.5)
                %s()
            end
        end)
    end
end
]], lastTimeVar, detectVar, lastTimeVar, lastTimeVar,
    checkVar, detectVar, checkVar, checkVar)
    
    return code
end

return AntiDebug
