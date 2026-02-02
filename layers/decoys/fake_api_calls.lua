--[[
    Fake API Calls
    Generates fake API calls that look legitimate
]]

local AST = require("core.ast")

local FakeApiCalls = {}
FakeApiCalls.__index = FakeApiCalls

function FakeApiCalls.new(parent)
    local self = setmetatable({}, FakeApiCalls)
    
    self.parent = parent
    self.random = parent.random
    
    return self
end

function FakeApiCalls:inject(ast)
    local self_ref = self
    
    -- Find function bodies and inject fake calls
    AST.transform(ast, {
        [AST.NodeType.FUNCTION_DECLARATION] = function(node)
            self_ref:injectIntroBody(node.body)
            return node
        end,
        
        [AST.NodeType.FUNCTION_EXPRESSION] = function(node)
            self_ref:injectIntroBody(node.body)
            return node
        end,
    })
    
    return ast
end

function FakeApiCalls:injectIntroBody(body)
    if not body or #body < 2 then
        return
    end
    
    -- Inject 1-3 fake calls
    local count = self.random:int(1, 3)
    
    for _ = 1, count do
        local position = self.random:int(1, #body)
        local fakeCall = self:generateFakeCall()
        
        -- Wrap in if false to never execute
        local wrapped = AST.ifStatement({
            AST.ifClause(
                AST.booleanLiteral(false),
                { fakeCall }
            )
        })
        
        table.insert(body, position, wrapped)
    end
end

function FakeApiCalls:generateFakeCall()
    local calls = {
        -- Roblox-like calls
        function(self)
            return AST.callStatement(
                AST.callExpression(
                    AST.memberExpression(
                        AST.identifier("game"),
                        AST.identifier("GetService"),
                        ":"
                    ),
                    { AST.stringLiteral(self.random:choice({
                        "HttpService", "DataStoreService", "Players",
                        "ReplicatedStorage", "ServerStorage"
                    })) }
                )
            )
        end,
        
        -- HTTP-like calls
        function(self)
            return AST.localStatement(
                { AST.identifier(self.random:identifier(10)) },
                {
                    AST.callExpression(
                        AST.memberExpression(
                            AST.identifier("http"),
                            AST.identifier("request"),
                            "."
                        ),
                        {
                            AST.tableExpression({
                                AST.tableField(
                                    AST.stringLiteral("url"),
                                    AST.stringLiteral("https://api." .. self.random:string(8) .. ".com")
                                ),
                                AST.tableField(
                                    AST.stringLiteral("method"),
                                    AST.stringLiteral("POST")
                                )
                            })
                        }
                    )
                }
            )
        end,
        
        -- Database-like calls
        function(self)
            return AST.localStatement(
                { AST.identifier(self.random:identifier(10)) },
                {
                    AST.callExpression(
                        AST.memberExpression(
                            AST.identifier("database"),
                            AST.identifier("query"),
                            ":"
                        ),
                        { AST.stringLiteral("SELECT * FROM users WHERE id = " .. self.random:int(1, 1000)) }
                    )
                }
            )
        end,
        
        -- File-like calls
        function(self)
            return AST.callStatement(
                AST.callExpression(
                    AST.memberExpression(
                        AST.identifier("fs"),
                        AST.identifier("writeFile"),
                        "."
                    ),
                    {
                        AST.stringLiteral("/tmp/" .. self.random:string(8) .. ".dat"),
                        AST.stringLiteral(self.random:string(20))
                    }
                )
            )
        end,
    }
    
    local generator = calls[self.random:int(1, #calls)]
    return generator(self)
end

return FakeApiCalls
