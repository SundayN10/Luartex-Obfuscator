--[[
    Structure Randomizer
    Randomizes code structure without changing behavior
]]

local AST = require("core.ast")

local StructureRandomizer = {}
StructureRandomizer.__index = StructureRandomizer

function StructureRandomizer.new(parent)
    local self = setmetatable({}, StructureRandomizer)
    
    self.parent = parent
    self.random = parent.random
    
    return self
end

function StructureRandomizer:randomize(ast)
    local self_ref = self
    
    AST.transform(ast, {
        [AST.NodeType.DO_STATEMENT] = function(node)
            -- Potentially wrap in additional do-end
            if self_ref.random:bool(0.3) then
                return AST.doStatement({ node })
            end
            return node
        end,
        
        [AST.NodeType.LOCAL_STATEMENT] = function(node)
            -- Wrap in do-end block
            if self_ref.random:bool(0.2) then
                return AST.doStatement({ node })
            end
            return node
        end,
    })
    
    return ast
end

function StructureRandomizer:wrapInDoBlock(statement)
    return AST.doStatement({ statement })
end

function StructureRandomizer:wrapInIIFE(statements)
    return AST.callExpression(
        AST.functionExpression({}, statements),
        {}
    )
end

return StructureRandomizer
