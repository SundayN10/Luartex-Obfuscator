--[[
    Chunk Loader
    Loads code in encrypted chunks
]]

local Utils = require("core.utils")

local ChunkLoader = {}
ChunkLoader.__index = ChunkLoader

function ChunkLoader.new(parent)
    local self = setmetatable({}, ChunkLoader)
    
    self.parent = parent
    self.random = parent.random
    
    return self
end

function ChunkLoader:splitAndEncrypt(source)
    local chunkSize = 500
    local chunks = {}
    
    for i = 1, #source, chunkSize do
        local chunk = source:sub(i, i + chunkSize - 1)
        local key = self.random:string(16)
        local encrypted = Utils.xor(chunk, key)
        
        table.insert(chunks, {
            data = Utils.base64Encode(encrypted),
            key = key,
        })
    end
    
    return chunks
end

function ChunkLoader:generateLoader(chunks)
    local loaderVar = self.random:identifier(14)
    local chunksVar = self.random:identifier(12)
    local decodeVar = self.random:identifier(12)
    local xorVar = self.random:identifier(10)
    local b64dVar = self.random:identifier(10)
    
    local chunkDefs = {}
    for _, chunk in ipairs(chunks) do
        local keyEscaped = Utils.escapeLuaString(chunk.key)
        local dataEscaped = Utils.escapeLuaString(chunk.data)
        table.insert(chunkDefs, string.format('{d="%s",k="%s"}', dataEscaped, keyEscaped))
    end
    
    local code = string.format([[
do
    local %s = {%s}
    
    local %s = function(d)
        local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        local lookup = {}
        for i = 1, 64 do lookup[b:sub(i, i):byte()] = i - 1 end
        
        d = d:gsub("[^" .. b .. "=]", "")
        local r = {}
        
        for i = 1, #d, 4 do
            local a = lookup[d:byte(i)] or 0
            local b = lookup[d:byte(i + 1)] or 0
            local c = lookup[d:byte(i + 2)] or 0
            local e = lookup[d:byte(i + 3)] or 0
            
            local n = a * 262144 + b * 4096 + c * 64 + e
            r[#r + 1] = string.char(math.floor(n / 65536) %% 256)
            if d:sub(i + 2, i + 2) ~= "=" then
                r[#r + 1] = string.char(math.floor(n / 256) %% 256)
            end
            if d:sub(i + 3, i + 3) ~= "=" then
                r[#r + 1] = string.char(n %% 256)
            end
        end
        
        return table.concat(r)
    end
    
    local %s = function(s, k)
        local r = {}
        for i = 1, #s do
            local ki = ((i - 1) %% #k) + 1
            r[i] = string.char(string.byte(s, i) ~ string.byte(k, ki))
        end
        return table.concat(r)
    end
    
    local %s = function(chunk)
        local decoded = %s(chunk.d)
        local decrypted = %s(decoded, chunk.k)
        return decrypted
    end
    
    local %s = {}
    for i = 1, #%s do
        %s[i] = %s(%s[i])
    end
    
    local source = table.concat(%s)
    local fn, err = loadstring(source)
    if fn then
        fn()
    else
        error(err or "Load failed")
    end
end
]], chunksVar, table.concat(chunkDefs, ","),
    b64dVar, xorVar, decodeVar, b64dVar, xorVar,
    loaderVar, chunksVar, loaderVar, decodeVar, chunksVar, loaderVar)
    
    return code
end

return ChunkLoader
