--[[
    Roblox Preset
    Optimized for Roblox scripts
]]

return {
    name = "roblox",
    description = "Optimized for Roblox scripts",
    
    config = {
        minify = true,
        
        roblox = {
            enabled = true,
            executor = "auto",
            safeMode = true,
        },
        
        layers = {
            stringEncryption = true,
            controlFlow = true,
            virtualization = false,  -- Can cause issues with some executors
            antiTamper = true,
            antiDump = true,
            mutation = true,
            decoys = true,
        },
        
        stringEncryption = {
            method = "multi",
            keyLength = 32,
            splitStrings = true,
        },
        
        controlFlow = {
            flattenIntensity = 0.6,
            opaquePredicates = true,
            bogusBranches = true,
        },
        
        antiTamper = {
            integrityCheck = true,
            environmentCheck = true,
            checksumVerify = false,  -- Can be problematic in Roblox
            crashOnDetect = true,
        },
        
        antiDump = {
            memoryProtection = false,  -- Limited in Roblox
            chunkEncryption = true,
            antiDebug = true,
        },
        
        mutation = {
            renameVariables = true,
            renameLength = 14,
            deadCodeInjection = true,
            deadCodeDensity = 0.25,
            expressionMutation = true,
        },
        
        decoys = {
            fakeFunctions = 15,
            fakeStrings = 20,
            honeyTraps = true,
            fakeApiCalls = true,
        },
    },
}
