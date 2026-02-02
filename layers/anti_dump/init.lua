--[[
    Luartex Anti-Dump Layer
    Prevents memory dumping and code extraction
]]

local AST = require("core.ast")
local Utils = require("core.utils")

local AntiDump = {}
AntiDump.__index = AntiDump

function AntiDump.new(luartex)
    local self = setmetatable({}, AntiDump)
    
    self.luartex = luartex
    self.config = luartex.config.antiDump
    self.random = luartex.random
    self.logger = luartex.logger
    
    -- Sub-modules
    self.memoryGuard = require("layers.anti_dump.memory_guard").new(self)
    self.runtimeDecrypt = require("layers.anti_dump.runtime_decrypt").new(self)
    self.chunkLoader = require("layers.anti_dump.chunk_loader").new(self)
    self.antiDebug = require("layers.anti_dump.anti_debug").new(self)
    
    return self
end

function AntiDump:apply(ast)
    -- Apply protections to AST
    return ast
end

function AntiDump:wrap(source)
    self.logger:debug("Applying anti-dump wrapper...")
    
    local wrappers = {}
    
    -- Add memory protection
    if self.config.memoryProtection then
        local memGuard = self.memoryGuard:generate()
        table.insert(wrappers, memGuard)
    end
    
    -- Add chunk encryption
    if self.config.chunkEncryption then
        source = self.runtimeDecrypt:encrypt(source)
    end
    
    -- Add anti-debug
    if self.config.antiDebug then
        local antiDebugCode = self.antiDebug:generate()
        table.insert(wrappers, antiDebugCode)
    end
    
    -- Combine wrappers with source
    local result = table.concat(wrappers, "\n") .. "\n" .. source
    
    return result
end

return AntiDump
