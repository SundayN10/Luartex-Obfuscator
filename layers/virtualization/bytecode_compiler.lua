--[[
    Bytecode Compiler
    Compiles AST to custom bytecode
]]

local AST = require("core.ast")

local BytecodeCompiler = {}
BytecodeCompiler.__index = BytecodeCompiler

function BytecodeCompiler.new(parent)
    local self = setmetatable({}, BytecodeCompiler)
    
    self.parent = parent
    self.random = parent.random
    self.bytecode = {}
    self.constants = {}
    self.variables = {}
    self.labels = {}
    self.instructions = nil
    
    return self
end

function BytecodeCompiler:compile(body, instructions)
    self.bytecode = {}
    self.constants = {}
    self.variables = {}
    self.labels = {}
    self.instructions = instructions
    
    local success, err = pcall(function()
        for _, statement in ipairs(body) do
            self:compileStatement(statement)
        end
    end)
    
    if not success then
        return nil, err
    end
    
    -- Add implicit return
    self:emit("RET", 0)
    
    return self.bytecode
end

function BytecodeCompiler:emit(opName, ...)
    local instr = self.instructions[opName]
    if not instr then
        error("Unknown instruction: " .. opName)
    end
    
    table.insert(self.bytecode, instr.opcode)
    
    for _, arg in ipairs({...}) do
        if type(arg) == "number" then
            -- Encode as 2 bytes
            table.insert(self.bytecode, math.floor(arg / 256) % 256)
            table.insert(self.bytecode, arg % 256)
        end
    end
end

function BytecodeCompiler:addConstant(value)
    for i, c in ipairs(self.constants) do
        if c == value then
            return i - 1
        end
    end
    
    table.insert(self.constants, value)
    return #self.constants - 1
end

function BytecodeCompiler:getVariable(name)
    if self.variables[name] then
        return self.variables[name]
    end
    
    local index = 0
    for _ in pairs(self.variables) do
        index = index + 1
    end
    
    self.variables[name] = index
    return index
end

function BytecodeCompiler:compileStatement(stmt)
    local handler = self["compile" .. stmt.type]
    
    if handler then
        handler(self, stmt)
    else
        error("Cannot compile statement: " .. stmt.type)
    end
end

function BytecodeCompiler:compileExpression(expr)
    local handler = self["compile" .. expr.type]
    
    if handler then
        handler(self, expr)
    else
        error("Cannot compile expression: " .. expr.type)
    end
end

-- Statement compilers
function BytecodeCompiler:compileLocalStatement(stmt)
    for i, init in ipairs(stmt.init or {}) do
        self:compileExpression(init)
        
        if stmt.variables[i] then
            local varIndex = self:getVariable(stmt.variables[i].name)
            self:emit("STORE", varIndex)
        end
    end
end

function BytecodeCompiler:compileAssignmentStatement(stmt)
    for i, init in ipairs(stmt.init) do
        self:compileExpression(init)
        
        if stmt.variables[i] then
            local var = stmt.variables[i]
            
            if var.type == AST.NodeType.IDENTIFIER then
                local varIndex = self:getVariable(var.name)
                self:emit("STORE", varIndex)
            end
        end
    end
end

function BytecodeCompiler:compileCallStatement(stmt)
    self:compileExpression(stmt.expression)
    self:emit("POP")  -- Discard return value
end

function BytecodeCompiler:compileReturnStatement(stmt)
    local argCount = #(stmt.arguments or {})
    
    for _, arg in ipairs(stmt.arguments or {}) do
        self:compileExpression(arg)
    end
    
    self:emit("RET", argCount)
end

