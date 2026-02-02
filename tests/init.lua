--[[
    Luartex Test Runner
]]

local Tests = {}

local testModules = {
    "tests.test_parser",
    "tests.test_layers",
    "tests.test_obfuscation",
}

function Tests.run()
    local passed = 0
    local failed = 0
    local errors = {}
    
    print("=" .. string.rep("=", 50))
    print("Luartex Obfuscator - Test Suite")
    print("=" .. string.rep("=", 50))
    
    for _, moduleName in ipairs(testModules) do
        print("\nRunning: " .. moduleName)
        print("-" .. string.rep("-", 40))
        
        local success, module = pcall(require, moduleName)
        
        if not success then
            print("  ✗ Failed to load module: " .. tostring(module))
            failed = failed + 1
            table.insert(errors, {
                module = moduleName,
                error = "Failed to load: " .. tostring(module)
            })
        else
            if type(module) == "table" and module.run then
                local testSuccess, testResult = pcall(module.run)
                
                if testSuccess and testResult then
                    passed = passed + (testResult.passed or 0)
                    failed = failed + (testResult.failed or 0)
                    
                    if testResult.errors then
                        for _, err in ipairs(testResult.errors) do
                            table.insert(errors, err)
                        end
                    end
                else
                    print("  ✗ Test execution failed: " .. tostring(testResult))
                    failed = failed + 1
                    table.insert(errors, {
                        module = moduleName,
                        error = tostring(testResult)
                    })
                end
            else
                print("  ✗ Invalid test module (no run function)")
                failed = failed + 1
            end
        end
    end
    
    -- Print summary
    print("\n" .. string.rep("=", 50))
    print("Test Results")
    print(string.rep("=", 50))
    print(string.format("  Passed: %d", passed))
    print(string.format("  Failed: %d", failed))
    print(string.format("  Total:  %d", passed + failed))
    
    if #errors > 0 then
        print("\nErrors:")
        for i, err in ipairs(errors) do
            print(string.format("  %d. [%s] %s", i, err.module or "?", err.error or "Unknown error"))
        end
    end
    
    print(string.rep("=", 50))
    
    return {
        passed = passed,
        failed = failed,
        errors = errors,
        success = failed == 0
    }
end

-- Run if executed directly
if arg and arg[0] and arg[0]:find("tests/init") then
    local result = Tests.run()
    os.exit(result.success and 0 or 1)
end

return Tests
