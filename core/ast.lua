--[[
    Luartex AST Node Definitions and Helpers
]]

local AST = {}

-- Node types
AST.NodeType = {
    -- Program
    CHUNK = "Chunk",
    
    -- Statements
    LOCAL_STATEMENT = "LocalStatement",
    ASSIGNMENT_STATEMENT = "AssignmentStatement",
    CALL_STATEMENT = "CallStatement",
    IF_STATEMENT = "IfStatement",
    WHILE_STATEMENT = "WhileStatement",
    DO_STATEMENT = "DoStatement",
    FOR_NUMERIC_STATEMENT = "ForNumericStatement",
    FOR_GENERIC_STATEMENT = "ForGenericStatement",
    REPEAT_STATEMENT = "RepeatStatement",
    FUNCTION_DECLARATION = "FunctionDeclaration",
    RETURN_STATEMENT = "ReturnStatement",
    BREAK_STATEMENT = "BreakStatement",
    GOTO_STATEMENT = "GotoStatement",
    LABEL_STATEMENT = "LabelStatement",
    
    -- Expressions
    IDENTIFIER = "Identifier",
    LITERAL = "Literal",
    STRING_LITERAL = "StringLiteral",
    NUMBER_LITERAL = "NumberLiteral",
    BOOLEAN_LITERAL = "BooleanLiteral",
    NIL_LITERAL = "NilLiteral",
    VARARG = "Vararg",
    BINARY_EXPRESSION = "BinaryExpression",
    UNARY_EXPRESSION = "UnaryExpression",
    CALL_EXPRESSION = "CallExpression",
    MEMBER_EXPRESSION = "MemberExpression",
    INDEX_EXPRESSION = "IndexExpression",
    FUNCTION_EXPRESSION = "FunctionExpression",
    TABLE_EXPRESSION = "TableExpression",
    TABLE_FIELD = "TableField",
    
    -- Clauses
    IF_CLAUSE = "IfClause",
    ELSEIF_CLAUSE = "ElseifClause",
    ELSE_CLAUSE = "ElseClause",
}

-- Create a new node
function AST.node(type, properties)
    local node = {
        type = type,
    }
    
    if properties then
        for k, v in pairs(properties) do
            node[k] = v
        end
    end
    
    return node
end

-- Chunk (program root)
function AST.chunk(body)
    return AST.node(AST.NodeType.CHUNK, { body = body or {} })
end

-- Statements
function AST.localStatement(variables, init)
    return AST.node(AST.NodeType.LOCAL_STATEMENT, {
        variables = variables,
        init = init or {},
    })
end

function AST.assignmentStatement(variables, init)
    return AST.node(AST.NodeType.ASSIGNMENT_STATEMENT, {
        variables = variables,
        init = init,
    })
end

function AST.callStatement(expression)
    return AST.node(AST.NodeType.CALL_STATEMENT, {
        expression = expression,
    })
end

function AST.ifStatement(clauses)
    return AST.node(AST.NodeType.IF_STATEMENT, {
        clauses = clauses,
    })
end

function AST.ifClause(condition, body)
    return AST.node(AST.NodeType.IF_CLAUSE, {
        condition = condition,
        body = body or {},
    })
end

function AST.elseifClause(condition, body)
    return AST.node(AST.NodeType.ELSEIF_CLAUSE, {
        condition = condition,
        body = body or {},
    })
end

function AST.elseClause(body)
    return AST.node(AST.NodeType.ELSE_CLAUSE, {
        body = body or {},
    })
end

function AST.whileStatement(condition, body)
    return AST.node(AST.NodeType.WHILE_STATEMENT, {
        condition = condition,
        body = body or {},
    })
end

function AST.doStatement(body)
    return AST.node(AST.NodeType.DO_STATEMENT, {
        body = body or {},
    })
end

function AST.forNumericStatement(variable, start, limit, step, body)
    return AST.node(AST.NodeType.FOR_NUMERIC_STATEMENT, {
        variable = variable,
        start = start,
        limit = limit,
        step = step,
        body = body or {},
    })
end

function AST.forGenericStatement(variables, iterators, body)
    return AST.node(AST.NodeType.FOR_GENERIC_STATEMENT, {
        variables = variables,
        iterators = iterators,
        body = body or {},
    })
end

function AST.repeatStatement(condition, body)
    return AST.node(AST.NodeType.REPEAT_STATEMENT, {
        condition = condition,
        body = body or {},
    })
end

function AST.functionDeclaration(identifier, parameters, body, isLocal)
    return AST.node(AST.NodeType.FUNCTION_DECLARATION, {
        identifier = identifier,
        parameters = parameters or {},
        body = body or {},
        isLocal = isLocal or false,
    })
end

function AST.returnStatement(arguments)
    return AST.node(AST.NodeType.RETURN_STATEMENT, {
        arguments = arguments or {},
    })
end

function AST.breakStatement()
    return AST.node(AST.NodeType.BREAK_STATEMENT, {})
end

-- Expressions
function AST.identifier(name)
    return AST.node(AST.NodeType.IDENTIFIER, { name = name })
end

function AST.stringLiteral(value, raw)
    return AST.node(AST.NodeType.STRING_LITERAL, {
        value = value,
        raw = raw or ("\"" .. value .. "\""),
    })
end

function AST.numberLiteral(value, raw)
    return AST.node(AST.NodeType.NUMBER_LITERAL, {
        value = value,
        raw = raw or tostring(value),
    })
end

function AST.booleanLiteral(value)
    return AST.node(AST.NodeType.BOOLEAN_LITERAL, { value = value })
end

function AST.nilLiteral()
    return AST.node(AST.NodeType.NIL_LITERAL, {})
end

