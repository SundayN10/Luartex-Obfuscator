--[[
    Decoy Strings
    Injects fake strings that look like important data
]]

local AST = require("core.ast")

local DecoyStrings = {}
DecoyStrings.__index = DecoyStrings

function DecoyStrings.new(parent)
    local self = setmetatable({}, DecoyStrings)
    
    self.parent = parent
    self.random = parent.random
    
    return self
end

function DecoyStrings:inject(ast, count)
    local decoys = {}
    
    for _ = 1, count do
        local decoy = self:generateDecoyVariable()
        table.insert(decoys, decoy)
    end
    
    -- Insert at random positions
    for _, decoy in ipairs(decoys) do
        local position = self.random:int(1, math.max(1, #ast.body))
        table.insert(ast.body, position, decoy)
    end
    
    return ast
end

function DecoyStrings:generateDecoyVariable()
    local varName = self.random:identifier(12)
    local fakeString = self:generateFakeString()
    
    return AST.localStatement(
        { AST.identifier(varName) },
        { AST.stringLiteral(fakeString) }
    )
end

function DecoyStrings:generateFakeString()
    local types = {
        self.generateFakeKey,
        self.generateFakeUrl,
        self.generateFakeToken,
        self.generateFakePassword,
        self.generateFakeApiKey,
        self.generateFakeLicense,
        self.generateFakeWebhook,
    }
    
    local generator = types[self.random:int(1, #types)]
    return generator(self)
end

function DecoyStrings:generateFakeKey()
    return "key_" .. self.random:hex(32)
end

function DecoyStrings:generateFakeUrl()
    local domains = {
        "api.service.com",
        "auth.platform.io",
        "backend.server.net",
        "data.cloud.org",
        "secure.gateway.com",
    }
    
    return "https://" .. self.random:choice(domains) .. "/" .. self.random:string(8)
end

function DecoyStrings:generateFakeToken()
    return "eyJ" .. self.random:string(32) .. "." .. self.random:string(48) .. "." .. self.random:string(24)
end

function DecoyStrings:generateFakePassword()
    return self.random:string(8) .. self.random:int(100, 999) .. "!" .. self.random:string(4)
end

function DecoyStrings:generateFakeApiKey()
    local prefixes = { "sk_live_", "pk_test_", "api_", "secret_", "access_" }
    return self.random:choice(prefixes) .. self.random:hex(24)
end

function DecoyStrings:generateFakeLicense()
    local parts = {}
    for _ = 1, 4 do
        table.insert(parts, self.random:string(4):upper())
    end
    return table.concat(parts, "-")
end

function DecoyStrings:generateFakeWebhook()
    local services = {
        "discord.com/api/webhooks",
        "hooks.slack.com/services",
        "api.telegram.org/bot",
    }
    return "https://" .. self.random:choice(services) .. "/" .. self.random:hex(16)
end

return DecoyStrings
