--[[
    Control Flow Flattener
    Converts structured code into state machine
]]

local AST = require("core.ast")

local Flattener = {}
Flattener.__index = Flattener

function Flattener.new(parent)
    local self = setmetatable({}, Flattener)
    
    self.parent = parent
    self.random = parent.random
    self.config = parent.config
    self.stateCounter = 0
    
    return self
end

function Flattener:flatten(ast)
    local self_ref = self
    
    AST.transform(ast, {
        [AST.NodeType.FUNCTION_DECLARATION] = function(node)
            if self_ref.random:float() < self_ref.config.flattenIntensity then
                self_ref:flattenFunction(node)
            end
            return node
        end,
        
        [AST.NodeType.FUNCTION_EXPRESSION] = function(node)
            if self_ref.random:float() < self_ref.config.flattenIntensity then
                self_ref:flattenFunction(node)
            end
            return node
        end,
    })
    
    return ast
end

function Flattener:flattenFunction(funcNode)
    local body = funcNode.body
    
    -- Need at least 3 statements to flatten
    if not body or #body < 3 then
        return
    end
    
    -- Check for unsupported constructs
    for _, stmt in ipairs(body) do
        if stmt.type == AST.NodeType.RETURN_STATEMENT then
            -- Has return, need special handling
        end
    end
    
    -- Create states for each statement
    local states = {}
    local stateVar = self.random:identifier(12)
    local runningVar = self.random:identifier(12)
    
    for i, stmt in ipairs(body) do
        local stateId = self:nextStateId()
        table.insert(states, {
            id = stateId,
            statement = stmt,
            nextState = i < #body and (stateId + 1) or nil,
        })
    end
    
    -- Shuffle state order (but keep logic intact)
    local shuffledStates = {}
    local stateMap = {}
    
    for i, state in ipairs(states) do
        stateMap[state.id] = state
        table.insert(shuffledStates, state)
    end
    
    self.random:shuffle(shuffledStates)
    
    -- Build the dispatcher
    local dispatchCases = {}
    
    for _, state in ipairs(shuffledStates) do
        local caseBody = { state.statement }
        
        -- Add state transition
        if state.nextState then
            table.insert(caseBody, AST.assignmentStatement(
                { AST.identifier(stateVar) },
                { AST.numberLiteral(state.nextState) }
            ))
        else
            -- End of function
            table.insert(caseBody, AST.assignmentStatement(
                { AST.identifier(runningVar) },
                { AST.booleanLiteral(false) }
            ))
        end
        
        table.insert(dispatchCases, AST.ifClause(
            AST.binaryExpression("==",
                AST.identifier(stateVar),
                AST.numberLiteral(state.id)
            ),
            caseBody
        ))
    end
    
    -- Convert if clauses to elseif chain
    local ifStatement
    if #dispatchCases > 0 then
        local clauses = { dispatchCases[1] }
        
        for i = 2, #dispatchCases do
            local clause = dispatchCases[i]
            clause.type = AST.NodeType.ELSEIF_CLAUSE
            table.insert(clauses, clause)
        end
        
        ifStatement = AST.ifStatement(clauses)
    end
    
    -- Build new function body
    local initialState = states[1] and states[1].id or 0
    
    local newBody = {
        -- local state = initialState
        AST.localStatement(
            { AST.identifier(stateVar) },
            { AST.numberLiteral(initialState) }
        ),
        
        -- local running = true
        AST.localStatement(
            { AST.identifier(runningVar) },
            { AST.booleanLiteral(true) }
        ),
        
        -- while running do
        AST.whileStatement(
            AST.identifier(runningVar),
            { ifStatement }
        ),
    }
    
    -- Replace function body
    funcNode.body = newBody
end

function Flattener:nextStateId()
    self.stateCounter = self.stateCounter + 1
    return self.stateCounter * self.random:int(7, 13) + self.random:int(100, 999)
end

return Flattener