function BytecodeCompiler:compileIfStatement(stmt)
    local endLabels = {}
    
    for i, clause in ipairs(stmt.clauses) do
        if clause.type == AST.NodeType.IF_CLAUSE or 
           clause.type == AST.NodeType.ELSEIF_CLAUSE then
            
            self:compileExpression(clause.condition)
            
            local skipLabel = #self.bytecode + 10  -- Approximate
            self:emit("JMPNOT", skipLabel)
            
            for _, bodyStmt in ipairs(clause.body) do
                self:compileStatement(bodyStmt)
            end
            
            table.insert(endLabels, #self.bytecode)
            self:emit("JMP", 0)  -- Will patch later
            
        elseif clause.type == AST.NodeType.ELSE_CLAUSE then
            for _, bodyStmt in ipairs(clause.body) do
                self:compileStatement(bodyStmt)
            end
        end
    end
    
    -- Patch end jumps
    local endPos = #self.bytecode
    for _, labelPos in ipairs(endLabels) do
        self.bytecode[labelPos + 1] = math.floor(endPos / 256) % 256
        self.bytecode[labelPos + 2] = endPos % 256
    end
end

function BytecodeCompiler:compileWhileStatement(stmt)
    local startPos = #self.bytecode
    
    self:compileExpression(stmt.condition)
    
    local exitJumpPos = #self.bytecode + 1
    self:emit("JMPNOT", 0)  -- Will patch
    
    for _, bodyStmt in ipairs(stmt.body) do
        self:compileStatement(bodyStmt)
    end
    
    self:emit("JMP", startPos)
    
    -- Patch exit jump
    local endPos = #self.bytecode
    self.bytecode[exitJumpPos + 1] = math.floor(endPos / 256) % 256
    self.bytecode[exitJumpPos + 2] = endPos % 256
end

-- Expression compilers
function BytecodeCompiler:compileIdentifier(expr)
    local varIndex = self:getVariable(expr.name)
    self:emit("FETCH", varIndex)
end

function BytecodeCompiler:compileNumberLiteral(expr)
    local constIndex = self:addConstant(expr.value)
    self:emit("LOAD", constIndex)
end

function BytecodeCompiler:compileStringLiteral(expr)
    local constIndex = self:addConstant(expr.value)
    self:emit("LOAD", constIndex)
end

function BytecodeCompiler:compileBooleanLiteral(expr)
    local constIndex = self:addConstant(expr.value)
    self:emit("LOAD", constIndex)
end

function BytecodeCompiler:compileNilLiteral(expr)
    local constIndex = self:addConstant(nil)
    self:emit("LOAD", constIndex)
end

function BytecodeCompiler:compileBinaryExpression(expr)
    self:compileExpression(expr.left)
    self:compileExpression(expr.right)
    
    local opMap = {
        ["+"] = "ADD",
        ["-"] = "SUB",
        ["*"] = "MUL",
        ["/"] = "DIV",
        ["%"] = "MOD",
        ["^"] = "POW",
        [".."] = "CONCAT",
        ["=="] = "EQ",
        ["~="] = "NE",
        ["<"] = "LT",
        ["<="] = "LE",
        [">"] = "GT",
        [">="] = "GE",
        ["and"] = "AND",
        ["or"] = "OR",
    }
    
    local opcode = opMap[expr.operator]
    if opcode then
        self:emit(opcode)
    else
        error("Unknown operator: " .. expr.operator)
    end
end

function BytecodeCompiler:compileUnaryExpression(expr)
    self:compileExpression(expr.argument)
    
    local opMap = {
        ["-"] = "NEG",
        ["not"] = "NOT",
        ["#"] = "LEN",
    }
    
    local opcode = opMap[expr.operator]
    if opcode then
        self:emit(opcode)
    else
        error("Unknown unary operator: " .. expr.operator)
    end
end

function BytecodeCompiler:compileCallExpression(expr)
    -- Push arguments
    for _, arg in ipairs(expr.arguments) do
        self:compileExpression(arg)
    end
    
    -- Push function
    self:compileExpression(expr.base)
    
    self:emit("CALL", #expr.arguments)
end

return BytecodeCompiler
