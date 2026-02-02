--[[
    Bogus Branches
    Adds fake branches that are never taken
]]

local AST = require("core.ast")

local BogusBranches = {}
BogusBranches.__index = BogusBranches

function BogusBranches.new(parent)
    local self = setmetatable({}, BogusBranches)
    
    self.parent = parent
    self.random = parent.random
    self.opaquePredicates = parent.opaquePredicates
    
    return self
end

function BogusBranches:inject(ast)
    local self_ref = self
    
    -- Find all function bodies and inject bogus branches
    AST.transform(ast, {
        [AST.NodeType.FUNCTION_DECLARATION] = function(node)
            self_ref:injectIntoBody(node.body)
            return node
        end,
        
        [AST.NodeType.FUNCTION_EXPRESSION] = function(node)
            self_ref:injectIntoBody(node.body)
            return node
        end,
    })
    
    return ast
end

function BogusBranches:injectIntoBody(body)
    if not body or #body == 0 then
        return
    end
    
    -- Inject 1-3 bogus branches
    local count = self.random:int(1, 3)
    
    for _ = 1, count do
        local position = self.random:int(1, #body + 1)
        local bogusIf = self:generateBogusBranch()
        table.insert(body, position, bogusIf)
    end
end

function BogusBranches:generateBogusBranch()
    -- Generate a condition that's always false
    local condition = self.opaquePredicates:generateFalse()
    
    -- Generate fake body that will never execute
    local fakeBody = self:generateFakeBody()
    
    return AST.ifStatement({
        AST.ifClause(condition, fakeBody)
    })
end

function BogusBranches:generateFakeBody()
    local bodies = {
        -- Fake error call
        function(self)
            return {
                AST.callStatement(
                    AST.callExpression(
                        AST.identifier("error"),
                        { AST.stringLiteral(self.random:string(20)) }
                    )
                )
            }
        end,
        
        -- Fake variable assignment
        function(self)
            return {
                AST.localStatement(
                    { AST.identifier(self.random:identifier(12)) },
                    { AST.numberLiteral(self.random:int(1, 99999)) }
                )
            }
        end,
        
        -- Fake function call
        function(self)
            return {
                AST.callStatement(
                    AST.callExpression(
                        AST.identifier(self.random:identifier(10)),
                        { AST.stringLiteral(self.random:string(10)) }
                    )
                )
            }
        end,
        
        -- Fake while loop
        function(self)
            return {
                AST.whileStatement(
                    AST.booleanLiteral(true),
                    {
                        AST.breakStatement()
                    }
                )
            }
        end,
        
        -- Nested fake if
        function(self)
            return {
                AST.ifStatement({
                    AST.ifClause(
                        AST.booleanLiteral(true),
                        {
                            AST.callStatement(
                                AST.callExpression(
                                    AST.identifier("print"),
                                    { AST.stringLiteral(self.random:string(15)) }
                                )
                            )
                        }
                    )
                })
            }
        end,
    }
    
    local chosen = bodies[self.random:int(1, #bodies)]
    return chosen(self)
end

return BogusBranches
