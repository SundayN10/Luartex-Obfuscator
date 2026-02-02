--[[
    Luartex Utility Functions
]]

local Utils = {}

-- Deep copy
function Utils.deepCopy(orig)
    local copy
    if type(orig) == "table" then
        copy = {}
        for k, v in next, orig, nil do
            copy[Utils.deepCopy(k)] = Utils.deepCopy(v)
        end
        setmetatable(copy, Utils.deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Shallow merge
function Utils.merge(...)
    local result = {}
    for _, tbl in ipairs({...}) do
        if type(tbl) == "table" then
            for k, v in pairs(tbl) do
                result[k] = v
            end
        end
    end
    return result
end

-- Deep merge
function Utils.deepMerge(base, override)
    local result = Utils.deepCopy(base)
    
    for k, v in pairs(override) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = Utils.deepMerge(result[k], v)
        else
            result[k] = v
        end
    end
    
    return result
end

-- Check if table contains value
function Utils.contains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then return true end
    end
    return false
end

-- Get table keys
function Utils.keys(tbl)
    local result = {}
    for k in pairs(tbl) do
        table.insert(result, k)
    end
    return result
end

-- Get table values
function Utils.values(tbl)
    local result = {}
    for _, v in pairs(tbl) do
        table.insert(result, v)
    end
    return result
end

-- Map function over array
function Utils.map(array, fn)
    local result = {}
    for i, v in ipairs(array) do
        result[i] = fn(v, i)
    end
    return result
end

-- Filter array
function Utils.filter(array, predicate)
    local result = {}
    for i, v in ipairs(array) do
        if predicate(v, i) then
            table.insert(result, v)
        end
    end
    return result
end

-- Reduce array
function Utils.reduce(array, fn, initial)
    local acc = initial
    for i, v in ipairs(array) do
        acc = fn(acc, v, i)
    end
    return acc
end

-- String utilities
function Utils.split(str, delimiter)
    local result = {}
    local pattern = string.format("([^%s]+)", delimiter or ",")
    for match in str:gmatch(pattern) do
        table.insert(result, match)
    end
    return result
end

function Utils.trim(str)
    return str:match("^%s*(.-)%s*$")
end

function Utils.startsWith(str, prefix)
    return str:sub(1, #prefix) == prefix
end

function Utils.endsWith(str, suffix)
    return str:sub(-#suffix) == suffix
end

-- Escape Lua string
function Utils.escapeLuaString(str)
    local escapes = {
        ["\\"] = "\\\\",
        ["\""] = "\\\"",
        ["'"] = "\\'",
        ["\n"] = "\\n",
        ["\r"] = "\\r",
        ["\t"] = "\\t",
        ["\0"] = "\\0",
    }
    
    return str:gsub(".", function(c)
        if escapes[c] then
            return escapes[c]
        elseif c:byte() < 32 or c:byte() > 126 then
            return string.format("\\%03d", c:byte())
        else
            return c
        end
    end)
end

-- Convert string to byte array representation
function Utils.stringToBytes(str)
    local bytes = {}
    for i = 1, #str do
        bytes[i] = string.byte(str, i)
    end
    return bytes
end

-- Convert byte array to string
function Utils.bytesToString(bytes)
    local chars = {}
    for i, b in ipairs(bytes) do
        chars[i] = string.char(b)
    end
    return table.concat(chars)
end

-- XOR encryption
function Utils.xor(data, key)
    local result = {}
    local keyLen = #key
    
    for i = 1, #data do
        local keyIdx = ((i - 1) % keyLen) + 1
        local dataByte = type(data) == "string" and string.byte(data, i) or data[i]
        local keyByte = type(key) == "string" and string.byte(key, keyIdx) or key[keyIdx]
        
        result[i] = string.char(dataByte ~ keyByte)
    end
    
    return table.concat(result)
end

-- Base64 encoding
local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

function Utils.base64Encode(data)
    local result = {}
    local padding = ""
    
    local mod = #data % 3
    if mod > 0 then
        padding = string.rep("=", 3 - mod)
        data = data .. string.rep("\0", 3 - mod)
    end
    
    for i = 1, #data, 3 do
        local b1, b2, b3 = string.byte(data, i, i + 2)
        local n = b1 * 65536 + b2 * 256 + b3
        
        table.insert(result, b64chars:sub(math.floor(n / 262144) + 1, math.floor(n / 262144) + 1))
        table.insert(result, b64chars:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1))
        table.insert(result, b64chars:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1))
        table.insert(result, b64chars:sub(n % 64 + 1, n % 64 + 1))
    end
    
    local encoded = table.concat(result)
    return encoded:sub(1, #encoded - #padding) .. padding
end

function Utils.base64Decode(data)
    local b64lookup = {}
    for i = 1, #b64chars do
        b64lookup[b64chars:sub(i, i)] = i - 1
    end
    
    data = data:gsub("=", "")
    local result = {}
    
    for i = 1, #data, 4 do
        local n = 0
        for j = 0, 3 do
            local char = data:sub(i + j, i + j)
            if char ~= "" then
                n = n * 64 + (b64lookup[char] or 0)
            end
        end
        
        local bytes = math.min(3, #data - i + 1 - 1)
        for j = 1, bytes do
            table.insert(result, string.char(math.floor(n / (256 ^ (3 - j))) % 256))
        end
    end
    
    return table.concat(result)
end

-- Generate checksum
function Utils.checksum(str)
    local sum = 0
    for i = 1, #str do
        sum = (sum + string.byte(str, i) * i) % 2147483647
    end
    return sum
end

-- Hash string (simple but fast)
function Utils.hash(str)
    local h = 5381
    for i = 1, #str do
        h = ((h * 33) + string.byte(str, i)) % 2147483647
    end
    return h
end

-- Timing utilities
function Utils.time(fn)
    local start = os.clock()
    local result = fn()
    return result, os.clock() - start
end

-- File utilities
function Utils.readFile(path)
    local file, err = io.open(path, "r")
    if not file then return nil, err end
    local content = file:read("*a")
    file:close()
    return content
end

function Utils.writeFile(path, content)
    local file, err = io.open(path, "w")
    if not file then return nil, err end
    file:write(content)
    file:close()
    return true
end

return Utils
