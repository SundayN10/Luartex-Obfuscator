--[[
    Variable Renamer
    Renames all variables to random identifiers
]]

local AST = require("core.ast")

local VariableRenamer = {}
VariableRenamer.__index = VariableRenamer

-- Reserved Lua keywords and built-in globals
VariableRenamer.RESERVED = {
    -- Keywords
    "and", "break", "do", "else", "elseif", "end", "false", "for",
    "function", "goto", "if", "in", "local", "nil", "not", "or",
    "repeat", "return", "then", "true", "until", "while",
    
    -- Globals
    "_G", "_VERSION", "assert", "collectgarbage", "dofile", "error",
    "getfenv", "getmetatable", "ipairs", "load", "loadfile", "loadstring",
    "next", "pairs", "pcall", "print", "rawequal", "rawget", "rawset",
    "require", "select", "setfenv", "setmetatable", "tonumber", "tostring",
    "type", "unpack", "xpcall",
    
    -- Libraries
    "coroutine", "debug", "io", "math", "os", "package", "string", "table",
    "bit", "bit32", "utf8",
    
    -- Roblox globals
    "game", "workspace", "script", "Instance", "Vector3", "CFrame",
    "Color3", "BrickColor", "UDim2", "UDim", "Ray", "Region3", "Enum",
    "wait", "spawn", "delay", "tick", "time", "warn",
}

function VariableRenamer.new(parent)
    local self = setmetatable({}, VariableRenamer)
    
    self.parent = parent
    self.random = parent.random
    self.config = parent.config
    
    self.mapping = {}
    self.scopes = {}
    self.currentScope = nil
    self.reserved = {}
    
    for _, name in ipairs(VariableRenamer.RESERVED) do
        self.reserved[name] = true
    end
    
    return self
end

function VariableRenamer:rename(ast)
    self.mapping = {}
    self.scopes = {}
    
    self:pushScope("global")
    self:walkAndRename(ast)
    self:popScope()
    
    return ast
end

function VariableRenamer:pushScope(name)
    local scope = {
        name = name,
        parent = self.currentScope,
        variables = {},
    }
    
    table.insert(self.scopes, scope)
    self.currentScope = scope
    
    return scope
end

function VariableRenamer:popScope()
    local scope = self.currentScope
    self.currentScope = scope and scope.parent
    return scope
end

function VariableRenamer:declareVariable(name)
    if self.reserved[name] then
        return name
    end
    
    local newName = self.random:identifier(self.config.renameLength or 16)
    
    -- Ensure uniqueness
    while self:isUsed(newName) do
        newName = self.random:identifier(self.config.renameLength or 16)
    end
    
    if self.currentScope then
        self.currentScope.variables[name] = newName
    end
    
    return newName
end

function VariableRenamer:resolveVariable(name)
    if self.reserved[name] then
        return name
    end
    
    local scope = self.currentScope
    
    while scope do
        if scope.variables[name] then
            return scope.variables[name]
        end
        scope = scope.parent
    end
    
    return name
end

function VariableRenamer:isUsed(name)
    for _, scope in ipairs(self.scopes) do
        for _, varName in pairs(scope.variables) do
            if varName == name then
                return true
            end
        end
    end
    return false
end

function VariableRenamer:walkAndRename(node)
    if not node or type(node) ~= "table" then
        return
    end
    
    local nodeType = node.type
    
    -- Handle different node types
    if nodeType == AST.NodeType.LOCAL_STATEMENT then
        -- First process init expressions
        for _, init in ipairs(node.init or {}) do
            self:walkAndRename(init)
        end
        
        -- Then declare and rename variables
        for _, var in ipairs(node.variables) do
            if var.type == AST.NodeType.IDENTIFIER then
                var.name = self:declareVariable(var.name)
            end
        end
        return
        
    elseif nodeType == AST.NodeType.FUNCTION_DECLARATION then
        -- Rename function identifier if local
        if node.isLocal and node.identifier and node.identifier.type == AST.NodeType.IDENTIFIER then
            node.identifier.name = self:declareVariable(node.identifier.name)
        end
        
        -- New scope for function body
        self:pushScope("function")
        
        -- Declare parameters
        for _, param in ipairs(node.parameters) do
            if param.type == AST.NodeType.IDENTIFIER then
                param.name = self:declareVariable(param.name)
            end
        end
        
        -- Process body
        for _, stmt in ipairs(node.body) do
            self:walkAndRename(stmt)
        end
        
        self:popScope()
        return
        
    elseif nodeType == AST.NodeType.FUNCTION_EXPRESSION then
        self:pushScope("function")
        
        for _, param in ipairs(node.parameters) do
            if param.type == AST.NodeType.IDENTIFIER then
                param.name = self:declareVariable(param.name)
            end
        end
        
        for _, stmt in ipairs(node.body) do
            self:walkAndRename(stmt)
        end
        
        self:popScope()
        return
        
    elseif nodeType == AST.NodeType.FOR_NUMERIC_STATEMENT then
        self:pushScope("for")
        
        node.variable.name = self:declareVariable(node.variable.name)
        
        self:walkAndRename(node.start)
        self:walkAndRename(node.limit)
        if node.step then
            self:walkAndRename(node.step)
        end
        
        for _, stmt in ipairs(node.body) do
            self:walkAndRename(stmt)
        end
        
        self:popScope()
        return
        
    elseif nodeType == AST.NodeType.FOR_GENERIC_STATEMENT then
        self:pushScope("for")
        
        -- Process iterators first
        for _, iter in ipairs(node.iterators) do
            self:walkAndRename(iter)
        end
        
        -- Declare loop variables
        for _, var in ipairs(node.variables) do
            if var.type == AST.NodeType.IDENTIFIER then
                var.name = self:declareVariable(var.name)
            end
        end
        
        for _, stmt in ipairs(node.body) do
            self:walkAndRename(stmt)
        end
        
        self:popScope()
        return
        
    elseif nodeType == AST.NodeType.IDENTIFIER then
        -- Resolve variable reference
        node.name = self:resolveVariable(node.name)
        return
    end
    
    -- Recurse into children
    for key, value in pairs(node) do
        if key ~= "type" and type(value) == "table" then
            if value.type then
                self:walkAndRename(value)
            else
                for _, child in ipairs(value) do
                    if type(child) == "table" then
                        self:walkAndRename(child)
                    end
                end
            end
        end
    end
end

return VariableRenamer
