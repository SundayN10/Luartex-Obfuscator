--[[
    Luartex Secure Random Generator
    Cryptographically-inspired PRNG
]]

local Random = {}
Random.__index = Random

-- Constants for xoshiro256**
local JUMP = { 0x180ec6d33cfd0aba, 0xd5a61266f0c9392c, 0xa9582618e03fc9aa, 0x39abdc4529b1661c }

function Random.new(seed)
    local self = setmetatable({}, Random)
    
    seed = seed or (os.time() * 1000 + os.clock() * 1000000)
    
    -- Initialize state with seed
    self.state = {
        seed,
        seed * 6364136223846793005 + 1442695040888963407,
        seed * 1103515245 + 12345,
        seed * 214013 + 2531011,
    }
    
    -- Warm up the generator
    for _ = 1, 50 do
        self:_next()
    end
    
    self.seed = seed
    self.calls = 0
    
    return self
end

-- Core random function (xoshiro256**)
function Random:_next()
    self.calls = self.calls + 1
    
    local s = self.state
    local result = self:_rotl(s[2] * 5, 7) * 9
    
    local t = s[2] * 0x20000  -- s[2] << 17
    
    s[3] = s[3] ~ s[1]
    s[4] = s[4] ~ s[2]
    s[2] = s[2] ~ s[3]
    s[1] = s[1] ~ s[4]
    
    s[3] = s[3] ~ t
    s[4] = self:_rotl(s[4], 45)
    
    return math.abs(result)
end

function Random:_rotl(x, k)
    return ((x * (2^k)) + math.floor(x / (2^(64-k)))) % (2^64)
end

-- Integer in range [min, max]
function Random:int(min, max)
    min = min or 0
    max = max or 2147483647
    return min + (self:_next() % (max - min + 1))
end

-- Float in range [0, 1)
function Random:float()
    return (self:_next() % 10000000) / 10000000
end

-- Float in range [min, max)
function Random:range(min, max)
    return min + self:float() * (max - min)
end

-- Boolean with probability
function Random:bool(probability)
    probability = probability or 0.5
    return self:float() < probability
end

-- Choose random element from array
function Random:choice(array)
    if #array == 0 then return nil end
    return array[self:int(1, #array)]
end

-- Choose multiple random elements
function Random:sample(array, count)
    local result = {}
    local copy = {}
    for i, v in ipairs(array) do copy[i] = v end
    
    count = math.min(count, #copy)
    
    for i = 1, count do
        local idx = self:int(1, #copy)
        table.insert(result, copy[idx])
        table.remove(copy, idx)
    end
    
    return result
end

-- Shuffle array in place
function Random:shuffle(array)
    for i = #array, 2, -1 do
        local j = self:int(1, i)
        array[i], array[j] = array[j], array[i]
    end
    return array
end

-- Weighted random choice
function Random:weighted(choices)
    local total = 0
    for _, choice in ipairs(choices) do
        total = total + (choice.weight or 1)
    end
    
    local rand = self:float() * total
    local cumulative = 0
    
    for _, choice in ipairs(choices) do
        cumulative = cumulative + (choice.weight or 1)
        if rand <= cumulative then
            return choice.value or choice
        end
    end
    
    return choices[#choices].value or choices[#choices]
end

-- Generate random string
function Random:string(length, charset)
    charset = charset or "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = {}
    
    for i = 1, length do
        local idx = self:int(1, #charset)
        result[i] = charset:sub(idx, idx)
    end
    
    return table.concat(result)
end

-- Generate random Lua identifier
function Random:identifier(length)
    length = length or self:int(8, 16)
    
    local first = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"
    local rest = first .. "0123456789"
    
    local result = first:sub(self:int(1, #first), 1)
    
    for _ = 2, length do
        local idx = self:int(1, #rest)
        result = result .. rest:sub(idx, idx)
    end
    
    return result
end

-- Generate unique identifiers
function Random:uniqueIdentifiers(count, length)
    local identifiers = {}
    local used = {}
    
    for i = 1, count do
        local id
        repeat
            id = self:identifier(length)
        until not used[id]
        
        used[id] = true
        identifiers[i] = id
    end
    
    return identifiers
end

-- Generate random bytes
function Random:bytes(count)
    local result = {}
    for i = 1, count do
        result[i] = self:int(0, 255)
    end
    return result
end

-- Generate random hex string
function Random:hex(length)
    local result = {}
    for i = 1, length do
        result[i] = string.format("%02x", self:int(0, 255))
    end
    return table.concat(result)
end

-- Get seed for reproducibility
function Random:getSeed()
    return self.seed
end

return Random
