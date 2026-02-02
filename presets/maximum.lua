--[[
    Maximum Preset
    Maximum protection - very slow but extremely secure
]]

return {
    name = "maximum",
    description = "Maximum protection - very slow but extremely secure",
    
    config = {
        minify = true,
        
        layers = {
            stringEncryption = true,
            controlFlow = true,
            virtualization = true,
            antiTamper = true,
            antiDump = true,
            mutation = true,
            decoys = true,
        },
        
        stringEncryption = {
            method = "multi",
            keyLength = 48,
            splitStrings = true,
            minSplitLength = 2,
        },
        
        controlFlow = {
            flattenIntensity = 0.9,
            opaquePredicates = true,
            bogusBranches = true,
            maxStates = 100,
        },
        
        virtualization = {
            instructionCount = 64,
            registerCount = 32,
            polymorphic = true,
        },
        
        antiTamper = {
            integrityCheck = true,
            environmentCheck = true,
            checksumVerify = true,
            crashOnDetect = true,
        },
        
        antiDump = {
            memoryProtection = true,
            chunkEncryption = true,
            antiDebug = true,
        },
        
        mutation = {
            renameVariables = true,
            renameLength = 20,
            deadCodeInjection = true,
            deadCodeDensity = 0.4,
            expressionMutation = true,
        },
        
        decoys = {
            fakeFunctions = 30,
            fakeStrings = 40,
            honeyTraps = true,
            fakeApiCalls = true,
        },
    },
}
