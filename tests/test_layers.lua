--[[
    Layer Tests
]]

local TestLayers = {}

local Parser = require("core.parser")
local Compiler = require("core.compiler")
local Random = require("core.random")

local tests = {}

-- Mock Luartex for testing
local function createMockLuartex()
    local random = Random.new(12345)
    
    return {
        random = random,
        logger = {
            debug = function() end,
            info = function() end,
            warn = function() end,
            error = function() end,
        },
        config = {
            stringEncryption = {
                method = "xor",
                keyLength = 16,
            },
            controlFlow = {
                flattenIntensity = 0.5,
                opaquePredicates = true,
                bogusBranches = true,
            },
            mutation = {
                renameVariables = true,
                renameLength = 12,
                deadCodeInjection = true,
                deadCodeDensity = 0.2,
                expressionMutation = true,
            },
            decoys = {
                fakeFunctions = 5,
                fakeStrings = 5,
                honeyTraps = true,
                fakeApiCalls = false,
            },
        },
        stats = {},
    }
end

function tests.test_variable_renamer()
    local VariableRenamer = require("layers.mutation.variable_renamer")
    local luartex = createMockLuartex()
    
    local source = [[
        local myVariable = 123
        local anotherVar = myVariable + 456
        print(anotherVar)
    ]]
    
    local ast = Parser.parse(source)
    local renamer = VariableRenamer.new({
        parent = luartex,
        random = luartex.random,
        config = luartex.config.mutation,
    })
    
    ast = renamer:rename(ast)
    local output = Compiler.compile(ast, { minify = false })
    
    -- Original variable names should not appear
    assert(not output:find("myVariable"), "myVariable should be renamed")
    assert(not output:find("anotherVar"), "anotherVar should be renamed")
    
    -- But built-in names should remain
    assert(output:find("print"), "print should not be renamed")
    
    return true
end

function tests.test_dead_code_injection()
    local DeadCodeInjection = require("layers.mutation.dead_code_injection")
    local luartex = createMockLuartex()
    
    local source = [[
        local function test()
            local x = 1
            local y = 2
            return x + y
        end
    ]]
    
    local ast = Parser.parse(source)
    local originalStatements = #ast.body[1].body
    
    local injector = DeadCodeInjection.new({
        parent = luartex,
        random = luartex.random,
        config = luartex.config.mutation,
    })
    
    ast = injector:inject(ast)
    local newStatements = #ast.body[1].body
    
    -- Should have more statements after injection
    assert(newStatements > originalStatements, "Should inject dead code")
    
    return true
end

function tests.test_expression_mutator()
    local ExpressionMutator = require("layers.mutation.expression_mutator")
    local luartex = createMockLuartex()
    
    local source = [[
        local x = true
        local y = false
        local z = 1 + 2
    ]]
    
    local ast = Parser.parse(source)
    
    local mutator = ExpressionMutator.new({
        parent = luartex,
        random = luartex.random,
    })
    
    ast = mutator:mutate(ast)
    local output = Compiler.compile(ast, { minify = false })
    
    -- Output should be valid Lua
    local fn, err = loadstring(output)
    assert(fn ~= nil, "Output should be valid Lua: " .. tostring(err))
    
    return true
end

function tests.test_fake_functions()
    local FakeFunctions = require("layers.decoys.fake_functions")
    local luartex = createMockLuartex()
    
    local source = [[
        print("Hello")
    ]]
    
    local ast = Parser.parse(source)
    local originalCount = #ast.body
    
    local generator = FakeFunctions.new({
        parent = luartex,
        random = luartex.random,
    })
    
    ast = generator:inject(ast, 5)
    
    -- Should have more statements
    assert(#ast.body > originalCount, "Should inject fake functions")
    assert(#ast.body >= originalCount + 5, "Should inject at least 5 fake functions")
    
    return true
end

function tests.test_constant_folder()
    local ConstantFolder = require("layers.mutation.constant_folder")
    local luartex = createMockLuartex()
    
    local source = [[
        local x = 42
    ]]
    
    local ast = Parser.parse(source)
    
    local folder = ConstantFolder.new({
        parent = luartex,
        random = luartex.random,
    })
    
    ast = folder:fold(ast)
    local output = Compiler.compile(ast, { minify = false })
    
    -- Output should be valid and produce same result
    local fn = loadstring(output)
    assert(fn ~= nil, "Output should be valid Lua")
    
    return true
end

function TestLayers.run()
    local passed = 0
    local failed = 0
    local errors = {}
    
    for name, testFn in pairs(tests) do
        local success, err = pcall(testFn)
        
        if success then
            print("  ✓ " .. name)
            passed = passed + 1
        else
            print("  ✗ " .. name .. ": " .. tostring(err))
            failed = failed + 1
            table.insert(errors, {
                module = "test_layers",
                test = name,
                error = tostring(err)
            })
        end
    end
    
    return {
        passed = passed,
        failed = failed,
        errors = errors
    }
end

return TestLayers
