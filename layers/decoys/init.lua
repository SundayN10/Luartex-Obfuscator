--[[
    Luartex Decoys Layer
    Injects fake code and honey traps
]]

local AST = require("core.ast")
local Utils = require("core.utils")

local Decoys = {}
Decoys.__index = Decoys

function Decoys.new(luartex)
    local self = setmetatable({}, Decoys)
    
    self.luartex = luartex
    self.config = luartex.config.decoys
    self.random = luartex.random
    self.logger = luartex.logger
    
    -- Sub-modules
    self.fakeFunctions = require("layers.decoys.fake_functions").new(self)
    self.honeyTraps = require("layers.decoys.honey_traps").new(self)
    self.fakeApiCalls = require("layers.decoys.fake_api_calls").new(self)
    self.decoyStrings = require("layers.decoys.decoy_strings").new(self)
    
    return self
end

function Decoys:apply(ast)
    self.logger:debug("Applying decoys layer...")
    
    -- Add fake functions
    if self.config.fakeFunctions > 0 then
        ast = self.fakeFunctions:inject(ast, self.config.fakeFunctions)
    end
    
    -- Add fake strings
    if self.config.fakeStrings > 0 then
        ast = self.decoyStrings:inject(ast, self.config.fakeStrings)
    end
    
    -- Add honey traps
    if self.config.honeyTraps then
        ast = self.honeyTraps:inject(ast)
    end
    
    -- Add fake API calls
    if self.config.fakeApiCalls then
        ast = self.fakeApiCalls:inject(ast)
    end
    
    return ast
end

return Decoys
