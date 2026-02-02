--[[
    Switch Statement Generator
    Creates switch-like constructs for state machines
]]

local AST = require("core.ast")

local SwitchGenerator = {}
SwitchGenerator.__index = SwitchGenerator

function SwitchGenerator.new(random)
    local self = setmetatable({}, SwitchGenerator)
    self.random = random
    return self
end

-- Generate a switch-like if-elseif chain
function SwitchGenerator:generate(switchVar, cases)
    local clauses = {}
    
    for i, case in ipairs(cases) do
        local condition = AST.binaryExpression("==",
            AST.identifier(switchVar),
            AST.numberLiteral(case.value)
        )
        
        if i == 1 then
            table.insert(clauses, AST.ifClause(condition, case.body))
        else
            table.insert(clauses, AST.elseifClause(condition, case.body))
        end
    end
    
    return AST.ifStatement(clauses)
end

-- Generate a table-based switch
function SwitchGenerator:generateTableSwitch(switchVar, cases)
    local tableName = self.random:identifier(12)
    
    -- Build the dispatch table
    local tableFields = {}
    
    for _, case in ipairs(cases) do
        local funcBody = case.body
        table.insert(funcBody, AST.returnStatement({}))
        
        table.insert(tableFields, AST.tableField(
            AST.numberLiteral(case.value),
            AST.functionExpression({}, funcBody)
        ))
    end
    
    local tableDecl = AST.localStatement(
        { AST.identifier(tableName) },
        { AST.tableExpression(tableFields) }
    )
    
    -- Call the dispatch function
    local dispatchCall = AST.callStatement(
        AST.callExpression(
            AST.indexExpression(
                AST.identifier(tableName),
                AST.identifier(switchVar)
            ),
            {}
        )
    )
    
    return AST.doStatement({ tableDecl, dispatchCall })
end

return SwitchGenerator
