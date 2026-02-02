--[[
    Loop Transformer
    Transforms loops into more complex structures
]]

local AST = require("core.ast")

local LoopTransformer = {}
LoopTransformer.__index = LoopTransformer

function LoopTransformer.new(parent)
    local self = setmetatable({}, LoopTransformer)
    
    self.parent = parent
    self.random = parent.random
    
    return self
end

function LoopTransformer:transform(ast)
    local self_ref = self
    
    AST.transform(ast, {
        [AST.NodeType.WHILE_STATEMENT] = function(node)
            if self_ref.random:bool(0.4) then
                return self_ref:transformWhile(node)
            end
            return node
        end,
        
        [AST.NodeType.FOR_NUMERIC_STATEMENT] = function(node)
            if self_ref.random:bool(0.3) then
                return self_ref:transformForNumeric(node)
            end
            return node
        end,
    })
    
    return ast
end

-- Transform while into repeat-until with inverted condition
function LoopTransformer:transformWhile(node)
    -- while cond do body end
    -- becomes:
    -- if cond then repeat body until not cond end
    
    local invertedCondition = AST.unaryExpression("not", node.condition)
    
    local repeatStmt = AST.repeatStatement(
        invertedCondition,
        node.body
    )
    
    return AST.ifStatement({
        AST.ifClause(
            AST.clone(node.condition),
            { repeatStmt }
        )
    })
end

-- Transform numeric for into while loop
function LoopTransformer:transformForNumeric(node)
    -- for i = start, limit, step do body end
    -- becomes:
    -- do
    --   local i = start
    --   while i <= limit do
    --     body
    --     i = i + step
    --   end
    -- end
    
    local varName = node.variable.name
    local step = node.step or AST.numberLiteral(1)
    
    -- Determine comparison operator based on step
    local compareOp = "<="  -- Assume positive step
    
    local newBody = {}
    for _, stmt in ipairs(node.body) do
        table.insert(newBody, stmt)
    end
    
    -- Add increment
    table.insert(newBody, AST.assignmentStatement(
        { AST.identifier(varName) },
        { AST.binaryExpression("+",
            AST.identifier(varName),
            step
        )}
    ))
    
    local whileStmt = AST.whileStatement(
        AST.binaryExpression(compareOp,
            AST.identifier(varName),
            node.limit
        ),
        newBody
    )
    
    return AST.doStatement({
        AST.localStatement(
            { AST.identifier(varName) },
            { node.start }
        ),
        whileStmt
    })
end

function AST.clone(node)
    if type(node) ~= "table" then
        return node
    end
    
    local cloned = {}
    for k, v in pairs(node) do
        cloned[k] = AST.clone(v)
    end
    
    return cloned
end

return LoopTransformer