function AST.vararg()
    return AST.node(AST.NodeType.VARARG, {})
end

function AST.binaryExpression(operator, left, right)
    return AST.node(AST.NodeType.BINARY_EXPRESSION, {
        operator = operator,
        left = left,
        right = right,
    })
end

function AST.unaryExpression(operator, argument)
    return AST.node(AST.NodeType.UNARY_EXPRESSION, {
        operator = operator,
        argument = argument,
    })
end

function AST.callExpression(base, arguments)
    return AST.node(AST.NodeType.CALL_EXPRESSION, {
        base = base,
        arguments = arguments or {},
    })
end

function AST.memberExpression(base, identifier, indexer)
    return AST.node(AST.NodeType.MEMBER_EXPRESSION, {
        base = base,
        identifier = identifier,
        indexer = indexer or ".",
    })
end

function AST.indexExpression(base, index)
    return AST.node(AST.NodeType.INDEX_EXPRESSION, {
        base = base,
        index = index,
    })
end

function AST.functionExpression(parameters, body)
    return AST.node(AST.NodeType.FUNCTION_EXPRESSION, {
        parameters = parameters or {},
        body = body or {},
    })
end

function AST.tableExpression(fields)
    return AST.node(AST.NodeType.TABLE_EXPRESSION, {
        fields = fields or {},
    })
end

function AST.tableField(key, value)
    return AST.node(AST.NodeType.TABLE_FIELD, {
        key = key,
        value = value,
    })
end

-- Utility functions
function AST.isStatement(node)
    local stmtTypes = {
        [AST.NodeType.LOCAL_STATEMENT] = true,
        [AST.NodeType.ASSIGNMENT_STATEMENT] = true,
        [AST.NodeType.CALL_STATEMENT] = true,
        [AST.NodeType.IF_STATEMENT] = true,
        [AST.NodeType.WHILE_STATEMENT] = true,
        [AST.NodeType.DO_STATEMENT] = true,
        [AST.NodeType.FOR_NUMERIC_STATEMENT] = true,
        [AST.NodeType.FOR_GENERIC_STATEMENT] = true,
        [AST.NodeType.REPEAT_STATEMENT] = true,
        [AST.NodeType.FUNCTION_DECLARATION] = true,
        [AST.NodeType.RETURN_STATEMENT] = true,
        [AST.NodeType.BREAK_STATEMENT] = true,
    }
    return stmtTypes[node.type] == true
end

function AST.isExpression(node)
    local exprTypes = {
        [AST.NodeType.IDENTIFIER] = true,
        [AST.NodeType.STRING_LITERAL] = true,
        [AST.NodeType.NUMBER_LITERAL] = true,
        [AST.NodeType.BOOLEAN_LITERAL] = true,
        [AST.NodeType.NIL_LITERAL] = true,
        [AST.NodeType.VARARG] = true,
        [AST.NodeType.BINARY_EXPRESSION] = true,
        [AST.NodeType.UNARY_EXPRESSION] = true,
        [AST.NodeType.CALL_EXPRESSION] = true,
        [AST.NodeType.MEMBER_EXPRESSION] = true,
        [AST.NodeType.INDEX_EXPRESSION] = true,
        [AST.NodeType.FUNCTION_EXPRESSION] = true,
        [AST.NodeType.TABLE_EXPRESSION] = true,
    }
    return exprTypes[node.type] == true
end

function AST.isLiteral(node)
    local literalTypes = {
        [AST.NodeType.STRING_LITERAL] = true,
        [AST.NodeType.NUMBER_LITERAL] = true,
        [AST.NodeType.BOOLEAN_LITERAL] = true,
        [AST.NodeType.NIL_LITERAL] = true,
    }
    return literalTypes[node.type] == true
end

-- Walk the AST
function AST.walk(node, visitor)
    if type(node) ~= "table" then
        return
    end
    
    -- Pre-visit
    if visitor.enter then
        local result = visitor.enter(node)
        if result == false then
            return
        end
    end
    
    -- Visit type-specific handler
    if visitor[node.type] then
        visitor[node.type](node)
    end
    
    -- Visit children
    for key, value in pairs(node) do
        if key ~= "type" and type(value) == "table" then
            if value.type then
                AST.walk(value, visitor)
            else
                for _, child in ipairs(value) do
                    if type(child) == "table" and child.type then
                        AST.walk(child, visitor)
                    end
                end
            end
        end
    end
    
    -- Post-visit
    if visitor.leave then
        visitor.leave(node)
    end
end

-- Transform the AST
function AST.transform(node, transformer)
    if type(node) ~= "table" then
        return node
    end
    
    -- Pre-transform
    if transformer.enter then
        local result = transformer.enter(node)
        if result then
            node = result
        end
    end
    
    -- Type-specific transformer
    if transformer[node.type] then
        local result = transformer[node.type](node)
        if result then
            node = result
        end
    end
    
    -- Transform children
    for key, value in pairs(node) do
        if key ~= "type" and type(value) == "table" then
            if value.type then
                node[key] = AST.transform(value, transformer)
            else
                for i, child in ipairs(value) do
                    if type(child) == "table" and child.type then
                        value[i] = AST.transform(child, transformer)
                    end
                end
            end
        end
    end
    
    -- Post-transform
    if transformer.leave then
        local result = transformer.leave(node)
        if result then
            node = result
        end
    end
    
    return node
end

-- Clone a node
function AST.clone(node)
    if type(node) ~= "table" then
        return node
    end
    
    local cloned = {}
    
    for key, value in pairs(node) do
        if type(value) == "table" then
            cloned[key] = AST.clone(value)
        else
            cloned[key] = value
        end
    end
    
    return cloned
end

return AST
