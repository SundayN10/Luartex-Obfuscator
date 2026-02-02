--[[
    Luartex Anti-Tamper Layer
    Prevents code modification and tampering
]]

local AST = require("core.ast")
local Utils = require("core.utils")

local AntiTamper = {}
AntiTamper.__index = AntiTamper

function AntiTamper.new(luartex)
    local self = setmetatable({}, AntiTamper)
    
    self.luartex = luartex
    self.config = luartex.config.antiTamper
    self.random = luartex.random
    self.logger = luartex.logger
    
    -- Sub-modules
    self.integrityCheck = require("layers.anti_tamper.integrity_check").new(self)
    self.environmentCheck = require("layers.anti_tamper.environment_check").new(self)
    self.checksum = require("layers.anti_tamper.checksum").new(self)
    self.selfVerify = require("layers.anti_tamper.self_verify").new(self)
    
    return self
end

function AntiTamper:apply(ast)
    self.logger:debug("Applying anti-tamper protection...")
    
    local protections = {}
    
    -- Add integrity checks
    if self.config.integrityCheck then
        local integrityCode = self.integrityCheck:generate()
        table.insert(protections, integrityCode)
    end
    
    -- Add environment checks
    if self.config.environmentCheck then
        local envCode = self.environmentCheck:generate()
        table.insert(protections, envCode)
    end
    
    -- Add checksum verification
    if self.config.checksumVerify then
        local checksumCode = self.checksum:generate(ast)
        table.insert(protections, checksumCode)
    end
    
    -- Inject protections at the beginning
    if #protections > 0 then
        local Parser = require("core.parser")
        
        for i = #protections, 1, -1 do
            local protectionAST = Parser.parse(protections[i])
            
            for j = #protectionAST.body, 1, -1 do
                table.insert(ast.body, 1, protectionAST.body[j])
            end
        end
    end
    
    return ast
end

return AntiTamper
